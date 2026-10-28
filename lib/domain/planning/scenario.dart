import '../money/fx_rate.dart';
import '../utils/dates.dart';
import 'cash_projection.dart';

extension on BigInt {
  bool get isPositive => !isNegative;
}

/// 情景组件（可组合叠加，按列表顺序依次作用，口径见 docs/05 §12）。
///
/// 全部组件只作用于"事件流"，不改动期初余额；重放由 [CashProjector]
/// 完成，与基线预测同一算法（同日内支出先于收入的保守规则不变）。
sealed class ScenarioComponent {
  const ScenarioComponent();

  /// 组件生效窗口（含两端）：start = from + startAfterDays，
  /// end = start 按 [addMonthsClamped] 推 months 个自然月。
  (DateTime, DateTime) window(DateTime from);

  /// 组件对单个事件的作用（不可作用时原样返回）。
  CashEvent applyTo(CashEvent e, DateTime from);
}

bool _inWindow(DateTime d, (DateTime, DateTime) w) =>
    !d.isBefore(w.$1) && !d.isAfter(w.$2);

/// 收入冲击：窗口内预期收入 × (1 − drop)。drop=1 即收入中断（失业）。
class IncomeShock extends ScenarioComponent {
  const IncomeShock({
    required this.drop,
    required this.months,
    this.startAfterDays = 0,
  });

  /// 收入降幅（0–1 有理数，1 = 完全中断）。
  final Rational drop;
  final int months;
  final int startAfterDays;

  @override
  (DateTime, DateTime) window(DateTime from) {
    final s = from.add(Duration(days: startAfterDays));
    return (s, addMonthsClamped(s, months));
  }

  @override
  CashEvent applyTo(CashEvent e, DateTime from) {
    if (e.kind != CashEventKind.incomeExpected ||
        !e.amountBaseMinor.isPositive) {
      return e;
    }
    if (!_inWindow(e.date, window(from))) return e;
    final scaled =
        (Rational.fromInt(e.amountBaseMinor) * (Rational.one - drop))
            .rounded();
    if (scaled.isNegative) return e; // 防御：降幅非法时不放大伤害
    return CashEvent(
      date: e.date,
      amountBaseMinor: scaled,
      label: e.label,
      accountId: e.accountId,
      isEstimate: e.isEstimate,
      kind: e.kind,
    );
  }
}

/// 工资延发：窗口内的收入事件推迟 delayDays 天。
/// 推出预测期外的事件由投影器自动丢弃（现金视角：钱到账前不算数）。
class IncomeDelay extends ScenarioComponent {
  const IncomeDelay({
    required this.delayDays,
    required this.months,
    this.startAfterDays = 0,
  });

  final int delayDays;
  final int months;
  final int startAfterDays;

  @override
  (DateTime, DateTime) window(DateTime from) {
    final s = from.add(Duration(days: startAfterDays));
    return (s, addMonthsClamped(s, months));
  }

  @override
  CashEvent applyTo(CashEvent e, DateTime from) {
    if (e.kind != CashEventKind.incomeExpected ||
        !e.amountBaseMinor.isPositive) {
      return e;
    }
    if (!_inWindow(e.date, window(from))) return e;
    return CashEvent(
      date: e.date.add(Duration(days: delayDays)),
      amountBaseMinor: e.amountBaseMinor,
      label: e.label,
      accountId: e.accountId,
      isEstimate: e.isEstimate,
      kind: e.kind,
    );
  }
}

/// 支出激增：窗口内固定计划支出 × (1 + surge)。
/// 只作用于 planned（固定/预定支出）；房贷等债务还款（debtRepay）
/// 为合同义务不参与，日常消费基线（budgetBaseline）不在此重复放大。
class ExpenseSurge extends ScenarioComponent {
  const ExpenseSurge({
    required this.surge,
    required this.months,
    this.startAfterDays = 0,
  });

  /// 支出涨幅（0–1 有理数，0.2 = +20%）。
  final Rational surge;
  final int months;
  final int startAfterDays;

  @override
  (DateTime, DateTime) window(DateTime from) {
    final s = from.add(Duration(days: startAfterDays));
    return (s, addMonthsClamped(s, months));
  }

  @override
  CashEvent applyTo(CashEvent e, DateTime from) {
    if (e.kind != CashEventKind.planned || e.amountBaseMinor.isPositive) {
      return e;
    }
    if (!_inWindow(e.date, window(from))) return e;
    final scaled =
        (Rational.fromInt(e.amountBaseMinor) * (Rational.one + surge))
            .rounded();
    if (scaled.isPositive) return e; // 防御：不把支出放大成流入
    return CashEvent(
      date: e.date,
      amountBaseMinor: scaled,
      label: e.label,
      accountId: e.accountId,
      isEstimate: e.isEstimate,
      kind: e.kind,
    );
  }
}

/// 一次性事件：额外现金流出/流入（金额符号决定方向）。
class OneOffEvent extends ScenarioComponent {
  const OneOffEvent({
    required this.afterDays,
    required this.amountBaseMinor,
    required this.label,
  });

  /// 从预测起点起算的第几天发生（0 = 当天）。
  final int afterDays;

  /// 本位币最小单位；负 = 额外支出（医疗/维修），正 = 额外收入（理赔/红包）。
  final BigInt amountBaseMinor;
  final String label;

  @override
  (DateTime, DateTime) window(DateTime from) {
    final d = from.add(Duration(days: afterDays));
    return (d, d);
  }

  @override
  CashEvent applyTo(CashEvent e, DateTime from) => e;
}

/// 额外月度流出：从 startAfterDays 起连续 months 个月（如提前还款加码、
/// 新增房租）。提前还款对利息的影响用债务页的模拟，这里只看现金压力。
class ExtraMonthlyOutflow extends ScenarioComponent {
  const ExtraMonthlyOutflow({
    required this.monthlyMinor,
    required this.months,
    required this.label,
    this.startAfterDays = 0,
  });

  /// 每月额外流出（正数，方向内部取负）。
  final BigInt monthlyMinor;
  final int months;
  final String label;
  final int startAfterDays;

  @override
  (DateTime, DateTime) window(DateTime from) {
    final s = from.add(Duration(days: startAfterDays));
    return (s, addMonthsClamped(s, months));
  }

  @override
  CashEvent applyTo(CashEvent e, DateTime from) => e;
}

/// 一个完整情景：名称 + 有序组件列表。
class ScenarioSpec {
  const ScenarioSpec({required this.name, required this.components});

  final String name;
  final List<ScenarioComponent> components;
}

/// 常用预设（UI 弹层一键选择）。
class ScenarioPresets {
  const ScenarioPresets._();

  static ScenarioSpec unemployment({int months = 3}) => ScenarioSpec(
        name: '失业 $months 个月',
        components: [
          IncomeShock(drop: Rational.one, months: months),
        ],
      );

  static ScenarioSpec incomeDown(
      {Rational? drop, int months = 6}) {
    final d = drop ??
        Rational.fromFrac(BigInt.from(3), BigInt.from(10));
    return ScenarioSpec(
        name: '收入降三成 · $months 个月',
        components: [IncomeShock(drop: d, months: months)]);
  }

  static ScenarioSpec salaryDelay({int delayDays = 30, int months = 2}) =>
      ScenarioSpec(
        name: '工资延发 $delayDays 天 · $months 个月',
        components: [IncomeDelay(delayDays: delayDays, months: months)],
      );

  static ScenarioSpec oneOff(BigInt amountMinor, int afterDays,
          {String label = '情景：一次性支出'}) =>
      ScenarioSpec(
        name: '一次性支出',
        components: [
          OneOffEvent(
              afterDays: afterDays,
              amountBaseMinor: -amountMinor,
              label: label),
        ],
      );

  static ScenarioSpec extraOutflow(BigInt monthlyMinor, int months,
          {String label = '情景：额外月支出'}) =>
      ScenarioSpec(
        name: '额外月支出 · $months 个月',
        components: [
          ExtraMonthlyOutflow(
              monthlyMinor: monthlyMinor, months: months, label: label),
        ],
      );
}

/// 情景引擎：把组件列表作用到基线事件流（纯函数，无 IO）。
class ScenarioEngine {
  const ScenarioEngine._();

  /// 组件按顺序依次作用（前一个的输出是后一个的输入），
  /// 生成型组件（一次性/额外月支出）最后追加。
  static List<CashEvent> apply(
      List<CashEvent> events, ScenarioSpec spec, DateTime from) {
    var current = [...events];
    final generated = <CashEvent>[];

    for (final c in spec.components) {
      switch (c) {
        case IncomeShock():
        case IncomeDelay():
        case ExpenseSurge():
          current = [for (final e in current) c.applyTo(e, from)];
        case OneOffEvent():
          final d = from.add(Duration(days: c.afterDays));
          generated.add(CashEvent(
            date: d,
            amountBaseMinor: c.amountBaseMinor,
            label: c.label,
            kind: CashEventKind.other,
          ));
        case ExtraMonthlyOutflow():
          final s = from.add(Duration(days: c.startAfterDays));
          for (var k = 0; k < c.months; k++) {
            generated.add(CashEvent(
              date: addMonthsClamped(s, k),
              amountBaseMinor: -c.monthlyMinor,
              label: c.label,
              kind: CashEventKind.other,
            ));
          }
      }
    }
    return [...current, ...generated];
  }
}

/// 基线 vs 情景的对比结论（两条曲线同 horizon 逐日对齐）。
class ScenarioComparison {
  const ScenarioComparison({
    required this.baseline,
    required this.scenario,
    required this.fromDate,
  });

  final CashProjection baseline;
  final CashProjection scenario;
  final DateTime fromDate;

  /// 最低现金变化（负 = 情景使低谷更深）。
  BigInt get minBalanceDelta =>
      scenario.minBalanceBaseMinor - baseline.minBalanceBaseMinor;

  /// 逐日差的最差值（比最低点差更严格：看最难受的那一天）。
  BigInt get worstDailyDelta {
    var worst = BigInt.zero;
    for (var i = 0;
        i < scenario.series.length && i < baseline.series.length;
        i++) {
      final d = scenario.series[i].balanceBaseMinor -
          baseline.series[i].balanceBaseMinor;
      if (d < worst) worst = d;
    }
    return worst;
  }

  /// 情景下总现金（未扣准备金）首次 < 0 的日期；始终为正则 null。
  DateTime? get firstCashOutDate {
    for (final p in scenario.series) {
      if (p.balanceBaseMinor < BigInt.zero) return p.date;
    }
    return null;
  }

  /// 现金耗尽剩余天数（从 from 起算）；不耗尽为 null。
  int? get daysToCashOut {
    final d = firstCashOutDate;
    return d == null ? null : calendarDaysBetween(fromDate, d);
  }

  /// 缺口总额变化（负 = 缺口扩大）。
  BigInt get shortfallTotalDelta =>
      _totalShortfall(scenario) - _totalShortfall(baseline);

  static BigInt _totalShortfall(CashProjection p) =>
      p.shortfalls.fold(BigInt.zero, (s, e) => s + e.amountBaseMinor);

  /// 情景新增缺口（基线中没有的日期+账户+原因组合）。
  List<CashShortfall> get newShortfalls {
    final base = baseline.shortfalls.map(_key).toSet();
    return [
      for (final s in scenario.shortfalls)
        if (!base.contains(_key(s))) s
    ];
  }

  static String _key(CashShortfall s) =>
      '${dateKey(s.date)}|${s.label}|${s.accountId ?? ''}';

  /// 情景是否可承受：无新增缺口、现金不耗尽。
  bool get survives => newShortfalls.isEmpty && firstCashOutDate == null;
}
