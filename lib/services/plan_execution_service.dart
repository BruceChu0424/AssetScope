import '../data/repositories/accounts_repo.dart';
import '../data/repositories/ledger_repo.dart';
import '../data/repositories/planning_repo.dart';
import '../domain/ledger/account.dart';
import '../domain/ledger/transaction.dart';
import '../domain/planning/recurrence.dart';
import '../domain/utils/dates.dart';

/// 一笔到期待落地的计划发生。
class DueOccurrence {
  const DueOccurrence({
    required this.occurrence,
    required this.event,
    required this.externalId,
    required this.autoReady,
    this.blockedReason,
  });

  final Occurrence occurrence;
  final ScheduledEvent event;

  /// 幂等键：同一计划同一天只落一笔（重复执行/重复点击安全）。
  final String externalId;

  /// autoPost 已开启且配置齐全（账户存在、类型与币种匹配），可自动过账。
  final bool autoReady;

  /// 不能自动过账的原因（UI 提示用），[autoReady] 为 true 时为 null。
  final String? blockedReason;
}

/// 计划落地执行：把周期计划的到期发生变成真实交易。
///
/// 口径（docs/05 §6）：
/// - 支出计划 → 消费（支付账户可用资产或信用卡/负债）；收入计划 → 收入（入账资产）；
/// - 落账日期 = 发生日（不是执行日），月报归属正确；
/// - 幂等：externalId 为 `plan:<事件id>:<yyyyMMdd>`，已存在（含作废）即视为已处理；
/// - 区间估算取中位数落账，用户可在确认弹层改金额；
/// - 单次跳过写入事件的 skippedDateKeys，预测同步剔除（口径一致）。
/// - [DueOccurrence.blockedReason] 对自动与手动计划都披露账户配置问题；
///   自动过账（postAutoDue）只处理 autoPost 且配置齐全的。
class PlanExecutionService {
  PlanExecutionService(this.accounts, this.ledger, this.planning);

  final AccountsRepo accounts;
  final LedgerRepo ledger;
  final PlanningRepo planning;

  /// 回溯窗口：太久没打开应用时，只提示最近一年内到期的发生。
  static const int defaultLookbackDays = 365;

  static String externalIdFor(String eventId, DateTime date) =>
      planExternalId(eventId, date);

  /// 到期未落地清单（[from]..today，默认回溯一年）。
  Future<List<DueOccurrence>> pendingDue({
    DateTime? now,
    int lookbackDays = defaultLookbackDays,
  }) async {
    final today = _today(now);
    final from = DateTime(
      today.year,
      today.month,
      today.day,
    ).subtract(Duration(days: lookbackDays));
    final events = (await planning.scheduledEvents())
        .where((e) => e.isActive)
        .toList();
    if (events.isEmpty) return const [];
    final posted = await ledger.externalIds();
    final accountsById = {for (final a in await accounts.all()) a.id: a};
    final due = <DueOccurrence>[];
    for (final e in events) {
      for (final o in e.expand(from, today)) {
        final id = externalIdFor(e.id, o.date);
        if (posted.contains(id)) continue;
        final (ready, reason) = _autoPostCheck(e, accountsById);
        due.add(
          DueOccurrence(
            occurrence: o,
            event: e,
            externalId: id,
            autoReady: ready,
            blockedReason: reason,
          ),
        );
      }
    }
    due.sort((a, b) {
      final c = a.occurrence.date.compareTo(b.occurrence.date);
      return c != 0 ? c : a.event.name.compareTo(b.event.name);
    });
    return due;
  }

  /// 自动落地：执行所有 autoReady 的到期发生，返回入账笔数。
  /// 只处理 autoPost=true 且配置齐全的计划；其余留在待落地清单由用户确认。
  Future<int> postAutoDue({DateTime? now}) async {
    final due = await pendingDue(now: now);
    var count = 0;
    for (final d in due) {
      if (!d.autoReady) continue;
      if (await ledger.externalIdExists(d.externalId)) continue;
      await _post(d, accountsById: null);
      count++;
    }
    return count;
  }

  /// 手动落地一笔（确认弹层调用）。金额/账户/分类可改；
  /// 幂等：已入账时抛 [StateError] 由调用方提示。
  Future<LedgerTransaction> postOne(
    DueOccurrence d, {
    BigInt? amountMinor,
    String? payAccountId,
    String? categoryId,
  }) async {
    if (await ledger.externalIdExists(d.externalId)) {
      throw StateError('这笔计划发生已入账');
    }
    final all = await accounts.all();
    final byId = {for (final a in all) a.id: a};
    return _post(
      d,
      accountsById: byId,
      amountOverrideMinor: amountMinor,
      payAccountId: payAccountId,
      categoryId: categoryId,
    );
  }

  /// 跳过这一次：写入事件的 skippedDateKeys，预测与待落地同时剔除。
  Future<void> skip(DueOccurrence d) async {
    final key = dateKey(d.occurrence.date);
    await planning.saveScheduledEvent(
      d.event.copyWith(skippedDateKeys: {...d.event.skippedDateKeys, key}),
    );
  }

  Future<LedgerTransaction> _post(
    DueOccurrence d, {
    required Map<String, Account>? accountsById,
    BigInt? amountOverrideMinor,
    String? payAccountId,
    String? categoryId,
  }) async {
    final o = d.occurrence;
    final e = d.event;
    final all = accountsById ?? {for (final a in await accounts.all()) a.id: a};
    final payId = payAccountId ?? e.paymentAccountId;
    if (payId == null) throw StateError('未设置支付账户');
    final pay = all[payId];
    if (pay == null) throw StateError('支付账户不存在：$payId');
    final amount = (amountOverrideMinor ?? o.amountMinor).abs();
    if (amount <= BigInt.zero) throw StateError('计划金额无效');

    final isIncome = e.direction == EventDirection.inflow;
    final catId =
        categoryId ??
        e.categoryId ??
        (isIncome ? 'cat:i:other' : 'cat:e:other');
    final cat = all[catId];
    if (cat == null) throw StateError('分类不存在：$catId');

    final draft = isIncome
        ? TxBuilders.income(
            destAsset: pay,
            incomeCategory: cat,
            amountMinor: amount,
            date: o.date,
            note: '${e.name} · 计划',
            tags: const ['计划'],
            source: TxSource.planGenerated,
            externalId: d.externalId,
          )
        : TxBuilders.expense(
            payFrom: pay,
            expenseCategory: cat,
            amountMinor: amount,
            date: o.date,
            note: '${e.name} · 计划',
            tags: const ['计划'],
            source: TxSource.planGenerated,
            externalId: d.externalId,
          );
    return ledger.post(draft);
  }

  /// 自动过账条件：autoPost 开 + 账户配置且类型/币种匹配。
  /// 分类缺省时自动落"其他"，因此不阻塞。
  /// 返回 (autoReady, 受阻原因)。账户问题对非自动计划同样披露（UI 提示）。
  (bool, String?) _autoPostCheck(
    ScheduledEvent e,
    Map<String, Account> accountsById,
  ) {
    final payId = e.paymentAccountId;
    if (payId == null) return (false, '未设置支付账户');
    final pay = accountsById[payId];
    if (pay == null) return (false, '支付账户不存在');
    if (pay.currencyCode != e.currencyCode) return (false, '账户币种与计划不一致');
    if (pay.isHolding) return (false, '支付账户不能是持仓账户');
    if (pay.assetSubtype == AssetSubtype.receivable) {
      return (false, '支付账户不能是应收款账户');
    }
    final isIncome = e.direction == EventDirection.inflow;
    if (isIncome && pay.type != AccountType.asset) {
      return (false, '收入计划必须入账到资产账户');
    }
    if (!isIncome &&
        pay.type != AccountType.asset &&
        pay.type != AccountType.liability) {
      return (false, '支出计划的支付账户须为资产或信用卡/负债');
    }
    return (e.autoPost, null);
  }

  DateTime _today(DateTime? now) {
    final n = now ?? DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }
}
