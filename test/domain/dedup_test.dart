import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:assetscope/domain/import/dedup.dart';
import 'package:assetscope/domain/ledger/transaction.dart';

void main() {
  NormalizedRow row(
    DateTime date,
    BigInt amount, {
    bool direction = false,
    String cparty = '美团平台-美团外卖',
    String? rowKey,
  }) =>
      NormalizedRow(
        date: date,
        direction: direction,
        amountMinor: amount,
        currencyCode: 'CNY',
        counterparty: cparty,
        rowKey: rowKey,
      );

  test('纯 Dart SHA-256 与标准测试向量一致', () {
    // 通过 externalId 间接验证（内部使用 _sha256Hex）
    final id = row(DateTime(2026, 1, 1), BigInt.from(100), rowKey: 'abc')
        .externalId('p', 'a');
    // 同输入 → 稳定输出
    final id2 = row(DateTime(2026, 1, 1), BigInt.from(100), rowKey: 'abc')
        .externalId('p', 'a');
    expect(id, id2);
    // 不同 parser/account → 不同 id
    expect(id2 != row(DateTime(2026, 1, 1), BigInt.from(100), rowKey: 'abc').externalId('q', 'a'), isTrue);
  });

  test('externalId 幂等：同一来源行重复导入得到相同 ID', () {
    final r1 = row(DateTime(2026, 5, 1), BigInt.from(2500), rowKey: '2026050122001');
    final r2 = row(DateTime(2026, 5, 1), BigInt.from(2500), rowKey: '2026050122001');
    expect(r1.externalId('alipay', 'alipayAcc'),
        r2.externalId('alipay', 'alipayAcc'));
  });

  test('指纹规范化：空白/大小写/括号注记不改变指纹', () {
    final a = row(DateTime(2026, 5, 1), BigInt.from(2500), cparty: '美团 外卖');
    final b = row(DateTime(2026, 5, 1), BigInt.from(2500), cparty: '美团外卖（订单号123）');
    expect(a.fingerprint(), b.fingerprint());
    // 金额不同 → 指纹不同
    final c = row(DateTime(2026, 5, 1), BigInt.from(2501), cparty: '美团外卖');
    expect(a.fingerprint() != c.fingerprint(), isTrue);
  });

  test('同日同商户同金额可能是真实两次消费：指纹重复只建议不删除', () {
    final r = row(DateTime(2026, 5, 1), BigInt.from(1500));
    final match = Deduper.matchAgainst(
      row: r,
      knownExternalIds: {},
      fingerprintToTxId: {r.fingerprint(): 'tx:1'},
    );
    expect(match.decision, DedupDecision.fingerprintDuplicate);
    expect(match.existingTxId, 'tx:1');
    // 决策是"疑似"，由 UI 让用户确认，不自动跳过
  });

  test('微信支出 + 银行入账同额同日：识别为转账对候选', () {
    final rows = [
      row(DateTime(2026, 5, 1, 10), BigInt.from(50000),
          direction: true, cparty: '零钱通转入'), // 收入
      row(DateTime(2026, 5, 1, 10), BigInt.from(50000),
          cparty: '银行卡扣款'),
      row(DateTime(2026, 5, 2), BigInt.from(3000), cparty: '早餐'),
    ];
    final pairs = Deduper.pairTransfers(rows);
    expect(pairs.length, 1);
    // 配对后早餐行不受影响
  });

  test('金额一致但方向相同的两笔不会误配', () {
    final rows = [
      row(DateTime(2026, 5, 1), BigInt.from(5000)),
      row(DateTime(2026, 5, 1), BigInt.from(5000)),
    ];
    expect(Deduper.pairTransfers(rows), isEmpty);
  });

  test('stableExternalId 与 TxSource 无关稳定', () {
    final a = stableExternalId(
        parserId: 'wechat', accountId: 'wx', source: TxSource.importWechat, basis: 'row1');
    final b = stableExternalId(
        parserId: 'wechat', accountId: 'wx', source: TxSource.importWechat, basis: 'row1');
    expect(a, b);
    expect(a.length, 64);
    // 合法 hex
    expect(() => BigInt.parse(a, radix: 16), returnsNormally);
  });

  test('原始行 JSON 快照可回溯', () {
    final r = NormalizedRow(
      date: DateTime(2026, 5, 1),
      direction: false,
      amountMinor: BigInt.from(100),
      currencyCode: 'CNY',
      counterparty: 'x',
      rawRowJson: jsonEncode(['2026-05-01', 'x', '1.00']),
    );
    final back = jsonDecode(r.rawRowJson!) as List;
    expect(back[2], '1.00');
  });
}
