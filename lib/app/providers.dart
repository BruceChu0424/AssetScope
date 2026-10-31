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
import '../l10n/runtime_l10n.dart';
import '../security/crypto_suite.dart';
import '../security/dart_crypto_suite.dart';
import '../security/key_manager.dart';
import '../services/ai/ai_usage.dart';
import '../services/ai/ai_valuation_service.dart';
import '../services/ai/assistant_service.dart';
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
    required this.aiValuation,
    required this.assistant,
    required this.aiUsage,
    this.hasRecoveryCode = true,
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
  final AiValuationService aiValuation;
  final AssistantService assistant;
  final AiUsageStore aiUsage;

  /// 解锁后自动执行计划落地入账的笔数（UI 提示一次后清零）。
  int autoPostedCount = 0;

  /// 解锁后 AI 自动估值成功的条数（UI 提示一次后清零；
  /// -1 = 本轮有失败项，提示里带失败数）。
  int aiValuationNotice = 0;

  /// 解锁后从设置读取的可调参数（有默认值）。
  int lockTimeoutMinutes = 5;
  int projectionHorizonDays = 90;

  /// 恢复码是否已落盘（安全页状态章数据源；测试直构默认 true）。
  final bool hasRecoveryCode;
}

/// 密钥存储：密文头保存在应用支持目录（内容无明文机密；
/// 被包裹的 DEK 本身就是密文），恢复码头单独存放。
class FileKeyStore implements KeyStore {
  FileKeyStore(this._dir);

  final Directory _dir;

  File get _primary => File(p.join(_dir.path, 'vault.key'));
  File get _recovery => File(p.join(_dir.path, 'vault.recovery.key'));

  @override
  Future<void> savePrimary(VaultHeader header) =>
      _primary.writeAsString(header.encode(), flush: true);

  @override
  Future<void> saveRecovery(VaultHeader header) =>
      _recovery.writeAsString(header.encode(), flush: true);

  @override
  Future<VaultHeader?> loadPrimary() async => await _primary.exists()
      ? VaultHeader.decode(await _primary.readAsString())
      : null;

  @override
  Future<VaultHeader?> loadRecovery() async => await _recovery.exists()
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
    final dir = await _supportDir();
    final appDir = Directory(p.join(dir.path, 'assetscope'));
    await appDir.create(recursive: true);
    _store = FileKeyStore(appDir);
    final header = await _store!.loadPrimary();
    // 首次运行（无密钥头）：保持 VaultUninitialized，锁屏显示"创建"表单。
    // 不得在此置为 Locked——否则新用户会面对永远解不开的解锁死锁
    // （v0.2 引入锁屏起存在，直至 v0.15 由真机首启动发现）。
    if (header != null) {
      state = VaultLocked(hasRecovery: true);
    }
  }

  Future<Directory> appDir() async {
    final dir = await _supportDir();
    return Directory(p.join(dir.path, 'assetscope'));
  }

  /// 开发预览：`--dart-define=ASCOPE_PREVIEW_DIR=<路径>` 时账本改用
  /// 指定目录（隔离真实数据，便于 UI 走查/截图）；正式构建不受影响。
  static const _previewDir = String.fromEnvironment('ASCOPE_PREVIEW_DIR');

  Future<Directory> _supportDir() async => _previewDir.isEmpty
      ? await getApplicationSupportDirectory()
      : Directory(_previewDir);

  CryptoSuite get _suite => DartCryptoSuite.instance;

  /// 首次创建金库：派生密钥并落盘密钥头。**不**在此发布会话——恢复码
  /// 必须先让用户离线保存（LockPage 展示恢复码界面），待确认后再
  /// [finishCreate] 打开数据库进入首页。若中途退出，下次启动走正常
  /// 解锁（口令即创建口令），无中间态。
  Future<String> createVault(String passphrase) async {
    final km = KeyManager(suite: _suite);
    final boot = await km.createVault(passphrase);
    await _store!.savePrimary(boot.header);
    await _store!.saveRecovery(boot.recoveryHeader);
    _keyManager = km;
    return boot.recoveryCode;
  }

  /// 创建确认（恢复码已保存）：打开数据库、发布会话，进入首页。
  Future<void> finishCreate() async {
    await _openDatabase(appDir: await appDir());
  }

  /// 解锁（主口令或恢复码）＝核验 + 落库发布会话。
  /// UI 需要分两段编排（核验期间只有按钮粒子、成功后才上全屏舞台）时
  /// 直接用 [unlockCheck] + [finalizeUnlock]。
  Future<void> unlock(String passphrase) async {
    await unlockCheck(passphrase);
    await finalizeUnlock();
  }

  /// 解锁第一步：只核验口令（慢哈希在此），不发布会话、不换树。
  ///
  /// 快排门控（省一轮注定失败的慢哈希）：
  /// - 形如恢复码的输入先试恢复码头，命中即免主口令那轮；
  /// - 主口令失败且输入不符恢复码形态（[looksLikeRecoveryCode]）时
  ///   立即抛 [WrongPassphraseException]——不符形态的字符串不可能等于
  ///   任何恢复码，第二轮必败，不再白等。
  ///
  /// 失败抛 [WrongPassphraseException]；成功把已装填密钥的 KeyManager
  /// 挂上本 notifier 并返回（恢复码命中时同样返回，调用方可提示改口令）。
  Future<KeyManager> unlockCheck(String passphrase) async {
    final store = _store!;
    final primary = await store.loadPrimary();
    final recovery = await store.loadRecovery();
    if (primary == null && recovery == null) {
      throw StateError(rt('金库不存在'));
    }
    final recoveryShaped = looksLikeRecoveryCode(passphrase);
    final order = recoveryShaped
        ? <(String, VaultHeader?)>[
            ('recovery', recovery),
            ('primary', primary),
          ]
        : <(String, VaultHeader?)>[
            ('primary', primary),
            ('recovery', recovery),
          ];
    for (final (kind, header) in order) {
      if (header == null) continue;
      final km = KeyManager(suite: _suite);
      try {
        await km.unlock(passphrase, header);
        _keyManager = km;
        return km;
      } on WrongPassphraseException {
        if (kind == 'primary' && !recoveryShaped) break;
      }
    }
    throw WrongPassphraseException();
  }

  /// 解锁第二步（口令已核验）：打开数据库、发布会话进入首页。
  Future<void> finalizeUnlock() async {
    await _openDatabase(appDir: await appDir());
  }

  Future<void> _openDatabase({required Directory appDir}) async {
    final km = _keyManager!;
    final dbFile = File(p.join(appDir.path, 'assetscope.db'));
    final db = AppDatabase.openFile(dbFile, dbKeyHex: km.databaseKeyHex());
    final accounts = AccountsRepo(db);
    final ledger = LedgerRepo(db);
    final planning = PlanningRepo(db);
    final meta = MetaRepo(db);
    // 安全页「恢复码」状态章：恢复码头是否落盘。
    final hasRecovery = await _store!.loadRecovery() != null;
    final stats = StatsService(accounts, ledger, meta);
    final portfolio = PortfolioService(accounts, ledger, meta, stats);
    final projection = ProjectionService(accounts, ledger, planning, meta);
    // 全部 AI 请求经同一计数实例（设置页「用量与额度」统计）。
    final aiUsage = AiUsageStore(meta);
    final chat = CountingAiChat(onCall: aiUsage.record);
    final aiValuation = AiValuationService(accounts, meta, chat);
    final assistant = AssistantService(stats, meta, chat);
    final quoteFetch = QuoteFetchService(
      accounts,
      ledger,
      meta,
      chat,
    );
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
      portfolioAnalytics: PortfolioAnalyticsService(
        ledger,
        meta,
        stats,
        portfolio,
      ),
      yearReportService: YearReportService(accounts, ledger, stats),
      quoteFetch: quoteFetch,
      directQuotes: DirectQuoteService(accounts, quoteFetch),
      scenarios: ScenarioService(projection, stats),
      planExecution: planExecution,
      aiValuation: aiValuation,
      assistant: assistant,
      aiUsage: aiUsage,
      hasRecoveryCode: hasRecovery,
    );
    // 安全事件日志：解锁（含首建后的开启，同属会话建立）。
    unawaited(meta.appendSecurityEvent('unlock'));
    await _loadTunables();
    await _autoPostPlans();
    unawaited(_autoAiValuation());
    _armAutoLock();
  }

  /// 解锁后后台自动刷新资产 AI 估值（每天一轮；不阻塞进入首页，
  /// 失败静默——详情页可手动重估）。完成计数经
  /// [VaultUnlocked.aiValuationNotice] 交首页轮询组件提示并刷新统计。
  Future<void> _autoAiValuation() async {
    final s = state;
    if (s is! VaultUnlocked) return;
    try {
      final run = await s.aiValuation.refreshDue();
      if (state != s) return; // 期间已锁定/换会话
      if (run.updated > 0) {
        s.aiValuationNotice = run.failures.isEmpty ? run.updated : -run.updated;
      }
    } catch (_) {
      // 静默：AI 未配置/网络失败不影响使用。
    }
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
      // 安全事件日志：先落库再关库。
      await s.meta.appendSecurityEvent('lock');
      await s.db.close();
    }
    _keyManager?.lock();
    state = VaultLocked(hasRecovery: true);
  }

  /// 修改主口令（DEK 不变，数据库不受影响）。
  Future<void> changePassphrase(String oldPass, String newPass) async {
    final store = _store!;
    final header = await store.loadPrimary();
    if (header == null) throw StateError(rt('金库不存在'));
    final km = KeyManager(suite: _suite);
    final newHeader = await km.changePassphrase(oldPass, newPass, header);
    await store.savePrimary(newHeader);
    final s = state;
    if (s is VaultUnlocked) await s.meta.appendSecurityEvent('pass');
  }

  /// 重新生成恢复码，返回新码。
  Future<String> regenerateRecoveryCode() async {
    final km = _keyManager;
    if (km == null || !km.isUnlocked) throw StateError(rt('尚未解锁'));
    final (code, header) = await km.newRecoveryCode();
    await _store!.saveRecovery(header);
    final s = state;
    if (s is VaultUnlocked) await s.meta.appendSecurityEvent('recovery');
    return code;
  }
}

final vaultProvider = NotifierProvider<VaultNotifier, VaultState>(
  VaultNotifier.new,
);

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

final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);

/// 当前 base 币种。
final baseCurrencyProvider = FutureProvider<String>((ref) async {
  final s = sessionOf(ref.watch(vaultProvider));
  if (s == null) return 'CNY';
  return s.statsService.baseCurrency();
});
