import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:assetscope/data/app_database.dart';
import 'package:assetscope/data/repositories/accounts_repo.dart';
import 'package:assetscope/data/repositories/ledger_repo.dart';
import 'package:assetscope/data/repositories/meta_repo.dart';
import 'package:assetscope/data/repositories/planning_repo.dart';
import 'package:assetscope/domain/ledger/account.dart';
import 'package:assetscope/domain/ledger/transaction.dart';
import 'package:assetscope/domain/planning/recurrence.dart';
import 'package:assetscope/domain/planning/scenario.dart';
import 'package:assetscope/services/projection_service.dart';
import 'package:assetscope/services/scenario_service.dart';
import 'package:assetscope/services/stats_service.dart';

/// 情景模拟服务：真实内存库上跑通 基线 → 冲击 → 对比 全链路。
/// 运行需要宿主可加载 sqlite3；不可用时跳过。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late AccountsRepo accounts;
  late LedgerRepo ledger;
  late PlanningRepo planning;
  late MetaRepo meta;
  late ScenarioService scenarioService;

  bool dbAvailable = true;

  setUp(() async {
    try {
      db = AppDatabase(NativeDatabase.memory());
      await db.customSelect('SELECT 1').getSingle();
    } catch (_) {
      dbAvailable = false;
      return;
    }
    accounts = AccountsRepo(db);
    ledger = LedgerRepo(db);
    planning = PlanningRepo(db);
    meta = MetaRepo(db);
    final stats = StatsService(accounts, ledger, meta);
    scenarioService =
        ScenarioService(ProjectionService(accounts, ledger, planning, meta), stats);
  });

  tearDown(() async {
    if (dbAvailable) await db.close();
  });

  Future<void> seed() async {
    final bank = Account(
        id: 'bank',
        name: '招行',
        type: AccountType.asset,
        assetSubtype: AssetSubtype.bank,
        currencyCode: 'CNY');
    await accounts.upsert(bank);
    await ledger.post(TxBuilders.openingBalance(
        assetAccount: bank,
        amountMinor: BigInt.from(1000000),
        date: DateTime(2026, 1, 1)));
    await planning.saveScheduledEvent(ScheduledEvent(
        id: 'evt:salary',
        name: '工资',
        direction: EventDirection.inflow,
        currencyCode: 'CNY',
        cadence: Cadence.monthly,
        anchorDate: DateTime(2026, 6, 1),
        amountMinor: BigInt.from(200000)));
    await planning.saveScheduledEvent(ScheduledEvent(
        id: 'evt:rent',
        name: '房租',
        direction: EventDirection.outflow,
        currencyCode: 'CNY',
        cadence: Cadence.monthly,
        anchorDate: DateTime(2026, 6, 3),
        amountMinor: BigInt.from(150000)));
  }

  test('空库 fireDefaults 全零', () async {
    if (!dbAvailable) {
      markTestSkipped('宿主环境无可用 sqlite3，跳过数据层测试');
      return;
    }
    final d = await scenarioService.fireDefaults(now: DateTime(2026, 6, 1));
    expect(d.investableMinor, BigInt.zero);
    expect(d.ttmSavingsMinor, BigInt.zero);
    expect(d.ttmSpendMinor, BigInt.zero);
    expect(d.monthsOfHistory, 0);
  });

  test('失业情景：低谷显著低于基线且方向正确', () async {
    if (!dbAvailable) {
      markTestSkipped('宿主环境无可用 sqlite3，跳过数据层测试');
      return;
    }
    await seed();
    final now = DateTime(2026, 6, 1);
    final c = await scenarioService.run(ScenarioPresets.unemployment(months: 3),
        now: now, horizonDays: 120);
    expect(c.fromDate, now);
    // 基线（120 天内房租 4 次 −1500、工资 3 次 +2000，起始日事件按口径丢弃）：
    // 低谷在 6/3 = 10000 − 1500。
    expect(c.baseline.minBalanceBaseMinor, BigInt.from(850000));
    // 情景：7/1、8/1、9/1 工资归零 → 低谷 9/3 = 4000。
    expect(c.scenario.minBalanceBaseMinor, BigInt.from(400000));
    expect(c.minBalanceDelta, BigInt.from(-450000));
    // 1 万期初足够扛住 3×1500 房租 → 不耗尽、无新增缺口。
    expect(c.firstCashOutDate, isNull);
    expect(c.survives, isTrue);
  });

  test('叠加额外月支出后压力放大', () async {
    if (!dbAvailable) {
      markTestSkipped('宿主环境无可用 sqlite3，跳过数据层测试');
      return;
    }
    await seed();
    final now = DateTime(2026, 6, 1);
    final mild = await scenarioService.run(
        ScenarioPresets.extraOutflow(BigInt.from(100000), 2),
        now: now,
        horizonDays: 120);
    final harsh = await scenarioService.run(
        ScenarioPresets.extraOutflow(BigInt.from(500000), 4),
        now: now,
        horizonDays: 120);
    expect(harsh.minBalanceDelta, lessThan(mild.minBalanceDelta));
  });

  test('fireDefaults：活期计入可投资净资产', () async {
    if (!dbAvailable) {
      markTestSkipped('宿主环境无可用 sqlite3，跳过数据层测试');
      return;
    }
    await seed();
    final d = await scenarioService.fireDefaults(now: DateTime(2026, 6, 1));
    expect(d.investableMinor, BigInt.from(1000000));
  });

  test('基线与 project() 同引擎（重构不改变行为）', () async {
    if (!dbAvailable) {
      markTestSkipped('宿主环境无可用 sqlite3，跳过数据层测试');
      return;
    }
    await seed();
    final now = DateTime(2026, 6, 1);
    final s = (await scenarioService.run(
        const ScenarioSpec(name: '空', components: []),
        now: now,
        horizonDays: 90));
    final projection = await ProjectionService(accounts, ledger, planning, meta)
        .project(now: now, horizonDays: 90);
    expect(s.baseline.minBalanceBaseMinor, projection.minBalanceBaseMinor);
    expect(s.baseline.shortfalls.length, projection.shortfalls.length);
  });
}
