import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

import 'package:assetscope/data/app_database.dart';
import 'package:assetscope/data/repositories/planning_repo.dart';

/// schema 迁移：v3 → v4（scheduled_events.skipped_dates_json）。
/// 用手工建出的旧形态库验证升级路径与旧行兼容。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('v3→v4：新列默认空、旧事件可读、写回往返一致', () async {
    final raw = sqlite3.sqlite3.openInMemory();
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
}
