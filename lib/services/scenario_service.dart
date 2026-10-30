import '../domain/invest/allocation.dart';
import '../domain/ledger/account.dart';
import '../domain/money/fx_rate.dart';
import '../domain/planning/cash_projection.dart';
import '../domain/planning/scenario.dart';
import 'projection_service.dart';
import 'stats_service.dart';

/// FIRE 预填值：从真实账本提炼的默认参数（UI 可改，见 docs/05 §13）。
class FireDefaults {
  const FireDefaults({
    required this.investableMinor,
    required this.ttmSavingsMinor,
    required this.ttmSpendMinor,
    required this.monthsOfHistory,
  });

  /// 可投资净资产 = 净资产 − 固定资产 − 长期权益（负债全额抵减，保守）。
  final BigInt investableMinor;

  /// 近 12 个完整月储蓄合计（收入 − 支出）。
  final BigInt ttmSavingsMinor;

  /// 近 12 个完整月消费合计。
  final BigInt ttmSpendMinor;

  /// 近 12 个月中有收支记录的月数（不足 12 时 UI 提示代表性有限）。
  final int monthsOfHistory;
}

/// 人生规划预填值（docs/05 §14）。
class LifeDefaults {
  const LifeDefaults({
    required this.investMinor,
    required this.fixedAssetsMinor,
    required this.monthlyIncomeMinor,
    required this.monthlyExpenseMinor,
    required this.monthsOfHistory,
  });

  final BigInt investMinor;

  /// 固定资产 + 长期权益（锁定资产，名义恒值不生息）。
  final BigInt fixedAssetsMinor;

  final BigInt monthlyIncomeMinor;
  final BigInt monthlyExpenseMinor;
  final int monthsOfHistory;
}

/// 情景模拟与 FIRE 规划服务：领域算法 + 账本数据组装。
class ScenarioService {
  ScenarioService(this._projection, this._stats);

  final ProjectionService _projection;
  final StatsService _stats;

  /// 跑一个情景：与基线共用同一份预测输入，只重放变换后的事件流。
  Future<ScenarioComparison> run(
    ScenarioSpec spec, {
    DateTime? now,
    int horizonDays = 180,
  }) async {
    final input = await _projection.buildInput(
      now: now,
      horizonDays: horizonDays,
    );
    final baseline = CashProjector.project(input);
    final events = ScenarioEngine.apply(input.events, spec, input.fromDate);
    final scenario = CashProjector.project(
      ProjectionInput(
        baseCurrencyCode: input.baseCurrencyCode,
        accounts: input.accounts,
        events: events,
        reserveBaseMinor: input.reserveBaseMinor,
        reserveReleases: input.reserveReleases,
        baselineMinCashBaseMinor: input.baselineMinCashBaseMinor,
        fromDate: input.fromDate,
        horizonDays: input.horizonDays,
      ),
    );
    return ScenarioComparison(
      baseline: baseline,
      scenario: scenario,
      fromDate: input.fromDate,
    );
  }

  /// 从账本提炼 FIRE 默认参数。
  Future<FireDefaults> fireDefaults({DateTime? now}) async {
    final n = now ?? DateTime.now();

    // 近 12 个完整月（不含本月）收支。
    var savings = BigInt.zero;
    var spend = BigInt.zero;
    var months = 0;
    for (var k = 1; k <= 12; k++) {
      final d = DateTime(n.year, n.month - k);
      final r = await _stats.monthReport(d.year, d.month);
      final inc = r.incomeByCategory.values.fold(BigInt.zero, (a, b) => a + b);
      final exp = r.expenseByCategory.values.fold(BigInt.zero, (a, b) => a + b);
      if (inc != BigInt.zero || exp != BigInt.zero) months++;
      savings += inc - exp;
      spend += exp;
    }

    // 可投资净资产：扣除固定资产与长期权益（养老/公积金等锁定），负债全额抵减。
    // FIRE 是个人规划 → 存量按本人份额（共享账户只算我的，docs/05 §16）。
    final nw = await _stats.netWorthAt(n);
    var investableBuckets = BigInt.zero;
    for (final i in nw.items) {
      if (i.account.type != AccountType.asset || i.valuationMissing) continue;
      final sub = i.account.assetSubtype;
      if (sub == null) continue;
      final c = AllocationClass.fromSubtype(sub);
      if (c == AllocationClass.realAssets || c == AllocationClass.longTerm) {
        continue;
      }
      investableBuckets += i.myValueBaseMinor;
    }
    var investable = investableBuckets - nw.myTotalLiabilities;
    if (investable < BigInt.zero) investable = BigInt.zero;

    return FireDefaults(
      investableMinor: investable,
      ttmSavingsMinor: savings,
      ttmSpendMinor: spend,
      monthsOfHistory: months,
    );
  }

  /// 从账本提炼人生规划默认参数（月收支取 TTM/12，与 FIRE 年口径一致）。
  Future<LifeDefaults> lifeDefaults({DateTime? now}) async {
    final n = now ?? DateTime.now();
    final f = await fireDefaults(now: n);

    // 固定/锁定资产：realAssets + longTerm 桶（有估值），按本人份额。
    final nw = await _stats.netWorthAt(n);
    var fixedLike = BigInt.zero;
    for (final i in nw.items) {
      if (i.account.type != AccountType.asset || i.valuationMissing) continue;
      final sub = i.account.assetSubtype;
      if (sub == null) continue;
      final c = AllocationClass.fromSubtype(sub);
      if (c == AllocationClass.realAssets || c == AllocationClass.longTerm) {
        fixedLike += i.myValueBaseMinor;
      }
    }

    // 月基线 = TTM 合计 ÷ 12（不足 12 月历史时 UI 提示代表性有限）。
    final twelve = Rational.fromInt(BigInt.from(12));
    final income = f.ttmSavingsMinor + f.ttmSpendMinor;
    final monthlyIncome = (Rational.fromInt(income) / twelve).rounded();
    final monthlyExpense = (Rational.fromInt(f.ttmSpendMinor) / twelve)
        .rounded();

    return LifeDefaults(
      investMinor: f.investableMinor,
      fixedAssetsMinor: fixedLike,
      monthlyIncomeMinor: monthlyIncome,
      monthlyExpenseMinor: monthlyExpense,
      monthsOfHistory: f.monthsOfHistory,
    );
  }
}
