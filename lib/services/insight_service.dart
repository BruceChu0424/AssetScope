import '../data/repositories/accounts_repo.dart';
import '../data/repositories/ledger_repo.dart';
import '../data/repositories/meta_repo.dart';
import '../data/repositories/planning_repo.dart';
import '../domain/analytics/anomaly.dart';
import '../domain/analytics/health.dart';
import '../domain/analytics/recurring_detector.dart';
import '../domain/analytics/spending_pace.dart';
import '../domain/debt/debt_contract.dart';
import '../domain/import/category_rules.dart';
import '../domain/ledger/account.dart';
import '../domain/ledger/transaction.dart';
import '../domain/money/fx_rate.dart';
import '../l10n/runtime_l10n.dart';
import 'stats_service.dart';

/// 单条智慧洞察（首页"体检"卡与洞察列表用）。
class Insight {
  const Insight({
    required this.icon,
    required this.title,
    required this.detail,
    this.severity = InsightSeverity.info,
  });

  final String icon;
  final String title;
  final String detail;
  final InsightSeverity severity;
}

enum InsightSeverity { info, good, warn }

/// 首页聚合的智慧视图模型。
class InsightBundle {
  const InsightBundle({
    required this.health,
    required this.pace,
    required this.anomalies,
    required this.recurring,
    required this.milestone,
    required this.insights,
  });

  final FinancialHealth health;
  final SpendingPace pace;
  final List<SpendingAnomaly> anomalies;
  final List<RecurringSuggestion> recurring;

  /// 净资产下一个整数关口（当前值向上取最近的 10 万/百万级整数）的预测。
  final NetWorthMilestone? milestone;
  final List<Insight> insights;
}

/// 智慧分析服务：把仓储数据喂给纯算法层，产出首页/报表可用的结论。
class InsightService {
  InsightService(this._accounts, this._ledger, this._planning, this._meta)
    : stats = StatsService(_accounts, _ledger, _meta);

  final AccountsRepo _accounts;
  final LedgerRepo _ledger;
  final PlanningRepo _planning;
  final MetaRepo _meta;
  final StatsService stats;

  /// 商户分类规则：持久化在 settings 表（key: categoryRules）。
  Future<List<CategoryRule>> categoryRules() async =>
      CategoryRulesEngine.decodeRules(
        await _meta.settingString('categoryRules'),
      );

  Future<void> saveCategoryRules(List<CategoryRule> rules) =>
      _meta.setSetting('categoryRules', CategoryRulesEngine.encodeRules(rules));

  /// 用全部历史（对手方→分类）构建学习引擎。
  Future<CategoryRulesEngine> buildRulesEngine() async {
    final rules = await categoryRules();
    final txs = await _ledger.list(
      from: DateTime(2000),
      to: DateTime.now().add(const Duration(days: 1)),
    );
    final agg = <String, Map<String, int>>{};
    for (final tx in txs) {
      if (tx.status == TxStatus.voided) continue;
      if ((tx.kind != TxKind.expense && tx.kind != TxKind.income) ||
          tx.counterparty == null ||
          tx.counterparty!.trim().isEmpty ||
          tx.categoryId == null) {
        continue;
      }
      final key = tx.counterparty!.trim();
      final m = agg.putIfAbsent(key, () => {});
      m[tx.categoryId!] = (m[tx.categoryId!] ?? 0) + 1;
    }
    final history = <CategoryHistoryEntry>[];
    agg.forEach((cp, m) {
      m.forEach(
        (cat, n) => history.add(
          CategoryHistoryEntry(counterparty: cp, categoryId: cat, count: n),
        ),
      );
    });
    return CategoryRulesEngine(rules: rules, history: history);
  }

  /// 周期建议（近 18 个月对手方流水 → RecurringDetector）。
  Future<List<RecurringSuggestion>> recurringSuggestions() async {
    final now = DateTime.now();
    final txs = await _ledger.list(
      from: DateTime(now.year, now.month - 18, now.day),
      to: now.add(const Duration(days: 1)),
    );
    final candidates = <RecurringTx>[];
    for (final tx in txs) {
      if (tx.status == TxStatus.voided) continue;
      if (tx.kind != TxKind.expense && tx.kind != TxKind.income) continue;
      final label = tx.counterparty?.trim().isNotEmpty == true
          ? tx.counterparty!.trim()
          : tx.note?.trim() ?? '';
      if (label.isEmpty) continue;
      for (final p in tx.postings) {
        if (p.accountId == tx.categoryId && p.amountMinor != null) {
          candidates.add(
            RecurringTx(
              date: tx.date,
              amountMinor: p.amountMinor!.abs(),
              label: label,
              direction: tx.kind == TxKind.income,
            ),
          );
          break;
        }
      }
    }
    return RecurringDetector.detect(candidates, now: now);
  }

  /// 首页智慧包：健康指标 + 配速 + 异常 + 周期建议 + 里程碑。
  Future<InsightBundle> dashboardInsights() async {
    final now = DateTime.now();

    // --- 本月与近月分类支出 ---
    final report = await stats.monthReport(now.year, now.month);
    final income = report.incomeByCategory.values.fold(
      BigInt.zero,
      (a, b) => a + b,
    );
    final expense = report.expenseByCategory.values.fold(
      BigInt.zero,
      (a, b) => a + b,
    );

    // 近 5 个月（不含本月）各分类月支出 → 基线。
    final historyByCategory = <String, List<BigInt>>{};
    final names = <String, String>{};
    for (var k = 1; k <= 5; k++) {
      final d = DateTime(now.year, now.month - k);
      final r = await stats.monthReport(d.year, d.month);
      r.expenseByCategory.forEach((cat, v) {
        historyByCategory.putIfAbsent(cat, () => []).add(v);
      });
    }
    final accounts = await _accounts.all();
    for (final a in accounts) {
      names[a.id] = a.name;
    }

    // --- 健康指标 ---
    final nw = await stats.netWorthAt(now);
    BigInt liquid = BigInt.zero;
    for (final i in nw.items) {
      final sub = i.account.assetSubtype;
      if (i.account.type == AccountType.asset &&
          sub != null &&
          sub.liquidityDays <= 30 &&
          !i.valuationMissing) {
        liquid += i.valueBaseMinor;
      }
    }
    // 近 3 个月月均消费（应急口径用全消费，不做必要/可选拆分的主观判断）。
    var expense3m = BigInt.zero;
    for (var k = 1; k <= 3; k++) {
      final d = DateTime(now.year, now.month - k);
      final r = await stats.monthReport(d.year, d.month);
      expense3m += r.expenseByCategory.values.fold(
        BigInt.zero,
        (a, b) => a + b,
      );
    }
    final avgExpense = expense3m ~/ BigInt.from(3);

    // 固定收支（计划事件）。
    BigInt fixedIn = BigInt.zero;
    BigInt fixedOut = BigInt.zero;
    final monthEnd = DateTime(now.year, now.month + 1, 0);
    for (final e in await _planning.scheduledEvents()) {
      final occ = e.expand(DateTime(now.year, now.month, 1), monthEnd);
      if (occ.isEmpty) continue;
      final amount = occ.length == 1
          ? occ.first.amountMinor
          : e.resolvedAmountMinor();
      if (amount.isNegative) {
        fixedOut += amount.abs();
      } else {
        fixedIn += amount;
      }
    }

    final health = computeHealth(
      incomeMinor: income,
      expenseMinor: expense,
      liquidAssetsMinor: liquid,
      avgMonthlyEssentialMinor: avgExpense,
      totalAssetsMinor: nw.totalAssets,
      totalLiabilitiesMinor: nw.totalLiabilities,
      fixedIncomeMonthlyMinor: fixedIn,
      fixedExpenseMonthlyMinor: fixedOut,
    );

    // --- 配速 ---
    final pace = SpendingPace.of(now: now, spentMinor: expense);

    // --- 异常 ---
    final anomalies = AnomalyDetector.detect(
      categoryNames: names,
      historyByCategory: historyByCategory,
      currentByCategory: report.expenseByCategory,
    );

    // --- 周期建议（复用独立方法，计划页同口径） ---
    final recurring = await recurringSuggestions();

    // --- 里程碑：下一个整数关口 ---
    final series = await stats.netWorthSeries(12, now: now);
    final target = _nextRoundNumber(series.map((e) => e.$2).toList());
    final milestone = NetWorthMilestone.predict(
      series: [for (final e in series) e.$2],
      targetMinor: target,
      asOf: now,
    );

    // --- 组装洞察文案 ---
    final insights = <Insight>[];
    if (health.emergencyMonths != null) {
      final m = health.emergencyMonths!;
      insights.add(
        Insight(
          icon: m >= 6 ? '🛡️' : (m >= 3 ? '🛡️' : '⚠️'),
          title: '${rt('应急准备金 ≈ ')}${m.toStringAsFixed(1)}${rt(' 个月')}',
          detail: m >= 6
              ? rt('已超过 6 个月安全线，闲钱可以考虑做更长周期安排')
              : m >= 3
              ? rt('达到 3 个月基本线，继续向 6 个月目标积累')
              : rt('低于 3 个月基本线，优先把流动资产补到月均消费的 3 倍'),
          severity: m >= 3 ? InsightSeverity.good : InsightSeverity.warn,
        ),
      );
    }
    if (health.savingsRate != null) {
      final r = health.savingsRate!;
      insights.add(
        Insight(
          icon: r >= 0.3 ? '💰' : (r >= 0.1 ? '💰' : '⚠️'),
          title: '${rt('本月储蓄率 ')}${(r * 100).toStringAsFixed(0)}%',
          detail: r >= 0.3
              ? rt('高于 30%，保持这个节奏净资产会稳步爬升')
              : r >= 0.1
              ? rt('介于 10%–30%，还有优化空间')
              : rt('本月入不敷出，看看消费构成里哪一项在拉动'),
          severity: r >= 0.1 ? InsightSeverity.good : InsightSeverity.warn,
        ),
      );
    }
    if (health.passiveCushion != null && health.passiveCushion! < 1) {
      insights.add(
        Insight(
          icon: '🧨',
          title: rt('固定支出已超固定收入'),
          detail:
              '${rt('月度计划支出是固定收入的 ')}'
              '${(1 / health.passiveCushion!).toStringAsFixed(1)}'
              '${rt(' 倍，依赖弹性收入或储蓄填补')}',
          severity: InsightSeverity.warn,
        ),
      );
    }
    for (final a in anomalies.take(2)) {
      final pct = a.baselineMedianMinor == BigInt.zero
          ? '—'
          : '${((a.currentMinor - a.baselineMedianMinor).abs().toDouble() / a.baselineMedianMinor.toDouble() * 100).toStringAsFixed(0)}%';
      insights.add(
        Insight(
          icon: '📈',
          title:
              '${rt('「')}${a.categoryName}${rt('」本月')}'
              '${a.spendUp ? rt('激增') : rt('骤降')} $pct',
          detail: rt('基线（近月中位数）对照的稳健异常信号，确认是否为一次性大额'),
          severity: InsightSeverity.warn,
        ),
      );
    }
    if (milestone != null) {
      insights.add(
        Insight(
          icon: '🏁',
          title: rt('净资产关口预测'),
          detail:
              '${rt('按近 12 个月趋势（月均 +')}'
              '${(milestone.slopePerMonthMinor ~/ BigInt.from(100)).toString()}'
              '${rt(' 元），预计 ')}${milestone.targetDate.year}${rt(' 年 ')}'
              '${milestone.targetDate.month}${rt(' 月达到 ')}'
              '${_roundLabel(target)}',
          severity: InsightSeverity.info,
        ),
      );
    }
    for (final r in recurring.take(2)) {
      insights.add(
        Insight(
          icon: r.direction ? '🔁' : '📅',
          title:
              '${rt('发现周期性')}${r.direction ? rt('收入') : rt('支出')}${rt('：')}${r.label}',
          detail:
              '${r.cadenceLabel} · ${r.occurrences}${rt(' 次 · 置信 ')}'
              '${(r.confidence * 100).toStringAsFixed(0)}'
              '${rt('%，可在计划页固化为固定开销')}',
          severity: InsightSeverity.info,
        ),
      );
    }

    // --- 备份提醒：距上次加密备份超过 30 天（或有账无备份）时提示 ---
    final backupInsight = await _backupReminder(now);
    if (backupInsight != null) insights.add(backupInsight);

    return InsightBundle(
      health: health,
      pace: pace,
      anomalies: anomalies,
      recurring: recurring,
      milestone: milestone,
      insights: insights,
    );
  }

  /// 备份提醒洞察：从未备份（且有交易）或距上次备份 > 30 天时返回。
  Future<Insight?> _backupReminder(DateTime now) async {
    final lastMs = await _meta.settingInt('lastBackupAtMs');
    final txCount = await _ledger.countPosted();
    if (txCount == 0) return null;
    if (lastMs == null) {
      return Insight(
        icon: '💾',
        title: rt('还没有备份过'),
        detail: rt(
          '数据只存在本机（Android 卸载即清空）。到 设置 → 导出加密备份，'
          '生成 .asbk 离线保存一份',
        ),
        severity: InsightSeverity.warn,
      );
    }
    final days = now
        .difference(DateTime.fromMillisecondsSinceEpoch(lastMs))
        .inDays;
    if (days >= 30) {
      return Insight(
        icon: '💾',
        title: '${rt('距上次备份已 ')}$days${rt(' 天')}',
        detail: rt('重要数据建议每月备份一次；到 设置 → 导出加密备份 更新 .asbk'),
        severity: InsightSeverity.warn,
      );
    }
    return null;
  }

  /// 下一个"整数关口"：10 万级 → 最近的 10 万倍数；百万以上 → 100 万倍数。
  BigInt _nextRoundNumber(Iterable<BigInt> values) {
    var max = BigInt.zero;
    for (final v in values) {
      if (v > max) max = v;
    }
    if (max <= BigInt.zero) {
      return BigInt.from(100000) * BigInt.from(100); // 10 万
    }
    final yuan = max ~/ BigInt.from(100);
    final BigInt step;
    if (yuan < BigInt.from(1000000)) {
      step = BigInt.from(100000); // 10 万
    } else {
      step = BigInt.from(1000000); // 100 万
    }
    return (yuan ~/ step + BigInt.one) * step * BigInt.from(100);
  }

  String _roundLabel(BigInt minor) {
    final yuan = minor ~/ BigInt.from(100);
    if (yuan >= BigInt.from(1000000)) {
      return '${(yuan ~/ BigInt.from(10000)).toString()}${rt(' 万')}';
    }
    return '$yuan${rt(' 元')}';
  }

  /// 雪崩 vs 雪球对比：返回两套计划与共同假设。
  Future<DebtStrategyCompare> debtStrategies({
    required BigInt extraMonthlyMinor,
  }) async {
    final accounts = await _accounts.all();
    final contracts = await _planning.debtContracts();
    final balances = await _ledger.moneyBalancesAt(
      DateTime.now().add(const Duration(days: 1)),
    );
    final positions = <DebtPosition>[];
    for (final a in accounts) {
      if (a.type != AccountType.liability || a.isSystem) continue;
      final owed = -(balances[a.id] ?? BigInt.zero);
      if (owed <= BigInt.zero) continue;
      final c = contracts[a.id];
      final schedule = c?.generateSchedule() ?? const <DebtScheduleEntry>[];
      BigInt minPay = BigInt.zero;
      final today = DateTime.now();
      for (final e in schedule) {
        if (!e.dueDate.isBefore(DateTime(today.year, today.month, today.day))) {
          minPay = e.principalMinor + e.interestMinor + e.feeMinor;
          break;
        }
      }
      positions.add(
        DebtPosition(
          name: a.name,
          remainingPrincipalMinor: owed,
          aprPercent: c?.aprPercent ?? Rational.zero(),
          minMonthlyPaymentMinor: minPay,
        ),
      );
    }
    return DebtStrategyCompare(
      positions: positions,
      avalanche: DebtPayoffPlanner.simulate(
        positions,
        PayoffStrategy.avalanche,
        extraMonthlyMinor: extraMonthlyMinor,
      ),
      snowball: DebtPayoffPlanner.simulate(
        positions,
        PayoffStrategy.snowball,
        extraMonthlyMinor: extraMonthlyMinor,
      ),
    );
  }
}

/// 策略对比结果。
class DebtStrategyCompare {
  const DebtStrategyCompare({
    required this.positions,
    required this.avalanche,
    required this.snowball,
  });

  final List<DebtPosition> positions;
  final PayoffPlan avalanche;
  final PayoffPlan snowball;

  /// 雪崩相对雪球的利息节省（≥0 时值得优先高利率）。
  BigInt get avalancheSaving =>
      snowball.totalInterestMinor - avalanche.totalInterestMinor;
}
