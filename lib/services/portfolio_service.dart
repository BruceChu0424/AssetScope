import '../data/repositories/accounts_repo.dart';
import '../data/repositories/ledger_repo.dart';
import '../data/repositories/meta_repo.dart';
import '../domain/invest/returns.dart';
import '../domain/ledger/account.dart';
import '../domain/ledger/transaction.dart';
import '../domain/money/fx_rate.dart';
import '../domain/valuation/valuation.dart';
import 'stats_service.dart';

/// 持仓快照：数量、成本、市值与浮盈。
class HoldingSnapshot {
  const HoldingSnapshot({
    required this.account,
    required this.quantity,
    required this.costMinor,
    required this.unitPrice,
    required this.marketValueMinor,
    required this.priceMissing,
  });

  final Account account;
  final Rational quantity;
  final BigInt costMinor;

  /// 最新单价；缺失为 null。
  final Rational? unitPrice;

  /// 数量 × 单价；缺价为 null。
  final BigInt? marketValueMinor;
  final bool priceMissing;

  /// 浮盈 = 市值 − 成本（缺价为 null）。
  Rational? get unrealizedPnl {
    if (marketValueMinor == null) return null;
    return Rational.fromInt(marketValueMinor!) - Rational.fromInt(costMinor);
  }
}

/// 投资组合收益结果。
class PortfolioReturn {
  const PortfolioReturn({
    required this.xirr,
    required this.twr,
    required this.twrValuationPoints,
    required this.currentValueMinor,
    required this.investedMinor,
    required this.skippedFlows,
  });

  /// 年化 XIRR（资金加权）；现金流不足或无解时为 null。
  final double? xirr;

  /// 年化 TWR（时间加权）；可用估值点不足时为 null。
  final double? twr;

  /// 参与计算的月末估值点数（含今天）。
  final int twrValuationPoints;

  final BigInt currentValueMinor;
  final BigInt investedMinor;
  final int skippedFlows;
}

/// 投资组合服务：持仓快照 + 组合收益（XIRR/TWR）。
///
/// 组合边界 = 券商现金 + 全部持仓账户。买卖/分红为组合内部事件，
/// 只有跨边界转账与外部收支是现金流；期末以当前市值作为回收。
/// 外币折算按交易日前最近汇率，缺失的流水跳过并计数披露
///（宁可少算不乱算）。TWR 取近 13 个月末 + 今天的组合估值点
///（全部持仓当时有价才有效），估值点不足 2 个时为 null；年化按实际天数复利。
class PortfolioService {
  PortfolioService(this._accounts, this._ledger, this._meta, this._stats);

  final AccountsRepo _accounts;
  final LedgerRepo _ledger;
  final MetaRepo _meta;
  final StatsService _stats;

  /// 持仓快照（数量 / 成本 / 市值 / 浮盈）。
  Future<List<HoldingSnapshot>> holdings() async {
    final accounts = await _accounts.all();
    final end = DateTime.now();
    final qtys = await _ledger.quantityBalancesAt(end);
    final money = await _ledger.moneyBalancesAt(end);
    final valuations = await _meta.valuations();
    final byAccount = <String, List<ValuationRecord>>{};
    for (final v in valuations) {
      byAccount.putIfAbsent(v.accountId, () => []).add(v);
    }
    final out = <HoldingSnapshot>[];
    for (final a in accounts) {
      if (!a.isHolding) continue;
      final qty = qtys[a.id] ?? Rational.zero();
      if (qty.isZero) continue;
      final cost = a.costBasisAccountId == null
          ? BigInt.zero
          : (money[a.costBasisAccountId!] ?? BigInt.zero);
      final r = ValuationResolver.resolve(byAccount[a.id] ?? const [], end);
      final price = r.record?.unitPrice;
      if (price == null) {
        out.add(HoldingSnapshot(
            account: a, quantity: qty, costMinor: cost,
            unitPrice: null, marketValueMinor: null, priceMissing: true));
      } else {
        out.add(HoldingSnapshot(
            account: a, quantity: qty, costMinor: cost,
            unitPrice: price, marketValueMinor: (qty * price).rounded(),
            priceMissing: false));
      }
    }
    out.sort((x, y) =>
        (y.marketValueMinor ?? BigInt.zero).compareTo(x.marketValueMinor ?? BigInt.zero));
    return out;
  }

  /// 组合收益：XIRR（资金加权）+ TWR（时间加权），口径见 docs/05 §6。
  Future<PortfolioReturn> portfolioReturns() async {
    final now = DateTime.now();
    final accounts = await _accounts.all();
    final portfolioIds = accounts
        .where((a) =>
            a.assetSubtype == AssetSubtype.brokerCash || a.isHolding)
        .map((a) => a.id)
        .toSet();
    if (portfolioIds.isEmpty) {
      return PortfolioReturn(
          xirr: null,
          twr: null,
          twrValuationPoints: 0,
          currentValueMinor: BigInt.zero,
          investedMinor: BigInt.zero,
          skippedFlows: 0);
    }
    final base = await _stats.baseCurrency();
    final byId = {for (final a in accounts) a.id: a};

    Future<BigInt?> toBase(BigInt minor, String ccy, DateTime at) async {
      if (ccy == base) return minor;
      final rate = await _meta.toBaseRate(ccy: ccy, base: base, onOrBefore: at);
      if (rate == null) return null;
      return (Rational.fromInt(minor) * rate.rate).rounded();
    }

    // 期末组合市值（含券商现金）。
    final nw = await _stats.netWorthAt(now);
    var value = BigInt.zero;
    for (final i in nw.items) {
      if (portfolioIds.contains(i.account.id) && !i.valuationMissing) {
        value += i.valueBaseMinor;
      }
    }

    final txs = await _ledger.list(
        from: DateTime(2000), to: now.add(const Duration(days: 1)));
    final byDate = <DateTime, BigInt>{};
    var skipped = 0;
    for (final tx in txs) {
      if (tx.status == TxStatus.voided) continue;
      if (tx.kind == TxKind.buy ||
          tx.kind == TxKind.sell ||
          tx.kind == TxKind.dividend) {
        continue; // 组合内部事件
      }
      var netInto = BigInt.zero; // 流入组合为正
      var hasForeignGap = false;
      for (final p in tx.postings) {
        if (!portfolioIds.contains(p.accountId)) continue;
        if (p.amountMinor == null || p.currencyCode == null) continue;
        final acc = byId[p.accountId];
        if (acc == null) continue;
        final b = await toBase(p.amountMinor!, p.currencyCode!, tx.date);
        if (b == null) {
          hasForeignGap = true;
          continue;
        }
        netInto += b;
      }
      if (netInto == BigInt.zero && !hasForeignGap) continue;
      if (hasForeignGap) {
        skipped++;
        continue;
      }
      final day = DateTime(tx.date.year, tx.date.month, tx.date.day);
      byDate[day] = (byDate[day] ?? BigInt.zero) - netInto; // 投入为负
    }
    final flows = <XirrFlow>[
      for (final e in byDate.entries) XirrFlow(e.key, e.value),
      XirrFlow(now, value),
    ];
    final invested = byDate.values
        .where((v) => v.isNegative)
        .fold(BigInt.zero, (a, b) => a + b.abs());

    // --- TWR 估值点（月末 + 今天；任一持仓缺价则该点作废） ---
    final valuations = await _meta.valuations();
    final byAccount = <String, List<ValuationRecord>>{};
    for (final v in valuations) {
      byAccount.putIfAbsent(v.accountId, () => []).add(v);
    }
    final points = <TwrValuation>[];
    for (var k = 13; k >= 0; k--) {
      final d = k == 0
          ? now
          : DateTime(now.year, now.month - k + 1, 0, 23, 59, 59); // 月末
      final money =
          await _ledger.moneyBalancesAt(d, accountIds: portfolioIds);
      final qtys = await _ledger.quantityBalancesAt(d);
      var pointValue = BigInt.zero;
      var valid = true;
      for (final a in accounts) {
        if (!portfolioIds.contains(a.id)) continue;
        if (a.assetSubtype == AssetSubtype.brokerCash) {
          final b = money[a.id] ?? BigInt.zero;
          final v = await toBase(b, a.currencyCode, d);
          if (v == null) {
            valid = false;
            break;
          }
          pointValue += v;
        } else if (a.isHolding) {
          final qty = qtys[a.id] ?? Rational.zero();
          if (qty.isZero) continue;
          final price =
              ValuationResolver.resolve(byAccount[a.id] ?? const [], d)
                  .record
                  ?.unitPrice;
          if (price == null) {
            valid = false; // 当时持仓缺价：该估值点不可用
            break;
          }
          final ccyValue = (qty * price).rounded();
          final v = await toBase(ccyValue, a.currencyCode, d);
          if (v == null) {
            valid = false;
            break;
          }
          pointValue += v;
        }
      }
      if (valid && pointValue > BigInt.zero) {
        points.add(TwrValuation(d, pointValue));
      }
    }
    final twr = TwrCalculator.twr(
      valuations: points,
      flows: [for (final e in byDate.entries) TwrFlow(e.key, -e.value)],
      annualizeDays: 365,
    );
    return PortfolioReturn(
      xirr: xirr(flows),
      twr: twr,
      twrValuationPoints: points.length,
      currentValueMinor: value,
      investedMinor: invested,
      skippedFlows: skipped,
    );
  }
}
