import 'package:flutter_test/flutter_test.dart';

import 'package:assetscope/domain/import/bill_parsers.dart';

/// 微信/支付宝原生账单解析（合成脱敏样本校准，真实格式结构对齐）。
void main() {
  const wechatSample = '''
微信支付账单明细,,,,,,,,
微信昵称：[张*],,,,,,,
起始时间：[2026-08-01 00:00:00] 终止时间：[2026-08-31 23:59:59],,,,,,,
导出类型：[全部],,,,,,,
导出时间:[2026-09-01 10:00:00],,,,,,,
----------------------微信支付账单明细列表--------------------,,,,,,,,
交易时间,交易类型,交易对方,商品,收/支,金额(元),支付方式,当前状态,交易单号,商户单号,备注
2026-08-02 08:15:30,商户消费,永辉超市,生鲜果蔬,支出,¥86.40,招商银行储蓄卡(1234),支付成功,1000039901202608020123456789,,
2026-08-05 21:10:00,微信红包,李*四,红包,收入,¥200.00,零钱,已存入零钱,1000039901202608050098765432,,
2026-08-10 12:00:00,转账,零钱通,/,/,¥1000.00,零钱,转账成功,1000039901202608100111111111,,
2026-08-15 09:30:00,商户消费,某电商平台,数码配件,支出,¥329.00,零钱,已全额退款,1000039901202608150222222222,,
2026-08-20 18:45:00,商户消费,美团外卖,午晚餐,支出,¥35.60,招商银行储蓄卡(1234),支付成功,1000039901202608200333333333,,晚高峰配送
''';

  const alipaySample = '''
支付宝交易明细查询,,,,,,,,
账号:[x***@163.com],,,,,,,,
起始日期:[2026-08-01 00:00:00]    终止日期:[2026-08-31 00:00:00],,,,,,,,
---------------------------------交易记录明细列表------------------------------------
交易号,商家订单号,交易创建时间,付款时间,最近修改时间,交易来源地,类型,交易对方,商品名称,金额（元）,收/支,交易状态,服务费（元）,成功退款（元）,备注,资金状态
2026080212345678901234567890,,2026-08-02 09:00:00,2026-08-02 09:00:15,2026-08-02 09:00:15,其他,即时到账交易,盒马鲜生,生鲜食品,112.30,支出,交易成功,0.00,0.00,,已支出
2026080512345678901234567891,,2026-08-05 10:00:00,2026-08-05 10:00:05,2026-08-05 10:00:05,其他,转账,王*五,转账,500.00,收入,交易成功,0.00,0.00,,已收入
2026081012345678901234567892,,2026-08-10 14:30:00,2026-08-10 14:30:20,2026-08-10 14:30:20,其他,余额宝,余额宝-转入,/,1000.00,不计收支,交易成功,0.00,0.00,,资金转移
2026081512345678901234567893,,2026-08-15 16:00:00,2026-08-15 16:00:10,2026-08-15 16:00:10,其他,即时到账交易,京东商城,电子产品,299.00,支出,交易关闭,0.00,0.00,,未支出
2026081812345678901234567894,,2026-08-18 19:20:00,2026-08-18 19:20:08,2026-08-18 19:20:08,其他,蚂蚁森林,蚂蚁森林,能量,0.00,不计收支,交易成功,0.00,0.00,,/
''';

  test('格式探测：微信/支付宝/未知', () {
    expect(BillParsers.detect(wechatSample), BillFormat.wechat);
    expect(BillParsers.detect(alipaySample), BillFormat.alipay);
    expect(BillParsers.detect('date,type,amount\n2026-01-01,支出,10.00'),
        isNull);
  });

  test('微信：成功流水正确规范化，交易单号作稳定外部 ID', () {
    final r = BillParsers.parseWeChat(wechatSample)!;
    expect(r.rows, hasLength(3));

    final first = r.rows[0];
    expect(first.date, DateTime(2026, 8, 2, 8, 15, 30));
    expect(first.direction, isFalse); // 支出
    expect(first.amountMinor, BigInt.from(8640));
    expect(first.counterparty, '永辉超市');
    expect(first.note, '生鲜果蔬');
    expect(first.sourceTxId, '1000039901202608020123456789');
    expect(first.currencyCode, 'CNY');

    final second = r.rows[1];
    expect(second.direction, isTrue); // 收入
    expect(second.amountMinor, BigInt.from(20000));
    expect(second.counterparty, '李*四');

    // 备注拼接：商品 + 备注
    expect(r.rows[2].note, '午晚餐 · 晚高峰配送');

    // 幂等：同一交易单号在任何两次解析中外部 ID 一致
    final again = BillParsers.parseWeChat(wechatSample)!;
    expect(again.rows[0].externalId('wechat', 'acc1'),
        equals(first.externalId('wechat', 'acc1')));
  });

  test('微信：中性流水与退款行按原因跳过', () {
    final r = BillParsers.parseWeChat(wechatSample)!;
    expect(r.skippedCount, 2);
    final reasons = r.skippedSummary;
    expect(reasons, anyElement(contains('不计收支')));
    expect(reasons, anyElement(contains('退款')));
  });

  test('支付宝：成功流水正确规范化，交易号作稳定外部 ID', () {
    final r = BillParsers.parseAlipay(alipaySample)!;
    expect(r.rows, hasLength(2));

    final first = r.rows[0];
    expect(first.date, DateTime(2026, 8, 2, 9, 0, 0));
    expect(first.direction, isFalse);
    expect(first.amountMinor, BigInt.from(11230));
    expect(first.counterparty, '盒马鲜生');
    expect(first.note, '生鲜食品');
    expect(first.sourceTxId, '2026080212345678901234567890');

    final second = r.rows[1];
    expect(second.direction, isTrue);
    expect(second.amountMinor, BigInt.from(50000));
    expect(second.counterparty, '王*五');

    // 幂等
    final again = BillParsers.parseAlipay(alipaySample)!;
    expect(again.rows[0].externalId('alipay', 'a'),
        equals(first.externalId('alipay', 'a')));
  });

  test('支付宝：不计收支与关闭交易按原因跳过', () {
    final r = BillParsers.parseAlipay(alipaySample)!;
    expect(r.skippedCount, 3);
    final reasons = r.skippedSummary;
    expect(reasons.where((s) => s.contains('不计收支')), hasLength(1));
    expect(reasons, anyElement(contains('关闭')));
  });

  test('非对应格式的文本返回 null 而不是抛错', () {
    expect(BillParsers.parseWeChat('date,type,amount\nx'), isNull);
    expect(BillParsers.parseAlipay(wechatSample), isNull);
  });

  test('微信：含引号字段的行可解析', () {
    const quoted = '''
微信支付账单明细,,,,,
交易时间,交易类型,交易对方,商品,收/支,金额(元),支付方式,当前状态,交易单号,商户单号,备注
2026-08-02 08:15:30,商户消费,"永辉,超市",生鲜,支出,¥12.00,零钱,支付成功,10001,,
''';
    final r = BillParsers.parseWeChat(quoted)!;
    expect(r.rows.single.counterparty, '永辉,超市');
  });
}
