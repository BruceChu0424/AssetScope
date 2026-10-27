import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';

import 'package:assetscope/data/app_database.dart';
import 'package:assetscope/data/repositories/accounts_repo.dart';
import 'package:assetscope/data/repositories/ledger_repo.dart';
import 'package:assetscope/domain/ledger/account.dart';
import 'package:assetscope/domain/ledger/ledger_math.dart';
import 'package:assetscope/domain/ledger/posting.dart';
import 'package:assetscope/domain/ledger/transaction.dart';

/// 数据层 roundtrip：过账 → 查询 → 余额重算 → 幂等外部 ID。
/// 运行需要宿主可加载 sqlite3（build hook 或系统库）；不可用时跳过。
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
    } catch (e) {
      dbAvailable = false;
      return;
    }
    accounts = AccountsRepo(db);
    ledger = LedgerRepo(db);
    // 基线种子（系统账户 + 分类）已随 onCreate 注入
  });

  tearDown(() async {
    if (dbAvailable) await db.close();
  });

  test('过账后可查询、余额正确、作废生效', () async {
    if (!dbAvailable) {
      markTestSkipped('宿主环境无可用 sqlite3，跳过数据层测试');
      return;
    }
    final bank = Account(
        id: 'bank',
        name: '招行',
        type: AccountType.asset,
        assetSubtype: AssetSubtype.bank,
        currencyCode: 'CNY');
    final dining = Account(
        id: 'cat:e:dining', name: '餐饮', type: AccountType.expense, currencyCode: 'CNY');
    final salary = Account(
        id: 'cat:i:salary', name: '工资', type: AccountType.income, currencyCode: 'CNY');

    await ledger.post(TxBuilders.openingBalance(
        assetAccount: bank, amountMinor: BigInt.from(1000000), date: DateTime(2026, 1, 1)));
    await ledger.post(TxBuilders.income(
        destAsset: bank,
        incomeCategory: salary,
        amountMinor: BigInt.from(50000),
        date: DateTime(2026, 5, 1)));
    final expTx = await ledger.post(TxBuilders.expense(
        payFrom: bank,
        expenseCategory: dining,
        amountMinor: BigInt.from(3500),
        date: DateTime(2026, 5, 2)));

    final balances = await ledger.moneyBalancesAt(DateTime(2026, 5, 31));
    expect(balances['bank'],
        BigInt.from(1000000) + BigInt.from(50000) - BigInt.from(3500));

    // 历史某日余额（不含 5 月）
    final jan = await ledger.moneyBalancesAt(DateTime(2026, 1, 31));
    expect(jan['bank'], BigInt.from(1000000));

    // 月度分类合计
    final sums = await ledger.postingSumsBetween(DateTime(2026, 5, 1), DateTime(2026, 5, 31));
    expect(sums['cat:e:dining'], BigInt.from(3500));
    expect(sums['cat:i:salary'], -BigInt.from(50000));

    // 作废后余额恢复
    await ledger.voidTransaction(expTx.id);
    final after = await ledger.moneyBalancesAt(DateTime(2026, 5, 31));
    expect(after['bank'], BigInt.from(1050000));
  });

  test('外部 ID 幂等：同一导入行第二次被拒', () async {
    if (!dbAvailable) {
      markTestSkipped('宿主环境无可用 sqlite3，跳过数据层测试');
      return;
    }
    final bank = Account(
        id: 'bank2',
        name: '支付宝',
        type: AccountType.asset,
        assetSubtype: AssetSubtype.alipay,
        currencyCode: 'CNY');
    final dining = await accounts.byId('cat:e:dining');
    expect(dining, isNotNull, reason: '种子分类应存在');

    const extId = 'alipay|acc|row-42';
    await ledger.post(TxBuilders.expense(
        payFrom: bank,
        expenseCategory: dining!,
        amountMinor: BigInt.from(1999),
        date: DateTime(2026, 5, 3),
        externalId: extId,
        source: TxSource.importAlipay));
    expect(await ledger.externalIdExists(extId), isTrue);
    expect(await ledger.externalIdExists('alipay|acc|row-43'), isFalse);
  });

  test('守恒违规在过账入口被拒绝', () async {
    if (!dbAvailable) {
      markTestSkipped('宿主环境无可用 sqlite3，跳过数据层测试');
      return;
    }
    // 手写不守恒分录（借贷差 10 分）绕过构造器也应被仓储拒绝
    final draft = TransactionDraft(
      date: DateTime(2026, 5, 1),
      kind: TxKind.expense,
      postings: [
        Posting.money(
            accountId: 'cat:e:dining',
            amountMinor: BigInt.from(100),
            currencyCode: 'CNY'),
        Posting.money(
            accountId: 'bankX',
            amountMinor: -BigInt.from(90),
            currencyCode: 'CNY'),
      ],
    );
    expect(LedgerMath.checkConservation(draft.postings), isNotNull);
    await expectLater(ledger.post(draft), throwsStateError);
  });
}
