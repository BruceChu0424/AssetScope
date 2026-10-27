/// 币种定义与小数位注册表。
///
/// 金额一律以“最小货币单位”的整数（BigInt）存储与运算：
/// CNY/USD 为“分”，JPY 为“元”，加密资产可到 8 位。
/// 账本任何路径都不允许使用 double 累加金额。
class CurrencyInfo {
  const CurrencyInfo(this.code, this.minorUnitDigits, this.symbol, this.nameZh);

  /// ISO 4217 风格代码，全大写；自定义币种允许 CNYX 之类扩展码。
  final String code;

  /// 最小单位小数位数（CNY=2, JPY=0, BTC=8）。
  final int minorUnitDigits;

  final String symbol;
  final String nameZh;

  BigInt get minorFactor => BigInt.from(10).pow(minorUnitDigits);

  static const cny = CurrencyInfo('CNY', 2, '¥', '人民币');
  static const usd = CurrencyInfo('USD', 2, r'$', '美元');
  static const hkd = CurrencyInfo('HKD', 2, r'HK$', '港币');
  static const eur = CurrencyInfo('EUR', 2, '€', '欧元');
  static const jpy = CurrencyInfo('JPY', 0, 'JP¥', '日元');
  static const gbp = CurrencyInfo('GBP', 2, '£', '英镑');
  static const btc = CurrencyInfo('BTC', 8, '₿', '比特币');
  static const usdt = CurrencyInfo('USDT', 2, 'USDT', '泰达币');
  static const xau = CurrencyInfo('XAU', 4, 'XAU', '黄金（克/盎司计价）');

  static const List<CurrencyInfo> builtin = [
    cny, usd, hkd, eur, jpy, gbp, btc, usdt, xau,
  ];

  static final Map<String, CurrencyInfo> _registry = {
    for (final c in builtin) c.code: c,
  };

  /// 注册自定义币种（例如券商理财份额币种）。重复注册同码覆盖定义。
  static void register(CurrencyInfo info) => _registry[info.code] = info;

  static CurrencyInfo? tryParse(String code) => _registry[code.toUpperCase()];

  static CurrencyInfo parse(String code) {
    final v = tryParse(code);
    if (v == null) {
      throw ArgumentError('未注册的币种代码: $code');
    }
    return v;
  }

  @override
  String toString() => code;
}
