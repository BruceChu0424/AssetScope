import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../data/app_database.dart';
import '../data/repositories/accounts_repo.dart';
import '../data/repositories/ledger_repo.dart';
import '../data/repositories/meta_repo.dart';
import '../data/repositories/planning_repo.dart';
import '../security/crypto_suite.dart';
import '../security/dart_crypto_suite.dart';
import '../security/key_manager.dart';
import '../services/ai/ai_chat.dart';
import '../services/ai/quote_fetch_service.dart';
import '../services/export_service.dart';
import '../services/import_service.dart';
import '../services/insight_service.dart';
import '../services/ledger_service.dart';
import '../services/plan_execution_service.dart';
import '../services/portfolio_analytics_service.dart';
import '../services/portfolio_service.dart';
import '../services/projection_service.dart';
import '../services/quotes/direct_quote_service.dart';
import '../services/scenario_service.dart';
import '../services/stats_service.dart';
import '../services/year_report_service.dart';

/// 会话状态：未初始化 / 已锁定 / 已解锁（含数据库与全部服务）。
sealed class VaultState {
  const VaultState();
}

class VaultUninitialized extends VaultState {
  const VaultUninitialized();
}

class VaultLocked extends VaultState {
  const VaultLocked({required this.hasRecovery});
  final bool hasRecovery;
}

class VaultUnlocked extends VaultState {
  VaultUnlocked({
    required this.db,
    required this.keyManager,
    required this.accounts,
    required this.ledger,
    required this.planning,
    required this.meta,
    required this.ledgerService,
    required this.statsService,
    required this.projectionService,
    required this.importService,
    required this.insightService,
    required this.exportService,
    required this.portfolioService,
    required this.portfolioAnalytics,
    required this.yearReportService,
    required this.quoteFetch,
    required this.directQuotes,
    required this.scenarios,
    required this.planExecution,
  });

  final AppDatabase db;
  final KeyManager keyManager;
  final AccountsRepo accounts;
  final LedgerRepo ledger;
  final PlanningRepo planning;
  final MetaRepo meta;
  final LedgerService ledgerService;
  final StatsService statsService;
  final ProjectionService projectionService;
  final ImportService importService;
  final InsightService insightService;
  final ExportService exportService;
  final PortfolioService portfolioService;
  final PortfolioAnalyticsService portfolioAnalytics;
  final YearReportService yearReportService;
  final QuoteFetchService quoteFetch;
  final DirectQuoteService directQuotes;
  final ScenarioService scenarios;
  final PlanExecutionService planExecution;

  /// 解锁后自动执行计划落地入账的笔数（UI 提示一次后清零）。
  int autoPostedCount = 0;

  /// 解锁后从设置读取的可调参数（有默认值）。
  int lockTimeoutMinutes = 5;
  int projectionHorizonDays = 90;
}

/// 密钥存储：密文头保存在应用支持目录（内容无明文机密；
/// 被包裹的 DEK 本身就是密文），恢复码头单独存放。
class FileKeyStore implements KeyStore {
  FileKeyStore(this._dir);

  final Directory _dir;

  File get _primary =>
      File(p.join(_dir.path, 'vault.key'));
  File get _recovery =>
      File(p.join(_dir.path, 'vault.recovery.key'));

  @override
  Future<void> savePrimary(VaultHeader header) =>
      _primary.writeAsString(header.encode(), flush: true);

  @override
  Future<void> saveRecovery(VaultHeader header) =>
      _recovery.writeAsString(header.encode(), flush: true);

  @override
  Future<VaultHeader?> loadPrimary() async =>
      await _primary.exists() ? VaultHeader.decode(await _primary.readAsString()) : null;

  @override
  Future<VaultHeader?> loadRecovery() async =>
      await _recovery.exists()
          ? VaultHeader.decode(await _recovery.readAsString())
          : null;

  @override
  Future<void> clear() async {
    if (await _primary.exists()) await _primary.delete();
    if (await _recovery.exists()) await _recovery.delete();
  }
}

class VaultNotifier extends Notifier<VaultState> {
  Timer? _lockTimer;
  KeyManager? _keyManager;
  FileKeyStore? _store;

  @override
  VaultState build() {
    ref.onDispose(() => _lockTimer?.cancel());
    _init();
    return const VaultUninitialized();
  }

  Future<void> _init() async {
    final dir = await getApplicationSupportDirectory();
    final appDir = Directory(p.join(dir.path, 'assetscope'));
    await appDir.create(recursive: true);
    _store = FileKeyStore(appDir);
    final header = await _store!.loadPrimary();
    state = VaultLocked(hasRecovery: header != null);
  }

  Future<Directory> appDir() async {
    final dir = await getApplicationSupportDirectory();
    return Directory(p.join(dir.path, 'assetscope'));
  }

  CryptoSuite get _suite => DartCryptoSuite.instance;

  /// 首次创建金库。
  Future<String> createVault(String passphrase) async {
    final km = KeyManager(suite: _suite);
    final boot = await km.createVault(passphrase);
    await _store!.savePrimary(boot.header);
    await _store!.saveRecovery(boot.recoveryHeader);
    _keyManager = km;
    await _openDatabase(appDir: await appDir());
    // 提示用户离线保存恢复码
    return boot.recoveryCode;
  }

  /// 解锁（主口令或恢复码）。
  Future<void> unlock(String passphrase) async {
    final store = _store!;
    var header = await store.loadPrimary();
    var viaRecovery = false;
    try {
      if (header == null) {
        throw StateError('金库不存在');
      }
      final km = KeyManager(suite: _suite);
      await km.unlock(passphrase, header);
      _keyManager = km;
    } on WrongPassphraseException {
      header = await store.loadRecovery();
      if (header == null) rethrow;
      final km = KeyManager(suite: _suite);
      await km.unlock(passphrase, header);
      _keyManager = km;
      viaRecovery = true;
    }
    await _openDatabase(appDir: await appDir());
    if (viaRecovery) {
      // 用恢复码解锁后建议尽快改口令（UI 提示）。
    }
  }

  Future<void> _openDatabase({required Directory appDir}) async {
    final km = _keyManager!;
    final dbFile = File(p.join(appDir.path, 'assetscope.db'));
    final db = AppDatabase.openFile(dbFile, dbKeyHex: km.databaseKeyHex());
    final accounts = AccountsRepo(db);
    final ledger = LedgerRepo(db);
    final planning = PlanningRepo(db);
    final meta = MetaRepo(db);
    final stats = StatsService(accounts, ledger, meta);
    final portfolio = PortfolioService(accounts, ledger, meta, stats);
    final projection = ProjectionService(accounts, ledger, planning, meta);
    final quoteFetch =
        QuoteFetchService(accounts, ledger, meta, const AiChat());
    final planExecution = PlanExecutionService(accounts, ledger, planning);
    // 主题偏好先于会话发布生效，避免解锁首帧闪烁。
    final themeStr = await meta.settingString('themeMode');
    if (themeStr != null) {
      ref.read(themeModeProvider.notifier).apply(themeModeFromString(themeStr));
    }
    state = VaultUnlocked(
      db: db,
      keyManager: km,
      accounts: accounts,
      ledger: ledger,
      planning: planning,
      meta: meta,
      ledgerService: LedgerService(accounts, ledger),
      statsService: stats,
      projectionService: projection,
      importService: ImportService(accounts, ledger, meta),
      insightService: InsightService(accounts, ledger, planning, meta),
      exportService: ExportService(accounts, ledger, meta, planning),
      portfolioService: portfolio,
      portfolioAnalytics:
          PortfolioAnalyticsService(ledger, meta, stats, portfolio),
      yearReportService: YearReportService(accounts, ledger, stats),
      quoteFetch: quoteFetch,
      directQuotes: DirectQuoteService(accounts, quoteFetch),
      scenarios: ScenarioService(projection, stats),
      planExecution: planExecution,
    );
    await _loadTunables();
    await _autoPostPlans();
    _armAutoLock();
  }

  /// 解锁后自动落地到期计划（只处理 autoPost 且配置齐全的计划）。
  /// 失败不阻塞会话——待落地清单里仍可手动处理。
  Future<void> _autoPostPlans() async {
    final s = state;
    if (s is! VaultUnlocked) return;
    try {
      s.autoPostedCount = await s.planExecution.postAutoDue();
    } catch (_) {
      s.autoPostedCount = 0;
    }
  }

  /// 设置驱动的可调参数（改设置后无需重启，下次解锁生效；立即生效走 [refreshTunables]）。
  Future<void> _loadTunables() async {
    final s = state;
    if (s is! VaultUnlocked) return;
    final lock = await s.meta.settingInt('lockTimeoutMinutes');
    final horizon = await s.meta.settingInt('projectionHorizonDays');
    if (lock != null) s.lockTimeoutMinutes = lock;
    if (horizon != null) s.projectionHorizonDays = horizon;
  }

  /// 设置页修改锁定时长后调用：立即生效。
  Future<void> refreshTunables() async {
    await _loadTunables();
    if (state is VaultUnlocked) _armAutoLock();
  }

  /// 用户活动：重置自动锁定计时。
  void touch() {
    if (state is VaultUnlocked) _armAutoLock();
  }

  void _armAutoLock() {
    _lockTimer?.cancel();
    final minutes = state is VaultUnlocked
        ? (state as VaultUnlocked).lockTimeoutMinutes
        : 5;
    _lockTimer = Timer(Duration(minutes: minutes), lock);
  }

  /// 立即锁定：关闭数据库并清除内存中的 DEK。
  Future<void> lock() async {
    _lockTimer?.cancel();
    final s = state;
    if (s is VaultUnlocked) {
      await s.db.close();
    }
    _keyManager?.lock();
    state = VaultLocked(hasRecovery: true);
  }

  /// 修改主口令（DEK 不变，数据库不受影响）。
  Future<void> changePassphrase(String oldPass, String newPass) async {
    final store = _store!;
    final header = await store.loadPrimary();
    if (header == null) throw StateError('金库不存在');
    final km = KeyManager(suite: _suite);
    final newHeader =
        await km.changePassphrase(oldPass, newPass, header);
    await store.savePrimary(newHeader);
  }

  /// 重新生成恢复码，返回新码。
  Future<String> regenerateRecoveryCode() async {
    final km = _keyManager;
    if (km == null || !km.isUnlocked) throw StateError('尚未解锁');
    final (code, header) = await km.newRecoveryCode();
    await _store!.saveRecovery(header);
    return code;
  }
}

final vaultProvider =
    NotifierProvider<VaultNotifier, VaultState>(VaultNotifier.new);

/// 便捷：当前已解锁会话（未解锁时为 null）。
VaultUnlocked? sessionOf(VaultState s) => s is VaultUnlocked ? s : null;

/// 外观模式持久化（settings 表 themeMode 键，值 system/light/dark）。
ThemeMode themeModeFromString(String s) => switch (s) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
String themeModeToString(ThemeMode m) => switch (m) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };

/// 外观模式（跟随系统/浅色/深色）：解锁流程从设置表预读，
/// 设置页修改后立即生效；锁定期间记忆保留（锁定页自绘深色）。
class ThemeModeController extends Notifier<ThemeMode> {
  ThemeMode _mode = ThemeMode.system;

  @override
  ThemeMode build() {
    ref.watch(vaultProvider); // 解锁/锁定时重建，但保留已记忆的模式
    return _mode;
  }

  /// 供解锁流程在发布 VaultUnlocked 前预填，避免首帧闪烁。
  void apply(ThemeMode mode) => _mode = mode;

  Future<void> set(ThemeMode mode, VaultUnlocked s) async {
    await s.meta.setSetting('themeMode', themeModeToString(mode));
    _mode = mode;
    ref.invalidateSelf();
  }
}

final themeModeProvider =
    NotifierProvider<ThemeModeController, ThemeMode>(ThemeModeController.new);

/// 当前 base 币种。
final baseCurrencyProvider = FutureProvider<String>((ref) async {
  final s = sessionOf(ref.watch(vaultProvider));
  if (s == null) return 'CNY';
  return s.statsService.baseCurrency();
});
