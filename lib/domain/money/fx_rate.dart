import 'currency.dart';
import 'money.dart';

/// 精确有理数（分子/分母均为 BigInt），用于汇率、利率、归属比例、证券数量。
///
/// 不使用 double：0.1 + 0.2 类误差会污染账本。分母恒为正。
class Rational {
  final BigInt n;
  final BigInt d;

  const Rational._(this.n, this.d);

  factory Rational.zero() => Rational._(BigInt.zero, BigInt.one);

  static final Rational one = Rational._(BigInt.one, BigInt.one);

  /// percent("3.85") == 385/10000
  factory Rational.percent(String decimalPercent) =>
      Rational.parseDecimal(decimalPercent) / Rational._(BigInt.from(100), BigInt.one);

  factory Rational.parseDecimal(String s) {
    s = s.trim();
    if (s.isEmpty) throw const FormatException('空数字');
    var neg = false;
    if (s.startsWith('-')) {
      neg = true;
      s = s.substring(1);
    }
    final dot = s.indexOf('.');
    if (dot < 0) {
      final v = Rational._(BigInt.parse(s.isEmpty ? '0' : s), BigInt.one);
      return neg ? -v : v;
    }
    final intPart = s.substring(0, dot);
    final frac = s.substring(dot + 1);
    final num = BigInt.parse('${intPart.isEmpty ? '0' : intPart}$frac');
    final den = BigInt.from(10).pow(frac.length);
    final v = Rational._(num, den);
    return neg ? -v : v;
  }

  factory Rational.fromInt(BigInt v) => Rational._(v, BigInt.one);

  /// 分数构造（自动规范化、分母转正）。
  factory Rational.fromFrac(BigInt n, BigInt d) {
    if (d == BigInt.zero) throw ArgumentError('分母为零');
    return d.isNegative
        ? Rational._(-n, -d)._norm()
        : Rational._(n, d)._norm();
  }

  Rational operator +(Rational o) => Rational._(n * o.d + o.n * d, d * o.d)._norm();
  Rational operator -(Rational o) => Rational._(n * o.d - o.n * d, d * o.d)._norm();
  Rational operator *(Rational o) => Rational._(n * o.n, d * o.d)._norm();
  Rational operator /(Rational o) {
    if (o.n == BigInt.zero) throw ArgumentError('除以零');
    return Rational._(n * o.d, d * o.n)._norm();
  }
  Rational operator -() => Rational._(-n, d);

  bool operator <(Rational o) => (this - o).isNegative;
  bool operator >(Rational o) => (o - this).isNegative;
  bool operator <=(Rational o) => !((o - this).isNegative);
  bool operator >=(Rational o) => !((this - o).isNegative);

  bool get isNegative => n.isNegative;
  bool get isZero => n == BigInt.zero;

  Rational abs() => isNegative ? -this : this;

  /// 转为 double 仅用于展示（进度、图表、图表坐标）。
  double asDouble() => n.toDouble() / d.toDouble();

  /// num/den 的舍入整数。在绝对值上按模式舍入后回填符号
  /// （对称舍入：−3.5 halfEven → −4，与 +3.5 → 4 镜像）。
  BigInt rounded({RoundingMode mode = RoundingMode.halfEven}) {
    final neg = n.isNegative;
    final an = n.abs();
    final q = an ~/ d;
    final r = an.remainder(d);
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
    final mag = q + add;
    return neg ? -mag : mag;
  }

  Rational _norm() {
    if (d == BigInt.one) return this;
    var a = n.abs();
    var b = d.abs();
    while (b != BigInt.zero) {
      final t = b;
      b = a % b;
      a = t;
    }
    final g = a == BigInt.zero ? BigInt.one : a;
    var nn = n ~/ g;
    var dd = d ~/ g;
    if (dd.isNegative) {
      nn = -nn;
      dd = -dd;
    }
    return Rational._(nn, dd);
  }

  @override
  bool operator ==(Object other) =>
      other is Rational &&
      other.n * d == n * other.d;

  @override
  int get hashCode => Object.hash(n ~/ _gcd(n, d), d ~/ _gcd(n, d));

  BigInt _gcd(BigInt a, BigInt b) {
    a = a.abs();
    b = b.abs();
    while (b != BigInt.zero) {
      final t = b;
      b = a % b;
      a = t;
    }
    return a == BigInt.zero ? BigInt.one : a;
  }

  @override
  String toString() => d == BigInt.one ? '$n' : '$n/$d';
}

/// 汇率：1 单位 [from] 可兑换 [to] 的数量（有理数精确表示）。
class FxRate {
  const FxRate({
    required this.from,
    required this.to,
    required this.rate,
    required this.asOf,
    this.source = 'manual',
  });

  final CurrencyInfo from;
  final CurrencyInfo to;

  /// rate = 兑换数量(to) / 1 from。
  final Rational rate;
  final DateTime asOf;
  final String source;

  /// 用 [money] 的币种按本汇率折算为另一端币种金额（自动判方向）。
  Money convert(Money money, {RoundingMode mode = RoundingMode.halfEven}) {
    final src = money.currency;
    Rational r;
    CurrencyInfo dst;
    if (src.code == from.code) {
      r = rate;
      dst = to;
    } else if (src.code == to.code) {
      r = Rational.one / rate;
      dst = from;
    } else {
      throw ArgumentError('汇率 $from->$to 无法处理币种 ${src.code}');
    }
    // minor_out = minor_in × rate × (factor_to / factor_from)
    final scaled = Rational._(money.amountMinor, BigInt.one) *
        r *
        Rational._(
          BigInt.from(10).pow(dst.minorUnitDigits),
          BigInt.from(10).pow(src.minorUnitDigits),
        );
    return Money.fromMinor(scaled.rounded(mode: mode), dst);
  }

  FxRate inverse() => FxRate(
      from: to, to: from, rate: Rational.one / rate, asOf: asOf, source: source);
}
