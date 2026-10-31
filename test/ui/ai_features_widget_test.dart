import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';

import 'package:assetscope/data/app_database.dart';
import 'package:assetscope/domain/ledger/account.dart';
import 'package:assetscope/ui/accounts/account_detail_sheet.dart';
import 'package:assetscope/ui/ai/assistant_page.dart';
import 'package:assetscope/ui/settings/ai_config_sheet.dart';

import 'widget_host.dart';

/// AI 功能 UI 冒烟：助手页空状态/输入、账户详情 AI 估值区块、
/// 设置弹层用量面板。不触网（AI 未配置时走提示分支）。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('AI 助手页：空状态快捷指令 + 输入区 + 账本概况开关', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(() => db.close());
    final session = await buildWidgetSession(db);
    await seedWidgetData(session);

    await tester.pumpWidget(widgetHost(const AssistantPage(), session));
    await tester.pump(const Duration(milliseconds: 400)); // chips 阶梯入场

    expect(find.text('问点什么，或从下面开始'), findsOneWidget);
    expect(find.byType(ActionChip), findsNWidgets(4));
    expect(find.text('发送'), findsOneWidget);
    // 账本概况开关（默认激活：附账本上下文）。
    expect(find.byTooltip(RegExp('账本概况')), findsOneWidget);

    // 点快捷指令：未配置 AI → 顶部提示，不抛异常。
    await tester.tap(find.byType(ActionChip).first);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('设置 → AI 服务'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '随便问问');
    expect(find.text('随便问问'), findsOneWidget);
    // 排干顶部通知的自动消失计时器。
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('账户详情：manualValue 资产显示 AI 估值区块（开关+历史）',
      (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(() => db.close());
    final session = await buildWidgetSession(db);
    await session.accounts.upsert(const Account(
      id: 'a-estate',
      name: '前滩的房子',
      type: AccountType.asset,
      assetSubtype: AssetSubtype.realEstate,
      currencyCode: 'CNY',
      aiValuationEnabled: true,
    ));

    await tester.pumpWidget(
      widgetHost(
        Scaffold(
          body: SingleChildScrollView(child: AccountDetailBody(
            account: (await session.accounts.byId('a-estate'))!,
          )),
        ),
        session,
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('AI 估值'), findsOneWidget);
    expect(find.text('立即估值'), findsOneWidget);
    expect(find.textContaining('检索词空'), findsOneWidget);
    expect(find.text('暂无估值记录'), findsOneWidget);

    // 关闭开关：区块收起，且已持久化关闭。
    final sw = find.byType(Switch);
    expect(sw, findsOneWidget);
    await tester.tap(sw);
    await tester.pump(const Duration(milliseconds: 400));
    final after = await session.accounts.byId('a-estate');
    expect(after!.aiValuationEnabled, isFalse);
  });

  testWidgets('AI 配置弹层：用量与额度面板三格统计', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(() => db.close());
    final session = await buildWidgetSession(db);
    await session.aiUsage.record();
    await session.aiUsage.record();

    await tester.pumpWidget(widgetHost(
      Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => showAiConfigSheet(context, session),
            child: const Text('open'),
          ),
        ),
      ),
      session,
    ));
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('用量与额度'), findsOneWidget);
    expect(find.text('今日调用'), findsOneWidget);
    // 今日/近 7 天/累计此刻都是 2 次。
    expect(find.text('2 次'), findsNWidgets(3));
    expect(find.text('近 7 天'), findsOneWidget);
    expect(find.text('累计'), findsOneWidget);
  });
}
