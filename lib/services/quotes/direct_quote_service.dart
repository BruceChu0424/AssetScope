import 'dart:convert';

import '../../data/repositories/accounts_repo.dart';
import '../../domain/ledger/account.dart';
import '../../domain/money/fx_rate.dart';
import '../../l10n/runtime_l10n.dart';
import '../ai/ai_quote.dart';
import '../ai/quote_fetch_service.dart';
import '../net/guarded_http.dart';
import 'frankfurter_source.dart';
import 'stooq_source.dart';
import 'symbols.dart';
import 'tencent_source.dart';

/// 出网取原始字节（可注入假实现供测试）。
typedef QuoteHttp = Future<List<int>> Function(Uri uri);

/// 直连行情源服务（v0.6）：不经过 AI，直接向官方行情端点查询。
///
/// 路由（docs/06 §7）：A股/场内基金 → 腾讯行情（GBK，免费无 key）；
/// 港股/美股/国际 → stooq（CSV）；汇率 → frankfurter（欧央行参考汇率，
/// EUR 交叉精确换算）。与 AI 抓取共用预览确认 UI 与写入通道
/// （source 标记 `direct`，note 保留端点 URL，可审计）。
///
/// 隐私边界与 AI 一致：只发送证券代码与币种对，绝不发送金额与余额。
class DirectQuoteService {
  DirectQuoteService(this._accounts, this._quoteFetch);

  final AccountsRepo _accounts;
  final QuoteFetchService _quoteFetch;

  static const sourceLabel = 'direct';

  Future<QuoteFetchResult> fetch({QuoteHttp? http}) async {
    QuoteHttp get = http ?? (uri) => GuardedHttp.getBytes(uri.toString());
    final (holdings, currencies, base) = await _quoteFetch.targets();
    final codes = await _accounts.securityCodes();

    final prices = <FetchedPrice>[];
    final warnings = <String>[];

    // --- 代码解析与分组 ---
    // 代码优先取 securities.code（用户可改）；
    // 老账户（v0.5 前创建）accounts.securityId 列可能为空，
    // 按 id 约定 acc:hold:<code> 回溯到 sec:<code>。
    final cnGroup = <(Account, ResolvedSymbol)>[];
    final intlGroup = <(Account, ResolvedSymbol)>[];
    for (final h in holdings) {
      final raw = _codeOf(h, codes);
      final r = SymbolResolver.resolve(raw);
      if (!r.resolvable) {
        warnings.add(
          '${rt('「')}${h.name}${rt('」行情代码「')}$raw'
          '${rt('」无法识别（A股 6 位数字 / hk00700 / usAAPL / aapl.us），可在账户详情修改，已跳过')}',
        );
        continue;
      }
      if (r.market == QuoteMarket.cn) {
        cnGroup.add((h, r));
      } else {
        intlGroup.add((h, r));
      }
    }

    // --- 腾讯行情（A股）---
    if (cnGroup.isNotEmpty) {
      final syms = [for (final e in cnGroup) e.$2.tencentSymbol!];
      final bySym = {for (final e in cnGroup) e.$2.tencentSymbol!: e.$1};
      try {
        final bytes = await get(TencentSource.buildUrl(syms));
        final (quotes, failed) = TencentSource.parse(bytes, syms);
        for (final q in quotes) {
          final acc = bySym[q.symbol];
          if (acc == null) continue;
          prices.add(
            _price(
              acc,
              q.name,
              q.price,
              'CNY',
              q.asOf,
              'https://qt.gtimg.cn/?q=${q.symbol}',
            ),
          );
        }
        for (final f in failed) {
          warnings.add(
            '${rt('腾讯行情未返回「')}$f${rt('」的有效价格（停牌或代码错误），已跳过')}',
          );
        }
      } catch (e) {
        warnings.add(
          '${rt('腾讯行情请求失败：')}$e${rt('（可稍后重试或改用 AI 抓取）')}',
        );
      }
    }

    // --- stooq（港股/美股/国际）---
    if (intlGroup.isNotEmpty) {
      final syms = [for (final e in intlGroup) e.$2.stooqSymbol!];
      final bySym = {for (final e in intlGroup) e.$2.stooqSymbol!: e};
      try {
        final bytes = await get(StooqSource.buildUrl(syms));
        final (quotes, failed) = StooqSource.parse(utf8.decode(bytes), syms);
        for (final q in quotes) {
          final (acc, r) = bySym[q.symbol]!;
          prices.add(
            _price(
              acc,
              r.raw,
              q.price,
              r.currencyCode ?? '',
              q.asOf,
              'https://stooq.com/?s=${q.symbol}',
            ),
          );
        }
        for (final f in failed) {
          warnings.add(
            '${rt('stooq 未返回「')}$f${rt('」的有效价格（检查代码如 0700.hk / aapl.us），已跳过')}',
          );
        }
      } catch (e) {
        warnings.add(
          '${rt('stooq 请求失败：')}$e${rt('（可稍后重试或改用 AI 抓取）')}',
        );
      }
    }

    // --- frankfurter（汇率）---
    final rates = <FetchedRate>[];
    if (currencies.isNotEmpty) {
      try {
        final bytes = await get(FrankfurterFx.buildUrl({...currencies, base}));
        final (map, date, missing) = FrankfurterFx.parse(
          utf8.decode(bytes),
          currencies,
          base,
        );
        map.forEach((ccy, rate) {
          rates.add(
            FetchedRate(
              ccy: ccy,
              rate: rate,
              asOf: date,
              source: 'https://api.frankfurter.dev/',
            ),
          );
        });
        for (final c in missing) {
          warnings.add(
            '${rt('frankfurter 不支持币种 ')}$c${rt('（欧央行列表外），请手工录入或用 AI 抓取')}',
          );
        }
      } catch (e) {
        warnings.add(
          '${rt('frankfurter 汇率请求失败：')}$e${rt('（可手工录入或用 AI 抓取）')}',
        );
      }
    }

    if (prices.isEmpty && rates.isEmpty && warnings.isEmpty) {
      warnings.add(rt('没有可直连查询的目标（缺代码的持仓见上方提示）'));
    }
    return QuoteFetchResult(prices: prices, rates: rates, warnings: warnings);
  }

  /// 持仓账户的行情代码：securities.code（securityId 直查；
  /// 老账户 securityId 为空时按 acc:hold:<code> id 约定回溯）。
  String _codeOf(Account h, Map<String, String> codes) {
    final sid = h.securityId;
    if (sid != null && codes[sid]?.isNotEmpty == true) return codes[sid]!;
    if (sid != null && sid.startsWith('sec:')) return sid.substring(4);
    if (h.id.startsWith('acc:hold:')) {
      final code = h.id.substring('acc:hold:'.length);
      return codes['sec:$code'] ?? code;
    }
    return '';
  }

  FetchedPrice _price(
    Account acc,
    String name,
    Rational price,
    String currency,
    DateTime? asOf,
    String url,
  ) {
    final mismatch =
        currency.isNotEmpty &&
        currency.toUpperCase() != acc.currencyCode.toUpperCase();
    return FetchedPrice(
      query: name,
      price: price,
      currency: currency,
      asOf: asOf,
      source: url,
      accountId: acc.id,
      accountName: acc.name,
      currencyMismatch: mismatch,
    );
  }
}
