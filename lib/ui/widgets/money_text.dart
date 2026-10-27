import 'package:flutter/material.dart';

import '../../domain/money/currency.dart';
import '../../domain/money/money.dart';
import '../theme/app_theme.dart';

/// 最小单位金额 → 展示文本（全 UI 唯一格式化入口）。
String fmtMinor(BigInt minor, String ccyCode, {bool sign = false}) {
  final m = Money.fromMinor(minor, CurrencyInfo.parse(ccyCode));
  final s = m.format(withSymbol: true);
  if (sign && !minor.isNegative && minor != BigInt.zero) return '+$s';
  return s;
}

/// 金额文本：等宽数字、可选正负着色、三档字号。
///
/// 全部金额展示应经此组件，保证全应用数字排版一致。
class MoneyText extends StatelessWidget {
  const MoneyText(
    this.minor, {
    super.key,
    required this.currencyCode,
    this.size = MoneySize.md,
    this.colorBySign = false,
    this.color,
    this.sign = false,
    this.weight,
  });

  final BigInt minor;
  final String currencyCode;
  final MoneySize size;
  final bool colorBySign;

  /// 正负语义色覆盖 colorBySign。
  final Color? color;
  final bool sign;
  final FontWeight? weight;

  static const _styles = <MoneySize, TextStyle>{
    MoneySize.xl: TextStyle(fontSize: 36, fontWeight: FontWeight.w600),
    MoneySize.lg: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
    MoneySize.md: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    MoneySize.sm: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
  };

  @override
  Widget build(BuildContext context) {
    final style = _styles[size]!.copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
      color: color ??
          (colorBySign
              ? signColor(minor, Theme.of(context).brightness)
              : null),
      fontWeight: weight,
    );
    return Text(fmtMinor(minor, currencyCode, sign: sign), style: style);
  }
}

enum MoneySize { xl, lg, md, sm }
