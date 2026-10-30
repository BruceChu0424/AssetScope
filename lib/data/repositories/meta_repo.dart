import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/money/currency.dart';
import '../../domain/money/fx_rate.dart';
import '../../domain/valuation/valuation.dart';
import '../app_database.dart';

/// 估值、汇率、快照、导入批次、设置仓储。
class MetaRepo {
  MetaRepo(this._db);

  final AppDatabase _db;

  // ---------- 估值 ----------

  Future<List<ValuationRecord>> valuations({String? accountId}) async {
    final query = _db.select(_db.valuations);
    if (accountId != null) {
      query.where((v) => v.accountId.equals(accountId));
    }
    final rows = await query.get();
    return [
      for (final r in rows)
        ValuationRecord(
          accountId: r.accountId,
          date: r.date,
          kind: ValuationKind.values.firstWhere((k) => k.name == r.kind),
          unitPrice: r.unitPriceN == null || r.unitPriceD == null
              ? null
              : Rational.fromInt(r.unitPriceN!) /
                    Rational.fromInt(r.unitPriceD!),
          totalValueMinor: r.totalValueMinor,
          source: r.source,
          note: r.note,
        ),
    ];
  }

  Future<void> saveValuation(ValuationRecord v) => _db
      .into(_db.valuations)
      .insert(
        ValuationsCompanion.insert(
          accountId: v.accountId,
          date: v.date,
          kind: v.kind.name,
          unitPriceN: Value(v.unitPrice?.n),
          unitPriceD: Value(v.unitPrice?.d),
          totalValueMinor: Value(v.totalValueMinor),
          source: Value(v.source),
          note: Value(v.note),
        ),
      );

  // ---------- 汇率 ----------

  Future<void> saveFxRate({
    required String baseCcy,
    required String quoteCcy,
    required DateTime date,
    required Rational rate,
    String source = 'manual',
  }) => _db
      .into(_db.fxRates)
      .insert(
        FxRatesCompanion.insert(
          baseCcy: baseCcy,
          quoteCcy: quoteCcy,
          date: date,
          rateN: rate.n,
          rateD: rate.d,
          source: Value(source),
        ),
      );

  /// base→quote 在 [onOrBefore] 当日或之前最近的汇率。
  Future<FxRate?> fxRateAt({
    required String baseCcy,
    required String quoteCcy,
    required DateTime onOrBefore,
  }) async {
    final query = _db.select(_db.fxRates)
      ..where(
        (f) =>
            f.baseCcy.equals(baseCcy) &
            f.quoteCcy.equals(quoteCcy) &
            f.date.isSmallerOrEqualValue(onOrBefore),
      )
      ..orderBy([(f) => OrderingTerm.desc(f.date)])
      ..limit(1);
    final r = await query.getSingleOrNull();
    if (r == null) return null;
    return FxRate(
      from: CurrencyInfo.parse(r.baseCcy),
      to: CurrencyInfo.parse(r.quoteCcy),
      rate: Rational.fromInt(r.rateN) / Rational.fromInt(r.rateD),
      asOf: r.date,
      source: r.source,
    );
  }

  /// 任意币种 → [base] 的汇率（自动尝试两个方向与缓存）。
  Future<FxRate?> toBaseRate({
    required String ccy,
    required String base,
    required DateTime onOrBefore,
  }) async {
    if (ccy == base) return null; // 无需汇率
    final direct = await fxRateAt(
      baseCcy: ccy,
      quoteCcy: base,
      onOrBefore: onOrBefore,
    );
    if (direct != null) return direct;
    final inverse = await fxRateAt(
      baseCcy: base,
      quoteCcy: ccy,
      onOrBefore: onOrBefore,
    );
    return inverse?.inverse();
  }

  /// 全部汇率对的最新一条（设置页汇率管理用）。
  Future<List<FxRate>> latestFxRates() async {
    final rows = await (_db.select(
      _db.fxRates,
    )..orderBy([(f) => OrderingTerm.desc(f.date)])).get();
    final seen = <String>{};
    final out = <FxRate>[];
    for (final r in rows) {
      final key = '${r.baseCcy}/${r.quoteCcy}';
      if (seen.contains(key)) continue;
      seen.add(key);
      out.add(
        FxRate(
          from: CurrencyInfo.parse(r.baseCcy),
          to: CurrencyInfo.parse(r.quoteCcy),
          rate: Rational.fromInt(r.rateN) / Rational.fromInt(r.rateD),
          asOf: r.date,
          source: r.source,
        ),
      );
    }
    return out;
  }

  // ---------- 快照 ----------

  Future<void> saveSnapshot(String monthKey, Map<String, Object?> payload) =>
      _db
          .into(_db.snapshots)
          .insertOnConflictUpdate(
            SnapshotsCompanion.insert(
              month: monthKey,
              payloadJson: jsonEncode(payload),
            ),
          );

  Future<Map<String, Object?>?> loadSnapshot(String monthKey) async {
    final r = await (_db.select(
      _db.snapshots,
    )..where((s) => s.month.equals(monthKey))).getSingleOrNull();
    if (r == null) return null;
    return jsonDecode(r.payloadJson) as Map<String, Object?>;
  }

  Future<List<(String, DateTime)>> snapshotMonths() async {
    final rows = await (_db.select(
      _db.snapshots,
    )..orderBy([(s) => OrderingTerm.desc(s.month)])).get();
    return [for (final r in rows) (r.month, r.updatedAt)];
  }

  // ---------- 导入批次 ----------

  Future<String> createImportBatch({
    required String source,
    required String filename,
    required String parserVersion,
  }) async {
    final id = 'imp:${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}';
    await _db
        .into(_db.importBatches)
        .insert(
          ImportBatchesCompanion.insert(
            id: id,
            source: source,
            filename: filename,
            parserVersion: parserVersion,
          ),
        );
    return id;
  }

  Future<void> finishImportBatch(
    String id,
    Map<String, Object> counts, {
    required String status,
  }) async {
    await (_db.update(_db.importBatches)..where((b) => b.id.equals(id))).write(
      ImportBatchesCompanion(
        status: Value(status),
        countsJson: Value(jsonEncode(counts)),
      ),
    );
  }

  // ---------- 设置 ----------

  Future<Map<String, Object?>> allSettings() async {
    final rows = await _db.select(_db.settings).get();
    return {for (final r in rows) r.key: jsonDecode(r.valueJson)};
  }

  Future<String?> settingString(String key) async {
    final r = await (_db.select(
      _db.settings,
    )..where((s) => s.key.equals(key))).getSingleOrNull();
    if (r == null) return null;
    return jsonDecode(r.valueJson) as String?;
  }

  Future<int?> settingInt(String key) async {
    final r = await (_db.select(
      _db.settings,
    )..where((s) => s.key.equals(key))).getSingleOrNull();
    if (r == null) return null;
    final v = jsonDecode(r.valueJson);
    return v is int ? v : (v is num ? v.toInt() : null);
  }

  Future<double?> settingDouble(String key) async {
    final r = await (_db.select(
      _db.settings,
    )..where((s) => s.key.equals(key))).getSingleOrNull();
    if (r == null) return null;
    final v = jsonDecode(r.valueJson);
    return v is num ? v.toDouble() : null;
  }

  Future<void> setSetting(String key, Object value) => _db
      .into(_db.settings)
      .insertOnConflictUpdate(
        SettingsCompanion.insert(key: key, valueJson: jsonEncode(value)),
      );

  // ---------- 数据指纹（统计缓存失效判断） ----------

  /// 关键表内容摘要：任一影响统计口径的数据变化（过账/作废/删除、
  /// 估值、汇率、账户口径、设置）都会改变指纹。
  /// 大表用 COUNT+MAX 聚合（O(1) 结果行）；accounts/settings 行数少，
  /// 全量拼接关键列。查询代价 ~6 条小 SQL，适合高频比对。
  Future<String> dataFingerprint() async {
    final parts = <String>[];

    Future<void> agg(String tag, String sql) async {
      final r = await _db.customSelect(sql).getSingle();
      parts.add('$tag:${r.data.values.join('|')}');
    }

    // transactions：行数 + 最近更新 + 作废数（作废只改 status，
    // 同毫秒内 updated_at 可能不变，需显式计入）。
    await agg(
      'tx',
      "SELECT COUNT(*) AS c, IFNULL(MAX(updated_at),'') AS m, "
          "IFNULL(SUM(CASE WHEN status='voided' THEN 1 ELSE 0 END),0) AS v FROM transactions",
    );
    await agg(
      'po',
      'SELECT COUNT(*) AS c, IFNULL(MAX(id),0) AS m FROM postings',
    );
    await agg(
      'va',
      'SELECT COUNT(*) AS c, IFNULL(MAX(id),0) AS m FROM valuations',
    );
    await agg(
      'fx',
      'SELECT COUNT(*) AS c, IFNULL(MAX(id),0) AS m FROM fx_rates',
    );

    // accounts：行数少但更新不改行号（如 archive），全量拼接统计相关列。
    final accRows = await _db
        .customSelect(
          'SELECT id, type, asset_subtype, liability_subtype, currency_code, '
          'include_in_net_worth, archived, cost_basis_account_id, security_id, is_system '
          'FROM accounts ORDER BY id',
        )
        .get();
    final accountsPart = accRows
        .map((r) => r.data.values.map((v) => v ?? '').join('~'))
        .join(';');
    parts.add('ac:$accountsPart');

    final setRows = await (_db.select(
      _db.settings,
    )..orderBy([(s) => OrderingTerm.asc(s.key)])).get();
    parts.add('st:${setRows.map((r) => '${r.key}=${r.valueJson}').join(';')}');

    return parts.join('/');
  }
}
