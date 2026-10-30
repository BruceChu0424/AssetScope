import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';

import 'package:assetscope/data/app_database.dart';
import 'package:assetscope/data/repositories/accounts_repo.dart';
import 'package:assetscope/data/repositories/meta_repo.dart';
import 'package:assetscope/domain/ledger/account.dart';
import 'package:assetscope/domain/money/fx_rate.dart';
import 'package:assetscope/domain/valuation/valuation.dart';
import 'package:assetscope/services/ai/ai_chat.dart';
import 'package:assetscope/services/ai/ai_valuation_service.dart';

/// AI 资产估值：解析、目标筛选、每日门控、当日人工纠正优先。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const cfg = AiConfig(
    presetId: 'glm',
    baseUrl: 'https://open.bigmodel.cn/api/paas/v4',
    apiKey: 'test-key',
    model: 'glm-4.7-flash',
    enableWebSearch: true,
  );

  group('parseEstimate', () {
    test('正常解析：金额/区间/置信度/来源/依据', () {
      final est = parseEstimate('''
        {"found":true,"value":"2850000","currency":"cny",
         "low":"2800000","high":"2900000","as_of":"2026-10-30",
         "confidence":75,"sources":["https://ke.com/1","https://lianjia.com/2"],
         "rationale":"该小区近3月成交均价约 5.1 万/㎡"}''', '测试小区');
      expect(est.valueMinor, BigInt.from(285000000));
      expect(est.currency, 'CNY');
      expect(est.low!.n, BigInt.from(2800000));
      expect(est.high!.n, BigInt.from(2900000));
      expect(est.asOf, DateTime(2026, 10, 30));
      expect(est.confidence, 75);
      expect(est.sources.length, 2);
      expect(est.rationale, contains('成交均价'));
    });

    test('markdown 围栏包裹也能解出', () {
      final est = parseEstimate(
        '```json\n{"found":true,"value":"12345.67","currency":"CNY"}\n```',
        'q',
      );
      expect(est.valueMinor, BigInt.from(1234567));
    });

    test('found=false 抛 FormatException 且带原因', () {
      expect(
        () => parseEstimate('{"found":false,"reason":"查无该小区"}', 'q'),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('查无该小区'),
          ),
        ),
      );
    });

    test('value 非正数/缺失抛错', () {
      expect(
        () => parseEstimate('{"found":true,"value":"0","currency":"CNY"}', 'q'),
        throwsFormatException,
      );
      expect(
        () => parseEstimate('{"found":true,"currency":"CNY"}', 'q'),
        throwsFormatException,
      );
    });

    test('moneyMinor 按币种精度换算（CNY 2 位 / JPY 0 位）', () {
      final cny = moneyMinor(Rational.parseDecimal('1234.5'), 'CNY');
      expect(cny, BigInt.from(123450));
      final jpy = moneyMinor(Rational.parseDecimal('1234.5'), 'JPY');
      // halfEven：1234.5 → 1234（偶数）。
      expect(jpy, BigInt.from(1234));
    });
  });

  test('estimateNote 汇总依据与来源（最多带两条来源）', () {
    final note = estimateNote(AiAssetEstimate(
      query: 'q',
      valueMinor: BigInt.one,
      currency: 'CNY',
      confidence: 80,
      sources: ['https://a.com', 'https://b.com', 'https://c.com'],
      rationale: '依据文字',
    ));
    expect(note, contains('置信度 80%'));
    expect(note, contains('依据文字'));
    expect(note, contains('https://a.com'));
    expect(note, contains('https://b.com'));
    expect(note, isNot(contains('c.com'))); // 第三条来源被截断
  });

  group('targets 与刷新', () {
    late AppDatabase db;
    late AccountsRepo accounts;
    late MetaRepo meta;
    late FakeChat chat;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      accounts = AccountsRepo(db);
      meta = MetaRepo(db);
      chat = FakeChat();
      await meta.setSetting('aiProvider', jsonEncode(cfg.toJson()));
      await accounts.upsert(const Account(
        id: 'a-estate',
        name: '前滩的房子',
        type: AccountType.asset,
        assetSubtype: AssetSubtype.realEstate,
        currencyCode: 'CNY',
        aiValuationEnabled: true,
      ));
      await accounts.upsert(const Account(
        id: 'a-car',
        name: '2021 款 325Li',
        type: AccountType.asset,
        assetSubtype: AssetSubtype.vehicle,
        currencyCode: 'CNY',
        aiValuationEnabled: true,
      ));
      // 未启用 / 归档 / 非 manualValue 的都不该进目标。
      await accounts.upsert(const Account(
        id: 'a-off',
        name: '未启用估值',
        type: AccountType.asset,
        assetSubtype: AssetSubtype.realEstate,
        currencyCode: 'CNY',
      ));
      await accounts.upsert(const Account(
        id: 'a-arch',
        name: '已归档',
        type: AccountType.asset,
        assetSubtype: AssetSubtype.realEstate,
        currencyCode: 'CNY',
        aiValuationEnabled: true,
        archived: true,
      ));
      await accounts.upsert(const Account(
        id: 'a-cash',
        name: '现金',
        type: AccountType.asset,
        assetSubtype: AssetSubtype.cash,
        currencyCode: 'CNY',
        aiValuationEnabled: true,
      ));
    });

    tearDown(() async => db.close());

    test('targets 只含启用且 manualValue 的未归档资产', () async {
      final svc = AiValuationService(accounts, meta, chat);
      final ids = (await svc.targets()).map((a) => a.id).toSet();
      expect(ids, {'a-estate', 'a-car'});
    });

    test('refresh：逐项写入 ai: 来源估值', () async {
      chat.replies = [
        '{"found":true,"value":"8000000","currency":"CNY","confidence":70}',
        '{"found":true,"value":"250000","currency":"CNY","confidence":65}',
      ];
      final svc = AiValuationService(accounts, meta, chat);
      final run = await svc.refresh();
      expect(run.updated, 2);
      expect(run.failures, isEmpty);
      expect(chat.calls, 2);
      final vals = await meta.valuations(accountId: 'a-estate');
      expect(vals.single.totalValueMinor, BigInt.from(800000000));
      expect(vals.single.source, startsWith('ai:glm/'));
      expect(vals.single.kind, ValuationKind.totalValue);
    });

    test('当日手动估值优先：AI 跳过不覆盖', () async {
      await meta.saveValuation(ValuationRecord(
        accountId: 'a-estate',
        date: DateTime.now(),
        kind: ValuationKind.totalValue,
        totalValueMinor: BigInt.parse('700000000'),
        source: 'manual',
      ));
      chat.replies = ['{"found":true,"value":"8000000","currency":"CNY"}'];
      final svc = AiValuationService(accounts, meta, chat);
      final run = await svc.refresh();
      expect(run.updated, 1); // 只有车
      expect(run.skippedManual, 1);
      final vals = await meta.valuations(accountId: 'a-estate');
      expect(
        vals.where((v) => v.source == 'manual').single.totalValueMinor,
        BigInt.parse('700000000'),
      );
      expect(vals.where((v) => v.source.startsWith('ai:')), isEmpty);
    });

    test('refreshDue 每天只跑一轮（门控）', () async {
      chat.replies = [
        '{"found":true,"value":"1","currency":"CNY"}',
        '{"found":true,"value":"2","currency":"CNY"}',
      ];
      final svc = AiValuationService(accounts, meta, chat);
      final first = await svc.refreshDue();
      expect(first.ran, true);
      expect(chat.calls, 2);
      final second = await svc.refreshDue();
      expect(second.ran, false);
      expect(chat.calls, 2); // 未再发请求
    });

    test('单条失败进 failures，其余照常', () async {
      chat.replies = [
        '{"found":false,"reason":"查无该车"}',
        '{"found":true,"value":"250000","currency":"CNY"}',
      ];
      final svc = AiValuationService(accounts, meta, chat);
      final run = await svc.refresh();
      expect(run.updated, 1);
      expect(run.failures.single, contains('查无该车'));
    });
  });
}

class FakeChat extends AiChat {
  List<String> replies = [];

  int calls = 0;

  @override
  Future<String> complete(AiConfig cfg, String system, String user) async {
    if (replies.isEmpty) {
      throw StateError('FakeChat 未配置应答');
    }
    return replies[calls++ % replies.length];
  }
}
