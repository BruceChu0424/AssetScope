import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';

import '../l10n/runtime_l10n.dart';
import 'tables.dart';

part 'app_database.g.dart';

/// 加密 SQLite 账本数据库。
///
/// 打开方式：`NativeDatabase.createInBackground` + `setup` 中先于一切访问
/// 执行 `PRAGMA key = x'...'`（SQLite3MultipleCiphers，pubspec 的
/// hooks.user_defines.sqlite3.source=sqlite3mc 构建变体）。
/// 密钥来自 KeyManager 的 DEK（32 字节 hex），绝不落盘明文。
@DriftDatabase(
  tables: [
    Accounts,
    Securities,
    Transactions,
    Postings,
    Budgets,
    ScheduledEvents,
    Goals,
    DebtContracts,
    Valuations,
    FxRates,
    Snapshots,
    ImportBatches,
    Settings,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  AppDatabase.openFile(File file, {required String dbKeyHex})
    : super(
        NativeDatabase.createInBackground(
          file,
          setup: (rawDb) {
            rawDb.execute("PRAGMA key = \"x'$dbKeyHex'\";");
          },
        ),
      );

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await seedBaseline();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        // v2：账户增加地理位置（3D 地球固定资产视图）。
        await m.addColumn(accounts, accounts.locationLat);
        await m.addColumn(accounts, accounts.locationLon);
        await m.addColumn(accounts, accounts.locationName);
      }
      if (from < 3) {
        // v3：统计聚合热路径索引（万级流水）。
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_transactions_date ON transactions (date)',
        );
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_postings_tx ON postings (tx_id)',
        );
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_postings_account ON postings (account_id)',
        );
      }
      if (from < 4) {
        // v4：周期计划单次跳过（计划落地执行，docs/05 §6）。
        await m.addColumn(scheduledEvents, scheduledEvents.skippedDatesJson);
      }
      if (from < 5) {
        // v5：AI 每日自动估值（房产/车辆联网市价检索）。
        await m.addColumn(accounts, accounts.aiValuationEnabled);
        await m.addColumn(accounts, accounts.aiValuationQuery);
      }
    },
  );

  /// 初始数据：系统账户、默认分类、默认设置。
  Future<void> seedBaseline() async {
    await batch((b) {
      b.insertAll(accounts, _seedAccounts);
      b.insertAll(settings, [
        SettingsCompanion.insert(key: 'baseCurrency', valueJson: '"CNY"'),
        SettingsCompanion.insert(key: 'lockTimeoutMinutes', valueJson: '5'),
        SettingsCompanion.insert(key: 'projectionHorizonDays', valueJson: '90'),
        SettingsCompanion.insert(key: 'baselineMinCashMinor', valueJson: '"0"'),
      ]);
    });
  }

  static final List<AccountsCompanion> _seedAccounts = [
    // 系统账户
    AccountsCompanion.insert(
      id: 'sys:equity:opening',
      name: rt('期初余额权益'),
      type: 'equity',
      currencyCode: 'CNY',
      isSystem: const Value(true),
    ),
    AccountsCompanion.insert(
      id: 'sys:equity:adjustment',
      name: rt('对账调整'),
      type: 'equity',
      currencyCode: 'CNY',
      isSystem: const Value(true),
    ),
    AccountsCompanion.insert(
      id: 'sys:expense:fx',
      name: rt('汇兑损益'),
      type: 'expense',
      currencyCode: 'CNY',
      isSystem: const Value(true),
    ),
    AccountsCompanion.insert(
      id: 'sys:expense:rounding',
      name: rt('尾差'),
      type: 'expense',
      currencyCode: 'CNY',
      isSystem: const Value(true),
    ),
    AccountsCompanion.insert(
      id: 'sys:income:realized-pnl',
      name: rt('已实现投资损益'),
      type: 'income',
      currencyCode: 'CNY',
      isSystem: const Value(true),
    ),
    AccountsCompanion.insert(
      id: 'sys:income:dividend',
      name: rt('股息与分红'),
      type: 'income',
      currencyCode: 'CNY',
      isSystem: const Value(true),
    ),
    // 默认支出分类
    AccountsCompanion.insert(
      id: 'cat:e:dining',
      name: rt('餐饮'),
      type: 'expense',
      currencyCode: 'CNY',
    ),
    AccountsCompanion.insert(
      id: 'cat:e:transport',
      name: rt('交通'),
      type: 'expense',
      currencyCode: 'CNY',
    ),
    AccountsCompanion.insert(
      id: 'cat:e:shopping',
      name: rt('购物'),
      type: 'expense',
      currencyCode: 'CNY',
    ),
    AccountsCompanion.insert(
      id: 'cat:e:housing',
      name: rt('居住'),
      type: 'expense',
      currencyCode: 'CNY',
    ),
    AccountsCompanion.insert(
      id: 'cat:e:utilities',
      name: rt('水电燃气'),
      type: 'expense',
      currencyCode: 'CNY',
    ),
    AccountsCompanion.insert(
      id: 'cat:e:telecom',
      name: rt('通讯网络'),
      type: 'expense',
      currencyCode: 'CNY',
    ),
    AccountsCompanion.insert(
      id: 'cat:e:medical',
      name: rt('医疗'),
      type: 'expense',
      currencyCode: 'CNY',
    ),
    AccountsCompanion.insert(
      id: 'cat:e:education',
      name: rt('教育'),
      type: 'expense',
      currencyCode: 'CNY',
    ),
    AccountsCompanion.insert(
      id: 'cat:e:fun',
      name: rt('娱乐'),
      type: 'expense',
      currencyCode: 'CNY',
    ),
    AccountsCompanion.insert(
      id: 'cat:e:travel',
      name: rt('旅行'),
      type: 'expense',
      currencyCode: 'CNY',
    ),
    AccountsCompanion.insert(
      id: 'cat:e:insurance',
      name: rt('保险费'),
      type: 'expense',
      currencyCode: 'CNY',
    ),
    AccountsCompanion.insert(
      id: 'cat:e:gift',
      name: rt('人情往来'),
      type: 'expense',
      currencyCode: 'CNY',
    ),
    AccountsCompanion.insert(
      id: 'cat:e:interest',
      name: rt('利息费用'),
      type: 'expense',
      currencyCode: 'CNY',
    ),
    AccountsCompanion.insert(
      id: 'cat:e:other',
      name: rt('其他支出'),
      type: 'expense',
      currencyCode: 'CNY',
    ),
    // 默认收入分类
    AccountsCompanion.insert(
      id: 'cat:i:salary',
      name: rt('工资'),
      type: 'income',
      currencyCode: 'CNY',
    ),
    AccountsCompanion.insert(
      id: 'cat:i:bonus',
      name: rt('奖金'),
      type: 'income',
      currencyCode: 'CNY',
    ),
    AccountsCompanion.insert(
      id: 'cat:i:side-job',
      name: rt('兼职/副业'),
      type: 'income',
      currencyCode: 'CNY',
    ),
    AccountsCompanion.insert(
      id: 'cat:i:other',
      name: rt('其他收入'),
      type: 'income',
      currencyCode: 'CNY',
    ),
  ];
}
