import 'dart:math' as math;

import '../money/fx_rate.dart';

/// FIRE（财务独立）输入：金额一律 BigInt（本位币最小单位），
/// 利率一律 Rational 精确值（口径见 docs/05 §13）。
///
/// 月利率 = 年利率 / 12（与债务模块同口径，国内惯例），
/// 名义累积、目标按月通胀复利，全程有理数精确，展示时才取整。
class FireInput {
  const FireInput({
    required this.portfolioMinor,
    required this.annualSavingsMinor,
    required this.annualSpendMinor,
    required this.nominalReturnAnnual,
    required this.inflationAnnual,
    required this.withdrawalRate,
    this.maxYears = 50,
  });

  /// 当前可投资净资产（净资产 − 固定资产 − 长期权益，见服务层口径）。
  final BigInt portfolioMinor;

  /// 年储蓄（可为负；月储蓄 = 年储蓄/12 精确有理数）。
  final BigInt annualSavingsMinor;

  /// 目标年支出（当前生活水平）。
  final BigInt annualSpendMinor;

  /// 名义年收益，如 Rational.percent('6') 表示 6%。
  final Rational nominalReturnAnnual;

  /// 年通胀，如 Rational.percent('2.5')。
  final Rational inflationAnnual;

  /// 提取率（0–1），如 Rational.parseDecimal('0.04') 表示 4% 法则。
  final Rational withdrawalRate;

  /// 累积模拟上限（年）。
  final int maxYears;

  /// 月名义收益率。
  Rational get monthlyGrowth =>
      Rational.one + nominalReturnAnnual / Rational.fromInt(BigInt.from(12));

  /// 月通胀率。
  Rational get monthlyInflation =>
      Rational.one + inflationAnnual / Rational.fromInt(BigInt.from(12));

  /// 实际年收益（Fisher：(1+名义)/(1+通胀) − 1，double 展示口径）。
  double get realReturnAnnual {
    final n = 1 + nominalReturnAnnual.asDouble();
    final f = 1 + inflationAnnual.asDouble();
    if (f <= 0) return n - 1;
    return n / f - 1;
  }
}

/// 累积曲线上的一点（金额为四舍五入到最小单位的展示值）。
class FirePoint {
  const FirePoint({
    required this.monthsFromNow,
    required this.portfolioMinor,
    required this.targetMinor,
  });

  final int monthsFromNow;

  /// 名义资产（按假设收益复利 + 月储蓄累积）。
  final BigInt portfolioMinor;

  /// 当时生活水平的 FI 门槛（年支出按通胀增长后 ÷ 提取率）。
  final BigInt targetMinor;

  bool get reached => portfolioMinor >= targetMinor;
}

/// FIRE 规划结论。
class FirePlan {
  const FirePlan({
    required this.fiNumberMinor,
    required this.monthsToFi,
    required this.alreadyFi,
    required this.coverage,
    required this.curve,
  });

  /// FI 门槛（今天的钱）：目标年支出 ÷ 提取率。
  final BigInt fiNumberMinor;

  /// 达标所需月数；-1 = 在假设内不可达。
  final int monthsToFi;

  /// 当前组合已覆盖 FI 门槛。
  final bool alreadyFi;

  /// 覆盖率 = 组合 ÷ FI 门槛（double 展示口径）。
  final double coverage;

  /// 逐年曲线（含起点与终点；达标月之后不再延伸）。
  final List<FirePoint> curve;

  int? get yearsToFi => monthsToFi < 0 ? null : (monthsToFi / 12).ceil();
}

/// 敏感性网格单元：收益平移 × 支出缩放 → 达标月数。
class FireSensitivityCell {
  const FireSensitivityCell({
    required this.returnShiftPercentPoint,
    required this.spendFactor,
    required this.monthsToFi,
  });

  /// 名义收益平移（-1 / 0 / +1 个百分点）。
  final int returnShiftPercentPoint;

  /// 支出缩放（0.9 / 1.0 / 1.1）。
  final double spendFactor;

  /// 该组合下的达标月数；-1 = 不可达。
  final int monthsToFi;
}

/// 严格正数（Rational 无 isPositive，包一个语义化判断）。
bool _isPositive(Rational r) => !r.isNegative && !r.isZero;

class FirePlanner {
  const FirePlanner._();

  /// 主规划：逐月精确复利，资产 ≥ 通胀调整后的门槛即达标。
  static FirePlan plan(FireInput input) {
    final wr = input.withdrawalRate;
    final spend = Rational.fromInt(input.annualSpendMinor);

    Rational target;
    if (!wr.isNegative && !wr.isZero && !spend.isZero) {
      target = spend / wr;
    } else {
      // 无支出目标或提取率非法：无可达门槛，仅输出曲线。
      target = Rational.zero();
    }
    final fiNumber = target.isZero ? BigInt.zero : target.rounded();

    var p = Rational.fromInt(input.portfolioMinor);
    final sMonthly =
        Rational.fromInt(input.annualSavingsMinor) /
        Rational.fromInt(BigInt.from(12));
    final g = input.monthlyGrowth;
    final x = input.monthlyInflation;

    final curve = <FirePoint>[
      FirePoint(
        monthsFromNow: 0,
        portfolioMinor: p.rounded(),
        targetMinor: target.rounded(),
      ),
    ];

    // 已达标 / 无门槛。
    if (!target.isZero && p >= target) {
      return FirePlan(
        fiNumberMinor: fiNumber,
        monthsToFi: 0,
        alreadyFi: true,
        coverage: _coverage(p, target),
        curve: curve,
      );
    }

    // 储蓄非正且名义收益追不上通胀：缺口只会扩大。
    if (!_isPositive(sMonthly) && g <= x) {
      return FirePlan(
        fiNumberMinor: fiNumber,
        monthsToFi: -1,
        alreadyFi: false,
        coverage: _coverage(p, target),
        curve: curve,
      );
    }

    var months = -1;
    final limit = input.maxYears * 12;
    for (var t = 1; t <= limit; t++) {
      p = p * g + sMonthly;
      target *= x;
      if (t % 12 == 0 || (!target.isZero && p >= target)) {
        curve.add(
          FirePoint(
            monthsFromNow: t,
            portfolioMinor: p.rounded(),
            targetMinor: target.rounded(),
          ),
        );
      }
      if (!target.isZero && p >= target) {
        months = t;
        break;
      }
    }
    return FirePlan(
      fiNumberMinor: fiNumber,
      monthsToFi: months,
      alreadyFi: false,
      coverage: _coverage(p, target),
      curve: curve,
    );
  }

  static double _coverage(Rational p, Rational target) =>
      target.isZero ? 0 : (p / target).asDouble();

  /// 反解：想在 [years] 年内达标，每年需存多少（向上取整保证达标）。
  /// 返回 0 表示现有组合复利即可达标。
  static BigInt requiredAnnualSavingsMinor(FireInput input, int years) {
    if (years <= 0) throw ArgumentError('years 必须为正');
    final n = years * 12;
    final wr = input.withdrawalRate;
    final spend = Rational.fromInt(input.annualSpendMinor);
    if (wr.isZero || spend.isZero) return BigInt.zero;

    final g = input.monthlyGrowth;
    final x = input.monthlyInflation;
    final targetN = (spend / wr) * _pow(x, n); // 第 n 月门槛（精确）
    final p0 = Rational.fromInt(input.portfolioMinor);

    Rational monthly;
    if (g == Rational.one) {
      monthly = (targetN - p0) / Rational.fromInt(BigInt.from(n));
    } else {
      final gn = _pow(g, n);
      // p_n = p0·gⁿ + s·(gⁿ−1)/(g−1) ≥ targetN
      monthly = (targetN - p0 * gn) * (g - Rational.one) / (gn - Rational.one);
    }
    if (!_isPositive(monthly)) return BigInt.zero;
    final annual = monthly * Rational.fromInt(BigInt.from(12));
    return annual.rounded(); // halfEven 已够（门槛本身已取整，量级为分）
  }

  /// 敏感性：收益 −1/0/+1 个百分点 × 支出 ×0.9/×1.0/×1.1。
  static List<FireSensitivityCell> sensitivity(FireInput input) {
    final cells = <FireSensitivityCell>[];
    for (final shift in const [-1, 0, 1]) {
      for (final f in const [0.9, 1.0, 1.1]) {
        final shifted = FireInput(
          portfolioMinor: input.portfolioMinor,
          annualSavingsMinor: input.annualSavingsMinor,
          annualSpendMinor:
              (Rational.fromInt(input.annualSpendMinor) *
                      Rational.parseDecimal(f.toString()))
                  .rounded(),
          // 平移单位是百分点：±1pp = ±0.01。
          nominalReturnAnnual:
              input.nominalReturnAnnual +
              Rational.fromFrac(BigInt.from(shift), BigInt.from(100)),
          inflationAnnual: input.inflationAnnual,
          withdrawalRate: input.withdrawalRate,
          maxYears: input.maxYears,
        );
        cells.add(
          FireSensitivityCell(
            returnShiftPercentPoint: shift,
            spendFactor: f,
            monthsToFi: plan(shifted).monthsToFi,
          ),
        );
      }
    }
    return cells;
  }

  static Rational _pow(Rational base, int exp) {
    var r = Rational.one;
    for (var i = 0; i < exp; i++) {
      r *= base;
    }
    return r;
  }
}

/// 蒙特卡洛提取期生存模拟（Trinity/FIRECalc 风格，docs/05 §13）。
///
/// 全程在「年支出倍数」空间运行：期初组合 = k 倍年支出，每年提取 1 倍
/// （实际口径：支出已按通胀调整，收益为实际收益），组合按随机实际收益
/// 增长。**不含任何金额单位**，因此 double 只出现在比率空间。
class FireMonteCarlo {
  const FireMonteCarlo._();

  /// [initialMultiple] 期初组合 ÷ 年支出（如提取率 4% → 25）。
  /// [seed] 固定时结果可复现（测试与审计用）。
  static FireMcResult survival({
    required double initialMultiple,
    required double realReturnMean,
    required double realVol,
    int years = 30,
    int paths = 1000,
    int seed = 7,
  }) {
    if (years <= 0 || paths <= 0 || initialMultiple <= 0) {
      return const FireMcResult(
        successRate: 1,
        p10: 0,
        p50: 0,
        p90: 0,
        paths: 0,
      );
    }
    final rng = math.Random(seed);
    var ok = 0;
    final terminals = <double>[];

    for (var i = 0; i < paths; i++) {
      var v = initialMultiple;
      var alive = true;
      for (var y = 0; y < years; y++) {
        final r = realVol <= 0
            ? realReturnMean
            : realReturnMean + realVol * _gauss(rng);
        v = v * (1 + r) - 1; // 先增长再提取（年末提取）
        if (v < 0) {
          alive = false;
          break;
        }
      }
      if (alive) ok++;
      terminals.add(alive ? v : 0);
    }
    terminals.sort();
    double pct(double q) =>
        terminals[(q * (terminals.length - 1)).floor().clamp(
          0,
          terminals.length - 1,
        )];
    return FireMcResult(
      successRate: ok / paths,
      p10: pct(0.10),
      p50: pct(0.50),
      p90: pct(0.90),
      paths: paths,
    );
  }

  /// Box-Muller 标准正态（u1==0 时取 cos(0)=1 的安全分支）。
  static double _gauss(math.Random rng) {
    var u1 = rng.nextDouble();
    while (u1 <= 0) {
      u1 = rng.nextDouble();
    }
    final u2 = rng.nextDouble();
    return math.sqrt(-2 * math.log(u1)) * math.cos(2 * math.pi * u2);
  }
}

/// 蒙特卡洛结论：成功率与期末余额（年支出倍数）分位。
class FireMcResult {
  const FireMcResult({
    required this.successRate,
    required this.p10,
    required this.p50,
    required this.p90,
    required this.paths,
  });

  final double successRate;
  final double p10;
  final double p50;
  final double p90;
  final int paths;
}
