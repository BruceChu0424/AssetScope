import 'dart:convert';

import '../../data/repositories/meta_repo.dart';
import '../../l10n/runtime_l10n.dart';
import '../stats_service.dart';
import 'ai_chat.dart';

/// AI 财务助手：多轮对话 + 可选账本概况注入。
///
/// 账本是用户本人的，助手按用户授权工作（用户在设置里绑定自己的
/// AI Key，数据只发往该服务商）。「账本概况」开关打开时，会在
/// system 提示里注入净资产/本月收支等汇总数字（只取整数元，不含
/// 交易明细），让回答贴合真实财务状况；关闭则纯通用对话。
class AssistantService {
  AssistantService(this._stats, this._meta, this._chat);

  final StatsService _stats;
  final MetaRepo _meta;
  final AiChat _chat;

  static const _configKey = 'aiProvider';

  static const _systemPrompt =
      '你是「资观」个人财务应用里的 AI 助手，帮用户分析财务、答疑、出主意。'
      '回答务实、具体、面向行动，不堆砌免责声明；涉及数据时标注口径与时间。'
      '你可以使用联网搜索查证市场信息；不确定就说不确定，不编造数字。'
      '用户使用简体中文。';

  Future<AiConfig?> config() async {
    final raw = await _meta.settingString(_configKey);
    if (raw == null) return null;
    try {
      return AiConfig.fromJson(jsonDecode(raw) as Map<String, Object?>);
    } on FormatException {
      return null;
    }
  }

  /// 对话：[history] 按时间序、最后一条为用户最新消息。
  /// [withLedger] 为真时注入账本概况（汇总数字，无交易明细）。
  Future<String> reply({
    required List<AiMessage> history,
    bool withLedger = true,
  }) async {
    final cfg = await config();
    if (cfg == null || cfg.apiKey.isEmpty || cfg.baseUrl.isEmpty) {
      throw StateError(rt('尚未配置 AI 服务（设置 → AI 服务配置）'));
    }
    var system = _systemPrompt;
    if (withLedger) {
      try {
        final summary = await ledgerSummary();
        if (summary.isNotEmpty) {
          system += '\n\n— 用户账本概况（数据来自本地账本，截至最近）—\n$summary';
        }
      } catch (_) {
        // 概况失败不影响对话，只是少了上下文。
      }
    }
    return _chat.converse(cfg, system, history);
  }

  /// 账本概况（system 注入用）：净资产、资产/负债、本月与上月收支、
  /// Top 支出分类。只输出汇总整数，绝不包含逐笔明细。
  Future<String> ledgerSummary() async {
    final base = await _stats.baseCurrency();
    final now = DateTime.now();
    final sb = StringBuffer();
    try {
      final nw = await _stats.netWorthAt(now);
      sb
        ..writeln('净资产（$base）：${_fmt(nw.netWorth)}')
        ..writeln('总资产：${_fmt(nw.totalAssets)}；总负债：${_fmt(nw.totalLiabilities)}');
    } catch (_) {}
    try {
      final cur = await _stats.monthReport(now.year, now.month);
      final income = cur.incomeByCategory.values.fold(
        BigInt.zero,
        (a, b) => a + b,
      );
      final expense = cur.expenseByCategory.values.fold(
        BigInt.zero,
        (a, b) => a + b,
      );
      sb
        ..writeln('本月（${now.year}-${now.month.toString().padLeft(2, '0')}）'
            '收入：${_fmt(income)}；支出：${_fmt(expense)}；'
            '净资产变动：${_fmt(cur.attribution.netChange)}')
        ..write('本月支出 Top：');
      final top = cur.expenseByCategory.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      if (top.isEmpty) {
        sb.write('暂无记录');
      } else {
        sb.write(
          [for (final e in top.take(3)) '${e.key} ${_fmt(e.value)}'].join('、'),
        );
      }
      sb.writeln();
    } catch (_) {}
    return sb.toString().trim();
  }

  static String _fmt(BigInt minor) {
    final yuan = minor.abs() ~/ BigInt.from(100);
    final neg = minor.isNegative ? '-' : '';
    final s = yuan.toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      final pos = s.length - i;
      b.write(s[i]);
      if (pos > 1 && (pos - 1) % 3 == 0) b.write(',');
    }
    return '$neg$b';
  }
}
