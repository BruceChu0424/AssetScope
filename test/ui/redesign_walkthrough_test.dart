import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:assetscope/app/providers.dart';
import 'package:assetscope/data/app_database.dart';
import 'package:assetscope/domain/budget/budget.dart';
import 'package:assetscope/domain/debt/debt_contract.dart';
import 'package:assetscope/domain/ledger/account.dart';
import 'package:assetscope/domain/money/fx_rate.dart';
import 'package:assetscope/domain/planning/recurrence.dart';
import 'package:assetscope/domain/utils/dates.dart';
import 'package:assetscope/ui/budget/budgets_page.dart';
import 'package:assetscope/ui/debts/debts_page.dart';
import 'package:assetscope/ui/goals/goals_page.dart';
import 'package:assetscope/ui/planning/plans_page.dart';
import 'package:assetscope/ui/reports/report_page.dart';
import 'package:assetscope/ui/settings/settings_page.dart';
import 'package:assetscope/ui/theme/app_theme.dart';
import 'package:assetscope/ui/transactions/transactions_page.dart';

import 'widget_host.dart';

/// 页面重设计走查：两档窗口尺寸（大屏 1600×1000 / 小屏 480×900）对
/// 每个重写页面出 golden 截图（--update-goldens 生成），供被动版式
/// 走查——不注入真实输入、不依赖人工点击。种子补齐预算/目标/负债，
/// 保证网格态（而非空态）被截到。
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
    await _seedMore(session);
  });

  tearDown(() async {
    if (dbAvailable) await db.close();
  });

  Future<void> shot(
    WidgetTester tester,
    String name,
    Widget page, {
    bool settle = true,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [vaultProvider.overrideWith(() => FixedVault(session))],
        child: MaterialApp(
          theme: buildAppTheme(Brightness.dark),
          home: page,
        ),
      ),
    );
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 120));
      }
    }
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('redesign/$name.png'),
    );
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  testWidgets('走查：各页面两档尺寸', (tester) async {
    if (!dbAvailable) {
      markTestSkipped('宿主环境无可用 sqlite3，跳过');
      return;
    }
    for (final (w, h, tag) in const [
      (1600.0, 1000.0, 'wide'),
      (480.0, 900.0, 'small'),
    ]) {
      await tester.binding.setSurfaceSize(Size(w, h));
      tester.view.physicalSize = Size(w, h);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await shot(tester, 'transactions_$tag', const TransactionsPage());
      await shot(tester, 'budgets_$tag', const BudgetsPage());
      await shot(tester, 'plans_$tag', const PlansPage());
      await shot(tester, 'goals_$tag', const GoalsPage());
      await shot(tester, 'debts_$tag', const DebtsPage());
      await shot(tester, 'reports_$tag', const ReportPage());
      await shot(tester, 'settings_$tag', const SettingsPage());
    }
  });
}

/// 走查专用补充种子：预算 2 只 / 目标 1 只 / 负债 1 笔。
Future<void> _seedMore(VaultUnlocked s) async {
  final now = DateTime.now();
  await s.planning.saveBudget(Budget(
    id: 'bud:total',
    name: '月度总预算',
    scope: BudgetScope.total,
    limitMinor: BigInt.from(600000),
    currencyCode: 'CNY',
    startMonthKey: monthKey(now),
    rollover: RolloverPolicy.none,
  ));
  await s.planning.saveBudget(Budget(
    id: 'bud:dining',
    name: '餐饮',
    scope: BudgetScope.category,
    limitMinor: BigInt.from(200000),
    currencyCode: 'CNY',
    startMonthKey: monthKey(now),
    categoryId: 'cat:e:dining',
    rollover: RolloverPolicy.none,
  ));
  await s.planning.saveGoal(SavingsGoal(
    id: 'goal:trip',
    name: '北海道旅行',
    targetAmountMinor: BigInt.from(3000000),
    targetDate: now.add(const Duration(days: 200)),
    reservedAmountMinor: BigInt.from(1200000),
  ));
  await s.accounts.upsert(Account(
    id: 'acc:liab:demo',
    name: '房贷',
    type: AccountType.liability,
    liabilitySubtype: LiabilitySubtype.mortgage,
    currencyCode: 'CNY',
  ));
  await s.planning.saveDebtContract(DebtContract(
    liabilityAccountId: 'acc:liab:demo',
    principalOriginalMinor: BigInt.from(90000000),
    aprPercent: Rational.parseDecimal('3.85'),
    method: RepaymentMethod.annuity,
    termMonths: 360,
    startDate: DateTime(now.year - 2, now.month, 1),
    repaymentDay: 1,
  ));
}
