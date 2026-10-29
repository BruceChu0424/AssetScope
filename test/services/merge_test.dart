import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';

import 'package:assetscope/data/app_database.dart';
import 'package:assetscope/data/repositories/accounts_repo.dart';
import 'package:assetscope/data/repositories/ledger_repo.dart';
import 'package:assetscope/data/repositories/meta_repo.dart';
import 'package:assetscope/data/repositories/planning_repo.dart';
import 'package:assetscope/domain/ledger/account.dart';
import 'package:assetscope/domain/ledger/transaction.dart';
import 'package:assetscope/domain/planning/recurrence.dart';
import 'package:assetscope/security/backup.dart';
import 'package:assetscope/services/merge_service.dart';

/// 账本合并：LWW/补缺/自然键去重/事件并集/设置补缺/幂等 + 容器谱系预检。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmp;
  late AppDatabase live; // 本机账本（合并目标）
  late File srcFile; // 另一台设备的明文库（合并来源）
  AppDatabase? src; // 来源库连接（构造数据用）
  late AccountsRepo accountsA;
  late LedgerRepo ledgerA;
  late PlanningRepo planningA;
  late MetaRepo metaA;

  bool dbAvailable = true;

  setUp(() async {
    try {
      tmp = await Directory.systemTemp.createTemp('assetscope-merge-');
      live = AppDatabase(NativeDatabase(File('${tmp.path}/live.db')));
      await live.customSelect('SELECT 1').getSingle();
    } catch (_) {
      dbAvailable = false;
      return;
    }
    src = AppDatabase(NativeDatabase(File('${tmp.path}/src.db')));
    accountsA = AccountsRepo(live);
    ledgerA = LedgerRepo(live);
    planningA = PlanningRepo(live);
    metaA = MetaRepo(live);
  });

  tearDown(() async {
    if (dbAvailable) {
      await src?.close();
      await live.close();
      await tmp.delete(recursive: true);
    }
  });

  /// 两边都建同一现金账户（同 id），返回账户。
  Future<Account> seedBank(AppDatabase db, AccountsRepo repo) async {
    final bank = Account(
        id: 'bank',
        name: '招行',
        type: AccountType.asset,
        assetSubtype: AssetSubtype.bank,
        currencyCode: 'CNY');
    await repo.upsert(bank);
    return bank;
  }

  test('双向补缺 + 交易 LWW：新交易并入、同 id 新者胜且分录整体替换', () async {
    if (!dbAvailable) return;
    final bankA = await seedBank(live, accountsA);
    final diningA = (await accountsA.byId('cat:e:dining'))!;
    // 本机：tx:dup 支出 100。
    await ledgerA.post(
        TxBuilders.expense(
            payFrom: bankA,
            expenseCategory: diningA,
            amountMinor: BigInt.from(10000),
            date: DateTime(2026, 6, 1)),
        id: 'tx:dup');

    final accountsB = AccountsRepo(src!);
    final ledgerB = LedgerRepo(src!);
    final bankB = await seedBank(src!, accountsB);
    final diningB = (await accountsB.byId('cat:e:dining'))!;
    // 来源：tx:dup 支出 200（内容不同，同 id）+ 独有 tx:only-b。
    await ledgerB.post(
        TxBuilders.expense(
            payFrom: bankB,
            expenseCategory: diningB,
            amountMinor: BigInt.from(20000),
            date: DateTime(2026, 6, 1)),
        id: 'tx:dup');
    await ledgerB.post(
        TxBuilders.income(
            destAsset: bankB,
            incomeCategory: (await accountsB.byId('cat:i:salary'))!,
            amountMinor: BigInt.from(500000),
            date: DateTime(2026, 6, 2)),
        id: 'tx:only-b');
    // 来源的 tx:dup 更新时间置为远未来 → LWW 应胜出。
    await src!.customStatement('UPDATE transactions SET updated_at = ? '
        "WHERE id = 'tx:dup'", [2000000000]);
    await src!.close();
    src = null;
    srcFile = File('${tmp.path}/src.db');

    final merge = MergeService(live);
    final preview = await merge.previewFrom(srcFile);
    expect(preview.newTransactions, 1);
    expect(preview.updatedTransactions, 1);
    expect(preview.newSettings, 0); // 两边种子设置一致

    final result = await merge.applyFrom(srcFile);
    expect(result.newTransactions, 1);
    expect(result.updatedTransactions, 1);
    expect(await ledgerA.countPosted(), 2);
    // tx:dup 现在是来源版本：银行分录 -200。
    final bankLeg = await live.customSelect(
        'SELECT p.amount_minor FROM postings p '
        'JOIN transactions t ON t.id = p.tx_id '
        "WHERE t.id = 'tx:dup' AND p.account_id = 'bank'").getSingle();
    expect(bankLeg.read<String>('amount_minor'), '-20000');
    // 幂等：再合并一次全为零。
    final again = await merge.previewFrom(srcFile);
    expect(again.isEmpty, isTrue);
  });

  test('汇率/估值自然键去重；设置只补缺、本机已有键保留', () async {
    if (!dbAvailable) return;
    await live.customStatement(
        'INSERT INTO fx_rates (base_ccy, quote_ccy, date, rate_n, rate_d, source) '
        "VALUES ('USD', 'CNY', 1893456000, '710', '100', 'manual')");
    await live.customStatement(
        'INSERT INTO valuations (account_id, date, kind, total_value_minor, source) '
        "VALUES ('bank', 1893456000, 'totalValue', '12345', 'manual')");
    await metaA.setSetting('baseCurrency', '"CNY"');

    await src!.customStatement(
        'INSERT INTO fx_rates (base_ccy, quote_ccy, date, rate_n, rate_d, source) '
        "VALUES ('USD', 'CNY', 1893456000, '999', '100', 'manual')"); // 同自然键
    await src!.customStatement(
        'INSERT INTO fx_rates (base_ccy, quote_ccy, date, rate_n, rate_d, source) '
        "VALUES ('EUR', 'CNY', 1893456000, '780', '100', 'manual')"); // 新键
    await src!.customStatement(
        'INSERT INTO valuations (account_id, date, kind, total_value_minor, source) '
        "VALUES ('bank', 1893456000, 'totalValue', '99999', 'manual')"); // 同自然键
    final metaB = MetaRepo(src!);
    await metaB.setSetting('baseCurrency', '"USD"'); // 已有键：本机优先
    await metaB.setSetting('myDeviceKey', '"x"'); // 缺失键：补上
    await src!.close();
    src = null;

    final c = await MergeService(live).applyFrom(File('${tmp.path}/src.db'));
    expect(c.newFxRates, 1);
    expect(c.newValuations, 0);
    expect(c.newSettings, 1);
    expect(await metaA.settingString('baseCurrency'), '"CNY"');
    expect(await metaA.settingString('myDeviceKey'), '"x"');
    final rate = await live.customSelect(
        "SELECT rate_n FROM fx_rates WHERE base_ccy = 'USD'").getSingle();
    expect(rate.read<String>('rate_n'), '710'); // 本机值未被覆盖
  });

  test('计划事件：补缺 + 跳过/覆盖并集（同键金额本机优先）', () async {
    if (!dbAvailable) return;
    await planningA.saveScheduledEvent(ScheduledEvent(
        id: 'evt:rent',
        name: '房租',
        direction: EventDirection.outflow,
        currencyCode: 'CNY',
        cadence: Cadence.monthly,
        anchorDate: DateTime(2026, 1, 5),
        amountMinor: BigInt.from(300000),
        skippedMonthKeys: {'2026-02'},
        amountOverrides: {'2026-03': BigInt.from(310000)}));
    final planningB = PlanningRepo(src!);
    await planningB.saveScheduledEvent(ScheduledEvent(
        id: 'evt:rent',
        name: '房租',
        direction: EventDirection.outflow,
        currencyCode: 'CNY',
        cadence: Cadence.monthly,
        anchorDate: DateTime(2026, 1, 5),
        amountMinor: BigInt.from(300000),
        skippedMonthKeys: {'2026-04'},
        amountOverrides: {
          '2026-03': BigInt.from(999999), // 同键冲突：本机优先
          '2026-05': BigInt.from(320000), // 新键：并入
        }));
    await planningB.saveScheduledEvent(ScheduledEvent(
        id: 'evt:only-b',
        name: '健身房',
        direction: EventDirection.outflow,
        currencyCode: 'CNY',
        cadence: Cadence.monthly,
        anchorDate: DateTime(2026, 1, 20),
        amountMinor: BigInt.from(20000)));
    await src!.close();
    src = null;

    final c = await MergeService(live).applyFrom(File('${tmp.path}/src.db'));
    expect(c.newEvents, 1);
    expect(c.mergedEventSets, 1);
    final events = await planningA.scheduledEvents();
    final rent = events.firstWhere((e) => e.id == 'evt:rent');
    expect(rent.skippedMonthKeys, {'2026-02', '2026-04'});
    expect(rent.amountOverrides['2026-03'], BigInt.from(310000));
    expect(rent.amountOverrides['2026-05'], BigInt.from(320000));
    expect(events.any((e) => e.id == 'evt:only-b'), isTrue);
  });

  test('容器谱系预检 + 解密到明文库', () async {
    if (!dbAvailable) return;
    // 触发来源库文件落盘（NativeDatabase 惰性创建）。
    await src!.customSelect('SELECT 1').getSingle();
    final dek = Uint8List.fromList(List.generate(32, (i) => i));
    final wrongDek = Uint8List.fromList(List.generate(32, (i) => 99 - i));
    final payload = await File('${tmp.path}/src.db').readAsBytes();
    final container = await BackupContainer.create(
        payload: payload,
        dek: dek,
        meta: {
          'app': 'assetscope',
          'schemaVersion': 4,
          'vaultId': MergeService.vaultFingerprint('abcd1234'),
        });

    final good = await MergeService.precheck(
        container: container,
        currentFingerprint: MergeService.vaultFingerprint('abcd1234'),
        currentSchemaVersion: 4,
        dek: dek);
    expect(good.sameLineage, isTrue);
    expect(good.schemaOk, isTrue);

    final foreign = await MergeService.precheck(
        container: container,
        currentFingerprint: MergeService.vaultFingerprint('other'),
        currentSchemaVersion: 4,
        dek: dek);
    expect(foreign.sameLineage, isFalse);

    final future = await MergeService.precheck(
        container: container,
        currentFingerprint: MergeService.vaultFingerprint('abcd1234'),
        currentSchemaVersion: 3,
        dek: dek);
    expect(future.schemaOk, isFalse); // 备份来自更新版本

    // 错误 DEK：解密失败（AEAD 认证）。
    await expectLater(
        MergeService.precheck(
            container: container,
            currentFingerprint: 'x',
            currentSchemaVersion: 4,
            dek: wrongDek),
        throwsA(anything));

    final plain =
        await MergeService.decryptToPlain(container: container, workDir: tmp, dek: dek);
    expect(await plain.exists(), isTrue);
    final probe = AppDatabase(NativeDatabase(plain));
    expect(await probe.customSelect('SELECT COUNT(*) n FROM accounts').getSingle()
        .then((r) => r.read<int>('n') > 0), isTrue);
    await probe.close();
    await plain.delete();

    // 指纹确定性：同 DEK 同指纹，不同 DEK 不同指纹。
    expect(MergeService.vaultFingerprint('aa'),
        equals(MergeService.vaultFingerprint('aa')));
    expect(MergeService.vaultFingerprint('aa'),
        isNot(equals(MergeService.vaultFingerprint('bb'))));
  });
}
