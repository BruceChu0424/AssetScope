import '../data/repositories/accounts_repo.dart';
import '../data/repositories/ledger_repo.dart';
import '../data/repositories/meta_repo.dart';
import '../data/repositories/planning_repo.dart';
import '../domain/ledger/account.dart';
import '../domain/ledger/ledger_math.dart';
import '../domain/money/fx_rate.dart';
import '../domain/planning/cash_projection.dart';
import '../domain/planning/recurrence.dart';
import '../l10n/runtime_l10n.dart';

/// 现金流预测服务：把计划、债务、预算拼装为现金事件后调用领域投影器。
class ProjectionService {
  ProjectionService(this._accounts, this._ledger, this._planning, this._meta);

  final AccountsRepo _accounts;
  final LedgerRepo _ledger;
  final PlanningRepo _planning;
  final MetaRepo _meta;

  /// 生成预测。
  ///
  /// 组成：
  /// - 期初现金：流动性 ≤ [cashLiquidityDays] 的资产账户余额；
  /// - 事件：固定/预定支出计划、预期收入计划、债务还款计划未付部分；
  /// - 预算基线：本月剩余预算按剩余天数摊到每日（可选）；
  /// - 准备金：目标已预留总额 + 应急现金底线（settings）。
  Future<CashProjection> project({
    DateTime? now,
    int horizonDays = 90,
    bool includeBudgetBaseline = true,
    int cashLiquidityDays = 1,
  }) async {
    final input = await buildInput(
      now: now,
      horizonDays: horizonDays,
      includeBudgetBaseline: includeBudgetBaseline,
      cashLiquidityDays: cashLiquidityDays,
    );
    return CashProjector.project(input);
  }

  /// 组装预测输入（事件流 + 期初余额 + 准备金）。
  /// 独立暴露给情景模拟：基线与情景共用同一份输入，只换事件流重放。
  Future<ProjectionInput> buildInput({
    DateTime? now,
    int horizonDays = 90,
    bool includeBudgetBaseline = true,
    int cashLiquidityDays = 1,
  }) async {
    final n = now ?? DateTime.now();
    final from = DateTime(n.year, n.month, n.day);
    final through = from.add(Duration(days: horizonDays));
    final base = await _meta.settingString('baseCurrency') ?? 'CNY';

    // 1) 现金账户
    final all = await _accounts.all();
    final snapshots = <CashAccountSnapshot>[];
    final balances = await _ledger.moneyBalancesAt(from);
    for (final a in all) {
      if (a.type != AccountType.asset ||
          a.archived ||
          a.isHolding ||
          a.valuationMethod != ValuationMethod.ledger) {
        continue;
      }
      if (a.liquidityDays > cashLiquidityDays) continue;
      final signed = balances[a.id] ?? BigInt.zero;
      final bal = LedgerMath.displayBalance(a.type, signed);
      final rate = a.currencyCode == base
          ? Rational.one
          : (await _meta.toBaseRate(
                  ccy: a.currencyCode,
                  base: base,
                  onOrBefore: from,
                ))?.rate ??
                Rational.one;
      snapshots.add(
        CashAccountSnapshot(
          accountId: a.id,
          name: a.name,
          currencyCode: a.currencyCode,
          balanceMinor: bal,
          toBaseRate: rate,
        ),
      );
    }

    // 2) 计划事件（已落地的发生剔除：余额已含当天交易，不再重复扣减。
    //    docs/05 §4"已实际支付的计划由服务层过滤"。）
    final events = <CashEvent>[];
    Future<BigInt> toBaseMinorV(BigInt minor, String ccy) async {
      if (ccy == base) return minor;
      final r = await _meta.toBaseRate(ccy: ccy, base: base, onOrBefore: from);
      return r == null ? minor : (Rational.fromInt(minor) * r.rate).rounded();
    }

    final postedExtIds = await _ledger.externalIds();
    for (final e in await _planning.scheduledEvents()) {
      for (final occ in e.expand(from, through)) {
        if (postedExtIds.contains(planExternalId(e.id, occ.date))) continue;
        events.add(
          CashEvent(
            date: occ.date,
            amountBaseMinor:
                await toBaseMinorV(occ.amountMinor.abs(), e.currencyCode) *
                (occ.amountMinor.isNegative ? -BigInt.one : BigInt.one),
            label: occ.eventName,
            accountId: occ.paymentAccountId,
            isEstimate: occ.isEstimate,
            kind: occ.amountMinor.isNegative
                ? CashEventKind.planned
                : CashEventKind.incomeExpected,
          ),
        );
      }
    }

    // 3) 债务还款计划（未支付部分）
    final contracts = await _planning.debtContracts();
    for (final c in contracts.entries) {
      final acc = byId(all, c.key);
      if (acc == null) continue;
      final schedule = c.value.generateSchedule();
      if (schedule.isEmpty) continue;
      // 已发生还款笔数 → 视为已付期数（近似，见 docs/05）。
      final paidTxs = await _ledger.list(
        from: schedule.first.dueDate,
        to: through,
        accountId: c.key,
      );
      final paidCount = paidTxs.where((t) => t.kind.name == 'loanRepay').length;
      for (var i = paidCount; i < schedule.length; i++) {
        final e = schedule[i];
        if (e.dueDate.isBefore(from)) continue;
        if (e.dueDate.isAfter(through)) break;
        events.add(
          CashEvent(
            date: e.dueDate,
            amountBaseMinor: -await toBaseMinorV(
              e.totalMinor,
              acc.currencyCode,
            ),
            label: '${acc.name}${rt(' 第')}${e.seq}${rt('期')}',
            accountId: null,
            kind: CashEventKind.debtRepay,
          ),
        );
      }
    }

    // 4) 预算基线：v1 由调用方在 events 里附加（如上月日均消费），
    //    服务层不重复计算，避免与月预算双扣。

    // 5) 准备金：目标预留 + 应急底线（只扣一次；目标到期日释放占用）
    BigInt reserve = BigInt.zero;
    final releases = <ReserveRelease>[];
    for (final g in await _planning.goals()) {
      if (g.status == GoalStatus.active &&
          g.reservedAmountMinor > BigInt.zero) {
        reserve += await toBaseMinorV(g.reservedAmountMinor, base);
        if (!g.targetDate.isAfter(through)) {
          releases.add(
            ReserveRelease(
              date: g.targetDate,
              amountBaseMinor: await toBaseMinorV(g.reservedAmountMinor, base),
            ),
          );
        }
      }
    }
    final baselineStr = await _meta.settingString('baselineMinCashMinor');
    final baseline = baselineStr == null
        ? BigInt.zero
        : BigInt.parse(baselineStr);

    return ProjectionInput(
      baseCurrencyCode: base,
      accounts: snapshots,
      events: events,
      reserveBaseMinor: reserve,
      reserveReleases: releases,
      baselineMinCashBaseMinor: baseline,
      fromDate: from,
      horizonDays: horizonDays,
    );
  }

  Account? byId(List<Account> list, String id) {
    for (final a in list) {
      if (a.id == id) return a;
    }
    return null;
  }
}
