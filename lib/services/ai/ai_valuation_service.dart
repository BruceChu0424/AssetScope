import 'dart:convert';

import '../../data/repositories/accounts_repo.dart';
import '../../data/repositories/meta_repo.dart';
import '../../domain/ledger/account.dart';
import '../../domain/money/currency.dart';
import '../../domain/money/fx_rate.dart';
import '../../domain/valuation/valuation.dart';
import '../../l10n/runtime_l10n.dart';
import 'ai_chat.dart';
import 'ai_json.dart';

/// AI 资产估值：房产/车辆等 manualValue 类资产的联网市价检索。
///
/// 用户在账户上启用后（accounts.aiValuationEnabled），每天首次解锁
/// 自动逐项联网检索真实市价并写入估值记录（source 标记
/// `ai:<preset>/<model>`，note 保留依据与来源网址，可审计）。用户同日
/// 手动改过估值的资产自动跳过——人工纠正永远优先于 AI。
///
/// 隐私边界：只发送资产描述线索（名称/地址/年款型号），绝不发送
/// 购置成本与金额。
class AiAssetEstimate {
  const AiAssetEstimate({
    required this.query,
    required this.valueMinor,
    required this.currency,
    this.low,
    this.high,
    this.asOf,
    this.confidence,
    this.sources = const [],
    this.rationale,
  });

  final String query;

  /// 估值中值（账户币种最小单位）。
  final BigInt valueMinor;
  final String currency;

  /// 区间上下限（主单位有理数；AI 未给出为 null）。
  final Rational? low;
  final Rational? high;
  final DateTime? asOf;

  /// 置信度 0-100（AI 自评，仅展示参考）。
  final int? confidence;
  final List<String> sources;
  final String? rationale;
}

/// 一轮刷新的结果汇总（首页通知与日志用）。
class AiValuationRun {
  const AiValuationRun({
    this.updated = 0,
    this.skippedManual = 0,
    this.failures = const [],
    this.ran = false,
  });

  /// 成功写入估值条数。
  final int updated;

  /// 因当日已有手动估值而跳过的资产数。
  final int skippedManual;

  /// 失败明细（资产名：原因）。
  final List<String> failures;

  /// 是否真正执行（每日门控未到期时 false）。
  final bool ran;

  bool get quiet => !ran || (updated == 0 && failures.isEmpty);
}

class AiValuationService {
  AiValuationService(this._accounts, this._meta, this._chat);

  final AccountsRepo _accounts;
  final MetaRepo _meta;
  final AiChat _chat;

  static const _configKey = 'aiProvider';
  static const _lastRunKey = 'aiValuation.lastRunDay';

  Future<AiConfig?> config() async {
    final raw = await _meta.settingString(_configKey);
    if (raw == null) return null;
    try {
      return AiConfig.fromJson(jsonDecode(raw) as Map<String, Object?>);
    } on FormatException {
      return null;
    }
  }

  /// 参与自动估值的资产：启用 AI 估值、未归档、manualValue 口径。
  Future<List<Account>> targets() async {
    final accounts = await _accounts.all();
    return accounts
        .where(
          (a) =>
              a.aiValuationEnabled &&
              !a.archived &&
              a.type == AccountType.asset &&
              a.valuationMethod == ValuationMethod.manualValue,
        )
        .toList();
  }

  /// 每日自动刷新（每天首次调用真正执行，之后直接返回）。
  Future<AiValuationRun> refreshDue() async {
    final today = _dayKey(DateTime.now());
    final last = await _meta.settingString(_lastRunKey);
    if (last == today) return const AiValuationRun(ran: false);
    // 先占位再执行：一天只联网一轮（即使部分失败也不反复重试，
    // 失败明细在结果里，详情页可手动重估单个资产）。
    await _meta.setSetting(_lastRunKey, today);
    final cfg = await config();
    if (cfg == null || cfg.apiKey.isEmpty || cfg.baseUrl.isEmpty) {
      return const AiValuationRun();
    }
    return refresh();
  }

  /// 全量刷新（详情页「立即估值」入口；逐资产串行，限流友好）。
  /// 当日已被用户手动纠正过的资产自动跳过。
  Future<AiValuationRun> refresh() async {
    final cfg = await config();
    if (cfg == null || cfg.apiKey.isEmpty || cfg.baseUrl.isEmpty) {
      throw StateError(rt('尚未配置 AI 服务（设置 → AI 服务配置）'));
    }
    final targets = await this.targets();
    if (targets.isEmpty) return const AiValuationRun();

    var updated = 0;
    var skipped = 0;
    final failures = <String>[];
    final today = DateTime.now();
    for (final a in targets) {
      try {
        if (await _hasManualToday(a.id, today)) {
          skipped++;
          continue;
        }
        final e = await estimateOne(cfg, a);
        await applyEstimate(a, e, cfg);
        updated++;
      } catch (err) {
        failures.add('${a.name}${rt('：')}$err');
      }
    }
    return AiValuationRun(
      updated: updated,
      skippedManual: skipped,
      failures: failures,
      ran: true,
    );
  }

  /// 单资产估值检索（不落库；UI 预览与批量共用）。
  Future<AiAssetEstimate> estimateOne(AiConfig cfg, Account a) async {
    final content = await _chat.complete(
      cfg,
      _kSystemPrompt,
      buildValuationPrompt(a),
    );
    return parseEstimate(content, queryOf(a));
  }

  /// 估值写入估值表（kind=totalValue；note 带依据与来源，可审计）。
  Future<void> applyEstimate(
    Account a,
    AiAssetEstimate e,
    AiConfig cfg,
  ) async {
    await _meta.saveValuation(
      ValuationRecord(
        accountId: a.id,
        date: e.asOf ?? DateTime.now(),
        kind: ValuationKind.totalValue,
        totalValueMinor: e.valueMinor,
        source: 'ai:${cfg.presetId}/${cfg.model}',
        note: estimateNote(e),
      ),
    );
  }

  /// 当日是否已有非 AI 来源的估值（用户手动纠正优先，AI 不覆盖）。
  Future<bool> _hasManualToday(String accountId, DateTime today) async {
    final records = await _meta.valuations(accountId: accountId);
    for (final r in records) {
      if (r.kind != ValuationKind.totalValue) continue;
      if (_dayKey(r.date) != _dayKey(today)) continue;
      if (!r.source.startsWith('ai:')) return true;
    }
    return false;
  }

  static String _dayKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

const _kSystemPrompt =
    '你是一个严谨的资产估值助手，专门评估个人房产与车辆等资产的当前真实市价。'
    '你必须使用联网搜索获取真实、最新的市场数据，绝对不允许凭训练记忆编造数字。'
    '优先采信权威平台（房产：贝壳/链家等挂牌与成交记录、政府住建部门成交数据；'
    '车辆：汽车之家/懂车帝等估值工具与二手车行情），主动剔除营销号、软文与'
    '明显偏离市场的报价；多来源交叉验证后给出区间与中值。'
    '查不到可靠数据时如实报告 found=false，不要输出猜测值。'
    '输出必须是且仅是一个 JSON 对象。';

/// 估值提示词（线索=用户填写的检索词，含小区/栋/室或年款型号）。
String buildValuationPrompt(Account a) {
  final query = queryOf(a);
  final sb = StringBuffer()
    ..writeln('资产类型：${a.assetSubtype?.labelZh ?? a.name}')
    ..writeln('描述线索：$query')
    ..writeln('计价币种：${a.currencyCode}');
  switch (a.assetSubtype) {
    case AssetSubtype.realEstate:
      sb
        ..writeln('要求：联网搜索该房产（小区）最近的成交价与当前挂牌价，')
        ..writeln('结合城市/地段/楼龄综合判断其当前市场价值（整套房产总价值）。')
        ..writeln('参考依据写入 rationale（如「该小区近 3 月成交均价约 X 万/㎡，'
            '在售挂牌 Y 套」），来源网址写入 sources。');
    case AssetSubtype.vehicle:
      sb
        ..writeln('要求：联网检索该年款型号车辆的当前二手市场行情，')
        ..writeln('按年份折旧与里程常规假设给出当前估值。')
        ..writeln('参考依据写入 rationale，来源网址写入 sources。');
    default:
      sb
        ..writeln('要求：联网检索该资产的当前合理市场价值。')
        ..writeln('参考依据写入 rationale，来源网址写入 sources。');
  }
  sb
    ..writeln()
    ..writeln('只输出严格 JSON（不要 markdown 围栏、不要解释），格式：')
    ..writeln('{"found":true,"value":"1234567.89","currency":"${a.currencyCode}",')
    ..writeln(' "low":"1100000","high":"1300000","as_of":"2026-10-30",')
    ..writeln(' "confidence":75,"sources":["https://..."],')
    ..writeln(' "rationale":"一句话依据"}')
    ..writeln('value/low/high 为十进制数字字符串（主单位，不带货币符号与千分位）。')
    ..writeln('查不到可靠数据输出 {"found":false,"reason":"原因"}。');
  return sb.toString();
}

String queryOf(Account a) => a.effectiveAiValuationQuery;

/// 估值记录的审计备注（用户在估值历史里可查依据与来源）。
String estimateNote(AiAssetEstimate e) {
  final low = e.low;
  final high = e.high;
  final sb = StringBuffer(rt('AI 估值'));
  if (e.confidence != null) {
    sb.write('${rt('（置信度 ')}${e.confidence}${rt('%）')}');
  }
  if (low != null && high != null) {
    sb.write('${rt('：区间 ')}${fmtRational(low)} ~ ${fmtRational(high)}');
  }
  if (e.rationale != null && e.rationale!.trim().isNotEmpty) {
    sb.write('${rt('；')}${e.rationale!.trim()}');
  }
  for (final s in e.sources.take(2)) {
    sb.write('${rt('；来源 ')}$s');
  }
  return sb.toString();
}

String fmtRational(Rational r) {
  final cents = (r * Rational.fromInt(BigInt.from(100))).rounded();
  final neg = cents.isNegative ? '-' : '';
  final abs = cents.abs().toString().padLeft(3, '0');
  return '$neg${abs.substring(0, abs.length - 2)}.${abs.substring(abs.length - 2)}';
}

/// 解析估值应答；found=false / 数值无效时抛 FormatException。
AiAssetEstimate parseEstimate(String content, String query) {
  final decoded = decodeAiJsonObject(content);
  if (decoded['found'] == false) {
    final reason = decoded['reason'];
    throw FormatException(
      reason is String && reason.trim().isNotEmpty
          ? '${rt('AI 未查到可靠市价：')}${reason.trim()}'
          : rt('AI 未查到可靠市价'),
    );
  }
  final value = _parsePositiveDecimal(decoded['value']);
  if (value == null) {
    throw FormatException(rt('AI 估值数值无效'));
  }
  final currency = decoded['currency'];
  final low = _parsePositiveDecimal(decoded['low']);
  final high = _parsePositiveDecimal(decoded['high']);
  final sourcesRaw = decoded['sources'];
  final confidence = decoded['confidence'];
  return AiAssetEstimate(
    query: query,
    valueMinor: moneyMinor(value, currency is String ? currency : 'CNY'),
    currency: currency is String ? currency.toUpperCase() : 'CNY',
    low: low,
    high: high,
    asOf: _parseDate(decoded['as_of'] ?? decoded['asOf']),
    confidence: confidence is num ? confidence.round().clamp(0, 100) : null,
    sources: [
      if (sourcesRaw is List)
        for (final s in sourcesRaw)
          if (s is String && s.trim().isNotEmpty) s.trim(),
    ],
    rationale: decoded['rationale'] is String
        ? decoded['rationale'] as String
        : null,
  );
}

/// 有理数金额（主单位）→ 最小单位整数（halfEven 经 Rational 整体舍入）。
BigInt moneyMinor(Rational amount, String currencyCode) {
  final info = CurrencyInfo.tryParse(currencyCode) ?? CurrencyInfo.cny;
  return (amount * Rational.fromInt(info.minorFactor)).rounded();
}

Rational? _parsePositiveDecimal(Object? raw) {
  if (raw is! String) return null;
  final s = raw.trim().replaceAll(',', '');
  if (s.isEmpty) return null;
  final Rational v;
  try {
    v = Rational.parseDecimal(s);
  } on FormatException {
    return null;
  }
  return v > Rational.zero() && !v.isNegative ? v : null;
}

DateTime? _parseDate(Object? raw) {
  if (raw is! String) return null;
  final m = RegExp(
    r'^(\d{4})[-/年.](\d{1,2})[-/月.](\d{1,2})',
  ).firstMatch(raw.trim());
  if (m == null) return null;
  return DateTime(
    int.parse(m.group(1)!),
    int.parse(m.group(2)!),
    int.parse(m.group(3)!),
  );
}
