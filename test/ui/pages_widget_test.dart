import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:assetscope/app/providers.dart';
import 'package:assetscope/data/app_database.dart';
import 'package:assetscope/domain/ledger/transaction.dart';
import 'package:assetscope/domain/money/fx_rate.dart';
import 'package:assetscope/domain/planning/recurrence.dart';
import 'package:assetscope/domain/utils/dates.dart';
import 'package:assetscope/ui/budget/budgets_page.dart';
import 'package:assetscope/ui/debts/debts_page.dart';
import 'package:assetscope/ui/globe/globe_home_page.dart';
import 'package:assetscope/ui/globe/globe_page.dart';
import 'package:assetscope/ui/planning/plans_page.dart';
import 'package:assetscope/ui/reports/report_page.dart';
import 'package:assetscope/ui/transactions/transactions_page.dart';
import 'package:assetscope/ui/widgets/app_dialog.dart';
import 'package:assetscope/ui/widgets/section_card.dart';

import 'package:assetscope/ui/planning/life_planner_sheet.dart';
import 'widget_host.dart';

/// 关键页面 widget 测试：内存库 + 真实全服务栈，页面渲染与核心交互冒烟。
/// 运行需要宿主可加载 sqlite3；不可用时跳过。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late VaultUnlocked session;
  bool dbAvailable = true;

  setUp(() async {
    try {
      db = AppDatabase(NativeDatabase.memory());
      await db.customSelect('SELECT 1').getSingle();
    } catch (_) {
      dbAvailable = false;
      return;
    }
    session = await buildWidgetSession(db);
    await seedWidgetData(session);
  });

  tearDown(() async {
    if (dbAvailable) await db.close();
  });

  Widget host(Widget child) => widgetHost(child, session);

  /// 首页含常驻动画（地球自转/标记呼吸），不能 pumpAndSettle：
  /// 定时泵帧等异步数据落定即可。
  Future<void> pumpHome(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 120));
    }
  }

  testWidgets('首页：净资产 hero 与洞察卡渲染', (tester) async {
    if (!dbAvailable) {
      markTestSkipped('宿主环境无可用 sqlite3，跳过');
      return;
    }
    await tester.pumpWidget(host(const GlobeHomePage()));
    await pumpHome(tester);
    expect(find.text('净资产'), findsOneWidget);
    expect(find.byType(SectionCard), findsWidgets);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  });

  testWidgets('流水页：渲染种子交易 + 记一笔对话框全流程', (tester) async {
    if (!dbAvailable) {
      markTestSkipped('宿主环境无可用 sqlite3，跳过');
      return;
    }
    await tester.pumpWidget(host(const TransactionsPage()));
    await tester.pumpAndSettle();
    expect(find.text('超市'), findsWidgets);

    // 打开记一笔 → 输入金额 → 保存 → 列表出现新金额。
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    // FAB 标签与对话框标题同名，两个都在树上。
    expect(find.text('记一笔'), findsWidgets);

    // 金额输入限定在对话框内（页面自身还有搜索框）。
    final amountField = find
        .descendant(
            of: find.byType(AppDialog), matching: find.byType(TextField))
        .first;
    await tester.enterText(amountField, '88.50');
    // 注意：聚焦的输入框光标闪烁会一直调度帧，此处不能用 pumpAndSettle。
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, '保存'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 200));

    final txs = await session.ledger.list();
    expect(txs.any((t) => t.kind == TxKind.expense && t.note == null), isTrue);
    expect(
        txs.where((t) => t.kind == TxKind.expense).map((t) => t.postings
            .where((p) => p.amountMinor == BigInt.from(8850))
            .isNotEmpty),
        contains(true),
        reason: '新消费 88.50 元应已入账');
    // 释放焦点，取消光标闪烁 Timer；再干净卸载页面
    //（drift watch 流取消会挂零时长 Timer，需要泵帧消化，
    // 否则测试收尾的"挂起 Timer"断言失败且 db.close() 卡死）。
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  });


  testWidgets('流水页：详情 → 编辑交易 → 原地更新', (tester) async {
    if (!dbAvailable) {
      markTestSkipped('宿主环境无可用 sqlite3，跳过');
      return;
    }
    await tester.pumpWidget(host(const TransactionsPage()));
    await tester.pumpAndSettle();

    // 打开第一笔"超市"详情 → 编辑。
    await tester.tap(find.text('超市').first);
    await tester.pumpAndSettle();
    expect(find.text('分录（借贷平衡）'), findsOneWidget);
    await tester.tap(find.text('编辑'));
    await tester.pumpAndSettle();
    expect(find.text('编辑交易'), findsOneWidget);

    // 金额改为 99.99（预填原金额 42.xx，覆盖）。
    final amountField = find
        .descendant(
            of: find.byType(AppDialog), matching: find.byType(TextField))
        .first;
    await tester.enterText(amountField, '99.99');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, '保存'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final now = DateTime.now();
    final txs = await session.ledger
        .list(from: DateTime(now.year, now.month, 1));
    // 编辑不增不减交易数（3 笔消费），且新金额在账、旧分类分录被替换。
    expect(txs.where((t) => t.kind == TxKind.expense).length, 3);
    expect(
        txs.any((t) => t.postings
            .any((p) => p.amountMinor == -BigInt.from(9999))),
        isTrue,
        reason: '编辑后的 99.99 元应已原地入账');

    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  });

  testWidgets('计划页：情景模拟弹层端到端', (tester) async {
    if (!dbAvailable) {
      markTestSkipped('宿主环境无可用 sqlite3，跳过');
      return;
    }
    await tester.pumpWidget(host(const PlansPage()));
    await tester.pumpAndSettle();
    expect(find.text('计划'), findsOneWidget);

    await tester.tap(find.byTooltip('情景模拟 · 现金压力测试'));
    await tester.pumpAndSettle();
    expect(find.text('情景模拟 · 现金压力测试'), findsOneWidget);

    await tester.tap(find.text('运行模拟'));
    await tester.pumpAndSettle();
    // 结果卡出现：基线/情景最低现金与可承受结论。
    expect(find.textContaining('最低现金 · 基线'), findsOneWidget);
    expect(find.text('预测期内未耗尽'), findsOneWidget);
  });

  testWidgets('计划页：人生规划弹层 · 添加买房事件并推演', (tester) async {
    if (!dbAvailable) {
      markTestSkipped('宿主环境无可用 sqlite3，跳过');
      return;
    }
    await tester.pumpWidget(host(const PlansPage()));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('人生规划 · 多年度推演'));
    await tester.pumpAndSettle();
    expect(find.text('人生规划 · 多年度推演'), findsOneWidget);

    // 添加买房事件（默认 3 年后 · 3.6% · 30 年）。
    await tester.tap(find.byTooltip('添加事件'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('买房（含贷款）'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.widgetWithText(TextField, '总价（元）'), '1000000');
    await tester.enterText(
        find.widgetWithText(TextField, '首付（元）'), '300000');
    // 光标闪烁 Timer 会阻塞 pumpAndSettle，先 unfocus 再点确定。
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, '确定'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // 事件列表出现摘要；结论卡在惰性列表视口外，滚动到位后断言
    //（显式指定弹层内的 Scrollable——自动探测会命中底层页面的列表）。
    expect(find.textContaining('3 年后买房'), findsOneWidget);
    final sheetScrollable = find
        .descendant(
            of: find.byType(LifePlannerSheet),
            matching: find.byType(Scrollable))
        .first;
    await tester.scrollUntilVisible(find.text('推演结论'), 200,
        scrollable: sheetScrollable);
    expect(find.text('推演结论'), findsOneWidget);
    expect(find.textContaining('年后净资产'), findsOneWidget);

    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  });

  testWidgets('首页：共享账户显示我的份额行', (tester) async {
    if (!dbAvailable) {
      markTestSkipped('宿主环境无可用 sqlite3，跳过');
      return;
    }
    final bank = (await session.accounts.byId('bank'))!;
    await session.accounts.upsert(bank.copyWith(
        ownership: Rational.fromFrac(BigInt.one, BigInt.from(2))));
    await tester.pumpWidget(host(const GlobeHomePage()));
    await pumpHome(tester);
    // hero 上出现"我的份额"口径行（家庭总仍是主数字）。
    expect(find.textContaining('我的份额'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  });

  testWidgets('计划页：到期计划一键全部记入 → 清单消失', (tester) async {
    if (!dbAvailable) {
      markTestSkipped('宿主环境无可用 sqlite3，跳过');
      return;
    }
    // 今天到期的咖啡计划（配置齐全，可直接一键记入）。
    // 先删种子自带的房租计划（未配账户会留在待落地清单，干扰断言）。
    await session.planning.deleteScheduledEvent('evt:rent');
    final today = DateTime.now();
    await session.planning.saveScheduledEvent(ScheduledEvent(
        id: 'evt:coffee',
        name: '咖啡豆',
        direction: EventDirection.outflow,
        currencyCode: 'CNY',
        cadence: Cadence.weekly,
        anchorDate: DateTime(today.year, today.month, today.day),
        amountMinor: BigInt.from(6600),
        paymentAccountId: 'bank',
        categoryId: 'cat:e:dining'));
    await tester.pumpWidget(host(const PlansPage()));
    await tester.pumpAndSettle();
    expect(find.textContaining('待落地'), findsOneWidget);
    expect(find.text('咖啡豆'), findsWidgets);

    await tester.tap(find.text('全部记入'));
    await tester.pumpAndSettle();
    expect(find.textContaining('已记入 1 笔计划'), findsOneWidget);
    // 清单刷新后消失。
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.textContaining('待落地'), findsNothing);

    final extId =
        'plan:evt:coffee:${dateKey(DateTime(today.year, today.month, today.day))}';
    expect(await session.ledger.externalIdExists(extId), isTrue);
    // 再点不会重复入账（幂等）。
    expect(find.text('全部记入'), findsNothing);
  });

  testWidgets('计划页：确认弹层改金额记入账本', (tester) async {
    if (!dbAvailable) {
      markTestSkipped('宿主环境无可用 sqlite3，跳过');
      return;
    }
    // 未配置支付账户的到期计划：确认弹层里选默认账户并改金额。
    await session.planning.deleteScheduledEvent('evt:rent');
    final today = DateTime.now();
    await session.planning.saveScheduledEvent(ScheduledEvent(
        id: 'evt:milk',
        name: '鲜奶',
        direction: EventDirection.outflow,
        currencyCode: 'CNY',
        cadence: Cadence.once,
        anchorDate: DateTime(today.year, today.month, today.day),
        amountMinor: BigInt.from(3000)));
    await tester.pumpWidget(host(const PlansPage()));
    await tester.pumpAndSettle();
    expect(find.text('鲜奶'), findsWidgets);

    await tester.tap(find.byTooltip('记入账本'));
    await tester.pumpAndSettle();
    expect(find.textContaining('记入账本 · 鲜奶'), findsOneWidget);

    final sheetAmount = find
        .descendant(
            of: find.byType(BottomSheet), matching: find.byType(TextField))
        .first;
    await tester.enterText(sheetAmount, '32.50');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, '记入账本'));
    await tester.pumpAndSettle();

    expect(find.textContaining('待落地'), findsNothing);
    final rows = await (db.select(db.transactions)
          ..where((t) => t.externalId.equals('plan:evt:milk:${dateKey(DateTime(today.year, today.month, today.day))}')))
        .get();
    expect(rows, hasLength(1));
    expect(rows.single.kind, 'expense');
    expect(rows.single.source, 'planGenerated');

    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  });

  testWidgets('报表页：归因卡渲染 + 年度切换', (tester) async {
    if (!dbAvailable) {
      markTestSkipped('宿主环境无可用 sqlite3，跳过');
      return;
    }
    await tester.pumpWidget(host(const ReportPage()));
    await tester.pumpAndSettle();
    expect(find.text('净资产变化分解'), findsOneWidget);

    // 顶部切换年度（先于滚动，避免目标滚出懒加载区）。
    await tester.tap(find.text('年度'));
    await tester.pumpAndSettle();
    expect(find.textContaining('年度 ·'), findsOneWidget);
    await tester.tap(find.text('月报'));
    await tester.pumpAndSettle();

    // 分类卡在视口之外，滚动到位后再断言。
    await tester.scrollUntilVisible(find.text('消费构成'), 300);
    expect(find.text('消费构成'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('预算 / 负债页冒烟', (tester) async {
    if (!dbAvailable) {
      markTestSkipped('宿主环境无可用 sqlite3，跳过');
      return;
    }
    for (final (page, title) in const [
      (BudgetsPage(), '预算'),
      (DebtsPage(), '负债'),
    ]) {
      await tester.pumpWidget(host(page));
      await tester.pumpAndSettle();
      expect(find.text(title), findsWidgets, reason: '$page 应渲染标题 $title');
    }
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('地球页渲染（空闲自转动画）', (tester) async {
    if (!dbAvailable) {
      markTestSkipped('宿主环境无可用 sqlite3，跳过');
      return;
    }
    // 地球页空闲自转动画持续调度帧，不能用 pumpAndSettle，改定时推进。
    await tester.pumpWidget(host(const GlobePage()));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('资产地球'), findsWidgets);
    // 干净卸载动画页（dispose 在树活跃时执行，收尾不再补 dispose）。
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  });
}

