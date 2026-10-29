/// 个人消费指数：用账本自己的分类支出算"我的通胀率"（docs/11 §8）。
///
/// 口径：固定篮子 Laspeyres 近似——篮子 = 基期（近段前 [windowMonths] 个月）
/// 各消费分类的月均支出份额 wᵢ；指数 = Σ wᵢ × (近期月均ᵢ / 基期月均ᵢ)。
/// 含义："维持基期生活结构不变，现在要多花多少"。比率运算用 double 展示
///（不涉金额计算，金额合计仍是 BigInt 精确值）。
///
/// 边界：基期有、近期归零的分类（消费习惯消失）剔除出篮子并对剩余权重
/// 归一；基期没有、近期新增的分类天然不在篮子——两者都通过
/// [PersonalCpiResult.basketCoverage] 披露。样本不足返回 null。
library;

import 'dart:math' as math;
class PersonalCpiResult {
  const PersonalCpiResult({
    required this.annualRate,
    required this.basketCoverage,
    required this.reliable,
    required this.contributions,
    required this.baseMonths,
    required this.recentMonths,
    required this.gapMonths,
  });

  /// 年化篮子涨幅（如 0.07 = 7%/年；可为负 = 生活成本在降）。
  final double annualRate;

  /// 篮子覆盖率 0–1：基期支出中可比较分类的权重和。
  final double basketCoverage;

  /// 样本与覆盖是否足以解读（每侧 ≥3 月且覆盖 ≥0.6）。
  final bool reliable;

  /// 膨胀贡献分解（降序）：分类 → (基期份额, 近期/基期)。
  final List<({String categoryId, double share, double ratio})> contributions;

  final int baseMonths;
  final int recentMonths;

  /// 近期窗末与基期窗首的间隔月数（年化用）。
  final int gapMonths;
}

class PersonalCpi {
  const PersonalCpi._();

  /// [monthly] 按月升序：月份键 → 该月各消费分类支出（最小单位）。
  static PersonalCpiResult? compute(
    List<(String, Map<String, BigInt>)> monthly, {
    int windowMonths = 6,
  }) {
    if (monthly.length < 6 || windowMonths < 3) return null;
    // 取尾部 2×window 个月。
    final tail = monthly.length >= windowMonths * 2
        ? monthly.sublist(monthly.length - windowMonths * 2)
        : monthly;
    final baseMonthsData = tail.sublist(0, tail.length ~/ 2);
    final recentMonthsData = tail.sublist(tail.length ~/ 2);
    if (baseMonthsData.length < 3 || recentMonthsData.length < 3) return null;

    Map<String, BigInt> avg(List<(String, Map<String, BigInt>)> ms) {
      final sum = <String, BigInt>{};
      for (final (_, byCat) in ms) {
        byCat.forEach((c, v) => sum[c] = (sum[c] ?? BigInt.zero) + v);
      }
      return {
        for (final e in sum.entries)
          e.key: (e.value ~/ BigInt.from(ms.length)),
      };
    }

    final base = avg(baseMonthsData);
    final recent = avg(recentMonthsData);
    final baseTotal =
        base.values.fold(BigInt.zero, (a, b) => a + b);
    if (baseTotal == BigInt.zero) return null;

    var coveredWeight = 0.0;
    var indexSum = 0.0;
    final contributions = <({String categoryId, double share, double ratio})>[];
    for (final e in base.entries) {
      final w = e.value.toDouble() / baseTotal.toDouble();
      final r = recent[e.key];
      if (r == null || r == BigInt.zero || e.value == BigInt.zero) continue;
      final ratio = r.toDouble() / e.value.toDouble();
      coveredWeight += w;
      indexSum += w * ratio;
      contributions.add((categoryId: e.key, share: w, ratio: ratio));
    }
    if (coveredWeight <= 0) return null;
    final index = indexSum / coveredWeight; // 归一化篮子指数

    // 年化：指数^(12/间隔月)。
    final gap = _monthGap(baseMonthsData.first.$1, recentMonthsData.last.$1);
    final annual = gap <= 0
        ? index - 1
        : math.pow(index, 12.0 / gap).toDouble() - 1;

    contributions.sort((a, b) =>
        (b.share * (b.ratio - 1)).compareTo(a.share * (a.ratio - 1)));

    return PersonalCpiResult(
      annualRate: annual,
      basketCoverage: coveredWeight,
      reliable: coveredWeight >= 0.6,
      contributions: contributions,
      baseMonths: baseMonthsData.length,
      recentMonths: recentMonthsData.length,
      gapMonths: gap,
    );
  }

  /// 月份键（yyyy-MM）差值。
  static int _monthGap(String a, String b) {
    int parse(String s) {
      final parts = s.split('-');
      return int.parse(parts[0]) * 12 + int.parse(parts[1]);
    }

    return parse(b) - parse(a);
  }
}
