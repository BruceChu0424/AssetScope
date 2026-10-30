import '../money/fx_rate.dart';
import '../utils/dates.dart';

/// 还款方式。
enum RepaymentMethod {
  annuity('等额本息'),
  equalPrincipal('等额本金'),
  bulletInterest('先息后本'),
  fixedInstallment('固定分期费率'),
  interestFree('免息分期'),
  manual('手工计划');

  const RepaymentMethod(this.labelZh);
  final String labelZh;
}

enum DayCountBasis {
  /// 月利率 = 名义年利率 / 12（国内房贷/消费贷主流）。
  monthlyRate,

  /// 日利率 = 名义年利率 / 360，按实际占用天数计息。
  d360,

  /// 日利率 = 名义年利率 / 365。
  d365,
}

Rational _r(BigInt v) => Rational.fromInt(v);

/// 债务合同：利率、期限、计息方式与费用规则。
class DebtContract {
  const DebtContract({
    required this.liabilityAccountId,
    required this.principalOriginalMinor,
    required this.aprPercent,
    required this.method,
    required this.termMonths,
    required this.startDate,
    this.firstPaymentDate,
    this.repaymentDay,
    this.monthlyFeeMinor,
    this.basis = DayCountBasis.monthlyRate,
    this.prepayFeePercent,
    this.notes,
  });

  /// 对应的负债账户 id。
  final String liabilityAccountId;
  final BigInt principalOriginalMinor;

  /// 名义年利率（百分数有理数，如 "3.85" 表示 3.85%）。
  final Rational aprPercent;
  final RepaymentMethod method;
  final int termMonths;
  final DateTime startDate;
  final DateTime? firstPaymentDate;
  final int? repaymentDay;
  final BigInt? monthlyFeeMinor;
  final DayCountBasis basis;

  /// 提前还款手续费（剩余本金的百分数）。
  final Rational? prepayFeePercent;
  final String? notes;

  /// 月利率（有理数精确值）。
  Rational get monthlyRate => switch (basis) {
    DayCountBasis.monthlyRate => aprPercent / _r(BigInt.from(1200)),
    DayCountBasis.d360 => aprPercent / _r(BigInt.from(36000)),
    DayCountBasis.d365 => aprPercent / _r(BigInt.from(36500)),
  };

  DateTime paymentDate(int seqFrom1) {
    final anchor =
        firstPaymentDate ??
        DateTime(
          startDate.year,
          startDate.month,
          repaymentDay ?? startDate.day,
        );
    return addMonthsClamped(
      anchor,
      seqFrom1 - 1,
      policy: MonthEndPolicy.clampToMonthEnd,
    );
  }

  /// 生成完整还款计划（末期修正累计舍入差，保证本金恰好清零）。
  List<DebtScheduleEntry> generateSchedule() {
    switch (method) {
      case RepaymentMethod.annuity:
        return _annuity();
      case RepaymentMethod.equalPrincipal:
        return _equalPrincipal();
      case RepaymentMethod.bulletInterest:
        return _bulletInterest();
      case RepaymentMethod.fixedInstallment:
        return _fixedInstallment();
      case RepaymentMethod.interestFree:
        return _interestFree();
      case RepaymentMethod.manual:
        return const [];
    }
  }

  /// 等额本息：A = P·i·(1+i)^n / ((1+i)^n − 1)
  List<DebtScheduleEntry> _annuity() {
    final p = principalOriginalMinor;
    final i = monthlyRate;
    final n = termMonths;
    if (i.isZero) return _interestFree();
    final growth = _pow(_r(BigInt.one) + i, n); // (1+i)^n
    final a = (_r(p) * i * growth / (growth - Rational.one)).rounded();
    final fee = monthlyFeeMinor ?? BigInt.zero;
    final entries = <DebtScheduleEntry>[];
    var remaining = p;
    for (var k = 1; k <= n && remaining > BigInt.zero; k++) {
      final interest = (_r(remaining) * i).rounded();
      var principal = a - interest;
      if (k == n || principal <= BigInt.zero || principal >= remaining) {
        principal = remaining; // 末期（或利率极端时）整笔清偿
      }
      remaining -= principal;
      entries.add(
        DebtScheduleEntry(
          seq: k,
          dueDate: paymentDate(k),
          principalMinor: principal,
          interestMinor: interest,
          feeMinor: fee,
          remainingPrincipalMinor: remaining,
        ),
      );
    }
    return entries;
  }

  /// 等额本金：每期本金 P/n，利息 = 剩余本金 × i。
  List<DebtScheduleEntry> _equalPrincipal() {
    final p = principalOriginalMinor;
    final i = monthlyRate;
    final fee = monthlyFeeMinor ?? BigInt.zero;
    final entries = <DebtScheduleEntry>[];
    var remaining = p;
    for (var k = 1; k <= termMonths && remaining > BigInt.zero; k++) {
      var principal = (_r(p) / _r(BigInt.from(termMonths))).rounded();
      if (k == termMonths || principal >= remaining) principal = remaining;
      final interest = (_r(remaining) * i).rounded();
      remaining -= principal;
      entries.add(
        DebtScheduleEntry(
          seq: k,
          dueDate: paymentDate(k),
          principalMinor: principal,
          interestMinor: interest,
          feeMinor: fee,
          remainingPrincipalMinor: remaining,
        ),
      );
    }
    return entries;
  }

  /// 先息后本：每期只付利息，末期归还全部本金。
  List<DebtScheduleEntry> _bulletInterest() {
    final p = principalOriginalMinor;
    final i = monthlyRate;
    final fee = monthlyFeeMinor ?? BigInt.zero;
    final entries = <DebtScheduleEntry>[];
    for (var k = 1; k <= termMonths; k++) {
      final interest = (_r(p) * i).rounded();
      final principal = k == termMonths ? p : BigInt.zero;
      entries.add(
        DebtScheduleEntry(
          seq: k,
          dueDate: paymentDate(k),
          principalMinor: principal,
          interestMinor: interest,
          feeMinor: fee,
          remainingPrincipalMinor: k == termMonths ? BigInt.zero : p,
        ),
      );
    }
    return entries;
  }

  /// 固定分期费率（等本等费）：每期本金 P/n，每期费用 = 原始本金 × 月费率。
  /// 名义费率会显著低估真实成本，用 [effectiveAprPercent] 揭示。
  List<DebtScheduleEntry> _fixedInstallment() {
    final p = principalOriginalMinor;
    final r = aprPercent / _r(BigInt.from(1200));
    final entries = <DebtScheduleEntry>[];
    var remaining = p;
    for (var k = 1; k <= termMonths && remaining > BigInt.zero; k++) {
      var principal = (_r(p) / _r(BigInt.from(termMonths))).rounded();
      if (k == termMonths || principal >= remaining) principal = remaining;
      final fee = (_r(p) * r).rounded();
      remaining -= principal;
      entries.add(
        DebtScheduleEntry(
          seq: k,
          dueDate: paymentDate(k),
          principalMinor: principal,
          interestMinor: BigInt.zero,
          feeMinor: fee,
          remainingPrincipalMinor: remaining,
        ),
      );
    }
    return entries;
  }

  List<DebtScheduleEntry> _interestFree() {
    final p = principalOriginalMinor;
    final entries = <DebtScheduleEntry>[];
    var remaining = p;
    for (var k = 1; k <= termMonths && remaining > BigInt.zero; k++) {
      var principal = (_r(p) / _r(BigInt.from(termMonths))).rounded();
      if (k == termMonths || principal >= remaining) principal = remaining;
      remaining -= principal;
      entries.add(
        DebtScheduleEntry(
          seq: k,
          dueDate: paymentDate(k),
          principalMinor: principal,
          interestMinor: BigInt.zero,
          feeMinor: BigInt.zero,
          remainingPrincipalMinor: remaining,
        ),
      );
    }
    return entries;
  }

  /// 有效年化利率（按计划现金流求月 IRR 后年化）。现金流不完整时返回 null。
  Rational? effectiveAprPercent() {
    final entries = generateSchedule();
    if (entries.isEmpty) return null;
    final flows = <double>[principalOriginalMinor.toDouble()];
    for (final e in entries) {
      flows.add(-e.totalMinor.toDouble());
    }
    final monthly = irrMonthly(flows);
    if (monthly == null) return null;
    return Rational.parseDecimal(monthly.toStringAsFixed(10)) *
        _r(BigInt.from(1200));
  }

  /// 提前还款模拟：在原计划第 [afterEntrySeq] 期还完之后，额外偿还 [extraMinor]。
  /// [shortenTerm]=true 保持每期还款额不变、缩短期限；
  /// false 时保持剩余期限、降低每期还款额。
  PrepaymentResult simulatePrepayment({
    required int afterEntrySeq,
    required BigInt extraMinor,
    required BigInt remainingPrincipalMinor,
    bool shortenTerm = true,
  }) {
    final schedule = generateSchedule();
    if (afterEntrySeq < 0 || afterEntrySeq > schedule.length) {
      throw ArgumentError('期数越界');
    }
    final oldTailInterest = _tailCost(schedule, afterEntrySeq);
    final fee = prepayFeePercent == null
        ? BigInt.zero
        : (_r(extraMinor) * prepayFeePercent! / _r(BigInt.from(100))).rounded();
    var remaining = remainingPrincipalMinor - extraMinor;
    if (remaining < BigInt.zero) remaining = BigInt.zero;
    final oldRemainingMonths = schedule.length - afterEntrySeq;

    if (remaining == BigInt.zero) {
      return PrepaymentResult(
        remainingEntries: const [],
        prepayFeeMinor: fee,
        interestSavedMinor: oldTailInterest - fee,
        monthsSaved: oldRemainingMonths,
      );
    }

    final List<DebtScheduleEntry> tail;
    if (shortenTerm) {
      // 保持原每期还款额（参考下一期），逐月清偿。
      final payLevel = afterEntrySeq < schedule.length
          ? schedule[afterEntrySeq].totalMinor
          : BigInt.one;
      tail = _simulateWithPayment(remaining, afterEntrySeq, payLevel);
    } else {
      // 保持剩余期限：重新生成同方式计划。
      tail = DebtContract(
        liabilityAccountId: liabilityAccountId,
        principalOriginalMinor: remaining,
        aprPercent: aprPercent,
        method: method == RepaymentMethod.manual
            ? RepaymentMethod.annuity
            : method,
        termMonths: oldRemainingMonths,
        startDate: startDate,
        firstPaymentDate: afterEntrySeq < schedule.length
            ? schedule[afterEntrySeq].dueDate
            : null,
        monthlyFeeMinor: monthlyFeeMinor,
        basis: basis,
      ).generateSchedule();
    }
    final newCost = tail.fold(
      BigInt.zero,
      (s, e) => s + e.interestMinor + e.feeMinor,
    );
    return PrepaymentResult(
      remainingEntries: tail,
      prepayFeeMinor: fee,
      interestSavedMinor: oldTailInterest - newCost - fee,
      monthsSaved: oldRemainingMonths - tail.length,
    );
  }

  /// 以固定每期还款额 [payLevelMinor] 逐月清偿 [startRemaining]，返回逐期明细。
  List<DebtScheduleEntry> _simulateWithPayment(
    BigInt startRemaining,
    int startSeq,
    BigInt payLevelMinor,
  ) {
    final i = monthlyRate;
    final fee = monthlyFeeMinor ?? BigInt.zero;
    final entries = <DebtScheduleEntry>[];
    var remaining = startRemaining;
    var seq = startSeq + 1;
    while (remaining > BigInt.zero && entries.length < 600) {
      final interest = (_r(remaining) * i).rounded();
      var principal = payLevelMinor - interest - fee;
      if (principal <= BigInt.zero || principal >= remaining) {
        principal = remaining;
      }
      remaining -= principal;
      entries.add(
        DebtScheduleEntry(
          seq: seq++,
          dueDate: paymentDate(seq - 1),
          principalMinor: principal,
          interestMinor: interest,
          feeMinor: fee,
          remainingPrincipalMinor: remaining,
        ),
      );
    }
    return entries;
  }

  BigInt _tailCost(List<DebtScheduleEntry> schedule, int fromSeqExclusive) {
    var sum = BigInt.zero;
    for (var k = fromSeqExclusive; k < schedule.length; k++) {
      sum += schedule[k].interestMinor + schedule[k].feeMinor;
    }
    return sum;
  }
}

class DebtScheduleEntry {
  const DebtScheduleEntry({
    required this.seq,
    required this.dueDate,
    required this.principalMinor,
    required this.interestMinor,
    required this.feeMinor,
    required this.remainingPrincipalMinor,
  });

  final int seq;
  final DateTime dueDate;
  final BigInt principalMinor;
  final BigInt interestMinor;
  final BigInt feeMinor;
  final BigInt remainingPrincipalMinor;

  BigInt get totalMinor => principalMinor + interestMinor + feeMinor;
}

class PrepaymentResult {
  const PrepaymentResult({
    required this.remainingEntries,
    required this.prepayFeeMinor,
    required this.interestSavedMinor,
    required this.monthsSaved,
  });

  final List<DebtScheduleEntry> remainingEntries;
  final BigInt prepayFeeMinor;

  /// 相对原计划节省的利息+费用（已扣手续费，可为负）。
  final BigInt interestSavedMinor;
  final int monthsSaved;
}

/// 还款优先级策略对比：雪崩（高利率优先） vs 雪球（小额优先）。
enum PayoffStrategy { avalanche, snowball }

class DebtPosition {
  const DebtPosition({
    required this.name,
    required this.remainingPrincipalMinor,
    required this.aprPercent,
    required this.minMonthlyPaymentMinor,
  });

  final String name;
  final BigInt remainingPrincipalMinor;
  final Rational aprPercent;
  final BigInt minMonthlyPaymentMinor;
}

class PayoffPlan {
  const PayoffPlan({
    required this.order,
    required this.months,
    required this.totalInterestMinor,
  });

  /// 债务还清顺序（入参索引）。
  final List<int> order;
  final int months;
  final BigInt totalInterestMinor;
}

/// 多债务按月模拟：月利息 = 剩余本金 × apr/1200；先付各笔最低还款，
/// 额外资金按策略注入优先债务，还清一笔后其最低还款滚入可用资金池。
class DebtPayoffPlanner {
  const DebtPayoffPlanner._();

  static PayoffPlan simulate(
    List<DebtPosition> debts,
    PayoffStrategy strategy, {
    BigInt? extraMonthlyMinor,
    int maxMonths = 600,
  }) {
    final n = debts.length;
    final remaining = [for (final d in debts) d.remainingPrincipalMinor];
    final rates = [for (final d in debts) d.aprPercent / _r(BigInt.from(1200))];
    final mins = [for (final d in debts) d.minMonthlyPaymentMinor];
    final extra = extraMonthlyMinor ?? BigInt.zero;
    final cleared = List<bool>.filled(n, false);
    final order = <int>[];
    var totalInterest = BigInt.zero;
    var month = 0;
    while (remaining.any((x) => x > BigInt.zero)) {
      month++;
      if (month > maxMonths) break;
      for (var j = 0; j < n; j++) {
        if (cleared[j]) continue;
        final interest = (_r(remaining[j]) * rates[j]).rounded();
        remaining[j] += interest;
        totalInterest += interest;
      }
      // 可用资金 = 额外预算 + 已还清债务释放的最低还款。
      var pool = extra;
      for (var j = 0; j < n; j++) {
        if (cleared[j]) pool += mins[j];
      }
      final live = [
        for (var j = 0; j < n; j++)
          if (!cleared[j]) j,
      ];
      live.sort(
        strategy == PayoffStrategy.avalanche
            ? (a, b) => debts[b].aprPercent.asDouble().compareTo(
                debts[a].aprPercent.asDouble(),
              )
            : (a, b) => remaining[a].compareTo(remaining[b]),
      );
      // 每笔先付自己的最低还款。
      for (final j in live) {
        var pay = mins[j] > remaining[j] ? remaining[j] : mins[j];
        remaining[j] -= pay;
      }
      // 再把资金池按优先级注入。
      for (final j in live) {
        if (remaining[j] <= BigInt.zero) continue;
        var inject = pool > remaining[j] ? remaining[j] : pool;
        remaining[j] -= inject;
        pool -= inject;
      }
      // 记录本期还清的顺序。
      for (final j in live) {
        if (remaining[j] <= BigInt.zero && !cleared[j]) {
          cleared[j] = true;
          order.add(j);
        }
      }
    }
    return PayoffPlan(
      order: order,
      months: month,
      totalInterestMinor: totalInterest,
    );
  }
}

/// 月度 IRR（Newton 迭代 + 二分兜底）。仅用于利率展示，不用于账本金额。
double? irrMonthly(List<double> cashFlows) {
  double npv(double r) {
    var sum = 0.0;
    var df = 1.0;
    for (final cf in cashFlows) {
      sum += cf / df;
      df *= 1 + r;
    }
    return sum;
  }

  var r = 0.01;
  for (var iter = 0; iter < 100; iter++) {
    final v = npv(r);
    if (v.abs() < 1e-9) return r;
    const h = 1e-7;
    final dv = (npv(r + h) - v) / h;
    if (dv == 0) break;
    final next = r - v / dv;
    if (next <= -0.999) break;
    if ((next - r).abs() < 1e-12) return next;
    r = next;
  }
  var lo = -0.9999;
  var hi = 10.0;
  var flo = npv(lo);
  for (var iter = 0; iter < 200; iter++) {
    final mid = (lo + hi) / 2;
    final fm = npv(mid);
    if (fm.abs() < 1e-9) return mid;
    if (flo * fm < 0) {
      hi = mid;
    } else {
      lo = mid;
      flo = fm;
    }
  }
  return null;
}

Rational _pow(Rational base, int exp) {
  var result = Rational.one;
  for (var i = 0; i < exp; i++) {
    result = result * base;
  }
  return result;
}
