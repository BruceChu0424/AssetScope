import 'dart:async';
import 'dart:convert';

import '../../data/repositories/meta_repo.dart';
import '../net/guarded_http.dart';
import 'ai_chat.dart';

/// AI 用量统计（本地计数，settings 表 key: aiUsage）。
///
/// 结构：{"total": 次数, "byDay": {"2026-10-30": 次数, …}}，
/// 按日保留最近 60 天。设置页的「用量与额度」面板展示；
/// 用户独占使用，无配额限制，仅作透明参考。
class AiUsage {
  const AiUsage({this.totalCalls = 0, this.byDay = const {}});

  final int totalCalls;
  final Map<String, int> byDay;

  static AiUsage fromJson(Map<String, Object?>? j) {
    if (j == null) return const AiUsage();
    final total = j['total'];
    final byDay = j['byDay'];
    return AiUsage(
      totalCalls: total is int ? total : 0,
      byDay: byDay is Map<String, Object?>
          ? {
              for (final e in byDay.entries)
                if (e.value is int) e.key: e.value as int,
            }
          : const {},
    );
  }

  Map<String, Object?> toJson() => {'total': totalCalls, 'byDay': byDay};

  static String dayKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  int get todayCalls => byDay[dayKey(DateTime.now())] ?? 0;

  /// 最近 7 天（含今日）调用次数。
  int get last7DaysCalls {
    final now = DateTime.now();
    var sum = 0;
    for (var i = 0; i < 7; i++) {
      sum += byDay[dayKey(now.subtract(Duration(days: i)))] ?? 0;
    }
    return sum;
  }

  /// 记一次调用，裁掉 60 天前的按日明细。
  AiUsage recorded(DateTime at) {
    final key = dayKey(at);
    final next = {...byDay, key: (byDay[key] ?? 0) + 1};
    final cutoff = at.subtract(const Duration(days: 60));
    next.removeWhere((k, _) {
      final d = DateTime.tryParse(k);
      return d == null || d.isBefore(cutoff);
    });
    return AiUsage(totalCalls: totalCalls + 1, byDay: next);
  }
}

/// 用量持久化（加密库 settings 表）。
class AiUsageStore {
  AiUsageStore(this._meta);

  final MetaRepo _meta;
  static const _key = 'aiUsage';

  Future<AiUsage> load() async {
    final raw = await _meta.settingString(_key);
    if (raw == null) return const AiUsage();
    try {
      return AiUsage.fromJson(jsonDecode(raw) as Map<String, Object?>?);
    } on FormatException {
      return const AiUsage();
    }
  }

  /// 记一次调用（fire-and-forget 友好：任何失败静默吞掉，不打断 AI 功能）。
  Future<void> record() async {
    try {
      final cur = await load();
      await _meta.setSetting(
        _key,
        jsonEncode(cur.recorded(DateTime.now()).toJson()),
      );
    } catch (_) {}
  }
}

/// 调用计数装饰器：所有 AI 请求（单轮/多轮）都经 [converse]，
/// 在此挂钩用量统计，业务服务零改动。
class CountingAiChat extends AiChat {
  CountingAiChat({required this.onCall});

  final FutureOr<void> Function() onCall;

  @override
  Future<String> converse(
    AiConfig cfg,
    String system,
    List<AiMessage> messages,
  ) {
    onCall();
    return super.converse(cfg, system, messages);
  }
}

/// 服务商余额查询结果（免费额度/代金券/现金余额，元）。
class AiBalanceResult {
  const AiBalanceResult({
    this.total,
    this.voucher,
    this.cash,
    this.fetchedAt,
  });

  /// 总可用额度（元）。null = 服务商未返回该字段。
  final double? total;
  final double? voucher;
  final double? cash;
  final DateTime? fetchedAt;
}

/// 服务商账户余额查询。
///
/// 目前仅智谱提供公开余额接口（GET {base}/users/me/balance，Bearer 鉴权）；
/// 其余服务商无公开接口，返回 null（设置面板只展示本地用量统计）。
class AiBalanceService {
  const AiBalanceService._();

  static Future<AiBalanceResult?> fetch(AiConfig cfg) async {
    if (cfg.preset?.id != 'glm' || cfg.apiKey.isEmpty) return null;
    final base = cfg.baseUrl.endsWith('/')
        ? cfg.baseUrl.substring(0, cfg.baseUrl.length - 1)
        : cfg.baseUrl;
    final bytes = await GuardedHttp.getBytes(
      '$base/users/me/balance',
      headers: {
        'Authorization': 'Bearer ${cfg.apiKey}',
        'Accept': 'application/json',
      },
    );
    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! Map<String, Object?>) {
      throw const FormatException('余额响应不是 JSON 对象');
    }
    return parseBalance(decoded, DateTime.now());
  }

  /// 智谱响应随版本变过字段名（data.balance.* / 顶层 balance.* /
  /// data.*）：在已知位置中搜索，找到即用；数值可能是字符串。
  static AiBalanceResult parseBalance(
    Map<String, Object?> resp, [
    DateTime? at,
  ]) {
    double? pick(Map<String, Object?> m, List<String> keys) {
      for (final k in keys) {
        final v = m[k];
        if (v is num) return v.toDouble();
        if (v is String) {
          final d = double.tryParse(v);
          if (d != null) return d;
        }
      }
      return null;
    }

    final data = resp['data'];
    final containers = <Map<String, Object?>>[];
    if (data is Map<String, Object?>) {
      final b = data['balance'];
      if (b is Map<String, Object?>) containers.add(b);
      containers.add(data);
    }
    final b = resp['balance'];
    if (b is Map<String, Object?>) containers.add(b);
    containers.add(resp);

    double? total, voucher, cash;
    for (final c in containers) {
      total ??= pick(c, const ['totalBalance', 'total', 'balance']);
      voucher ??= pick(c, const ['voucherBalance', 'voucher', 'freeBalance']);
      cash ??= pick(c, const ['cashBalance', 'cash']);
    }
    return AiBalanceResult(
      total: total,
      voucher: voucher,
      cash: cash,
      fetchedAt: at,
    );
  }
}
