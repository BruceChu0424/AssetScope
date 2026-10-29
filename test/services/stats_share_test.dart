import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';

import 'package:assetscope/data/app_database.dart';
import 'package:assetscope/data/repositories/accounts_repo.dart';
import 'package:assetscope/data/repositories/ledger_repo.dart';
import 'package:assetscope/data/repositories/meta_repo.dart';
import 'package:assetscope/data/repositories/planning_repo.dart';
import 'package:assetscope/domain/ledger/account.dart';
import 'package:assetscope/domain/ledger/transaction.dart';
import 'package:assetscope/domain/money/fx_rate.dart';
import 'package:assetscope/services/projection_service.dart';
import 'package:assetscope/services/scenario_service.dart';
import 'package:assetscope/services/stats_service.dart';
import 'package:assetscope/ui/accounts/ownership.dart';

/// 家庭账本·归属份额（v0.15，docs/05 §16）：
/// 存量按本人份额（Rational × BigInt halfEven）、流量全家庭、
/// 全 100% 时与原口径一致（向后兼容）、FIRE/人生规划用我的份额。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late AccountsRepo accounts;
  late LedgerRepo ledger;
  late MetaRepo meta;
  late StatsService stats;
  late ScenarioService scenarios;

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
    meta = MetaRepo(db);
    stats = StatsService(accounts, ledger, meta);
    scenarios = ScenarioService(
        ProjectionService(accounts, ledger, PlanningRepo(db), meta), stats);
  });

  tearDown(() async {
    if (dbAvailable) await db.close();
  });


  test('份额解析与显示：百分数往返、非法输入拒绝', () {
    final half = parseOwnership('50');
    expect(half, Rational.fromFrac(BigInt.one, BigInt.from(2)));
    final third = parseOwnership('33.3');
    expect(third!.n, BigInt.from(333));
    expect(parseOwnership('100'), Rational.one);
    expect(parseOwnership('0'), isNull);
    expect(parseOwnership('120'), isNull);
    expect(parseOwnership('abc'), isNull);
    expect(parseOwnership(''), isNull);
    expect(fmtOwnership(half!), '50');
    expect(fmtOwnership(Rational.fromFrac(BigInt.one, BigInt.from(3))), '33.33');
  });

  test('全 100% 账户：我的份额口径与原口径完全一致', () async {
    if (!dbAvailable) return;
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
    final nw = await stats.netWorthAt(DateTime(2026, 6, 1));
    expect(nw.hasSharedAccounts, isFalse);
    expect(nw.myNetWorth, nw.netWorth);
    expect(nw.myTotalAssets, nw.totalAssets);
    expect(nw.myTotalLiabilities, nw.totalLiabilities);
  });

  test('共享资产 + 共享负债：我的净资产按份额（含 1/3 舍入）', () async {
    if (!dbAvailable) return;
    final joint = Account(
        id: 'joint',
        name: '共同存款',
        type: AccountType.asset,
        assetSubtype: AssetSubtype.bank,
        currencyCode: 'CNY',
        ownership: Rational.fromFrac(BigInt.one, BigInt.from(3)));
    final mine = Account(
        id: 'mine',
        name: '个人存款',
        type: AccountType.asset,
        assetSubtype: AssetSubtype.bank,
        currencyCode: 'CNY');
    final jointCard = Account(
        id: 'jointcard',
        name: '共同信用卡',
        type: AccountType.liability,
        liabilitySubtype: LiabilitySubtype.creditCard,
        currencyCode: 'CNY',
        ownership: Rational.fromFrac(BigInt.one, BigInt.from(2)));
    await accounts.upsert(joint);
    await accounts.upsert(mine);
    await accounts.upsert(jointCard);
    // 共同存款 100.00 元（1/3 → 33.33）、个人 50.00、共同卡欠 20.00（1/2 → 10）。
    await ledger.post(TxBuilders.openingBalance(
        assetAccount: joint,
        amountMinor: BigInt.from(10000),
        date: DateTime(2026, 1, 1)));
    await ledger.post(TxBuilders.openingBalance(
        assetAccount: mine,
        amountMinor: BigInt.from(5000),
        date: DateTime(2026, 1, 1)));
    final dining = (await accounts.byId('cat:e:dining'))!;
    await ledger.post(TxBuilders.expense(
        payFrom: jointCard,
        expenseCategory: dining,
        amountMinor: BigInt.from(2000),
        date: DateTime(2026, 1, 15)));

    final nw = await stats.netWorthAt(DateTime(2026, 6, 1));
    expect(nw.hasSharedAccounts, isTrue);
    expect(nw.totalAssets, BigInt.from(15000));
    expect(nw.totalLiabilities, BigInt.from(2000));
    expect(nw.netWorth, BigInt.from(13000));
    // 1/3 × 10000 = 3333.33… → 3333；50.00 全额；负债 1/2 × 2000 = 1000。
    expect(nw.myTotalAssets, BigInt.from(3333 + 5000));
    expect(nw.myTotalLiabilities, BigInt.from(1000));
    expect(nw.myNetWorth, BigInt.from(3333 + 5000 - 1000));
  });

  test('FIRE 默认参数：可投资净资产按我的份额', () async {
    if (!dbAvailable) return;
    final joint = Account(
        id: 'joint',
        name: '共同存款',
        type: AccountType.asset,
        assetSubtype: AssetSubtype.bank,
        currencyCode: 'CNY',
        ownership: Rational.fromFrac(BigInt.one, BigInt.from(2)));
    await accounts.upsert(joint);
    await ledger.post(TxBuilders.openingBalance(
        assetAccount: joint,
        amountMinor: BigInt.from(1000000),
        date: DateTime(2026, 1, 1)));
    final f = await scenarios.fireDefaults(now: DateTime(2026, 6, 1));
    // 10000 元 × 1/2 = 5000.00 元（500000 分）。
    expect(f.investableMinor, BigInt.from(500000));
  });
}
