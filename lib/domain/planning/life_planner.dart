import '../money/fx_rate.dart';

/// 人生规划：多年度（月粒度）现金流与净资产推演（docs/05 §14）。
///
/// 与既有模块的关系：
/// - 现金预测（cash_projection）看未来 180 天的既有计划；
/// - 情景模拟（scenario）看 180 天压力冲击；
/// - FIRE（fire）只回答"多少才够"；
/// - 本模块回答"人生大事（买房/育儿/换车/退休）对未来几十年的联合影响"。
///
/// 口径铁律：金额全程 BigInt（经 Rational），比率全程 Rational；
/// 名义收益月复利 g = 1 + 年收益/12，收入与支出按月通胀 x = 1 + 年通胀/12
/// 增长（名义口径）。新增贷款月供 = 等额本息闭式（与债务模块同式）；
/// 月供整体计为现金流出，其中本金部分体现为净资产内部转移
/// （invest 减少 ↔ 负债减少），净资产只损失利息部分——复式记账直觉。
/// 既有负债不显式建模（其月供已含在基线支出、余额已含在起点净资产）。

/// 输入。
class LifeInput {
  const LifeInput({
    required this.investMinor,
    required this.fixedAssetsMinor,
    required this.monthlyIncomeMinor,
    required this.monthlyExpenseMinor,
    required this.nominalReturnAnnual,
    required this.inflationAnnual,
    this.events = const [],
    this.years = 40,
  });

  /// 当前可投资净资产（收益引擎载体；口径同 FIRE：净资产 − 固定资产 − 长期权益）。
  final BigInt investMinor;

  /// 当前固定资产（名义恒值，不生息不折旧——保守展示）。
  final BigInt fixedAssetsMinor;

  /// 基线税后月收入（不含事件；按通胀增长）。
  final BigInt monthlyIncomeMinor;

  /// 基线月支出（含既有房贷月供；按通胀增长）。
  final BigInt monthlyExpenseMinor;

  final Rational nominalReturnAnnual;
  final Rational inflationAnnual;
  final List<LifeEvent> events;
  final int years;

  Rational get monthlyGrowth =>
      Rational.one + nominalReturnAnnual / Rational.fromInt(BigInt.from(12));

  Rational get monthlyInflation =>
      Rational.one + inflationAnnual / Rational.fromInt(BigInt.from(12));
}

/// 人生事件（从现在起的月数 [month] 触发；0 = 当前月）。
sealed class LifeEvent {
  const LifeEvent({required this.month});
  final int month;
}

/// 买房：首付一次性流出 + 等额本息贷款；房产计入固定资产。
/// 恒等式：首付 + 贷款 = 房价时，买房瞬间净资产不变。
class HomePurchase extends LifeEvent {
  const HomePurchase({
    required super.month,
    required this.priceMinor,
    required this.downPaymentMinor,
    required this.annualRate,
    required this.termYears,
  });

  final BigInt priceMinor;
  final BigInt downPaymentMinor;
  final Rational annualRate;
  final int termYears;
}

/// 育儿：出生起每月养育成本（按通胀增长）；18–21 岁大学阶段加额外月成本。
class ChildRearing extends LifeEvent {
  const ChildRearing({
    required super.month,
    required this.monthlyCostMinor,
    this.collegeExtraMinor,
    this.dependentMonths = 252, // 21 年
  });

  final BigInt monthlyCostMinor;

  /// 大学阶段额外月成本（默认 0）。
  final BigInt? collegeExtraMinor;
  final int dependentMonths;

  BigInt get collegeExtraOrDefault => collegeExtraMinor ?? BigInt.zero;

  static const collegeStartAgeMonths = 216; // 18 岁
}

/// 收入跳变：之后月收入 × factor（1.3 = 涨三成；0 = 收入归零）。
class IncomeChange extends LifeEvent {
  const IncomeChange({required super.month, required this.factor});
  final Rational factor;
}

/// 退休：之后收入 × [incomeFactor]（养老金替代率，默认 0.4）、
/// 支出 × [spendFactor]（默认 0.75）。
class Retirement extends LifeEvent {
  const Retirement({required super.month, this.incomeFactor, this.spendFactor});

  final Rational? incomeFactor;
  final Rational? spendFactor;

  static Rational get defIncome =>
      Rational.fromFrac(BigInt.from(2), BigInt.from(5)); // 0.4
  static Rational get defSpend =>
      Rational.fromFrac(BigInt.from(3), BigInt.from(4)); // 0.75
}

/// 大件购置（换车等）：一次性流出 [costMinor]，[residualMinor] 计入固定资产。
class BigPurchase extends LifeEvent {
  const BigPurchase({
    required super.month,
    required this.costMinor,
    this.residualMinor,
  });

  final BigInt costMinor;

  /// 计入固定资产的残值（默认 0）。
  final BigInt? residualMinor;

  BigInt get residualOrDefault => residualMinor ?? BigInt.zero;
}

/// 一次性大额收支（遗产/大病/礼金）：正 = 流入。
class LumpSum extends LifeEvent {
  const LumpSum({required super.month, required this.amountMinor});
  final BigInt amountMinor;
}

/// 曲线采样点。
class LifePoint {
  const LifePoint({
    required this.month,
    required this.investMinor,
    required this.fixedMinor,
    required this.debtMinor,
    required this.cashFlowMinor,
  });

  final int month;
  final BigInt investMinor;
  final BigInt fixedMinor;
  final BigInt debtMinor;

  /// 当月净现金流（收入 − 支出，含月供；事件一次性流不计入）。
  final BigInt cashFlowMinor;

  BigInt get netWorthMinor => investMinor + fixedMinor - debtMinor;
}

/// 结论。
class LifeResult {
  const LifeResult({
    required this.curve,
    required this.months,
    this.exhaustedAtMonth,
    required this.peakNetWorthMinor,
    required this.newLoanInterestMinor,
  });

  /// 含起点；年度采样 + 事件月（由引擎填充）。
  final List<LifePoint> curve;
  final int months;

  /// 可投资资产首次为负的月份；null = 模拟期内未耗尽。
  final int? exhaustedAtMonth;

  final BigInt peakNetWorthMinor;

  /// 新增贷款（买房事件）的累计利息。
  final BigInt newLoanInterestMinor;

  bool get ok => exhaustedAtMonth == null;
}

class _Loan {
  _Loan({
    required this.born,
    required this.remaining,
    required this.rate,
    required this.payment,
    required this.left,
  });

  final int born; // 加入月；月供从 born+1 起扣
  Rational remaining;
  final Rational rate;
  final Rational payment;
  int left;

  /// 等额本息月供闭式：A = P·i·(1+i)^n / ((1+i)^n − 1)；i=0 → P/n。
  factory _Loan.of(HomePurchase h) {
    final p = Rational.fromInt(h.priceMinor - h.downPaymentMinor);
    final n = h.termYears * 12;
    final i = h.annualRate / Rational.fromInt(BigInt.from(12));
    final payment = i.isZero
        ? p / Rational.fromInt(BigInt.from(n))
        : p *
              i *
              _pow(Rational.one + i, n) /
              (_pow(Rational.one + i, n) - Rational.one);
    return _Loan(
      born: h.month,
      remaining: p,
      rate: i,
      payment: payment,
      left: n,
    );
  }
}

Rational _pow(Rational base, int exp) {
  var r = Rational.one;
  for (var i = 0; i < exp; i++) {
    r *= base;
  }
  return r;
}

Rational _r(BigInt v) => Rational.fromInt(v);

class LifePlanner {
  const LifePlanner._();

  /// 逐月推演：事件触发 → 现金流（收入/支出/月供/育儿）→ 复利 → 记点。
  static LifeResult simulate(LifeInput input) {
    final months = input.years * 12;
    final byMonth = <int, List<LifeEvent>>{};
    for (final e in input.events) {
      byMonth.putIfAbsent(e.month, () => []).add(e);
    }
    final eventMonths = byMonth.keys.toSet();

    var invest = _r(input.investMinor);
    var fixed = _r(input.fixedAssetsMinor);
    final loans = <_Loan>[];
    final children = <(int, ChildRearing)>[];
    var incomeFactor = Rational.one;
    var spendFactor = Rational.one;
    var totalInterest = Rational.zero();

    final g = input.monthlyGrowth;
    final x1 = input.monthlyInflation;
    var x = Rational.one; // 通胀累积 x^t

    final curve = <LifePoint>[];
    int? exhausted;
    var peak = Rational.zero();
    var lastCf = Rational.zero();

    for (var t = 0; t <= months; t++) {
      if (t > 0) x *= x1;

      // 1) 事件触发（修改状态，不计当月现金流）。
      for (final e in byMonth[t] ?? const <LifeEvent>[]) {
        switch (e) {
          case HomePurchase h:
            invest -= _r(h.downPaymentMinor);
            fixed += _r(h.priceMinor);
            loans.add(_Loan.of(h));
          case ChildRearing c:
            children.add((t, c));
          case IncomeChange ic:
            incomeFactor *= ic.factor;
          case Retirement r:
            incomeFactor *= r.incomeFactor ?? Retirement.defIncome;
            spendFactor *= r.spendFactor ?? Retirement.defSpend;
          case BigPurchase b:
            invest -= _r(b.costMinor);
            fixed += _r(b.residualOrDefault);
          case LumpSum l:
            invest += _r(l.amountMinor);
        }
      }

      // 2) 当月现金流与复利（t=0 是起点，无现金流）。
      if (t > 0) {
        var income = _r(input.monthlyIncomeMinor) * x * incomeFactor;
        var expense = _r(input.monthlyExpenseMinor) * x * spendFactor;
        for (final (born, c) in children) {
          final age = t - born - 1; // 出生次月起算的成本月龄
          if (age >= 0 && age < c.dependentMonths) {
            expense += _r(c.monthlyCostMinor) * x;
            if (age >= ChildRearing.collegeStartAgeMonths) {
              expense += _r(c.collegeExtraOrDefault) * x;
            }
          }
        }
        for (final l in loans) {
          if (l.left <= 0 || t <= l.born) continue;
          final interest = l.remaining * l.rate;
          var principal = l.payment - interest;
          if (principal >= l.remaining || l.left == 1) {
            principal = l.remaining; // 末期清偿
          }
          l.remaining -= principal;
          l.left--;
          totalInterest += interest;
          expense += l.payment;
        }
        lastCf = income - expense;
        invest = invest * g + lastCf;
      }

      final debt = loans.fold(
        Rational.zero(),
        (s, l) => s + (l.left > 0 ? l.remaining : Rational.zero()),
      );
      final nw = invest + fixed - debt;
      if (nw > peak) peak = nw;
      if (exhausted == null && invest.isNegative && t > 0) exhausted = t;

      // 3) 采样：起点、每年、事件月及其次月（首期现金流影响）、终点。
      if (t == 0 ||
          t == months ||
          t % 12 == 0 ||
          eventMonths.contains(t) ||
          eventMonths.contains(t - 1)) {
        curve.add(
          LifePoint(
            month: t,
            investMinor: invest.rounded(),
            fixedMinor: fixed.rounded(),
            debtMinor: debt.rounded(),
            cashFlowMinor: t > 0 ? lastCf.rounded() : BigInt.zero,
          ),
        );
      }
    }

    return LifeResult(
      curve: curve,
      months: months,
      exhaustedAtMonth: exhausted,
      peakNetWorthMinor: peak.rounded(),
      newLoanInterestMinor: totalInterest.rounded(),
    );
  }
}
