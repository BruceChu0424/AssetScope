import 'package:drift/drift.dart';

import '../../domain/ledger/ledger_math.dart';
import '../../domain/ledger/posting.dart';
import '../../domain/ledger/transaction.dart';
import '../../domain/money/fx_rate.dart';
import '../app_database.dart';

/// 账本仓储：交易写入（含守恒校验）、查询、余额与数量聚合。
class LedgerRepo {
  LedgerRepo(this._db);

  final AppDatabase _db;

  /// 过账：校验守恒后原子写入。返回带 id 的交易。
  Future<LedgerTransaction> post(TransactionDraft draft, {String? id}) async {
    final violation = LedgerMath.checkConservation(draft.postings);
    if (violation != null) {
      throw StateError('拒绝过账（$violation）kind=${draft.kind.name}');
    }
    final txId = id ?? 'tx:${_newId()}';
    final now = DateTime.now();
    await _db.transaction(() async {
      await _db.into(_db.transactions).insert(TransactionsCompanion.insert(
            id: txId,
            date: draft.date,
            kind: draft.kind.name,
            status: Value(draft.status.name),
            note: Value(draft.note),
            counterparty: Value(draft.counterparty),
            categoryId: Value(draft.categoryId),
            tagsJson: Value(draft.tags.join(',')),
            externalId: Value(draft.externalId),
            source: Value(draft.source.name),
            importBatchId: Value(draft.importBatchId),
            isAdjustment: Value(draft.isAdjustment || draft.kind.isAdjustmentKind),
            createdAt: Value(now),
            updatedAt: Value(now),
          ));
      for (final p in draft.postings) {
        await _db.into(_db.postings).insert(PostingsCompanion.insert(
              txId: txId,
              accountId: p.accountId,
              amountMinor: Value(p.amountMinor),
              currencyCode: Value(p.currencyCode),
              securityId: Value(p.securityId),
              quantityN: Value(p.quantity?.n),
              quantityD: Value(p.quantity?.d),
              memo: Value(p.memo),
            ));
      }
    });
    return LedgerTransaction(
      id: txId,
      date: draft.date,
      kind: draft.kind,
      status: draft.status,
      postings: draft.postings,
      note: draft.note,
      counterparty: draft.counterparty,
      categoryId: draft.categoryId,
      tags: draft.tags,
      externalId: draft.externalId,
      source: draft.source,
      importBatchId: draft.importBatchId,
      isAdjustment: draft.isAdjustment || draft.kind.isAdjustmentKind,
      createdAt: now,
      updatedAt: now,
    );
  }

  Future<void> voidTransaction(String txId) =>
      (_db.update(_db.transactions)..where((t) => t.id.equals(txId)))
          .write(TransactionsCompanion(
              status: const Value('voided'), updatedAt: Value(DateTime.now())));

  Future<void> deleteTransaction(String txId) => _db.transaction(() async {
        await (_db.delete(_db.postings)..where((p) => p.txId.equals(txId))).go();
        await (_db.delete(_db.transactions)..where((t) => t.id.equals(txId)))
            .go();
      });

  LedgerTransaction _toDomain(TransactionRow t, List<PostingRow> postings) {
    return LedgerTransaction(
      id: t.id,
      date: t.date,
      kind: TxKind.values.firstWhere((k) => k.name == t.kind),
      status: TxStatus.values.firstWhere((s) => s.name == t.status),
      postings: [
        for (final p in postings)
          p.securityId != null
              ? Posting.quantity(
                  accountId: p.accountId,
                  securityId: p.securityId,
                  quantity: Rational.fromInt(p.quantityN ?? BigInt.zero) /
                      Rational.fromInt(p.quantityD ?? BigInt.one),
                  memo: p.memo,
                )
              : Posting.money(
                  accountId: p.accountId,
                  amountMinor: p.amountMinor ?? BigInt.zero,
                  currencyCode: p.currencyCode ?? '',
                  memo: p.memo,
                )
      ],
      note: t.note,
      counterparty: t.counterparty,
      categoryId: t.categoryId,
      tags: t.tagsJson.isEmpty ? const [] : t.tagsJson.split(','),
      externalId: t.externalId,
      source: TxSource.values.firstWhere((s) => s.name == t.source),
      importBatchId: t.importBatchId,
      isAdjustment: t.isAdjustment,
      createdAt: t.createdAt,
      updatedAt: t.updatedAt,
    );
  }

  /// 日期区间内的交易（默认只含 posted）。
  Future<List<LedgerTransaction>> list({
    DateTime? from,
    DateTime? to,
    bool includeVoided = false,
    String? accountId,
    int? limit,
  }) async {
    final query = _db.select(_db.transactions).join(
        [innerJoin(_db.postings, _db.postings.txId.equalsExp(_db.transactions.id))]);
    query.where(_db.transactions.date.isBetweenValues(
        from ?? DateTime(1970), to ?? DateTime(2999, 12, 31)));
    if (!includeVoided) {
      query.where(_db.transactions.status.equals('posted'));
    }
    if (accountId != null) {
      query.where(_db.postings.accountId.equals(accountId));
      query.groupBy([_db.transactions.id]);
    }
    query.orderBy([OrderingTerm.desc(_db.transactions.date)]);
    if (limit != null) {
      query.limit(limit);
    }
    final rows = await query.get();
    final txIds = rows.map((r) => r.readTable(_db.transactions)).toList();
    if (txIds.isEmpty) return [];
    final postingRows = await (_db.select(_db.postings)
          ..where((p) => p.txId.isIn(txIds.map((t) => t.id).toList())))
        .get();
    final byTx = <String, List<PostingRow>>{};
    for (final p in postingRows) {
      byTx.putIfAbsent(p.txId, () => []).add(p);
    }
    // 去重（join 可能因 posting 多行产生重复交易行）
    final seen = <String>{};
    final out = <LedgerTransaction>[];
    for (final t in txIds) {
      if (seen.contains(t.id)) continue;
      seen.add(t.id);
      out.add(_toDomain(t, byTx[t.id] ?? const []));
    }
    return out;
  }

  Stream<List<LedgerTransaction>> watchLatest({int limit = 200}) {
    final query = _db.select(_db.transactions)
      ..where((t) => t.status.equals('posted'))
      ..orderBy([(t) => OrderingTerm.desc(t.date)])
      ..limit(limit);
    return query.watch().asyncMap((rows) async {
      if (rows.isEmpty) return [];
      final postingRows = await (_db.select(_db.postings)
            ..where((p) => p.txId.isIn(rows.map((t) => t.id).toList())))
          .get();
      final byTx = <String, List<PostingRow>>{};
      for (final p in postingRows) {
        byTx.putIfAbsent(p.txId, () => []).add(p);
      }
      return [for (final t in rows) _toDomain(t, byTx[t.id] ?? const [])];
    });
  }

  /// 账户在 [date]（含当日）的货币余额（带符号：借方为正）。
  /// 只统计 posted 交易。
  Future<Map<String, BigInt>> moneyBalancesAt(DateTime date,
      {Set<String>? accountIds}) async {
    final query = _db.select(_db.postings).join([
      innerJoin(_db.transactions, _db.transactions.id.equalsExp(_db.postings.txId))
    ]);
    query.where(_db.transactions.date.isSmallerOrEqualValue(date) &
        _db.transactions.status.equals('posted') &
        _db.postings.amountMinor.isNotNull());
    if (accountIds != null) {
      query.where(_db.postings.accountId.isIn(accountIds.toList()));
    }
    final rows = await query
        .map((row) => (row.readTable(_db.postings), row.readTable(_db.transactions)))
        .get();
    final sums = <String, BigInt>{};
    for (final (p, _) in rows) {
      final acc = sums[p.accountId] ?? BigInt.zero;
      sums[p.accountId] = acc + (p.amountMinor ?? BigInt.zero);
    }
    return sums;
  }

  /// 持仓账户在 [date] 的数量余额。
  Future<Map<String, Rational>> quantityBalancesAt(DateTime date) async {
    final query = _db.select(_db.postings).join([
      innerJoin(_db.transactions, _db.transactions.id.equalsExp(_db.postings.txId))
    ]);
    query.where(_db.transactions.date.isSmallerOrEqualValue(date) &
        _db.transactions.status.equals('posted') &
        _db.postings.securityId.isNotNull());
    final rows = await query.map((row) => row.readTable(_db.postings)).get();
    final sums = <String, Rational>{};
    for (final p in rows) {
      final cur = sums[p.accountId] ?? Rational.zero();
      sums[p.accountId] = cur +
          Rational.fromInt(p.quantityN ?? BigInt.zero) /
              Rational.fromInt(p.quantityD ?? BigInt.one);
    }
    return sums;
  }

  /// 某月触达账户/分类的货币分录合计（用于统计）。
  /// 返回 accountId → signed sum。
  Future<Map<String, BigInt>> postingSumsBetween(
      DateTime from, DateTime to) async {
    final query = _db.select(_db.postings).join([
      innerJoin(_db.transactions, _db.transactions.id.equalsExp(_db.postings.txId))
    ]);
    query.where(_db.transactions.date.isBetweenValues(from, to) &
        _db.transactions.status.equals('posted') &
        _db.postings.amountMinor.isNotNull());
    final rows = await query.map((row) => row.readTable(_db.postings)).get();
    final sums = <String, BigInt>{};
    for (final p in rows) {
      sums[p.accountId] = (sums[p.accountId] ?? BigInt.zero) + (p.amountMinor ?? BigInt.zero);
    }
    return sums;
  }

  /// 期初余额类交易的关联账户（补录检测）。
  Future<Set<String>> externalIds() async {
    final rows = await (_db.selectOnly(_db.transactions)
          ..addColumns([_db.transactions.externalId])
          ..where(_db.transactions.externalId.isNotNull()))
        .get();
    return rows.map((r) => r.read(_db.transactions.externalId)!).toSet();
  }

  Future<bool> externalIdExists(String externalId) async {
    final r = await (_db.select(_db.transactions)
          ..where((t) => t.externalId.equals(externalId))
          ..limit(1))
        .getSingleOrNull();
    return r != null;
  }

  String _newId() {
    final now = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final rnd = DateTime.now().hashCode.toRadixString(36);
    return '$now-$rnd'.replaceAll('-', '');
  }
}
