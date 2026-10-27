import 'dart:convert';

import '../../data/repositories/accounts_repo.dart';
import '../../data/repositories/ledger_repo.dart';
import '../../data/repositories/meta_repo.dart';
import '../../domain/ledger/account.dart';
import '../../domain/money/fx_rate.dart';
import '../../domain/valuation/valuation.dart';
import 'ai_chat.dart';
import 'ai_quote.dart';

const _kSystemPrompt = '你是一个严谨的金融数据查询助手。'
    '你必须使用联网搜索获取真实、最新的行情数据，'
    '绝对不允许凭训练记忆编造数字。查不到的数据直接省略，不要输出猜测值。'
    '输出必须是且仅是一个 JSON 对象。';

/// 行情/汇率 AI 抓取服务（手动触发、预览确认、可审计来源）。
///
/// 流程：收集目标（在持仓名称 + 外币→本位币对）→ AI 联网搜索 →
/// 解析校验 → 用户在预览中逐条确认 → 写入估值/汇率表
/// （source 标记 `ai:<preset>/<model>`，note 保留来源网址）。
///
/// 隐私边界：只发送查询名称与币种对，绝不发送余额、金额、账户编号。
class QuoteFetchService {
  QuoteFetchService(this._accounts, this._ledger, this._meta, this._chat);

  final AccountsRepo _accounts;
  final LedgerRepo _ledger;
  final MetaRepo _meta;
  final AiChat _chat;

  static const _configKey = 'aiProvider';

  Future<AiConfig?> config() async {
    final raw = await _meta.settingString(_configKey);
    if (raw == null) return null;
    try {
      return AiConfig.fromJson(jsonDecode(raw) as Map<String, Object?>);
    } on FormatException {
      return null;
    }
  }

  Future<void> saveConfig(AiConfig cfg) =>
      _meta.setSetting(_configKey, jsonEncode(cfg.toJson()));

  /// 抓取目标：数量 > 0 的持仓账户 + 各外币账户币种 → 本位币。
  Future<(List<Account>, List<String>, String)> targets() async {
    final base = await _meta.settingString('baseCurrency') ?? 'CNY';
    final accounts = await _accounts.all();
    final qtys = await _ledger.quantityBalancesAt(DateTime.now());
    final holdings = accounts
        .where((a) =>
            a.isHolding &&
            !a.archived &&
            (qtys[a.id] ?? Rational.zero()) != Rational.zero())
        .toList();
    final currencies = accounts
        .where((a) => !a.archived && a.includeInNetWorth)
        .map((a) => a.currencyCode)
        .where((c) => c != base)
        .toSet()
        .toList()
      ..sort();
    return (holdings, currencies, base);
  }

  /// 执行抓取：AI 联网搜索 → 解析 → 映射回持仓账户（名称精确匹配）。
  /// 币种不一致、未匹配到账户的条目保留在结果中但不映射（预览时提示）。
  Future<QuoteFetchResult> fetch() async {
    final cfg = await config();
    if (cfg == null || cfg.apiKey.isEmpty || cfg.baseUrl.isEmpty) {
      throw StateError('尚未配置 AI 服务（设置 → AI 服务配置）');
    }
    final (holdings, currencies, base) = await targets();
    if (holdings.isEmpty && currencies.isEmpty) {
      return const QuoteFetchResult(
          prices: [], rates: [], warnings: ['没有需要抓取的持仓或外币汇率']);
    }
    final prompt = buildQuotePrompt(
      holdingNames: [for (final h in holdings) h.name],
      fxPairs: [for (final c in currencies) '$c/$base'],
      baseCcy: base,
    );
    final content = await _chat.complete(cfg, _kSystemPrompt, prompt);
    final parsed = AiQuoteParser.parse(content);

    final byName = {for (final h in holdings) h.name.trim(): h};
    final prices = <FetchedPrice>[];
    final warnings = [...parsed.warnings];
    for (final p in parsed.prices) {
      final acc = byName[p.query.trim()];
      if (acc == null) {
        warnings.add('「${p.query}」未匹配到在持仓账户，不会入账');
        prices.add(p);
        continue;
      }
      final mismatch = p.currency.trim().toUpperCase().isNotEmpty &&
          p.currency.trim().toUpperCase() != acc.currencyCode.toUpperCase();
      if (mismatch) {
        warnings.add('「${p.query}」AI 标注币种 ${p.currency} 与账户币种 '
            '${acc.currencyCode} 不一致，请核对');
      }
      prices.add(FetchedPrice(
        query: p.query,
        price: p.price,
        currency: p.currency,
        asOf: p.asOf,
        source: p.source,
        accountId: acc.id,
        accountName: acc.name,
        currencyMismatch: mismatch,
      ));
    }
    final rates = [
      for (final r in parsed.rates)
        FetchedRate(
            ccy: r.ccy, rate: r.rate, asOf: r.asOf, source: r.source)
    ];
    if (prices.isEmpty && rates.isEmpty && warnings.isEmpty) {
      warnings.add('AI 未返回任何可用数据');
    }
    return QuoteFetchResult(prices: prices, rates: rates, warnings: warnings);
  }

  /// 用户确认后写入：价格 → 估值记录（unitPrice）；汇率 → ccy→本位币。
  /// 返回写入条数。
  Future<int> apply({
    required Iterable<FetchedPrice> prices,
    required Iterable<FetchedRate> rates,
  }) async {
    final cfg = await config();
    final source = 'ai:${cfg?.presetId ?? "custom"}/${cfg?.model ?? "?"}';
    final base = await _meta.settingString('baseCurrency') ?? 'CNY';
    final today = DateTime.now();
    var count = 0;
    for (final p in prices) {
      if (p.accountId == null) continue;
      await _meta.saveValuation(ValuationRecord(
        accountId: p.accountId!,
        date: p.asOf ?? today,
        kind: ValuationKind.unitPrice,
        unitPrice: p.price,
        source: source,
        note: p.source,
      ));
      count++;
    }
    for (final r in rates) {
      await _meta.saveFxRate(
        baseCcy: r.ccy,
        quoteCcy: base,
        date: r.asOf ?? today,
        rate: r.rate,
        source: source,
      );
      count++;
    }
    return count;
  }
}
