import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

import 'package:assetscope/data/app_database.dart';
import 'package:assetscope/data/repositories/accounts_repo.dart';
import 'package:assetscope/data/repositories/planning_repo.dart';

/// schema 迁移：v3 → v4（scheduled_events.skipped_dates_json）与
/// v4 → v5（accounts AI 估值两列）。
/// 用手工建出的旧形态库验证升级路径与旧行兼容。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('v3→v4：新列默认空、旧事件可读、写回往返一致', () async {
    final raw = sqlite3.sqlite3.openInMemory();
    // v3 库同样存在 accounts 表（v5 迁移 from<5 也会执行 ALTER）。
    raw.execute('''
      CREATE TABLE accounts (
        id TEXT NOT NULL PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        currency_code TEXT NOT NULL,
        location_lat REAL NULL,
        location_lon REAL NULL,
        location_name TEXT NULL
      )
    ''');
    // v3 形态的 scheduled_events（无 skipped_dates_json）。
    raw.execute('''
      CREATE TABLE scheduled_events (
        id TEXT NOT NULL PRIMARY KEY,
        name TEXT NOT NULL,
        direction TEXT NOT NULL,
        currency_code TEXT NOT NULL,
        cadence TEXT NOT NULL,
        anchor_date INTEGER NOT NULL,
        amount_minor TEXT NULL,
        amount_low_minor TEXT NULL,
        amount_high_minor TEXT NULL,
        interval_value INTEGER NOT NULL DEFAULT 1,
        month_end_policy TEXT NOT NULL DEFAULT 'clampToMonthEnd',
        end_date INTEGER NULL,
        payment_account_id TEXT NULL,
        category_id TEXT NULL,
        auto_post INTEGER NOT NULL DEFAULT 0,
        notes TEXT NULL,
        status TEXT NOT NULL DEFAULT 'active',
        skipped_months_json TEXT NOT NULL DEFAULT '[]',
        amount_overrides_json TEXT NOT NULL DEFAULT '{}'
      )
    ''');
    // drift 默认 DateTime 存 unix 秒。
    raw.execute(
        'INSERT INTO scheduled_events (id, name, direction, currency_code, cadence, anchor_date, amount_minor) '
        "VALUES ('e1', '房租', 'outflow', 'CNY', 'monthly', ${DateTime(2026, 1, 5).millisecondsSinceEpoch ~/ 1000}, '300000')");
    raw.execute('PRAGMA user_version = 3');

    final db = AppDatabase(NativeDatabase.opened(raw));
    addTearDown(() => db.close());
    final planning = PlanningRepo(db);

    final events = await planning.scheduledEvents();
    expect(events.single.id, 'e1');
    expect(events.single.amountMinor, BigInt.from(300000));
    expect(events.single.skippedDateKeys, isEmpty);

    await planning.saveScheduledEvent(
        events.single.copyWith(skippedDateKeys: {'2026-02-05'}));
    final reread = await planning.scheduledEvents();
    expect(reread.single.skippedDateKeys, {'2026-02-05'});
    expect(reread.single.skippedMonthKeys, isEmpty);
  });

  test('v4→v5：AI 估值列默认关闭、旧资产可读、写回往返一致', () async {
    final raw = sqlite3.sqlite3.openInMemory();
    // v4 形态的 accounts（无 ai_valuation_enabled / ai_valuation_query）。
    raw.execute('''
      CREATE TABLE accounts (
        id TEXT NOT NULL PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        asset_subtype TEXT NULL,
        liability_subtype TEXT NULL,
        institution TEXT NULL,
        currency_code TEXT NOT NULL,
        ownership_n TEXT NULL,
        ownership_d TEXT NULL,
        include_in_net_worth INTEGER NOT NULL DEFAULT 1,
        credit_limit_minor TEXT NULL,
        statement_day INTEGER NULL,
        due_day INTEGER NULL,
        is_system INTEGER NOT NULL DEFAULT 0,
        archived INTEGER NOT NULL DEFAULT 0,
        sort_order INTEGER NOT NULL DEFAULT 0,
        notes TEXT NULL,
        cost_basis_account_id TEXT NULL,
        security_id TEXT NULL,
        location_lat REAL NULL,
        location_lon REAL NULL,
        location_name TEXT NULL,
        created_at INTEGER NOT NULL DEFAULT 0
      )
    ''');
    raw.execute('''INSERT INTO accounts (id, name, type, asset_subtype, currency_code,
        location_lat, location_lon, location_name) VALUES
        ('a1', '前滩的房子', 'asset', 'realEstate', 'CNY', 31.18, 121.47, '上海浦东前滩')''');
    raw.execute('PRAGMA user_version = 4');

    final db = AppDatabase(NativeDatabase.opened(raw));
    addTearDown(() => db.close());
    final accounts = AccountsRepo(db);

    final old = await accounts.byId('a1');
    expect(old!.name, '前滩的房子');
    expect(old.aiValuationEnabled, isFalse); // 新列默认 false
    expect(old.aiValuationQuery, isNull);
    expect(old.locationName, '上海浦东前滩');

    // 开启 AI 估值并写检索线索，往返一致。
    await accounts.upsert(old.copyWith(
      aiValuationEnabled: true,
      aiValuationQuery: '前滩某小区 3 号楼 502',
    ));
    final reread = await accounts.byId('a1');
    expect(reread!.aiValuationEnabled, isTrue);
    expect(reread.aiValuationQuery, '前滩某小区 3 号楼 502');
    expect(reread.effectiveAiValuationQuery, '前滩某小区 3 号楼 502');
    // 无自定义线索时按 名称+位置 推导（copyWith 需显式清除）。
    await accounts.upsert(reread.copyWith(clearAiValuationQuery: true));
    final derived = await accounts.byId('a1');
    expect(
      derived!.effectiveAiValuationQuery,
      '前滩的房子（上海浦东前滩）',
    );
  });
}
