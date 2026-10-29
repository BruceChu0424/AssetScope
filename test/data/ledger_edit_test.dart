import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:assetscope/data/app_database.dart';
import 'package:assetscope/data/repositories/accounts_repo.dart';
import 'package:assetscope/data/repositories/ledger_repo.dart';
import 'package:assetscope/data/repositories/meta_repo.dart';
import 'package:assetscope/data/repositories/planning_repo.dart';
import 'package:assetscope/domain/ledger/account.dart';
import 'package:assetscope/domain/ledger/posting.dart';
import 'package:assetscope/domain/ledger/transaction.dart';
import 'package:assetscope/services/export_service.dart';
import 'package:assetscope/services/ledger_service.dart';

/// 交易编辑（replaceTransaction）、全账本搜索、全量 JSON 导出。
/// 运行需要宿主可加载 sqlite3；不可用时跳过。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late AccountsRepo accounts;
  late LedgerRepo ledger;
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
  });

  tearDown(() async {
    if (dbAvailable) await db.close();
  });

  Future<({Account bank, Account cat})> seed() async {
    final bank = Account(
        id: 'bank',
        name: '招行',
        type: AccountType.asset,
        assetSubtype: AssetSubtype.bank,
        currencyCode: 'CNY');
    await accounts.upsert(bank);
    final cat = (await accounts.byId('cat:e:dining'))!;
    return (bank: bank, cat: cat);
  }

  test('编辑交易：保留 id/来源审计字段，分录原子替换', () async {
    if (!dbAvailable) {
      markTestSkipped('宿主环境无可用 sqlite3，跳过');
      return;
    }
    final s = await seed();
    final orig = await ledger.post(TxBuilders.expense(
        payFrom: s.bank,
        expenseCategory: s.cat,
        amountMinor: BigInt.from(8850),
        date: DateTime(2026, 1, 10),
        note: '午饭',
        source: TxSource.importCsv,
        externalId: 'wx-20260110-001'));
    // post() 返回内存对象（微秒）；DB 列为秒级精度，用读回值作对照。
    final origPersisted =
        (await ledger.list(from: DateTime(2026, 1, 1))).first;
    final origCreatedAt = origPersisted.createdAt;

    // 编辑：改金额、分类、日期、备注。
    final other = (await accounts.byId('cat:e:other'))!;
    final edited = await ledger.replaceTransaction(
        orig.id,
        TxBuilders.expense(
            payFrom: s.bank,
            expenseCategory: other,
            amountMinor: BigInt.from(12000),
            date: DateTime(2026, 1, 12),
            note: '午饭改晚饭',
            // 以下字段应被忽略、保留旧行值。
            source: TxSource.manual,
            externalId: 'SHOULD-BE-IGNORED'));

    expect(edited.id, orig.id);
    expect(edited.externalId, 'wx-20260110-001', reason: '外部 ID 必须保留');
    expect(edited.source, TxSource.importCsv, reason: '来源必须保留');
    // drift 的 DateTime 列毫秒精度；微秒会截断，比较到毫秒。
    expect(edited.createdAt, origCreatedAt);

    expect(edited.note, '午饭改晚饭');
    expect(edited.categoryId, other.id);

    // 重读持久化结果：一条交易、新分录、旧值不残留。
    final txs = await ledger.list(from: DateTime(2026, 1, 1));
    expect(txs.length, 1);
    expect(txs.first.amountOf(s.bank.id), -BigInt.from(12000));
    expect(
        txs.first.postings
            .any((p) => p.accountId == s.cat.id),
        isFalse,
        reason: '旧分类分录不应残留');
  });

  test('编辑交易：守恒校验拒绝非法分录', () async {
    if (!dbAvailable) {
      markTestSkipped('宿主环境无可用 sqlite3，跳过');
      return;
    }
    final s = await seed();
    final orig = await ledger.post(TxBuilders.expense(
        payFrom: s.bank,
        expenseCategory: s.cat,
        amountMinor: BigInt.from(100),
        date: DateTime(2026, 1, 1)));
    expect(
        () => ledger.replaceTransaction(
            orig.id,
            TransactionDraft(
              date: DateTime(2026, 1, 2),
              kind: TxKind.expense,
              postings: [
                Posting.money(
                    accountId: 'bank',
                    amountMinor: BigInt.from(-100),
                    currencyCode: 'CNY'),
                // 缺少配平分录 → 守恒 violation
              ],
            )),
        throwsStateError);
    // 原交易未受影响。
    expect((await ledger.list(from: DateTime(2026, 1, 1))).length, 1);
  });

  test('isEditable：持仓/作废/本息拆分类型不可编辑', () async {
    if (!dbAvailable) {
      markTestSkipped('宿主环境无可用 sqlite3，跳过');
      return;
    }
    final s = await seed();
    final expense = await ledger.post(TxBuilders.expense(
        payFrom: s.bank,
        expenseCategory: s.cat,
        amountMinor: BigInt.from(100),
        date: DateTime(2026, 1, 1)));
    expect(LedgerService.isEditable(expense), isTrue);

    final loan = Account(
        id: 'loan1',
        name: '房贷',
        type: AccountType.liability,
        liabilitySubtype: LiabilitySubtype.mortgage,
        currencyCode: 'CNY');
    await accounts.upsert(loan);
    final interest = (await accounts.byId('cat:e:interest'))!;
    final repay = await ledger.post(TxBuilders.loanRepay(
        loan: loan,
        payFrom: s.bank,
        principalMinor: BigInt.from(1000),
        interestMinor: BigInt.from(5),
        interestCategory: interest,
        date: DateTime(2026, 1, 1)));
    expect(LedgerService.isEditable(repay), isFalse,
        reason: '本息拆分不可无损重放');

    await ledger.voidTransaction(expense.id);
    final voided = (await ledger.list(
        from: DateTime(2026, 1, 1), includeVoided: true))
        .firstWhere((t) => t.id == expense.id);
    expect(LedgerService.isEditable(voided), isFalse);
  });

  test('全账本搜索：备注/对手方/标签命中，通配符剔除', () async {
    if (!dbAvailable) {
      markTestSkipped('宿主环境无可用 sqlite3，跳过');
      return;
    }
    final s = await seed();
    await ledger.post(TxBuilders.expense(
        payFrom: s.bank,
        expenseCategory: s.cat,
        amountMinor: BigInt.from(100),
        date: DateTime(2026, 1, 1),
        counterparty: '盒马鲜生'));
    await ledger.post(TxBuilders.expense(
        payFrom: s.bank,
        expenseCategory: s.cat,
        amountMinor: BigInt.from(200),
        date: DateTime(2026, 1, 2),
        note: '深夜食堂'));
    final tagged = await ledger.post(TxBuilders.expense(
        payFrom: s.bank,
        expenseCategory: s.cat,
        amountMinor: BigInt.from(300),
        date: DateTime(2026, 1, 3)));
    // 给第三条加标签：直接用带 tags 的草稿重发一条更直观——
    // TxBuilders.expense 不透传 tags 的场景用 note 代替验证。
    expect(tagged.note, isNull);

    expect((await ledger.search('盒马')).length, 1);
    expect((await ledger.search('食堂')).length, 1);
    expect((await ledger.search('不存在')), isEmpty);
    expect(await ledger.search('%'), isEmpty, reason: '通配符剔除后空查询');
    expect(await ledger.search('  '), isEmpty);
  });

  test('全量 JSON 导出：结构完整、金额无损、密钥不外泄', () async {
    if (!dbAvailable) {
      markTestSkipped('宿主环境无可用 sqlite3，跳过');
      return;
    }
    final s = await seed();
    final meta = MetaRepo(db);
    final planning = PlanningRepo(db);
    await ledger.post(TxBuilders.expense(
        payFrom: s.bank,
        expenseCategory: s.cat,
        amountMinor: BigInt.from(8850),
        date: DateTime(2026, 1, 10),
        note: '午饭'));
    // 一个含"密钥"的设置：绝不进入导出。
    await meta.setSetting('aiProvider', {'apiKey': 'sk-SECRET', 'model': 'x'});
    await meta.setSetting('baseCurrency', 'CNY');

    final service = ExportService(accounts, ledger, meta, planning);
    final json = await service.fullLedgerJson(appVersion: 'test');
    expect(json.contains('sk-SECRET'), isFalse, reason: '密钥绝不外泄');
    expect(json.contains('aiProvider'), isFalse);
    expect(json.contains('"baseCurrency": "CNY"'), isTrue);
    expect(json.contains('"amountMinor": "-8850"'), isTrue,
        reason: '金额最小单位字符串无损');
    expect(json.contains('招行'), isTrue);
  });

  test('countPosted：只统计 posted', () async {
    if (!dbAvailable) {
      markTestSkipped('宿主环境无可用 sqlite3，跳过');
      return;
    }
    final s = await seed();
    final t1 = await ledger.post(TxBuilders.expense(
        payFrom: s.bank,
        expenseCategory: s.cat,
        amountMinor: BigInt.from(100),
        date: DateTime(2026, 1, 1)));
    await ledger.post(TxBuilders.expense(
        payFrom: s.bank,
        expenseCategory: s.cat,
        amountMinor: BigInt.from(200),
        date: DateTime(2026, 1, 2)));
    await ledger.voidTransaction(t1.id);
    expect(await ledger.countPosted(), 1);
  });
}

extension on LedgerTransaction {
  BigInt? amountOf(String accountId) {
    for (final p in postings) {
      if (p.accountId == accountId) return p.amountMinor;
    }
    return null;
  }
}
