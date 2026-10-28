import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:fast_gbk/fast_gbk.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:assetscope/data/app_database.dart';
import 'package:assetscope/data/repositories/accounts_repo.dart';
import 'package:assetscope/data/repositories/ledger_repo.dart';
import 'package:assetscope/data/repositories/meta_repo.dart';
import 'package:assetscope/domain/ledger/account.dart';
import 'package:assetscope/domain/ledger/transaction.dart';
import 'package:assetscope/domain/money/fx_rate.dart';
import 'package:assetscope/domain/valuation/valuation.dart';
import 'package:assetscope/services/import_service.dart';
import 'package:assetscope/services/stats_service.dart';

/// v0.8 性能与缓存：数据指纹失效、统计记忆化、SQL 聚合（含超大金额
/// 兜底）、热路径索引、isolate 导入解析、万级流水性能冒烟。
/// 运行需要宿主可加载 sqlite3；不可用时跳过。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late AccountsRepo accounts;
  late LedgerRepo ledger;
  late MetaRepo meta;
  late StatsService stats;

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
  });

  tearDown(() async {
    if (dbAvailable) await db.close();
  });

  Future<void> seedOne() async {
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
  }

  group('数据指纹', () {
    test('无写入时稳定；各类写入都使其变化', () async {
      if (!dbAvailable) {
        markTestSkipped('宿主环境无可用 sqlite3，跳过数据层测试');
        return;
      }
      final f0 = await meta.dataFingerprint();
      expect(await meta.dataFingerprint(), f0);

      await seedOne();
      final f1 = await meta.dataFingerprint();
      expect(f1 == f0, isFalse, reason: '过账改变指纹');

      // 作废
      final txs = await ledger.list(includeVoided: true);
      await ledger.voidTransaction(txs.first.id);
      expect(await meta.dataFingerprint() == f1, isFalse, reason: '作废改变指纹');

      // 估值
      final f2 = await meta.dataFingerprint();
      await meta.saveValuation(ValuationRecord(
          accountId: 'bank',
          date: DateTime(2026, 5, 1),
          kind: ValuationKind.totalValue,
          totalValueMinor: BigInt.from(123),
          source: 'manual'));
      expect(await meta.dataFingerprint() == f2, isFalse, reason: '估值改变指纹');

      // 汇率
      final f3 = await meta.dataFingerprint();
      await meta.saveFxRate(
          baseCcy: 'USD',
          quoteCcy: 'CNY',
          date: DateTime(2026, 5, 1),
          rate: Rational.parseDecimal('7.2'));
      expect(await meta.dataFingerprint() == f3, isFalse, reason: '汇率改变指纹');

      // 设置
      final f4 = await meta.dataFingerprint();
      await meta.setSetting('anyKey', 'v');
      expect(await meta.dataFingerprint() == f4, isFalse, reason: '设置改变指纹');
    });

    test('账户口径变化（archive）改变指纹', () async {
      if (!dbAvailable) {
        markTestSkipped('宿主环境无可用 sqlite3，跳过数据层测试');
        return;
      }
      await seedOne();
      final f0 = await meta.dataFingerprint();
      await accounts.archive('bank', archived: true);
      expect(await meta.dataFingerprint() == f0, isFalse);
    });
  });

  group('统计记忆化', () {
    test('同版本重复调用命中缓存（identical）；写入后失效且结果更新', () async {
      if (!dbAvailable) {
        markTestSkipped('宿主环境无可用 sqlite3，跳过数据层测试');
        return;
      }
      await seedOne();
      final now = DateTime(2026, 6, 15);

      final r1 = await stats.monthReport(2026, 3);
      final r2 = await stats.monthReport(2026, 3);
      expect(identical(r1, r2), isTrue);
      expect(stats.cachedMonthReportCount, 1);

      final n1 = await stats.netWorthAt(DateTime(2026, 6, 1));
      final n2 = await stats.netWorthAt(DateTime(2026, 6, 1));
      expect(identical(n1, n2), isTrue);

      final s1 = await stats.netWorthSeries(6, now: now);
      final s2 = await stats.netWorthSeries(6, now: now);
      expect(identical(s1, s2), isTrue);

      // 新过账 → 指纹变化 → 缓存整体失效，结果反映新数据。
      final bank = await accounts.byId('bank');
      await ledger.post(TxBuilders.income(
          destAsset: bank!,
          incomeCategory: (await accounts.byId('cat:i:salary'))!,
          amountMinor: BigInt.from(500000),
          date: DateTime(2026, 3, 10)));
      final r3 = await stats.monthReport(2026, 3);
      expect(identical(r3, r1), isFalse);
      // 收入分类分录为贷方（负号），与既有月报口径一致。
      expect(r3.incomeByCategory['cat:i:salary'], BigInt.from(-500000));
      expect(stats.cachedMonthReportCount, 1, reason: '失效后只重算请求的月份');
    });
  });

  group('SQL 聚合', () {
    test('正负金额混合的余额与手算一致', () async {
      if (!dbAvailable) {
        markTestSkipped('宿主环境无可用 sqlite3，跳过数据层测试');
        return;
      }
      await seedOne();
      final bank = await accounts.byId('bank');
      await ledger.post(TxBuilders.expense(
          payFrom: bank!,
          expenseCategory: (await accounts.byId('cat:e:dining'))!,
          amountMinor: BigInt.from(2550),
          date: DateTime(2026, 2, 3)));
      await ledger.post(TxBuilders.income(
          destAsset: bank,
          incomeCategory: (await accounts.byId('cat:i:salary'))!,
          amountMinor: BigInt.from(8000),
          date: DateTime(2026, 2, 5)));
      final bal =
          await ledger.moneyBalancesAt(DateTime(2026, 3, 1, 23, 59, 59));
      expect(bal['bank'], BigInt.from(1000000 - 2550 + 8000));
    });

    test('超出 int64 的金额自动回退精确折叠', () async {
      if (!dbAvailable) {
        markTestSkipped('宿主环境无可用 sqlite3，跳过数据层测试');
        return;
      }
      await seedOne();
      final bank = await accounts.byId('bank');
      final huge =
          BigInt.from(10).pow(19); // 19+ 位，超 int64 → SQL 快路径拒绝
      await ledger.post(TxBuilders.income(
          destAsset: bank!,
          incomeCategory: (await accounts.byId('cat:i:salary'))!,
          amountMinor: huge,
          date: DateTime(2026, 2, 5)));
      final bal =
          await ledger.moneyBalancesAt(DateTime(2026, 3, 1, 23, 59, 59));
      expect(bal['bank'], BigInt.from(1000000) + huge);
    });

    test('热路径索引存在（schema v3）', () async {
      if (!dbAvailable) {
        markTestSkipped('宿主环境无可用 sqlite3，跳过数据层测试');
        return;
      }
      final rows = await db.customSelect(
          "SELECT name FROM sqlite_master WHERE type='index'").get();
      final names = rows.map((r) => r.read<String>('name')).toSet();
      expect(names, containsAll(
          ['idx_transactions_date', 'idx_postings_tx', 'idx_postings_account']));
    });
  });

  group('isolate 导入解析', () {
    const csvText = 'date,type,amount,counterparty,note\n'
        '2026-01-05,支出,25.00,超市,买菜\n'
        '2026-01-06,收入,5000.00,公司,工资\n';

    ImportService service() => ImportService(accounts, ledger, meta);

    test('UTF-8：isolate 结果与同步解析一致', () async {
      final svc = service();
      final bytes = Uint8List.fromList(utf8.encode(csvText));
      final sync = svc.parseAuto(csvText, genericParserId: 't.csv');
      final iso = await svc.decodeAndParseAutoIsolated(bytes,
          genericParserId: 't.csv');
      expect(iso.rows.length, sync.rows.length);
      expect(iso.rows.length, 2);
      expect(iso.rows.first.amountMinor, sync.rows.first.amountMinor);
      expect(iso.rows.first.direction, sync.rows.first.direction);
      expect(iso.rows[1].direction, isTrue);
    });

    test('GBK 编码同样可用', () async {
      final svc = service();
      final bytes = Uint8List.fromList(gbk.encode(csvText));
      final iso = await svc.decodeAndParseAutoIsolated(bytes,
          genericParserId: 't.csv');
      expect(iso.rows.length, 2);
      expect(iso.rows.first.counterparty, '超市');
    });
  });

  group('万级流水性能冒烟', () {
    test('10k 交易：冷算后暖调用显著提速', () async {
      if (!dbAvailable) {
        markTestSkipped('宿主环境无可用 sqlite3，跳过数据层测试');
        return;
      }
      // 批量直插 10k 交易 × 2 分录（绕过逐笔校验，纯性能种子）。
      const n = 10000;
      final txRows = <TransactionsCompanion>[];
      final poRows = <PostingsCompanion>[];
      for (var i = 0; i < n; i++) {
        final id = 'perf:$i';
        final date = DateTime(2024, 10, 1).add(Duration(days: i % 730));
        final amount = BigInt.from(100 + (i % 977));
        txRows.add(TransactionsCompanion.insert(id: id, date: date, kind: 'expense'));
        poRows.add(PostingsCompanion.insert(
            txId: id,
            accountId: 'cat:e:dining',
            amountMinor: Value(amount)));
        poRows.add(PostingsCompanion.insert(
            txId: id, accountId: 'sys:equity:opening', amountMinor: Value(-amount)));
      }
      await db.batch((b) {
        b.insertAll(db.transactions, txRows);
        b.insertAll(db.postings, poRows);
      });

      final now = DateTime(2026, 9, 30);
      final swCold = Stopwatch()..start();
      final series = await stats.netWorthSeries(12, now: now);
      for (var m = 1; m <= 6; m++) {
        await stats.monthReport(2026, m);
      }
      swCold.stop();

      final swWarm = Stopwatch()..start();
      final series2 = await stats.netWorthSeries(12, now: now);
      for (var m = 1; m <= 6; m++) {
        await stats.monthReport(2026, m);
      }
      swWarm.stop();

      expect(identical(series, series2), isTrue);
      expect(swWarm.elapsed < swCold.elapsed, isTrue,
          reason: '暖调用应明显快于冷算（cold=${swCold.elapsedMilliseconds}ms '
              'warm=${swWarm.elapsedMilliseconds}ms）');
      // eslint-disable-next-line avoid_print
      // ignore: avoid_print
      print('10k 流水：冷算 ${swCold.elapsedMilliseconds}ms，'
          '暖调用 ${swWarm.elapsedMilliseconds}ms');
    });
  });
}
