import 'package:drift/drift.dart';

import '../../domain/ledger/account.dart';
import '../../domain/money/fx_rate.dart';
import '../app_database.dart';

/// 账户仓储：DB 行 ↔ 领域实体。
class AccountsRepo {
  AccountsRepo(this._db);

  final AppDatabase _db;

  AccountsCompanion toRow(Account a) => AccountsCompanion.insert(
    id: a.id,
    name: a.name,
    type: a.type.name,
    assetSubtype: Value(a.assetSubtype?.name),
    liabilitySubtype: Value(a.liabilitySubtype?.name),
    institution: Value(a.institution),
    currencyCode: a.currencyCode,
    ownershipN: Value(a.ownership?.n.toString()),
    ownershipD: Value(a.ownership?.d.toString()),
    includeInNetWorth: Value(a.includeInNetWorth),
    creditLimitMinor: Value(a.creditLimitMinor),
    statementDay: Value(a.statementDay),
    dueDay: Value(a.dueDay),
    isSystem: Value(a.isSystem),
    archived: Value(a.archived),
    sortOrder: Value(a.sortOrder),
    notes: Value(a.notes),
    costBasisAccountId: Value(a.costBasisAccountId),
    securityId: Value(a.securityId),
    locationLat: Value(a.locationLat),
    locationLon: Value(a.locationLon),
    locationName: Value(a.locationName),
    aiValuationEnabled: Value(a.aiValuationEnabled),
    aiValuationQuery: Value(a.aiValuationQuery),
  );

  Account toDomain(AccountRow r) => Account(
    id: r.id,
    name: r.name,
    type: AccountType.values.firstWhere((t) => t.name == r.type),
    assetSubtype: r.assetSubtype == null
        ? null
        : AssetSubtype.values.firstWhere((s) => s.name == r.assetSubtype),
    liabilitySubtype: r.liabilitySubtype == null
        ? null
        : LiabilitySubtype.values.firstWhere(
            (s) => s.name == r.liabilitySubtype,
          ),
    institution: r.institution,
    currencyCode: r.currencyCode,
    ownership: r.ownershipN == null || r.ownershipD == null
        ? null
        : _rationalFromParts(
            BigInt.parse(r.ownershipN!),
            BigInt.parse(r.ownershipD!),
          ),
    includeInNetWorth: r.includeInNetWorth,
    creditLimitMinor: r.creditLimitMinor,
    statementDay: r.statementDay,
    dueDay: r.dueDay,
    isSystem: r.isSystem,
    archived: r.archived,
    sortOrder: r.sortOrder,
    notes: r.notes,
    costBasisAccountId: r.costBasisAccountId,
    securityId: r.securityId,
    locationLat: r.locationLat,
    locationLon: r.locationLon,
    locationName: r.locationName,
    aiValuationEnabled: r.aiValuationEnabled,
    aiValuationQuery: r.aiValuationQuery,
  );

  Stream<List<Account>> watchAll() =>
      (_db.select(_db.accounts)
            ..orderBy([(a) => OrderingTerm.asc(a.sortOrder)]))
          .watch()
          .map((rows) => [for (final r in rows) toDomain(r)]);

  Future<List<Account>> all() async {
    final rows = await (_db.select(
      _db.accounts,
    )..orderBy([(a) => OrderingTerm(expression: a.sortOrder)])).get();
    return [for (final r in rows) toDomain(r)];
  }

  Future<Account?> byId(String id) async {
    final r = await (_db.select(
      _db.accounts,
    )..where((a) => a.id.equals(id))).getSingleOrNull();
    return r == null ? null : toDomain(r);
  }

  Future<void> upsert(Account a) =>
      _db.into(_db.accounts).insertOnConflictUpdate(toRow(a));

  Future<void> archive(String id, {required bool archived}) =>
      (_db.update(_db.accounts)..where((a) => a.id.equals(id))).write(
        AccountsCompanion(archived: Value(archived)),
      );

  /// 全部证券的 行情代码（securityId → code，直连行情源用）。
  Future<Map<String, String>> securityCodes() async {
    final rows = await _db.select(_db.securities).get();
    return {for (final r in rows) r.id: r.code};
  }

  /// 修改行情代码（只改 securities.code 元数据；
  /// 不动 securityId/分录，历史数量账不受影响）。
  Future<void> updateSecurityCode(String securityId, String code) =>
      (_db.update(_db.securities)..where((s) => s.id.equals(securityId))).write(
        SecuritiesCompanion(code: Value(code)),
      );

  /// 创建持仓账户：自动建立证券、持仓账户与成本镜像账户（同一事务）。
  Future<Account> createHolding({
    required String name,
    required AssetSubtype subtype,
    required String currencyCode,
    required String securityCode,
    String? institution,
  }) async {
    final securityId = 'sec:${securityCode.toLowerCase()}';
    final holdingId = 'acc:hold:${securityCode.toLowerCase()}';
    final costId = 'sys:cost:${securityCode.toLowerCase()}';
    await _db.transaction(() async {
      await (_db.into(_db.securities)).insertOnConflictUpdate(
        SecuritiesCompanion.insert(
          id: securityId,
          code: securityCode,
          name: name,
          type: subtype.name,
          currencyCode: currencyCode,
        ),
      );
      await _db
          .into(_db.accounts)
          .insertOnConflictUpdate(
            AccountsCompanion.insert(
              id: holdingId,
              name: name,
              type: 'asset',
              assetSubtype: Value(subtype.name),
              institution: Value(institution),
              currencyCode: currencyCode,
              securityId: Value(securityId),
              isSystem: const Value(false),
            ),
          );
      await _db
          .into(_db.accounts)
          .insertOnConflictUpdate(
            AccountsCompanion.insert(
              id: costId,
              name: '$name-成本',
              type: 'asset',
              currencyCode: currencyCode,
              includeInNetWorth: const Value(false),
              isSystem: const Value(true),
            ),
          );
    });
    return Account(
      id: holdingId,
      name: name,
      type: AccountType.asset,
      assetSubtype: subtype,
      institution: institution,
      currencyCode: currencyCode,
      costBasisAccountId: costId,
      securityId: securityId,
    );
  }
}

Rational _rationalFromParts(BigInt n, BigInt d) =>
    Rational.fromInt(n) / Rational.fromInt(d);
