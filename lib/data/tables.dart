import 'package:drift/drift.dart';

/// BigInt 以 TEXT 存储（避免 64 位溢出；加密资产 8 位小数场景安全）。
/// 统计聚合的 SQL 快路径用 CAST(AS INTEGER) 求和，仅当全部金额
/// ≤ 18 位数字时启用（见 LedgerRepo.moneyBalancesAt），否则回退 Dart 折叠。
class BigIntText extends TypeConverter<BigInt, String> {
  const BigIntText();

  @override
  BigInt fromSql(String fromDb) => BigInt.parse(fromDb);

  @override
  String toSql(BigInt value) => value.toString();
}

/// 有理数以 "分子/分母" TEXT 存储。
class RationalText extends TypeConverter<RationalStore, String> {
  const RationalText();

  @override
  RationalStore fromSql(String fromDb) {
    final i = fromDb.indexOf('/');
    if (i < 0) {
      return RationalStore(BigInt.parse(fromDb), BigInt.one);
    }
    return RationalStore(
        BigInt.parse(fromDb.substring(0, i)), BigInt.parse(fromDb.substring(i + 1)));
  }

  @override
  String toSql(RationalStore value) => '${value.n}/${value.d}';
}

/// 与 domain Rational 解耦的轻量存储结构（data 层不依赖 domain）。
class RationalStore {
  const RationalStore(this.n, this.d);
  final BigInt n;
  final BigInt d;
}

@DataClassName('AccountRow')
class Accounts extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get type => text()();

  /// AccountType / AssetSubtype / LiabilitySubtype 的 name。
  TextColumn get assetSubtype => text().nullable()();
  TextColumn get liabilitySubtype => text().nullable()();
  TextColumn get institution => text().nullable()();
  TextColumn get currencyCode => text()();
  TextColumn get ownershipN => text().nullable()();
  TextColumn get ownershipD => text().nullable()();
  BoolColumn get includeInNetWorth => boolean().withDefault(const Constant(true))();
  TextColumn get creditLimitMinor => text().nullable().map(const BigIntText())();
  IntColumn get statementDay => integer().nullable()();
  IntColumn get dueDay => integer().nullable()();
  BoolColumn get isSystem => boolean().withDefault(const Constant(false))();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  TextColumn get notes => text().nullable()();
  TextColumn get costBasisAccountId => text().nullable()();
  TextColumn get securityId => text().nullable()();

  /// 固定资产地理坐标（3D 地球展示用；仅坐标元数据，非金额，double 足够）。
  RealColumn get locationLat => real().nullable()();
  RealColumn get locationLon => real().nullable()();
  TextColumn get locationName => text().nullable()();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('SecurityRow')
class Securities extends Table {
  TextColumn get id => text()();
  TextColumn get code => text()();
  TextColumn get name => text()();
  TextColumn get type => text()();
  TextColumn get currencyCode => text()();
  TextColumn get notes => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('TransactionRow')
@TableIndex(name: 'idx_transactions_date', columns: {#date})
class Transactions extends Table {
  TextColumn get id => text()();
  DateTimeColumn get date => dateTime()();

  /// TxKind.name / TxStatus.name / TxSource.name。
  TextColumn get kind => text()();
  TextColumn get status => text().withDefault(const Constant('posted'))();
  TextColumn get note => text().nullable()();
  TextColumn get counterparty => text().nullable()();
  TextColumn get categoryId => text().nullable()();
  TextColumn get tagsJson => text().withDefault(const Constant('[]'))();
  TextColumn get externalId => text().nullable()();
  TextColumn get source => text().withDefault(const Constant('manual'))();
  TextColumn get importBatchId => text().nullable()();
  BoolColumn get isAdjustment => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('PostingRow')
@TableIndex(name: 'idx_postings_tx', columns: {#txId})
@TableIndex(name: 'idx_postings_account', columns: {#accountId})
class Postings extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get txId => text()();
  TextColumn get accountId => text()();
  TextColumn get amountMinor => text().nullable().map(const BigIntText())();
  TextColumn get currencyCode => text().nullable()();
  TextColumn get securityId => text().nullable()();
  TextColumn get quantityN => text().nullable().map(const BigIntText())();
  TextColumn get quantityD => text().nullable().map(const BigIntText())();
  TextColumn get memo => text().nullable()();
}

@DataClassName('BudgetRow')
class Budgets extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get scope => text()();
  TextColumn get limitMinor => text().map(const BigIntText())();
  TextColumn get currencyCode => text()();
  TextColumn get startMonth => text()();
  TextColumn get endMonth => text().nullable()();
  TextColumn get categoryId => text().nullable()();
  TextColumn get rollover => text().withDefault(const Constant('none'))();
  TextColumn get rolloverCapMinor => text().nullable().map(const BigIntText())();
  BoolColumn get active => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ScheduledEventRow')
class ScheduledEvents extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get direction => text()();
  TextColumn get currencyCode => text()();
  TextColumn get cadence => text()();
  DateTimeColumn get anchorDate => dateTime()();
  TextColumn get amountMinor => text().nullable().map(const BigIntText())();
  TextColumn get amountLowMinor => text().nullable().map(const BigIntText())();
  TextColumn get amountHighMinor => text().nullable().map(const BigIntText())();
  IntColumn get intervalValue => integer().withDefault(const Constant(1))();
  TextColumn get monthEndPolicy =>
      text().withDefault(const Constant('clampToMonthEnd'))();
  DateTimeColumn get endDate => dateTime().nullable()();
  TextColumn get paymentAccountId => text().nullable()();
  TextColumn get categoryId => text().nullable()();
  BoolColumn get autoPost => boolean().withDefault(const Constant(false))();
  TextColumn get notes => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('active'))();
  TextColumn get skippedMonthsJson => text().withDefault(const Constant('[]'))();
  TextColumn get amountOverridesJson => text().withDefault(const Constant('{}'))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('GoalRow')
class Goals extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get targetMinor => text().map(const BigIntText())();
  DateTimeColumn get targetDate => dateTime()();
  IntColumn get priority => integer().withDefault(const Constant(0))();
  TextColumn get reservedMinor =>
      text().withDefault(const Constant('0')).map(const BigIntText())();
  TextColumn get fundingAccountIdsJson =>
      text().withDefault(const Constant('[]'))();
  TextColumn get notes => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('active'))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('DebtContractRow')
class DebtContracts extends Table {
  TextColumn get liabilityAccountId => text()();
  TextColumn get principalOriginalMinor => text().map(const BigIntText())();

  /// 名义年利率（十进制字符串，如 "3.85" 表示 3.85%）。
  TextColumn get aprPercent => text()();
  TextColumn get method => text()();
  IntColumn get termMonths => integer()();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get firstPaymentDate => dateTime().nullable()();
  IntColumn get repaymentDay => integer().nullable()();
  TextColumn get monthlyFeeMinor => text().nullable().map(const BigIntText())();
  TextColumn get basis => text().withDefault(const Constant('monthlyRate'))();
  TextColumn get prepayFeePercent => text().nullable()();
  TextColumn get scheduleCacheJson => text().nullable()();
  TextColumn get notes => text().nullable()();

  @override
  Set<Column> get primaryKey => {liabilityAccountId};
}

@DataClassName('ValuationRow')
class Valuations extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get accountId => text()();
  DateTimeColumn get date => dateTime()();

  /// ValuationKind.name: unitPrice / totalValue。
  TextColumn get kind => text()();

  /// 单价（分子/分母）或总价值（最小单位）。
  TextColumn get unitPriceN => text().nullable().map(const BigIntText())();
  TextColumn get unitPriceD => text().nullable().map(const BigIntText())();
  TextColumn get totalValueMinor => text().nullable().map(const BigIntText())();
  TextColumn get source => text().withDefault(const Constant('manual'))();
  TextColumn get note => text().nullable()();
}

@DataClassName('FxRateRow')
class FxRates extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get baseCcy => text()();
  TextColumn get quoteCcy => text()();
  DateTimeColumn get date => dateTime()();
  TextColumn get rateN => text().map(const BigIntText())();
  TextColumn get rateD => text().map(const BigIntText())();
  TextColumn get source => text().withDefault(const Constant('manual'))();

  @override
  String get tableName => 'fx_rates';
}

@DataClassName('SnapshotRow')
class Snapshots extends Table {
  TextColumn get month => text()();
  TextColumn get payloadJson => text()();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {month};
}

@DataClassName('ImportBatchRow')
class ImportBatches extends Table {
  TextColumn get id => text()();
  TextColumn get source => text()();
  TextColumn get filename => text()();
  DateTimeColumn get importedAt =>
      dateTime().withDefault(currentDateAndTime)();
  TextColumn get parserVersion => text()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  TextColumn get countsJson => text().withDefault(const Constant('{}'))();
}

@DataClassName('SettingRow')
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get valueJson => text()();

  @override
  Set<Column> get primaryKey => {key};
}
