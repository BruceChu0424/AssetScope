import 'dart:convert';

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
import 'package:assetscope/services/ai/ai_chat.dart';
import 'package:assetscope/services/ai/quote_fetch_service.dart';
import 'package:assetscope/services/quotes/direct_quote_service.dart';

/// 直连行情源编排：内存库建持仓与外币账户 → 假 HTTP 按域名路由 →
/// 断言路由、价格/汇率映射、币种核对与无法识别代码的披露。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  bool dbAvailable = true;

  setUp(() async {
    try {
      db = AppDatabase(NativeDatabase.memory());
      await db.customSelect('SELECT 1').getSingle();
    } catch (_) {
      dbAvailable = false;
      return;
    }
  });

  tearDown(() async {
    if (dbAvailable) await db.close();
  });

  Future<DirectQuoteService> seed() async {
    final accounts = AccountsRepo(db);
    final ledger = LedgerRepo(db);
    final meta = MetaRepo(db);
    final quoteFetch =
        QuoteFetchService(accounts, ledger, meta, const AiChat());

    final bank = Account(
        id: 'bank',
        name: '招行',
        type: AccountType.asset,
        assetSubtype: AssetSubtype.bank,
        currencyCode: 'CNY');
    final hkdCash = Account(
        id: 'hkd',
        name: '港股现金',
        type: AccountType.asset,
        assetSubtype: AssetSubtype.cash,
        currencyCode: 'HKD');
    final usdCash = Account(
        id: 'usd',
        name: '美元现金',
        type: AccountType.asset,
        assetSubtype: AssetSubtype.cash,
        currencyCode: 'USD');
    for (final a in [bank, hkdCash, usdCash]) {
      await accounts.upsert(a);
      await ledger.post(TxBuilders.openingBalance(
          assetAccount: a,
          amountMinor: BigInt.from(100000000),
          date: DateTime(2026, 1, 1)));
    }

    Future<void> buyHolding(String name, String code, String ccy,
        AssetSubtype subtype) async {
      final h = await accounts.createHolding(
          name: name, subtype: subtype, currencyCode: ccy, securityCode: code);
      await ledger.post(TxBuilders.buy(
          holdingAccount: h,
          cashAccount: ccy == 'CNY' ? bank : (ccy == 'HKD' ? hkdCash : usdCash),
          quantity: Rational.fromInt(BigInt.from(100)),
          totalPaidMinor: BigInt.from(100000),
          date: DateTime(2026, 1, 15)));
    }

    await buyHolding('贵州茅台', '600519', 'CNY', AssetSubtype.stock);
    await buyHolding('腾讯控股', '700', 'HKD', AssetSubtype.stock);
    await buyHolding('神秘基金', '茅台', 'CNY', AssetSubtype.fund);

    return DirectQuoteService(accounts, quoteFetch);
  }

  test('路由与映射：A股→腾讯、港股→stooq、外币→frankfurter', () async {
    if (!dbAvailable) {
      markTestSkipped('宿主环境无可用 sqlite3，跳过');
      return;
    }
    final service = await seed();
    final hosts = <String>[];
    final result = await service.fetch(http: (uri) async {
      hosts.add(uri.host);
      if (uri.host == 'qt.gtimg.cn') {
        final f = List.generate(40, (_) => '');
        f[1] = '贵州茅台';
        f[3] = '1523.00';
        f[4] = '1518.00';
        f[30] = '20261027161403';
        return gbk.encode('v_sh600519="${f.join('~')}";');
      }
      if (uri.host == 'stooq.com') {
        return utf8.encode('Symbol,Date,Time,Open,High,Low,Close,Volume\n'
            '0700.HK,2026-10-27,16:08:11,410,415,408,412.4,1\n');
      }
      if (uri.host == 'api.frankfurter.dev') {
        return utf8.encode(
            '{"base":"EUR","date":"2026-10-24","rates":{"USD":1.08,"HKD":8.42,"CNY":8.5324}}');
      }
      throw StateError('意外请求 $uri');
    });

    expect(hosts.toSet(),
        containsAll(['qt.gtimg.cn', 'stooq.com', 'api.frankfurter.dev']));

    expect(result.prices, hasLength(2));
    final mt = result.prices
        .firstWhere((p) => p.accountName == '贵州茅台');
    expect(mt.price, Rational.parseDecimal('1523.00'));
    expect(mt.currency, 'CNY');
    expect(mt.currencyMismatch, false);
    expect(mt.asOf, DateTime(2026, 10, 27, 16, 14));
    expect(mt.source, contains('qt.gtimg.cn'));

    final tx = result.prices.firstWhere((p) => p.accountName == '腾讯控股');
    expect(tx.price, Rational.parseDecimal('412.4'));
    expect(tx.currency, 'HKD'); // 市场推断币种
    expect(tx.currencyMismatch, false);

    expect(result.rates, hasLength(2));
    final usd =
        result.rates.firstWhere((r) => r.ccy == 'USD');
    expect(usd.rate,
        Rational.parseDecimal('8.5324') / Rational.parseDecimal('1.08'));
    expect(usd.asOf, DateTime(2026, 10, 24));

    expect(result.warnings, isNotEmpty);
    expect(
        result.warnings.any((w) => w.contains('茅台') && w.contains('无法识别')),
        isTrue);
  });

  test('单源失败不中断其余源，失败进入提示', () async {
    if (!dbAvailable) {
      markTestSkipped('宿主环境无可用 sqlite3，跳过');
      return;
    }
    final service = await seed();
    final result = await service.fetch(http: (uri) async {
      if (uri.host == 'stooq.com') {
        throw const FormatException('stooq 不可达');
      }
      if (uri.host == 'qt.gtimg.cn') {
        final f = List.generate(40, (_) => '');
        f[1] = '贵州茅台';
        f[3] = '1523.00';
        f[30] = '20261027161403';
        return gbk.encode('v_sh600519="${f.join('~')}";');
      }
      return utf8.encode(
          '{"base":"EUR","date":"2026-10-24","rates":{"USD":1.08,"HKD":8.42,"CNY":8.5324}}');
    });
    expect(result.prices, hasLength(1)); // 腾讯源整体失败只剩茅台
    expect(result.rates, hasLength(2));
    expect(result.warnings.any((w) => w.contains('stooq 请求失败')), isTrue);
  });
}
