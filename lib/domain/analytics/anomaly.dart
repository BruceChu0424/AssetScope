/// 分类月度支出异常检测（稳健统计）。
///
/// 对每个分类的近 [windowSize] 个月支出序列计算中位数与
/// MAD（绝对中位差），本月偏离 ≥ [zThreshold] 个稳健 σ 视为异常。
/// 使用中位数而非均值：单月大额（如年缴保费）不会污染基线。
/// 金额 BigInt；z 值仅作展示用 double。
class SpendingAnomaly {
  const SpendingAnomaly({
    required this.categoryName,
    required this.currentMinor,
    required this.baselineMedianMinor,
    required this.robustZ,
    required this.spendUp,
  });

  final String categoryName;
  final BigInt currentMinor;
  final BigInt baselineMedianMinor;

  /// |current − median| / (1.4826 × MAD)；MAD=0 时按 |差|/median 折算。
  final double robustZ;

  /// true=花得比基线多，false=异常偏少。
  final bool spendUp;
}

class AnomalyDetector {
  const AnomalyDetector._();

  /// [history] 不含本月。序列不足 [minHistory] 个月的分类跳过。
  static List<SpendingAnomaly> detect({
    required Map<String, String> categoryNames,
    required Map<String, List<BigInt>> historyByCategory,
    required Map<String, BigInt> currentByCategory,
    int minHistory = 3,
    double zThreshold = 3.0,
  }) {
    final out = <SpendingAnomaly>[];
    for (final e in currentByCategory.entries) {
      final hist = historyByCategory[e.key];
      if (hist == null || hist.length < minHistory) continue;
      final current = e.value;
      final med = _median(hist);
      final dev = (current - med).abs();
      if (dev == BigInt.zero) continue;
      final mad = _median([for (final h in hist) (h - med).abs()]);
      double z;
      if (mad == BigInt.zero) {
        // 完全稳定序列：按相对偏差折算（dev/med 即"几倍"）。
        z = med == BigInt.zero
            ? (dev == BigInt.zero ? 0 : 99)
            : dev.toDouble() / med.toDouble();
      } else {
        z = dev.toDouble() / (1.4826 * mad.toDouble());
      }
      if (z < zThreshold) continue;
      out.add(
        SpendingAnomaly(
          categoryName: categoryNames[e.key] ?? e.key,
          currentMinor: current,
          baselineMedianMinor: med,
          robustZ: z,
          spendUp: current > med,
        ),
      );
    }
    out.sort((a, b) => b.robustZ.compareTo(a.robustZ));
    return out;
  }

  static BigInt _median(List<BigInt> xs) {
    final s = [...xs]..sort();
    final mid = s.length ~/ 2;
    if (s.length.isOdd) return s[mid];
    return (s[mid - 1] + s[mid]) ~/ BigInt.two;
  }
}
