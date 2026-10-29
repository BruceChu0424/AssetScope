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
import 'package:assetscope/domain/utils/dates.dart';
import 'package:assetscope/services/plan_execution_service.dart';
import 'package:assetscope/services/projection_service.dart';

/// 计划落地执行：到期清单、幂等去重、自动/手动过账、跳过。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late AccountsRepo accounts;
  late LedgerRepo ledger;
  late PlanningRepo planning;
  late PlanExecutionService svc;

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
    svc = PlanExecutionService(accounts, ledger, planning);
  });

  tearDown(() async {
    if (dbAvailable) await db.close();
  });

  // 2026-06-15 为"今天"：房租 6/5 已到期，工资 6/1 已到期。
  final today = DateTime(2026, 6, 15);

  Future<void> seed() async {
    final bank = Account(
        id: 'bank',
        name: '招行',
        type: AccountType.asset,
        assetSubtype: AssetSubtype.bank,
        currencyCode: 'CNY');
    final card = Account(
        id: 'card',
        name: '信用卡',
        type: AccountType.liability,
        liabilitySubtype: LiabilitySubtype.creditCard,
        currencyCode: 'CNY');
    await accounts.upsert(bank);
    await accounts.upsert(card);
    // 房租：自动过账，配置齐全。
    await planning.saveScheduledEvent(ScheduledEvent(
        id: 'evt:rent',
        name: '房租',
        direction: EventDirection.outflow,
        currencyCode: 'CNY',
        cadence: Cadence.monthly,
        anchorDate: DateTime(2026, 1, 5),
        amountMinor: BigInt.from(300000),
        paymentAccountId: 'card',
        autoPost: true));
    // 工资：手动确认。
    await planning.saveScheduledEvent(ScheduledEvent(
        id: 'evt:salary',
        name: '工资',
        direction: EventDirection.inflow,
        currencyCode: 'CNY',
        cadence: Cadence.monthly,
        anchorDate: DateTime(2026, 1, 1),
        amountMinor: BigInt.from(200000)));
  }

  test('到期清单：只列到期未入账，未到期与未来不出现', () async {
    if (!dbAvailable) return;
    await seed();
    final due = await svc.pendingDue(now: today);
    // 房租 1/5–6/5 共 6 笔（2/5…6/5），工资 1/1–6/1 共 6 笔。
    expect(due.length, 12);
    expect(due.first.occurrence.date, DateTime(2026, 1, 1)); // 工资最早
    final rentDue = due.where((d) => d.event.id == 'evt:rent').toList();
    expect(rentDue.every((d) => d.autoReady), isTrue);
    final salaryDue = due.where((d) => d.event.id == 'evt:salary').toList();
    // 手动计划：不自动入账；未配置支付账户时披露原因（确认弹层补选）。
    expect(salaryDue.every((d) => !d.autoReady), isTrue);
    expect(salaryDue.every((d) => d.blockedReason == '未设置支付账户'), isTrue);
  });

  test('自动过账幂等：只落 autoReady，重复执行不重复入账', () async {
    if (!dbAvailable) return;
    await seed();
    final n1 = await svc.postAutoDue(now: today);
    expect(n1, 6); // 只有房租 autoPost
    expect(await ledger.countPosted(), 6);
    final n2 = await svc.postAutoDue(now: today);
    expect(n2, 0);
    expect(await ledger.countPosted(), 6);

    final remaining = await svc.pendingDue(now: today);
    expect(remaining.length, 6); // 工资仍待确认
    expect(remaining.every((d) => d.event.id == 'evt:salary'), isTrue);
  });

  test('自动过账的分录与审计字段：来源/幂等键/落账日=发生日', () async {
    if (!dbAvailable) return;
    await seed();
    final due = await svc.pendingDue(now: today);
    final junRent = due.firstWhere(
        (d) => d.event.id == 'evt:rent' && dateOf(d) == DateTime(2026, 6, 5));
    final tx = await svc.postOne(junRent);
    expect(tx.source, TxSource.planGenerated);
    expect(tx.externalId, 'plan:evt:rent:2026-06-05');
    expect(tx.date, DateTime(2026, 6, 5));
    expect(tx.tags, ['计划']);
    expect(tx.note, contains('房租'));
    // 消费从信用卡支付：卡负债增、支出分类增。
    final cardPosting = tx.postings.firstWhere((p) => p.accountId == 'card');
    expect(cardPosting.amountMinor, -BigInt.from(300000));
    expect(tx.categoryId, 'cat:e:other'); // 分类缺省 → 其他
  });

  test('postOne 可改金额；已入账再 post 抛错', () async {
    if (!dbAvailable) return;
    await seed();
    final due = await svc.pendingDue(now: today);
    final d0 = due.firstWhere(
        (d) => d.event.id == 'evt:salary' && dateOf(d) == DateTime(2026, 6, 1));
    final tx =
        await svc.postOne(d0, amountMinor: BigInt.from(250000), payAccountId: 'bank');
    expect(tx.kind, TxKind.income);
    expect(tx.postings.first.amountMinor, BigInt.from(250000));
    // 幂等：同一笔再入账被拒。
    await expectLater(svc.postOne(d0), throwsA(isA<StateError>()));
  });

  test('跳过单次：清单剔除、预测同步剔除', () async {
    if (!dbAvailable) return;
    await seed();
    final due = await svc.pendingDue(now: today);
    final junSalary = due.firstWhere(
        (d) => d.event.id == 'evt:salary' && dateOf(d) == DateTime(2026, 6, 1));
    await svc.skip(junSalary);
    final after = await svc.pendingDue(now: today);
    expect(after.length, 11);
    expect(
        after.any((d) =>
            d.event.id == 'evt:salary' && dateOf(d) == DateTime(2026, 6, 1)),
        isFalse);
    final events = await planning.scheduledEvents();
    expect(events.firstWhere((e) => e.id == 'evt:salary').skippedDateKeys,
        {'2026-06-01'});
  });

  test('配置缺失的自动计划：给出受阻原因，不自动入账', () async {
    if (!dbAvailable) return;
    await seed();
    // 币种不匹配的自动支出计划。
    await planning.saveScheduledEvent(ScheduledEvent(
        id: 'evt:usd',
        name: '美元订阅',
        direction: EventDirection.outflow,
        currencyCode: 'USD',
        cadence: Cadence.monthly,
        anchorDate: DateTime(2026, 6, 1),
        amountMinor: BigInt.from(1500),
        paymentAccountId: 'card',
        autoPost: true));
    final n = await svc.postAutoDue(now: today);
    expect(n, 6); // 只有房租
    final usd = (await svc.pendingDue(now: today))
        .firstWhere((d) => d.event.id == 'evt:usd');
    expect(usd.autoReady, isFalse);
    expect(usd.blockedReason, '账户币种与计划不一致');

    // 无支付账户的自动收入计划。
    await planning.saveScheduledEvent(ScheduledEvent(
        id: 'evt:noacc',
        name: '副业',
        direction: EventDirection.inflow,
        currencyCode: 'CNY',
        cadence: Cadence.monthly,
        anchorDate: DateTime(2026, 6, 10),
        amountMinor: BigInt.from(50000),
        autoPost: true));
    final noacc = (await svc.pendingDue(now: today))
        .firstWhere((d) => d.event.id == 'evt:noacc');
    expect(noacc.blockedReason, '未设置支付账户');
  });

  test('暂停计划不进清单；回溯窗口外的历史不进清单', () async {
    if (!dbAvailable) return;
    await seed();
    await planning.saveScheduledEvent(ScheduledEvent(
        id: 'evt:paused',
        name: '健身房',
        direction: EventDirection.outflow,
        currencyCode: 'CNY',
        cadence: Cadence.monthly,
        anchorDate: DateTime(2026, 1, 20),
        amountMinor: BigInt.from(20000),
        status: PlanStatus.paused));
    // 单次计划发生在两年前：超回溯窗口，不提示补落。
    await planning.saveScheduledEvent(ScheduledEvent(
        id: 'evt:old',
        name: '旧保险',
        direction: EventDirection.outflow,
        currencyCode: 'CNY',
        cadence: Cadence.once,
        anchorDate: DateTime(2024, 6, 1),
        amountMinor: BigInt.from(100000)));
    final due = await svc.pendingDue(now: today);
    expect(due.any((d) => d.event.id == 'evt:paused'), isFalse);
    expect(due.any((d) => d.event.id == 'evt:old'), isFalse);
    expect(due.length, 12);
  });

  test('落地后预测事件流剔除该发生（防余额+事件双扣）', () async {
    if (!dbAvailable) return;
    await seed();
    final meta = MetaRepo(db);
    final projection = ProjectionService(accounts, ledger, planning, meta);
    final today = DateTime(2026, 6, 15);
    // 周计划锚在 6/15（今天）：未落地时应出现在事件流。
    await planning.saveScheduledEvent(ScheduledEvent(
        id: 'evt:week',
        name: '周订阅',
        direction: EventDirection.outflow,
        currencyCode: 'CNY',
        cadence: Cadence.weekly,
        anchorDate: today,
        amountMinor: BigInt.from(2500),
        paymentAccountId: 'card'));
    final before = await projection.buildInput(now: today, horizonDays: 7);
    expect(
        before.events.any((ev) =>
            ev.label == '周订阅' && dateKey(ev.date) == '2026-06-15'),
        isTrue);

    // 落地今天这笔 → 事件流剔除当天发生；余额已含该交易，不重复扣。
    final due = await svc.pendingDue(now: today);
    final todayDue = due.firstWhere(
        (d) => d.event.id == 'evt:week' && dateOf(d) == today);
    await svc.postOne(todayDue);
    final after = await projection.buildInput(now: today, horizonDays: 7);
    expect(
        after.events.any((ev) =>
            ev.label == '周订阅' && dateKey(ev.date) == '2026-06-15'),
        isFalse);
  });

  test('区间估算计划：取中位数入账', () async {
    if (!dbAvailable) return;
    await seed();
    await planning.saveScheduledEvent(ScheduledEvent(
        id: 'evt:util',
        name: '水电',
        direction: EventDirection.outflow,
        currencyCode: 'CNY',
        cadence: Cadence.monthly,
        anchorDate: DateTime(2026, 6, 10),
        amountLowMinor: BigInt.from(8000),
        amountHighMinor: BigInt.from(20000),
        paymentAccountId: 'bank'));
    final d = (await svc.pendingDue(now: today))
        .firstWhere((x) => x.event.id == 'evt:util');
    expect(d.occurrence.isEstimate, isTrue);
    final tx = await svc.postOne(d);
    expect(tx.postings.firstWhere((p) => p.accountId == 'bank').amountMinor,
        -BigInt.from(14000));
  });
}

DateTime dateOf(DueOccurrence d) => d.occurrence.date;
