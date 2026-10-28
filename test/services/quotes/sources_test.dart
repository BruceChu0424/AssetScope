
import 'package:flutter_test/flutter_test.dart';
import 'package:fast_gbk/fast_gbk.dart';

import 'package:assetscope/domain/money/fx_rate.dart';
import 'package:assetscope/services/quotes/frankfurter_source.dart';
import 'package:assetscope/services/quotes/stooq_source.dart';
import 'package:assetscope/services/quotes/tencent_source.dart';

/// 三家行情源的解析器：真实报文样式的最小复刻，纯函数测试（无网络）。
void main() {
  test('腾讯行情：GBK 解析、停牌回退昨收、失败行披露', () {
    String line(String sym, String name, String price, String prev,
        String stamp) {
      final f = List.generate(40, (_) => '');
      f[1] = name;
      f[3] = price;
      f[4] = prev;
      f[30] = stamp;
      return 'v_$sym="${f.join('~')}";';
    }

    final body = gbk.encode([
      line('sh600519', '贵州茅台', '1523.00', '1518.00', '20261027161403'),
      line('sz000001', '平安银行', '0.00', '11.45', '20261027150000'), // 停牌
      line('sh510300', '沪深300ETF', '4.012', '4.008', '20261027150300'),
      'v_sh999999="1~坏数据~999999~";', // 字段不足
    ].join('\n'));
    final (quotes, failed) = TencentSource.parse(
        body, ['sh600519', 'sz000001', 'sh510300', 'sh888888']);
    expect(quotes, hasLength(3));
    final moutai = quotes.first;
    expect(moutai.name, '贵州茅台');
    expect(moutai.price, Rational.parseDecimal('1523.00'));
    expect(moutai.asOf, DateTime(2026, 10, 27, 16, 14));
    expect(quotes[1].price, Rational.parseDecimal('11.45')); // 停牌用昨收
    expect(quotes[1].asOf, DateTime(2026, 10, 27, 15, 0));
    expect(failed, ['sh888888']); // 请求了但无有效行
  });

  test('stooq：CSV 解析、N/D 行失败披露', () {
    const csv = 'Symbol,Date,Time,Open,High,Low,Close,Volume\n'
        '0700.HK,2026-10-27,16:08:11,410.0,415.2,408.6,412.4,12345678\n'
        'AAPL.US,2026-10-24,16:00:00,228.0,231.0,227.4,230.2,54000000\n'
        'BRK-B.US,N/D,N/D,N/D,N/D,N/D,N/D,N/D\n';
    final (quotes, failed) =
        StooqSource.parse(csv, ['0700.hk', 'aapl.us', 'brk-b.us']);
    expect(quotes, hasLength(2));
    expect(quotes[0].symbol, '0700.hk');
    expect(quotes[0].price, Rational.parseDecimal('412.4'));
    expect(quotes[0].asOf, DateTime(2026, 10, 27, 16, 8));
    expect(quotes[1].price, Rational.parseDecimal('230.2'));
    expect(failed, ['brk-b.us']);
  });

  test('frankfurter：EUR 交叉换算精确', () {
    const body =
        '{"amount":1.0,"base":"EUR","date":"2026-10-24","rates":{"USD":1.08,"CNY":8.5324,"HKD":8.42}}';
    final (rates, date, missing) =
        FrankfurterFx.parse(body, ['USD', 'HKD'], 'CNY');
    expect(date, DateTime(2026, 10, 24));
    expect(missing, isEmpty);
    // USD→CNY = 8.5324 / 1.08；HKD→CNY = 8.5324 / 8.42（有理数精确）。
    expect(rates['USD'],
        Rational.parseDecimal('8.5324') / Rational.parseDecimal('1.08'));
    expect(rates['HKD'],
        Rational.parseDecimal('8.5324') / Rational.parseDecimal('8.42'));
  });

  test('frankfurter：不支持的币种披露；base 缺失全失败', () {
    const body =
        '{"amount":1.0,"base":"EUR","date":"2026-10-24","rates":{"USD":1.08,"CNY":8.5324}}';
    final (rates, _, missing) = FrankfurterFx.parse(body, ['USD', 'KRW'], 'CNY');
    expect(rates.containsKey('USD'), isTrue);
    expect(missing, ['KRW']); // 央行列表外

    const noBase =
        '{"amount":1.0,"base":"EUR","date":"2026-10-24","rates":{"USD":1.08}}';
    final (none, _, missAll) = FrankfurterFx.parse(noBase, ['USD'], 'KRW');
    expect(none, isEmpty);
    expect(missAll, containsAll(['USD', 'KRW']));
  });

  test('URL 构造', () {
    expect(TencentSource.buildUrl(['sh600519', 'sz000001']).toString(),
        'https://qt.gtimg.cn/q=sh600519,sz000001');
    expect(StooqSource.buildUrl(['0700.hk']).toString(),
        'https://stooq.com/q/l/?s=0700.hk&f=sd2t2ohlcv&h&e=csv');
    expect(FrankfurterFx.buildUrl({'USD', 'CNY'}).toString(),
        contains('https://api.frankfurter.dev/v1/latest?'));
  });

  test('CRLF 行尾解析健壮', () {
    const csv = 'Symbol,Date,Time,Open,High,Low,Close,Volume\r\n'
        '0700.HK,2026-10-27,16:08:11,1,1,1,412.4,1\r\n';
    final (quotes, failed) = StooqSource.parse(csv, ['0700.hk']);
    expect(quotes.single.price, Rational.parseDecimal('412.4'));
    expect(failed, isEmpty);
  });
}
