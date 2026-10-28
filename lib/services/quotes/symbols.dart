/// 证券代码 → 行情源解析（纯函数）。
///
/// 账户的行情代码存在 `securities.code`（账户详情可改）。
/// 支持的写法与归类：
/// - A股/场内基金：6 位数字（按首位推断交易所），或显式 sh/sz/bj 前缀 → 腾讯行情
/// - 港股：1–5 位数字、`hk` 前缀或 `XXXXX.hk` → stooq
/// - 美股/其他：字母代码、`us` 前缀、`sym.us` 或任意含点代码 → stooq
enum QuoteMarket { cn, hk, intl, unknown }

class ResolvedSymbol {
  const ResolvedSymbol({
    required this.raw,
    required this.market,
    this.tencentSymbol,
    this.stooqSymbol,
    this.currencyCode,
  });

  final String raw;
  final QuoteMarket market;

  /// 腾讯行情代码（仅 A股：sh600519 形式）。
  final String? tencentSymbol;

  /// stooq 代码（hk/intl：0700.hk / aapl.us 形式）。
  final String? stooqSymbol;

  /// 按市场推断的计价币种（用于与账户币种核对）。
  final String? currencyCode;

  bool get resolvable => market != QuoteMarket.unknown;
}

class SymbolResolver {
  const SymbolResolver._();

  static ResolvedSymbol resolve(String rawInput) {
    final raw = rawInput.trim();
    if (raw.isEmpty) {
      return ResolvedSymbol(raw: rawInput, market: QuoteMarket.unknown);
    }
    final lower = raw.toLowerCase();

    // 显式交易所前缀（A股）。
    final cnPrefix = RegExp(r'^(sh|sz|bj)(\d{6})$').firstMatch(lower);
    if (cnPrefix != null) {
      return ResolvedSymbol(
          raw: raw,
          market: QuoteMarket.cn,
          tencentSymbol: lower,
          currencyCode: 'CNY');
    }

    // 6 位纯数字：按首位推断交易所。
    if (RegExp(r'^\d{6}$').hasMatch(raw)) {
      final head = raw[0];
      final prefix = switch (head) {
        '0' || '1' || '3' => 'sz', // 股票/基金/转债（深市）
        '5' || '6' => 'sh', // ETF/股票（沪市）
        _ => 'bj', // 4/8/9：北交所
      };
      return ResolvedSymbol(
          raw: raw,
          market: QuoteMarket.cn,
          tencentSymbol: '$prefix$raw',
          currencyCode: 'CNY');
    }

    // 显式 hk 前缀或 1–5 位纯数字（港股）。
    final hkPrefix = RegExp(r'^hk\.?(\d{1,5})$').firstMatch(lower);
    if (hkPrefix != null) {
      return _hk(hkPrefix.group(1)!, raw);
    }
    if (RegExp(r'^\d{1,5}$').hasMatch(raw)) return _hk(raw, raw);

    // 显式 us 前缀。
    final usPrefix = RegExp(r'^us\.?([a-z0-9.]+)$').firstMatch(lower);
    if (usPrefix != null) {
      return _intl(usPrefix.group(1)!, raw);
    }

    // 含点：stooq 原样（0700.hk / aapl.us / brk-b.us…）。
    if (raw.contains('.')) {
      final cur = lower.endsWith('.hk') ? 'HKD' : null;
      return ResolvedSymbol(
          raw: raw,
          market: QuoteMarket.intl,
          stooqSymbol: lower,
          currencyCode: cur);
    }

    // 字母数字组合：按美股处理。
    if (RegExp(r'^[A-Za-z][A-Za-z0-9-]*$').hasMatch(raw)) {
      return _intl(lower, raw);
    }

    return ResolvedSymbol(raw: raw, market: QuoteMarket.unknown);
  }

  static ResolvedSymbol _hk(String digits, String raw) {
    // 港交所官方 4 位数字（0700/9988/0001）；去前导零后补足 4 位。
    final natural = digits.replaceFirst(RegExp(r'^0+'), '');
    final code = (natural.isEmpty ? '0' : natural).padLeft(4, '0');
    return ResolvedSymbol(
        raw: raw,
        market: QuoteMarket.hk,
        stooqSymbol: '$code.hk',
        currencyCode: 'HKD');
  }

  static ResolvedSymbol _intl(String code, String raw) => ResolvedSymbol(
      raw: raw,
      market: QuoteMarket.intl,
      stooqSymbol: code.endsWith('.us') ? code : '$code.us',
      currencyCode: 'USD');
}
