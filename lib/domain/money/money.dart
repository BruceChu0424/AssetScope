import 'currency.dart';
import 'fx_rate.dart';

/// 舍入模式。账本默认 halfEven（银行家舍入），展示可用 halfUp。
enum RoundingMode { halfUp, halfEven, down, up }

/// 不可变金额：某一币种下以最小单位计的整数金额。
///
/// - 运算只接受同币种（`+`/`-`/`compareTo`），跨币种必须走 [FxRate.convert]。
/// - 乘除以比例时必须显式给出舍入模式，禁止隐式截断。
class Money implements Comparable<Money> {
  Money.zero(this.currency) : amountMinor = BigInt.zero;

  const Money.fromMinor(this.amountMinor, this.currency);

  final BigInt amountMinor;
  final CurrencyInfo currency;

  static Money fromMajorUnits(BigInt majorUnits, CurrencyInfo currency) {
    return Money.fromMinor(majorUnits, currency);
  }

  /// 解析十进制字符串（如 "1234.56"、"-0.01"），忽略千分位逗号与首尾空白。
  /// 小数位超出币种精度时按 [mode] 舍入。
  static Money parse(
    String input,
    CurrencyInfo currency, {
    RoundingMode mode = RoundingMode.halfEven,
  }) {
    var s = input.trim().replaceAll(',', '').replaceAll(currency.symbol, '');
    if (s.isEmpty) throw const FormatException('空金额');
    var neg = false;
    if (s.startsWith('-')) {
      neg = true;
      s = s.substring(1);
    } else if (s.startsWith('+')) {
      s = s.substring(1);
    }
    final dot = s.indexOf('.');
    String intPart;
    String fracPart;
    if (dot < 0) {
      intPart = s;
      fracPart = '';
    } else {
      intPart = s.substring(0, dot);
      fracPart = s.substring(dot + 1);
    }
    if (intPart.isEmpty && fracPart.isEmpty) {
      throw const FormatException('空金额');
    }
    final digits = currency.minorUnitDigits;
    if (fracPart.length > digits) {
      // 超精度：转有理数后整体舍入（tie 时按最终值奇偶，避免分段舍入错误）
      final keep = fracPart.substring(0, digits);
      final rest = fracPart.substring(digits);
      final base = BigInt.parse('${intPart.isEmpty ? '0' : intPart}$keep');
      final exact =
          Rational.fromInt(base) +
          Rational.fromInt(BigInt.parse(rest)) /
              Rational.fromInt(BigInt.from(10).pow(rest.length));
      final minor = exact.rounded(mode: mode);
      return Money.fromMinor(neg ? -minor : minor, currency);
    }
    final padded = fracPart.padRight(digits, '0');
    final minor = BigInt.parse('${intPart.isEmpty ? '0' : intPart}$padded');
    return Money.fromMinor(neg ? -minor : minor, currency);
  }

  static BigInt _roundDiv(BigInt n, BigInt d, RoundingMode mode) {
    assert(d > BigInt.zero);
    final q = n ~/ d;
    final r = n.remainder(d).abs();
    final twice = r * BigInt.two;
    var add = BigInt.zero;
    switch (mode) {
      case RoundingMode.halfUp:
        if (twice >= d) add = BigInt.one;
      case RoundingMode.halfEven:
        if (twice > d || (twice == d && q.isOdd)) add = BigInt.one;
      case RoundingMode.down:
        add = BigInt.zero;
      case RoundingMode.up:
        if (r > BigInt.zero) add = BigInt.one;
    }
    final signed = n.isNegative ? -(q + add) : (q + add);
    return signed;
  }

  bool get isNegative => amountMinor.isNegative;
  bool get isZero => amountMinor == BigInt.zero;
  Money negate() => Money.fromMinor(-amountMinor, currency);
  Money abs() => Money.fromMinor(amountMinor.abs(), currency);

  Money operator +(Money o) =>
      _same(o, () => Money.fromMinor(amountMinor + o.amountMinor, currency));
  Money operator -(Money o) =>
      _same(o, () => Money.fromMinor(amountMinor - o.amountMinor, currency));

  Money scale(BigInt factor) => Money.fromMinor(amountMinor * factor, currency);

  /// 按有理数比例缩放并舍入（例如归属比例 2/3）。
  Money scaleRatio(
    BigInt numer,
    BigInt denom, {
    RoundingMode mode = RoundingMode.halfEven,
  }) => Money.fromMinor(_roundDiv(amountMinor * numer, denom, mode), currency);

  T _same<T>(Money other, T Function() f) {
    if (other.currency.code != currency.code) {
      throw ArgumentError(
        '币种不一致: ${currency.code} vs ${other.currency.code}，请使用 FxRate.convert',
      );
    }
    return f();
  }

  @override
  int compareTo(Money other) =>
      _same(other, () => amountMinor.compareTo(other.amountMinor));

  bool operator <(Money o) => compareTo(o) < 0;
  bool operator >(Money o) => compareTo(o) > 0;
  bool operator <=(Money o) => compareTo(o) <= 0;
  bool operator >=(Money o) => compareTo(o) >= 0;

  @override
  bool operator ==(Object other) =>
      other is Money &&
      other.currency.code == currency.code &&
      other.amountMinor == amountMinor;

  @override
  int get hashCode => Object.hash(currency.code, amountMinor);

  /// 主要单位数值（不再用于计算，仅用于展示与序列化）。
  BigInt get majorUnits => amountMinor ~/ currency.minorFactor;

  String format({bool withSymbol = false}) {
    final neg = amountMinor.isNegative;
    final abs = amountMinor.abs();
    final f = currency.minorFactor;
    final major = abs ~/ f;
    final minor = (abs % f).toString().padLeft(currency.minorUnitDigits, '0');
    final majorStr = _groupThousands(major.toString());
    final frac = currency.minorUnitDigits == 0 ? '' : '.$minor';
    final sign = neg ? '-' : '';
    final sym = withSymbol ? currency.symbol : '';
    return '$sign$sym$majorStr$frac';
  }

  static String _groupThousands(String digits) {
    final sb = StringBuffer();
    final n = digits.length;
    for (var i = 0; i < n; i++) {
      sb.write(digits[i]);
      final remaining = n - 1 - i;
      if (remaining > 0 && remaining % 3 == 0) sb.write(',');
    }
    return sb.toString();
  }

  @override
  String toString() => format(withSymbol: true);
}
