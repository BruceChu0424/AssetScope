import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:assetscope/app/providers.dart';
import 'package:assetscope/data/app_database.dart';
import 'package:assetscope/data/repositories/accounts_repo.dart';
import 'package:assetscope/data/repositories/ledger_repo.dart';
import 'package:assetscope/data/repositories/meta_repo.dart';
import 'package:assetscope/data/repositories/planning_repo.dart';
import 'package:assetscope/domain/ledger/account.dart';
import 'package:assetscope/domain/ledger/transaction.dart';
import 'package:assetscope/domain/planning/recurrence.dart';
import 'package:assetscope/security/dart_crypto_suite.dart';
import 'package:assetscope/security/key_manager.dart';
import 'package:assetscope/services/ai/ai_chat.dart';
import 'package:assetscope/services/ai/quote_fetch_service.dart';
import 'package:assetscope/services/export_service.dart';
import 'package:assetscope/services/import_service.dart';
import 'package:assetscope/services/insight_service.dart';
import 'package:assetscope/services/ledger_service.dart';
import 'package:assetscope/services/portfolio_analytics_service.dart';
import 'package:assetscope/services/portfolio_service.dart';
import 'package:assetscope/services/projection_service.dart';
import 'package:assetscope/services/quotes/direct_quote_service.dart';
import 'package:assetscope/services/scenario_service.dart';
import 'package:assetscope/services/stats_service.dart';
import 'package:assetscope/services/year_report_service.dart';
import 'package:assetscope/ui/theme/app_theme.dart';

/// Widget 测试公共 harness：内存库 + 真实全服务栈 + 固定已解锁会话。
/// 各测试文件共用；运行需要宿主可加载 sqlite3，不可用时自行跳过。

/// 内存库（调用方负责 close）。
AppDatabase widgetDb() => AppDatabase(NativeDatabase.memory());

/// 与 providers._openDatabase 同构的会话（内存库 + 未解锁的哑 KeyManager，
/// 页面流程不触达密钥操作）。
Future<VaultUnlocked> buildWidgetSession(AppDatabase db) async {
  final accounts = AccountsRepo(db);
  final ledger = LedgerRepo(db);
  final planning = PlanningRepo(db);
  final meta = MetaRepo(db);
  final stats = StatsService(accounts, ledger, meta);
  final portfolio = PortfolioService(accounts, ledger, meta, stats);
  final projection = ProjectionService(accounts, ledger, planning, meta);
  final quoteFetch =
      QuoteFetchService(accounts, ledger, meta, const AiChat());
  return VaultUnlocked(
    db: db,
    keyManager: KeyManager(suite: DartCryptoSuite.instance),
    accounts: accounts,
    ledger: ledger,
    planning: planning,
    meta: meta,
    ledgerService: LedgerService(accounts, ledger),
    statsService: stats,
    projectionService: projection,
    importService: ImportService(accounts, ledger, meta),
    insightService: InsightService(accounts, ledger, planning, meta),
    exportService: ExportService(accounts, ledger),
    portfolioService: portfolio,
    portfolioAnalytics:
        PortfolioAnalyticsService(ledger, meta, stats, portfolio),
    yearReportService: YearReportService(accounts, ledger, stats),
    quoteFetch: quoteFetch,
    directQuotes: DirectQuoteService(accounts, quoteFetch),
    scenarios: ScenarioService(projection, stats),
  );
}

/// 种子：一个现金账户 + 期初余额 + 本月 3 笔消费 1 笔收入 + 一条月度计划。
/// 金额与对手方被多处断言引用（招行/超市/88.50），改动需同步测试。
Future<void> seedWidgetData(VaultUnlocked s) async {
  final bank = Account(
      id: 'bank',
      name: '招行',
      type: AccountType.asset,
      assetSubtype: AssetSubtype.bank,
      currencyCode: 'CNY');
  await s.accounts.upsert(bank);
  final dining = (await s.accounts.byId('cat:e:dining'))!;
  final salary = (await s.accounts.byId('cat:i:salary'))!;
  final now = DateTime.now();
  await s.ledger.post(TxBuilders.openingBalance(
      assetAccount: bank,
      amountMinor: BigInt.from(10000000),
      date: DateTime(now.year, now.month, 1)));
  // 本月交易：报表页默认展示当前月，分类卡才有内容。
  for (var i = 1; i <= 3; i++) {
    await s.ledger.post(TxBuilders.expense(
        payFrom: bank,
        expenseCategory: dining,
        amountMinor: BigInt.from(4200 + i),
        date: DateTime(now.year, now.month, i * 2),
        counterparty: '超市'));
  }
  await s.ledger.post(TxBuilders.income(
      destAsset: bank,
      incomeCategory: salary,
      amountMinor: BigInt.from(500000),
      date: DateTime(now.year, now.month, 10),
      counterparty: '公司'));
  await s.planning.saveScheduledEvent(ScheduledEvent(
      id: 'evt:rent',
      name: '房租',
      direction: EventDirection.outflow,
      currencyCode: 'CNY',
      cadence: Cadence.monthly,
      anchorDate: DateTime(now.year, now.month, 3),
      amountMinor: BigInt.from(150000)));
}

/// 固定已解锁状态：不走真实金库初始化（文件系统/路径插件在测试里不可用）。
class FixedVault extends VaultNotifier {
  FixedVault(this.session);
  final VaultUnlocked session;

  @override
  VaultState build() => session;
}

/// 标准宿主：固定会话 + 浅色主题 MaterialApp。
Widget widgetHost(Widget child, VaultUnlocked session) => ProviderScope(
      overrides: [vaultProvider.overrideWith(() => FixedVault(session))],
      child: MaterialApp(
          theme: buildAppTheme(Brightness.light), home: child),
    );
