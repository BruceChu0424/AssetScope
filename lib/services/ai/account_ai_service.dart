import 'dart:convert';

import '../../data/repositories/meta_repo.dart';
import '../../domain/ledger/account.dart';
import 'ai_chat.dart';
import 'ai_json.dart';

const _kSystemPrompt =
    '你是一个严谨的个人财务助理。'
    '用户给你一个资产或负债的名称，你判断它的分类与所在地。'
    '只基于名称本身判断，不编造。输出必须是且仅是一个 JSON 对象。';

/// AI 对新建资产的识别建议。
///
/// 隐私边界：只发送资产名称文本，绝不含金额/余额；
/// 金额（价值）永远由用户手动填写，AI 不估、不填。
class AiAccountSuggestion {
  const AiAccountSuggestion({
    required this.type,
    this.assetSubtype,
    this.liabilitySubtype,
    this.currency,
    this.institution,
    this.city,
    this.lat,
    this.lon,
  });

  final AccountType type;
  final AssetSubtype? assetSubtype;
  final LiabilitySubtype? liabilitySubtype;

  /// 三字母币种码（大写）；AI 给出未知码时为 null，由调用方保留现值。
  final String? currency;
  final String? institution;
  final String? city;
  final double? lat;
  final double? lon;
}

/// 新建资产 AI 识别：名称 → 类型/子类型/币种/机构/城市坐标。
///
/// 与行情抓取（QuoteFetchService）共用同一个 AI 绑定
/// （加密库 settings 表 key: aiProvider）。
class AccountAiService {
  AccountAiService(this._meta, this._chat);

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

  Future<AiAccountSuggestion> recognize(AiConfig cfg, String name) async {
    final content = await _chat.complete(
      cfg,
      _kSystemPrompt,
      buildPrompt(name),
    );
    return parse(content);
  }

  /// 地址 → 精确地理编码（小区/楼栋级坐标，供 3D 地球定位）。
  ///
  /// 内置城市表只有城市级坐标；这里由 AI 联网检索具体 POI，
  /// 输出 WGS84 坐标 + 规范化地址。判不出具体位置时可退回城市级
  /// （[AiGeocode.precision] = city）；完全判不出抛 FormatException。
  Future<AiGeocode> geocode(AiConfig cfg, String address) async {
    final content = await _chat.complete(
      cfg,
      '你是一个严谨的地理编码助手。用户给你一个中文地址（可能精确到'
      '小区、楼栋）。你可以联网搜索确定该地址的真实位置。'
      '只基于真实地理信息回答，不编造。输出必须是且仅是一个 JSON 对象。',
      buildGeocodePrompt(address),
    );
    return parseGeocode(content);
  }

  static String buildPrompt(String name) {
    final assets = [
      for (final s in AssetSubtype.values) '${s.name}=${s.labelZh}',
    ].join('、');
    final liabilities = [
      for (final s in LiabilitySubtype.values) '${s.name}=${s.labelZh}',
    ].join('、');
    final sb = StringBuffer()
      ..writeln('资产或负债名称：$name')
      ..writeln()
      ..writeln('可选资产子类型：$assets')
      ..writeln('可选负债子类型：$liabilities')
      ..writeln()
      ..writeln('请判断它最可能属于哪一类，并输出严格 JSON（不要 markdown 围栏、不要解释）：')
      ..writeln('{"type":"asset 或 liability","subtype":"子类型枚举名",')
      ..writeln(' "currency":"三字母币种码","institution":"机构名，判断不出为 null",')
      ..writeln(' "city":"所在城市中文名，判断不出为 null","lat":纬度,"lon":经度}')
      ..writeln('city 为该资产/负债的地理所在城市；lat/lon 为该城市的 WGS84 近似')
      ..writeln('十进制坐标（判断不出城市则为 null）。');
    return sb.toString();
  }

  /// 解析 AI 应答；无 JSON 或不是对象时抛 FormatException。
  static AiAccountSuggestion parse(String content) {
    final decoded = decodeAiJsonObject(content);

    final (assetSub, liaSub) = _parseSubtype(decoded['subtype']);
    var type = decoded['type'] == 'liability'
        ? AccountType.liability
        : AccountType.asset;
    if (decoded['type'] is! String && liaSub != null) {
      type = AccountType.liability;
    }

    return AiAccountSuggestion(
      type: type,
      assetSubtype: type == AccountType.asset ? assetSub : null,
      liabilitySubtype: type == AccountType.liability ? liaSub : null,
      currency: _parseCurrency(decoded['currency']),
      institution: _parseStr(decoded['institution']),
      city: _parseStr(decoded['city']),
      lat: _parseCoord(decoded['lat'], -90, 90),
      lon: _parseCoord(decoded['lon'], -180, 180),
    );
  }

  /// 子类型：优先枚举名，其次中文标签；两者都认不出返回 (null, null)。
  static (AssetSubtype?, LiabilitySubtype?) _parseSubtype(Object? raw) {
    if (raw is! String || raw.trim().isEmpty) return (null, null);
    final t = raw.trim();
    for (final s in AssetSubtype.values) {
      if (s.name == t || s.labelZh == t) return (s, null);
    }
    for (final s in LiabilitySubtype.values) {
      if (s.name == t || s.labelZh == t) return (null, s);
    }
    return (null, null);
  }

  static String? _parseCurrency(Object? raw) {
    if (raw is! String) return null;
    final c = raw.trim().toUpperCase();
    return c.length == 3 || c.length == 4 ? c : null;
  }

  static String? _parseStr(Object? raw) {
    if (raw is! String) return null;
    final s = raw.trim();
    return s.isEmpty || s == 'null' ? null : s;
  }

  static double? _parseCoord(Object? raw, double min, double max) {
    if (raw is! num) return null;
    final v = raw.toDouble();
    return v >= min && v <= max ? v : null;
  }
}

/// AI 地理编码结果。
class AiGeocode {
  const AiGeocode({
    required this.formatted,
    required this.lat,
    required this.lon,
    this.city,
    this.precision = 'poi',
  });

  /// 规范化地址（AI 判定的完整地址文本）。
  final String formatted;

  /// WGS84 十进制坐标（3D 地球为全球球面，无需 GCJ-02 纠偏）。
  final double lat;
  final double lon;

  /// 城市名（可能为 null）。
  final String? city;

  /// poi = 具体 POI（小区/楼栋）；city = 仅城市级近似。
  final String precision;
}

String buildGeocodePrompt(String address) {
  final sb = StringBuffer()
    ..writeln('地址：$address')
    ..writeln()
    ..writeln('请确定这个地址的位置，输出严格 JSON（不要 markdown 围栏、不要解释）：')
    ..writeln('{"formatted":"规范化完整地址","city":"城市中文名",')
    ..writeln(' "lat":纬度,"lon":经度,"precision":"poi 或 city"}')
    ..writeln('lat/lon 为 WGS84 十进制坐标；能定位到小区/楼栋等具体 POI 时')
    ..writeln('precision 为 "poi"，只能确定到城市时为 "city"（坐标取城市中心）。')
    ..writeln('完全无法识别该地址时输出 {"error":"无法识别"}。');
  return sb.toString();
}

/// 解析地理编码应答；坐标缺失/越界/标记 error 时抛 FormatException。
AiGeocode parseGeocode(String content) {
  final decoded = decodeAiJsonObject(content);
  if (decoded['error'] is String) {
    throw FormatException('AI 无法识别该地址：${decoded['error']}');
  }
  final lat = _coordOf(decoded['lat'], -90, 90);
  final lon = _coordOf(decoded['lon'], -180, 180);
  if (lat == null || lon == null) {
    throw const FormatException('AI 应答缺少有效坐标');
  }
  final formatted = decoded['formatted'];
  final city = decoded['city'];
  final precision = decoded['precision'];
  return AiGeocode(
    formatted: formatted is String && formatted.trim().isNotEmpty
        ? formatted.trim()
        : addressOf(content),
    lat: lat,
    lon: lon,
    city: city is String && city.trim().isNotEmpty ? city.trim() : null,
    precision: precision == 'city' ? 'city' : 'poi',
  );
}

double? _coordOf(Object? raw, double min, double max) {
  if (raw is num) {
    final v = raw.toDouble();
    return v >= min && v <= max ? v : null;
  }
  if (raw is String) {
    final v = double.tryParse(raw.trim());
    return v != null && v >= min && v <= max ? v : null;
  }
  return null;
}

/// 兜底：formatted 缺失时从应答文本里取「地址：」后的文字。
String addressOf(String content) {
  final m = RegExp('地址[：:]\\s*(.+)').firstMatch(content);
  return m == null ? '' : m.group(1)!.trim();
}
