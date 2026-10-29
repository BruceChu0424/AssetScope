import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';

import '../data/app_database.dart';
import '../domain/utils/hashing.dart';
import '../security/backup.dart';

/// 备份容器预检结果（不落盘、不动库）。
class MergePrecheck {
  MergePrecheck({
    required this.meta,
    required this.sameLineage,
    required this.hasLineage,
    required this.schemaOk,
    required this.backupSchemaVersion,
  });

  final Map<String, Object> meta;

  /// 备份带谱系指纹且与本机一致。
  final bool sameLineage;

  /// 备份是否携带谱系指纹（v0.14 之前导出的备份没有）。
  final bool hasLineage;

  /// 备份 schema 不高于本机应用。
  final bool schemaOk;
  final int backupSchemaVersion;
}

/// 合并计数（预览与结果共用同一口径）。
class MergeCounts {
  MergeCounts({
    this.newTransactions = 0,
    this.updatedTransactions = 0,
    this.newAccounts = 0,
    this.newSecurities = 0,
    this.newEvents = 0,
    this.mergedEventSets = 0,
    this.newBudgets = 0,
    this.newGoals = 0,
    this.newContracts = 0,
    this.newValuations = 0,
    this.newFxRates = 0,
    this.newSnapshots = 0,
    this.newSettings = 0,
  });

  int newTransactions;
  int updatedTransactions;
  int newAccounts;
  int newSecurities;
  int newEvents;
  int mergedEventSets;
  int newBudgets;
  int newGoals;
  int newContracts;
  int newValuations;
  int newFxRates;
  int newSnapshots;
  int newSettings;

  bool get isEmpty =>
      newTransactions == 0 &&
      updatedTransactions == 0 &&
      newAccounts == 0 &&
      newSecurities == 0 &&
      newEvents == 0 &&
      mergedEventSets == 0 &&
      newBudgets == 0 &&
      newGoals == 0 &&
      newContracts == 0 &&
      newValuations == 0 &&
      newFxRates == 0 &&
      newSnapshots == 0 &&
      newSettings == 0;

  /// 人读摘要（结果弹层用）。
  String summarize() {
    final parts = <String>[
      if (newTransactions > 0) '新增 $newTransactions 笔交易',
      if (updatedTransactions > 0) '更新 $updatedTransactions 笔交易',
      if (newAccounts > 0) '新增 $newAccounts 个账户',
      if (newSecurities > 0) '新增 $newSecurities 个证券',
      if (newEvents > 0) '新增 $newEvents 条计划',
      if (mergedEventSets > 0) '合并 $mergedEventSets 条计划的跳过/覆盖',
      if (newBudgets > 0) '新增 $newBudgets 个预算',
      if (newGoals > 0) '新增 $newGoals 个目标',
      if (newContracts > 0) '新增 $newContracts 份贷款合同',
      if (newValuations > 0) '新增 $newValuations 条估值',
      if (newFxRates > 0) '新增 $newFxRates 条汇率',
      if (newSettings > 0) '补齐 $newSettings 项设置',
    ];
    return parts.isEmpty ? '两份账本已一致，没有需要合并的内容' : parts.join('；');
  }
}

/// 账本合并：把另一份同谱系账本（.asbk 解密后的明文库）并入当前库。
///
/// 表级策略（docs/08 §5）：
/// - transactions：按 id，updated_at 新者胜（LWW）；分录随交易整体替换；
/// - accounts/securities/budgets/goals/debt_contracts/import_batches：
///   按 id 补缺（本机已存在则保留本机——这些表无时间戳，冲突罕见且可手改）；
/// - scheduled_events：按 id 补缺 + 双端都存在时，跳过月份/日期与金额覆盖
///   做**集合并集**（同键金额覆盖冲突时本机优先）；
/// - valuations：自然键 (account_id, date, kind) 去重补缺；
/// - fx_rates：自然键 (base_ccy, quote_ccy, date) 去重补缺；
/// - snapshots：按月 LWW（updated_at 新者胜）——只是报表缓存；
/// - settings：只补缺，本机已有键一律保留（主题/锁时/AI 密钥是设备级偏好）。
///
/// [applyFrom] 在**单个事务**内完成，任一步失败整体回滚；
/// [previewFrom] 只读不写。两个方法都要求传入的明文库已迁移到当前 schema。
class MergeService {
  MergeService(this._db);

  final AppDatabase _db;
  static const _src = 'merge_src';

  /// 账本谱系指纹：DEK 的 SHA-256 hex。同一金库（含改口令/换恢复码后的
  /// 各设备）指纹不变；不同金库必然不同。导出时写入容器 meta，
  /// 合并前校验，防止把别的账本并进来。
  static String vaultFingerprint(String dbKeyHex) =>
      sha256Hex(utf8.encode('assetscope-vault|$dbKeyHex'));

  /// 容器预检：可解密性 + 谱系 + schema 版本（不解库、不写盘）。
  static Future<MergePrecheck> precheck({
    required Uint8List container,
    required String currentFingerprint,
    required int currentSchemaVersion,
    Uint8List? dek,
    String? passphrase,
  }) async {
    final meta = await BackupContainer.open(container,
        dek: dek, passphrase: passphrase);
    final backupVaultId = meta.meta['vaultId'];
    final backupSchema =
        (meta.meta['schemaVersion'] as num?)?.toInt() ?? currentSchemaVersion;
    return MergePrecheck(
      meta: meta.meta,
      hasLineage: backupVaultId is String,
      sameLineage: backupVaultId is String && backupVaultId == currentFingerprint,
      schemaOk: backupSchema <= currentSchemaVersion,
      backupSchemaVersion: backupSchema,
    );
  }

  /// 解密容器 → 明文临时库（自动迁移到当前 schema + 完整性检查）。
  /// 调用方负责用完删除返回的文件。
  static Future<File> decryptToPlain({
    required Uint8List container,
    required Directory workDir,
    Uint8List? dek,
    String? passphrase,
  }) async {
    final payload = await BackupContainer.open(container,
        dek: dek, passphrase: passphrase);
    await workDir.create(recursive: true);
    final plain = File(
        '${workDir.path}${Platform.pathSeparator}assetscope-merge-src.db');
    if (await plain.exists()) await plain.delete();
    try {
      await plain.writeAsBytes(payload.bytes, flush: true);
      // 打开即触发 drift 迁移到当前 schema；顺带完整性检查。
      final probe = AppDatabase(NativeDatabase(plain));
      try {
        await probe.customStatement('PRAGMA integrity_check');
        await probe.customSelect('SELECT COUNT(*) c FROM transactions').getSingle();
      } finally {
        await probe.close();
      }
      return plain;
    } catch (_) {
      if (await plain.exists()) await plain.delete();
      rethrow;
    }
  }

  /// 预览将要合并的内容（不写入任何数据，可重复调用）。
  Future<MergeCounts> previewFrom(File plainDb) async {
    final c = MergeCounts();
    await _withSrc(plainDb, () async {
      await _computeCounts(c);
    });
    return c;
  }

  /// 执行合并（单事务，失败回滚）。返回实际生效的计数——
  /// 计数在写入前按预览口径计算：事务内单写者，所见即所改。
  Future<MergeCounts> applyFrom(File plainDb) async {
    final c = MergeCounts();
    await _withSrc(plainDb, () async {
      await _db.transaction(() async {
        await _computeCounts(c);

        // 1) 交易 LWW：win = 新交易或 updated_at 更新者；分录随交易整体替换。
        await _db.customStatement(
            'CREATE TEMP TABLE IF NOT EXISTS merge_win (id TEXT NOT NULL)');
        await _db.customStatement('DELETE FROM merge_win');
        await _db.customStatement(
            'INSERT INTO merge_win '
            'SELECT s.id FROM $_src.transactions s '
            'LEFT JOIN main.transactions t ON t.id = s.id '
            'WHERE t.id IS NULL OR s.updated_at > t.updated_at');
        await _db.customStatement(
            'INSERT OR REPLACE INTO main.transactions '
            'SELECT s.* FROM $_src.transactions s JOIN merge_win w ON w.id = s.id');
        await _db.customStatement(
            'DELETE FROM main.postings WHERE tx_id IN (SELECT id FROM merge_win)');
        await _db.customStatement(
            'INSERT INTO main.postings '
            '(tx_id, account_id, amount_minor, currency_code, security_id, '
            'quantity_n, quantity_d, memo) '
            'SELECT p.tx_id, p.account_id, p.amount_minor, p.currency_code, '
            'p.security_id, p.quantity_n, p.quantity_d, p.memo '
            'FROM $_src.postings p JOIN merge_win w ON w.id = p.tx_id');

        // 2) 按 id 补缺的表（本机已存在则保留本机）。
        for (final table in [
          'accounts',
          'securities',
          'budgets',
          'goals',
          'debt_contracts',
          'import_batches',
          'scheduled_events',
        ]) {
          await _db.customStatement(
              'INSERT OR IGNORE INTO main.$table SELECT s.* FROM $_src.$table s');
        }

        // 3) 计划事件双端并存：跳过/覆盖做并集（本机金额覆盖优先）。
        await _unionEventSets();

        // 4) 估值/汇率：自然键去重补缺（自增 id 不跨库迁移）。
        await _db.customStatement(
            'INSERT INTO main.valuations '
            '(account_id, date, kind, unit_price_n, unit_price_d, '
            'total_value_minor, source, note) '
            'SELECT s.account_id, s.date, s.kind, s.unit_price_n, '
            's.unit_price_d, s.total_value_minor, s.source, s.note '
            'FROM $_src.valuations s WHERE NOT EXISTS ('
            'SELECT 1 FROM main.valuations v WHERE v.account_id = s.account_id '
            'AND v.date = s.date AND v.kind = s.kind)');
        await _db.customStatement(
            'INSERT INTO main.fx_rates '
            '(base_ccy, quote_ccy, date, rate_n, rate_d, source) '
            'SELECT s.base_ccy, s.quote_ccy, s.date, s.rate_n, s.rate_d, s.source '
            'FROM $_src.fx_rates s WHERE NOT EXISTS ('
            'SELECT 1 FROM main.fx_rates f WHERE f.base_ccy = s.base_ccy '
            'AND f.quote_ccy = s.quote_ccy AND f.date = s.date)');

        // 5) 月度快照 LWW（报表缓存，新者胜）。
        await _db.customStatement(
            'INSERT INTO main.snapshots (month, payload_json, updated_at) '
            'SELECT s.month, s.payload_json, s.updated_at FROM $_src.snapshots s '
            'WHERE true ON CONFLICT(month) DO UPDATE SET '
            'payload_json = excluded.payload_json, updated_at = excluded.updated_at '
            'WHERE excluded.updated_at > snapshots.updated_at');

        // 6) 设置只补缺（本机已有键保留）。
        await _db.customStatement(
            'INSERT OR IGNORE INTO main.settings SELECT s.* FROM $_src.settings s');
      });
    });
    return c;
  }

  /// 计数（预览与执行共用同一口径，在写入前执行）。
  Future<void> _computeCounts(MergeCounts c) async {
    await _fillTxCounts(c);
    c.newAccounts = await _countMissingBy('accounts', 'id');
    c.newSecurities = await _countMissingBy('securities', 'id');
    c.newEvents = await _countMissingBy('scheduled_events', 'id');
    c.mergedEventSets = await _countEventSetMerges();
    c.newBudgets = await _countMissingBy('budgets', 'id');
    c.newGoals = await _countMissingBy('goals', 'id');
    c.newContracts =
        await _countMissingBy('debt_contracts', 'liability_account_id');
    c.newValuations = (await _db.customSelect(
            'SELECT COUNT(*) n FROM $_src.valuations s WHERE NOT EXISTS ('
            'SELECT 1 FROM main.valuations v WHERE v.account_id = s.account_id '
            'AND v.date = s.date AND v.kind = s.kind)')
        .getSingle())
        .read<int>('n');
    c.newFxRates = (await _db.customSelect(
            'SELECT COUNT(*) n FROM $_src.fx_rates s WHERE NOT EXISTS ('
            'SELECT 1 FROM main.fx_rates f WHERE f.base_ccy = s.base_ccy '
            'AND f.quote_ccy = s.quote_ccy AND f.date = s.date)')
        .getSingle())
        .read<int>('n');
    c.newSnapshots = (await _db.customSelect(
            'SELECT COUNT(*) n FROM $_src.snapshots s WHERE NOT EXISTS ('
            'SELECT 1 FROM main.snapshots m WHERE m.month = s.month) '
            'OR EXISTS (SELECT 1 FROM main.snapshots m '
            'WHERE m.month = s.month AND s.updated_at > m.updated_at)')
        .getSingle())
        .read<int>('n');
    c.newSettings = await _countMissingBy('settings', 'key');
  }

  Future<void> _withSrc(File plainDb, Future<void> Function() body) async {
    await _db.customStatement(
        "ATTACH DATABASE ? AS $_src KEY ''", [plainDb.path]);
    try {
      await body();
    } finally {
      await _db.customStatement('DETACH DATABASE $_src');
    }
  }

  /// 交易胜负计数：填 [c].newTransactions / updatedTransactions。
  Future<void> _fillTxCounts(MergeCounts c) async {
    final total = await _db.customSelect(
        'SELECT COUNT(*) n FROM $_src.transactions s '
        'LEFT JOIN main.transactions t ON t.id = s.id '
        'WHERE t.id IS NULL OR s.updated_at > t.updated_at').getSingle();
    final fresh = await _db.customSelect(
        'SELECT COUNT(*) n FROM $_src.transactions s '
        'WHERE NOT EXISTS (SELECT 1 FROM main.transactions t WHERE t.id = s.id)')
        .getSingle();
    c.newTransactions = fresh.read<int>('n');
    c.updatedTransactions = total.read<int>('n') - c.newTransactions;
  }

  /// src 中存在、main 中缺失的行数（应用后调用即"实际新增"）。
  Future<int> _countMissingBy(String table, String pk) async {
    final r = await _db.customSelect(
        'SELECT COUNT(*) n FROM $_src.$table s WHERE NOT EXISTS ('
        'SELECT 1 FROM main.$table m WHERE m.$pk = s.$pk)').getSingle();
    return r.read<int>('n');
  }

  /// 双端并存且跳过/覆盖集合不同的计划数（预览口径）。
  Future<int> _countEventSetMerges() async {
    final rows = await _db.customSelect(
        'SELECT s.id AS id, m.skipped_months_json mm, m.skipped_dates_json md, '
        'm.amount_overrides_json mo, s.skipped_months_json sm, '
        's.skipped_dates_json sd, s.amount_overrides_json so '
        'FROM $_src.scheduled_events s JOIN main.scheduled_events m ON m.id = s.id'
        ).get();
    var n = 0;
    for (final r in rows) {
      if (_unionSets(r.read<String>('mm'), r.read<String>('sm')) !=
              r.read<String>('mm') ||
          _unionSets(r.read<String>('md'), r.read<String>('sd')) !=
              r.read<String>('md') ||
          _mergeOverrides(r.read<String>('mo'), r.read<String>('so')) !=
              r.read<String>('mo')) {
        n++;
      }
    }
    return n;
  }

  /// 计划事件集合并集落库；返回发生变化的条数。
  Future<int> _unionEventSets() async {
    final rows = await _db.customSelect(
        'SELECT s.id AS id, m.skipped_months_json mm, m.skipped_dates_json md, '
        'm.amount_overrides_json mo, s.skipped_months_json sm, '
        's.skipped_dates_json sd, s.amount_overrides_json so '
        'FROM $_src.scheduled_events s JOIN main.scheduled_events m ON m.id = s.id'
        ).get();
    var changed = 0;
    for (final r in rows) {
      final months = _unionSets(r.read<String>('mm'), r.read<String>('sm'));
      final dates = _unionSets(r.read<String>('md'), r.read<String>('sd'));
      final overrides =
          _mergeOverrides(r.read<String>('mo'), r.read<String>('so'));
      if (months == r.read<String>('mm') &&
          dates == r.read<String>('md') &&
          overrides == r.read<String>('mo')) {
        continue;
      }
      await _db.customUpdate(
          'UPDATE main.scheduled_events SET skipped_months_json = ?, '
          'skipped_dates_json = ?, amount_overrides_json = ? WHERE id = ?',
          variables: [
            Variable.withString(months),
            Variable.withString(dates),
            Variable.withString(overrides),
            Variable.withString(r.read<String>('id')),
          ]);
      changed++;
    }
    return changed;
  }

  /// 两个 JSON 数组的并集（保持本机元素在前、稳定排序）。
  static String _unionSets(String localJson, String incomingJson) {
    final local = (jsonDecode(localJson) as List).toSet();
    final incoming = (jsonDecode(incomingJson) as List).toSet();
    if (incoming.difference(local).isEmpty) return localJson;
    final merged = [...local, ...incoming.difference(local)]..sort();
    return jsonEncode(merged);
  }

  /// 两个 JSON 对象合并：补缺 + 同键本机优先。
  static String _mergeOverrides(String localJson, String incomingJson) {
    final local = jsonDecode(localJson) as Map<String, dynamic>;
    final incoming = jsonDecode(incomingJson) as Map<String, dynamic>;
    var changed = false;
    for (final e in incoming.entries) {
      if (!local.containsKey(e.key)) {
        local[e.key] = e.value;
        changed = true;
      }
    }
    return changed ? jsonEncode(local) : localJson;
  }
}
