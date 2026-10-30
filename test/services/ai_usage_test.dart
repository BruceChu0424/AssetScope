import 'package:flutter_test/flutter_test.dart';

import 'package:assetscope/services/ai/ai_chat.dart';
import 'package:assetscope/services/ai/ai_usage.dart';

/// AI 用量统计：按日计数、60 天裁剪、余额响应解析、计数装饰器。
void main() {
  test('recorded 累计并按日分桶（今天与昨天）', () {
    final now = DateTime.now();
    var u = const AiUsage();
    u = u.recorded(now);
    u = u.recorded(now);
    u = u.recorded(now.subtract(const Duration(days: 1)));
    expect(u.totalCalls, 3);
    expect(u.byDay[AiUsage.dayKey(now)], 2);
    expect(u.byDay[AiUsage.dayKey(now.subtract(const Duration(days: 1)))], 1);
    expect(u.todayCalls, 2);
    expect(u.last7DaysCalls, 3);
  });

  test('60 天前的旧明细被裁掉', () {
    final now = DateTime(2026, 10, 30);
    final u = AiUsage(
      totalCalls: 9,
      byDay: {'2026-01-01': 9},
    ).recorded(now);
    expect(u.byDay.containsKey('2026-01-01'), isFalse);
    expect(u.totalCalls, 10);
    expect(u.todayCalls, 1);
  });

  test('toJson/fromJson 往返', () {
    final u = AiUsage(
      totalCalls: 5,
      byDay: {'2026-10-30': 5},
    );
    final back = AiUsage.fromJson(u.toJson());
    expect(back.totalCalls, 5);
    expect(back.byDay['2026-10-30'], 5);
  });

  test('余额响应解析：data.balance 容器 + 字符串数值', () {
    final b = AiBalanceService.parseBalance({
      'data': {
        'balance': {
          'totalBalance': '102.40',
          'voucherBalance': '100',
          'cashBalance': '2.4',
        },
      },
    });
    expect(b.total, 102.4);
    expect(b.voucher, 100);
    expect(b.cash, 2.4);
  });

  test('余额响应解析：顶层字段与 data 直挂两种形态', () {
    final b1 = AiBalanceService.parseBalance({
      'balance': {'total': 88.5},
    });
    expect(b1.total, 88.5);
    final b2 = AiBalanceService.parseBalance({
      'data': {'totalBalance': 12},
    });
    expect(b2.total, 12);
  });

  test('CountingAiChat：请求发出前挂钩计数（complete 经由 converse）',
      () async {
    var calls = 0;
    final chat = CountingAiChat(onCall: () => calls++);
    // 指向不存在域名：请求必然失败，但计数挂钩先于网络执行。
    const cfg = AiConfig(
      presetId: 'glm',
      baseUrl: 'https://example.invalid',
      apiKey: 'k',
      model: 'm',
      enableWebSearch: false,
    );
    try {
      await chat.complete(cfg, 's', 'u');
    } catch (_) {}
    expect(calls, 1);
  });
}
