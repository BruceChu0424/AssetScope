import '../../domain/money/fx_rate.dart';

/// Rational 的展示辅助（全 UI 共用；账本计算仍用精确有理数）。
extension RationalDisplayX on Rational {
  /// 固定 [digits] 位小数的十进制字符串（截断，去除尾零）。
  String toDecimalString(int digits) {
    var r = this;
    final sign = r.isNegative ? '-' : '';
    if (r.isNegative) r = -r;
    final intPart = (r.n ~/ r.d).toString();
    var rem = r.n % r.d;
    final frac = StringBuffer();
    for (var i = 0; i < digits && rem != BigInt.zero; i++) {
      rem *= BigInt.from(10);
      frac.write((rem ~/ r.d).toString());
      rem = rem % r.d;
    }
    return frac.isEmpty ? '$sign$intPart' : '$sign$intPart.${frac.toString()}';
  }
}
