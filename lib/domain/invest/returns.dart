import 'dart:math' as math;

import '../debt/debt_contract.dart' show irrMonthly;
import '../utils/dates.dart';

/// 投资收益率：TWR（时间加权）与 XIRR（内部收益率/资金加权）。
///
/// 计算前必须先确定“组合边界”：组合内部买卖不是外部现金流；
/// 只有入金/出金是外部现金流。口径详见 docs/05。
class TwrFlow {
  const TwrFlow(this.date, this.amountBaseMinor);

  final DateTime date;

  /// 正=外部投入（入金），负=外部取出（出金）。本位币。
  final BigInt amountBaseMinor;
}

class TwrValuation {
  const TwrValuation(this.date, this.valueBaseMinor);

  final DateTime date;
  final BigInt valueBaseMinor;
}

/// TWR 的一个子期间收益：[start]/[end] 为相邻估值点日期，
/// r = (V_end − F) / V_start − 1（期间外部现金流计于期末）。
class PeriodReturn {
  const PeriodReturn(this.start, this.end, this.r);

  final DateTime start;
  final DateTime end;
  final double r;
}

/// 时间加权收益率：按估值点切分子期间，
/// r_k = (V_end − F_k) / V_start − 1（外部现金流计于期末），
/// 总收益 = Π(1+r_k) − 1。[annualizeDays] > 0 时给年化值。
class TwrCalculator {
  const TwrCalculator._();

  /// 子期间收益序列（风险指标等下游分析的输入）。
  /// 任一子期间期初估值为 0 时整体不可计算，返回 null。
  static List<PeriodReturn>? subPeriodReturns({
    required List<TwrValuation> valuations,
    required List<TwrFlow> flows,
  }) {
    if (valuations.length < 2) return null;
    final vs = [...valuations]..sort((a, b) => a.date.compareTo(b.date));
    final fs = [...flows]..sort((a, b) => a.date.compareTo(b.date));
    final out = <PeriodReturn>[];
    var fi = 0;
    for (var k = 1; k < vs.length; k++) {
      final v0 = vs[k - 1].valueBaseMinor;
      if (v0 == BigInt.zero) return null;
      var flowInPeriod = BigInt.zero;
      while (fi < fs.length &&
          fs[fi].date.isAfter(vs[k - 1].date) &&
          !fs[fi].date.isAfter(vs[k].date)) {
        flowInPeriod += fs[fi].amountBaseMinor;
        fi++;
      }
      final v1 = vs[k].valueBaseMinor - flowInPeriod;
      out.add(PeriodReturn(
          vs[k - 1].date, vs[k].date, v1.toDouble() / v0.toDouble() - 1));
    }
    return out;
  }

  static double? twr({
    required List<TwrValuation> valuations,
    required List<TwrFlow> flows,
    int? annualizeDays,
  }) {
    final subs = subPeriodReturns(valuations: valuations, flows: flows);
    if (subs == null) return null;
    var result = subs.fold(1.0, (a, p) => a * (1 + p.r)) - 1;
    if (annualizeDays != null && result > -1) {
      final days = calendarDaysBetween(subs.first.start, subs.last.end);
      if (days > 0) {
        final years = days / 365.0;
        result = math.pow(1 + result, 1 / years).toDouble() - 1;
      }
    }
    return result;
  }
}

class XirrFlow {
  const XirrFlow(this.date, this.amountBaseMinor);

  final DateTime date;

  /// 从组合视角：投入为负（钱离开你进入组合），取回与期末市值为正。
  final BigInt amountBaseMinor;
}

/// XIRR（年度化，实际/365 折现）。牛顿 + 二分兜底；
/// 无解（现金流同号）、多解或数值不收敛时返回 null 并通过 [failure] 说明。
double? xirr(List<XirrFlow> flows, {double? initialGuess}) {
  if (flows.length < 2) return null;
  final sorted = [...flows]..sort((a, b) => a.date.compareTo(b.date));
  final t0 = sorted.first.date;
  final hasPos = sorted.any((f) => f.amountBaseMinor > BigInt.zero);
  final hasNeg = sorted.any((f) => f.amountBaseMinor < BigInt.zero);
  if (!hasPos || !hasNeg) return null;

  double npv(double r) {
    var sum = 0.0;
    for (final f in sorted) {
      final years = f.date.difference(t0).inDays / 365.0;
      sum += f.amountBaseMinor.toDouble() / math.pow(1 + r, years).toDouble();
    }
    return sum;
  }

  var r = initialGuess ?? 0.1;
  for (var iter = 0; iter < 200; iter++) {
    final v = npv(r);
    if (v.abs() < 1e-7) return r > -0.999 ? r : null;
    const h = 1e-6;
    final dv = (npv(r + h) - v) / h;
    if (dv == 0 || r <= -0.9999) break;
    final next = r - v / dv;
    if (next <= -0.9999) break;
    if ((next - r).abs() < 1e-10) return next;
    r = next;
  }
  // 二分兜底：在 (-0.9999, 10] 找符号变化区间。
  var lo = -0.9999;
  var hi = 10.0;
  var flo = npv(lo);
  var fhi = npv(hi);
  if (flo * fhi > 0) return null;
  for (var iter = 0; iter < 300; iter++) {
    final mid = (lo + hi) / 2;
    final fm = npv(mid);
    if (fm.abs() < 1e-9) return mid;
    if (flo * fm < 0) {
      hi = mid;
      fhi = fm;
    } else {
      lo = mid;
      flo = fm;
    }
  }
  return (lo + hi) / 2;
}

/// 月 IRR → 年化（复利）。与 debt_contract.irrMonthly 复用。
double? monthlyIrrToAnnual(List<double> monthlyCashFlows) {
  final m = irrMonthly(monthlyCashFlows);
  if (m == null) return null;
  return math.pow(1 + m, 12).toDouble() - 1;
}
