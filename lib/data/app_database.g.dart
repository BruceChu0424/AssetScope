// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $AccountsTable extends Accounts
    with TableInfo<$AccountsTable, AccountRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AccountsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _assetSubtypeMeta = const VerificationMeta(
    'assetSubtype',
  );
  @override
  late final GeneratedColumn<String> assetSubtype = GeneratedColumn<String>(
    'asset_subtype',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _liabilitySubtypeMeta = const VerificationMeta(
    'liabilitySubtype',
  );
  @override
  late final GeneratedColumn<String> liabilitySubtype = GeneratedColumn<String>(
    'liability_subtype',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _institutionMeta = const VerificationMeta(
    'institution',
  );
  @override
  late final GeneratedColumn<String> institution = GeneratedColumn<String>(
    'institution',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _currencyCodeMeta = const VerificationMeta(
    'currencyCode',
  );
  @override
  late final GeneratedColumn<String> currencyCode = GeneratedColumn<String>(
    'currency_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ownershipNMeta = const VerificationMeta(
    'ownershipN',
  );
  @override
  late final GeneratedColumn<String> ownershipN = GeneratedColumn<String>(
    'ownership_n',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ownershipDMeta = const VerificationMeta(
    'ownershipD',
  );
  @override
  late final GeneratedColumn<String> ownershipD = GeneratedColumn<String>(
    'ownership_d',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _includeInNetWorthMeta = const VerificationMeta(
    'includeInNetWorth',
  );
  @override
  late final GeneratedColumn<bool> includeInNetWorth = GeneratedColumn<bool>(
    'include_in_net_worth',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("include_in_net_worth" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  late final GeneratedColumnWithTypeConverter<BigInt?, String>
  creditLimitMinor = GeneratedColumn<String>(
    'credit_limit_minor',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  ).withConverter<BigInt?>($AccountsTable.$convertercreditLimitMinorn);
  static const VerificationMeta _statementDayMeta = const VerificationMeta(
    'statementDay',
  );
  @override
  late final GeneratedColumn<int> statementDay = GeneratedColumn<int>(
    'statement_day',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dueDayMeta = const VerificationMeta('dueDay');
  @override
  late final GeneratedColumn<int> dueDay = GeneratedColumn<int>(
    'due_day',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isSystemMeta = const VerificationMeta(
    'isSystem',
  );
  @override
  late final GeneratedColumn<bool> isSystem = GeneratedColumn<bool>(
    'is_system',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_system" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _archivedMeta = const VerificationMeta(
    'archived',
  );
  @override
  late final GeneratedColumn<bool> archived = GeneratedColumn<bool>(
    'archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _costBasisAccountIdMeta =
      const VerificationMeta('costBasisAccountId');
  @override
  late final GeneratedColumn<String> costBasisAccountId =
      GeneratedColumn<String>(
        'cost_basis_account_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _securityIdMeta = const VerificationMeta(
    'securityId',
  );
  @override
  late final GeneratedColumn<String> securityId = GeneratedColumn<String>(
    'security_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _locationLatMeta = const VerificationMeta(
    'locationLat',
  );
  @override
  late final GeneratedColumn<double> locationLat = GeneratedColumn<double>(
    'location_lat',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _locationLonMeta = const VerificationMeta(
    'locationLon',
  );
  @override
  late final GeneratedColumn<double> locationLon = GeneratedColumn<double>(
    'location_lon',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _locationNameMeta = const VerificationMeta(
    'locationName',
  );
  @override
  late final GeneratedColumn<String> locationName = GeneratedColumn<String>(
    'location_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _aiValuationEnabledMeta =
      const VerificationMeta('aiValuationEnabled');
  @override
  late final GeneratedColumn<bool> aiValuationEnabled = GeneratedColumn<bool>(
    'ai_valuation_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("ai_valuation_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _aiValuationQueryMeta = const VerificationMeta(
    'aiValuationQuery',
  );
  @override
  late final GeneratedColumn<String> aiValuationQuery = GeneratedColumn<String>(
    'ai_valuation_query',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    type,
    assetSubtype,
    liabilitySubtype,
    institution,
    currencyCode,
    ownershipN,
    ownershipD,
    includeInNetWorth,
    creditLimitMinor,
    statementDay,
    dueDay,
    isSystem,
    archived,
    sortOrder,
    notes,
    costBasisAccountId,
    securityId,
    locationLat,
    locationLon,
    locationName,
    aiValuationEnabled,
    aiValuationQuery,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'accounts';
  @override
  VerificationContext validateIntegrity(
    Insertable<AccountRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('asset_subtype')) {
      context.handle(
        _assetSubtypeMeta,
        assetSubtype.isAcceptableOrUnknown(
          data['asset_subtype']!,
          _assetSubtypeMeta,
        ),
      );
    }
    if (data.containsKey('liability_subtype')) {
      context.handle(
        _liabilitySubtypeMeta,
        liabilitySubtype.isAcceptableOrUnknown(
          data['liability_subtype']!,
          _liabilitySubtypeMeta,
        ),
      );
    }
    if (data.containsKey('institution')) {
      context.handle(
        _institutionMeta,
        institution.isAcceptableOrUnknown(
          data['institution']!,
          _institutionMeta,
        ),
      );
    }
    if (data.containsKey('currency_code')) {
      context.handle(
        _currencyCodeMeta,
        currencyCode.isAcceptableOrUnknown(
          data['currency_code']!,
          _currencyCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_currencyCodeMeta);
    }
    if (data.containsKey('ownership_n')) {
      context.handle(
        _ownershipNMeta,
        ownershipN.isAcceptableOrUnknown(data['ownership_n']!, _ownershipNMeta),
      );
    }
    if (data.containsKey('ownership_d')) {
      context.handle(
        _ownershipDMeta,
        ownershipD.isAcceptableOrUnknown(data['ownership_d']!, _ownershipDMeta),
      );
    }
    if (data.containsKey('include_in_net_worth')) {
      context.handle(
        _includeInNetWorthMeta,
        includeInNetWorth.isAcceptableOrUnknown(
          data['include_in_net_worth']!,
          _includeInNetWorthMeta,
        ),
      );
    }
    if (data.containsKey('statement_day')) {
      context.handle(
        _statementDayMeta,
        statementDay.isAcceptableOrUnknown(
          data['statement_day']!,
          _statementDayMeta,
        ),
      );
    }
    if (data.containsKey('due_day')) {
      context.handle(
        _dueDayMeta,
        dueDay.isAcceptableOrUnknown(data['due_day']!, _dueDayMeta),
      );
    }
    if (data.containsKey('is_system')) {
      context.handle(
        _isSystemMeta,
        isSystem.isAcceptableOrUnknown(data['is_system']!, _isSystemMeta),
      );
    }
    if (data.containsKey('archived')) {
      context.handle(
        _archivedMeta,
        archived.isAcceptableOrUnknown(data['archived']!, _archivedMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('cost_basis_account_id')) {
      context.handle(
        _costBasisAccountIdMeta,
        costBasisAccountId.isAcceptableOrUnknown(
          data['cost_basis_account_id']!,
          _costBasisAccountIdMeta,
        ),
      );
    }
    if (data.containsKey('security_id')) {
      context.handle(
        _securityIdMeta,
        securityId.isAcceptableOrUnknown(data['security_id']!, _securityIdMeta),
      );
    }
    if (data.containsKey('location_lat')) {
      context.handle(
        _locationLatMeta,
        locationLat.isAcceptableOrUnknown(
          data['location_lat']!,
          _locationLatMeta,
        ),
      );
    }
    if (data.containsKey('location_lon')) {
      context.handle(
        _locationLonMeta,
        locationLon.isAcceptableOrUnknown(
          data['location_lon']!,
          _locationLonMeta,
        ),
      );
    }
    if (data.containsKey('location_name')) {
      context.handle(
        _locationNameMeta,
        locationName.isAcceptableOrUnknown(
          data['location_name']!,
          _locationNameMeta,
        ),
      );
    }
    if (data.containsKey('ai_valuation_enabled')) {
      context.handle(
        _aiValuationEnabledMeta,
        aiValuationEnabled.isAcceptableOrUnknown(
          data['ai_valuation_enabled']!,
          _aiValuationEnabledMeta,
        ),
      );
    }
    if (data.containsKey('ai_valuation_query')) {
      context.handle(
        _aiValuationQueryMeta,
        aiValuationQuery.isAcceptableOrUnknown(
          data['ai_valuation_query']!,
          _aiValuationQueryMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AccountRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AccountRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      assetSubtype: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}asset_subtype'],
      ),
      liabilitySubtype: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}liability_subtype'],
      ),
      institution: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}institution'],
      ),
      currencyCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency_code'],
      )!,
      ownershipN: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ownership_n'],
      ),
      ownershipD: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ownership_d'],
      ),
      includeInNetWorth: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}include_in_net_worth'],
      )!,
      creditLimitMinor: $AccountsTable.$convertercreditLimitMinorn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}credit_limit_minor'],
        ),
      ),
      statementDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}statement_day'],
      ),
      dueDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}due_day'],
      ),
      isSystem: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_system'],
      )!,
      archived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}archived'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      costBasisAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cost_basis_account_id'],
      ),
      securityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}security_id'],
      ),
      locationLat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}location_lat'],
      ),
      locationLon: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}location_lon'],
      ),
      locationName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location_name'],
      ),
      aiValuationEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}ai_valuation_enabled'],
      )!,
      aiValuationQuery: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ai_valuation_query'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $AccountsTable createAlias(String alias) {
    return $AccountsTable(attachedDatabase, alias);
  }

  static TypeConverter<BigInt, String> $convertercreditLimitMinor =
      const BigIntText();
  static TypeConverter<BigInt?, String?> $convertercreditLimitMinorn =
      NullAwareTypeConverter.wrap($convertercreditLimitMinor);
}

class AccountRow extends DataClass implements Insertable<AccountRow> {
  final String id;
  final String name;
  final String type;

  /// AccountType / AssetSubtype / LiabilitySubtype 的 name。
  final String? assetSubtype;
  final String? liabilitySubtype;
  final String? institution;
  final String currencyCode;
  final String? ownershipN;
  final String? ownershipD;
  final bool includeInNetWorth;
  final BigInt? creditLimitMinor;
  final int? statementDay;
  final int? dueDay;
  final bool isSystem;
  final bool archived;
  final int sortOrder;
  final String? notes;
  final String? costBasisAccountId;
  final String? securityId;

  /// 固定资产地理坐标（3D 地球展示用；仅坐标元数据，非金额，double 足够）。
  final double? locationLat;
  final double? locationLon;
  final String? locationName;

  /// AI 每日自动估值（房产/车辆等 manualValue 类）：启用后解锁时
  /// 联网检索最新市价并写入估值记录（source=ai:…），用户可随时手动
  /// 纠正（当日手动估值优先，AI 不再覆盖）。
  final bool aiValuationEnabled;

  /// AI 估值检索线索（小区/栋/室、年款型号等）；null = 由名称+位置推导。
  final String? aiValuationQuery;
  final DateTime createdAt;
  const AccountRow({
    required this.id,
    required this.name,
    required this.type,
    this.assetSubtype,
    this.liabilitySubtype,
    this.institution,
    required this.currencyCode,
    this.ownershipN,
    this.ownershipD,
    required this.includeInNetWorth,
    this.creditLimitMinor,
    this.statementDay,
    this.dueDay,
    required this.isSystem,
    required this.archived,
    required this.sortOrder,
    this.notes,
    this.costBasisAccountId,
    this.securityId,
    this.locationLat,
    this.locationLon,
    this.locationName,
    required this.aiValuationEnabled,
    this.aiValuationQuery,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || assetSubtype != null) {
      map['asset_subtype'] = Variable<String>(assetSubtype);
    }
    if (!nullToAbsent || liabilitySubtype != null) {
      map['liability_subtype'] = Variable<String>(liabilitySubtype);
    }
    if (!nullToAbsent || institution != null) {
      map['institution'] = Variable<String>(institution);
    }
    map['currency_code'] = Variable<String>(currencyCode);
    if (!nullToAbsent || ownershipN != null) {
      map['ownership_n'] = Variable<String>(ownershipN);
    }
    if (!nullToAbsent || ownershipD != null) {
      map['ownership_d'] = Variable<String>(ownershipD);
    }
    map['include_in_net_worth'] = Variable<bool>(includeInNetWorth);
    if (!nullToAbsent || creditLimitMinor != null) {
      map['credit_limit_minor'] = Variable<String>(
        $AccountsTable.$convertercreditLimitMinorn.toSql(creditLimitMinor),
      );
    }
    if (!nullToAbsent || statementDay != null) {
      map['statement_day'] = Variable<int>(statementDay);
    }
    if (!nullToAbsent || dueDay != null) {
      map['due_day'] = Variable<int>(dueDay);
    }
    map['is_system'] = Variable<bool>(isSystem);
    map['archived'] = Variable<bool>(archived);
    map['sort_order'] = Variable<int>(sortOrder);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || costBasisAccountId != null) {
      map['cost_basis_account_id'] = Variable<String>(costBasisAccountId);
    }
    if (!nullToAbsent || securityId != null) {
      map['security_id'] = Variable<String>(securityId);
    }
    if (!nullToAbsent || locationLat != null) {
      map['location_lat'] = Variable<double>(locationLat);
    }
    if (!nullToAbsent || locationLon != null) {
      map['location_lon'] = Variable<double>(locationLon);
    }
    if (!nullToAbsent || locationName != null) {
      map['location_name'] = Variable<String>(locationName);
    }
    map['ai_valuation_enabled'] = Variable<bool>(aiValuationEnabled);
    if (!nullToAbsent || aiValuationQuery != null) {
      map['ai_valuation_query'] = Variable<String>(aiValuationQuery);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  AccountsCompanion toCompanion(bool nullToAbsent) {
    return AccountsCompanion(
      id: Value(id),
      name: Value(name),
      type: Value(type),
      assetSubtype: assetSubtype == null && nullToAbsent
          ? const Value.absent()
          : Value(assetSubtype),
      liabilitySubtype: liabilitySubtype == null && nullToAbsent
          ? const Value.absent()
          : Value(liabilitySubtype),
      institution: institution == null && nullToAbsent
          ? const Value.absent()
          : Value(institution),
      currencyCode: Value(currencyCode),
      ownershipN: ownershipN == null && nullToAbsent
          ? const Value.absent()
          : Value(ownershipN),
      ownershipD: ownershipD == null && nullToAbsent
          ? const Value.absent()
          : Value(ownershipD),
      includeInNetWorth: Value(includeInNetWorth),
      creditLimitMinor: creditLimitMinor == null && nullToAbsent
          ? const Value.absent()
          : Value(creditLimitMinor),
      statementDay: statementDay == null && nullToAbsent
          ? const Value.absent()
          : Value(statementDay),
      dueDay: dueDay == null && nullToAbsent
          ? const Value.absent()
          : Value(dueDay),
      isSystem: Value(isSystem),
      archived: Value(archived),
      sortOrder: Value(sortOrder),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      costBasisAccountId: costBasisAccountId == null && nullToAbsent
          ? const Value.absent()
          : Value(costBasisAccountId),
      securityId: securityId == null && nullToAbsent
          ? const Value.absent()
          : Value(securityId),
      locationLat: locationLat == null && nullToAbsent
          ? const Value.absent()
          : Value(locationLat),
      locationLon: locationLon == null && nullToAbsent
          ? const Value.absent()
          : Value(locationLon),
      locationName: locationName == null && nullToAbsent
          ? const Value.absent()
          : Value(locationName),
      aiValuationEnabled: Value(aiValuationEnabled),
      aiValuationQuery: aiValuationQuery == null && nullToAbsent
          ? const Value.absent()
          : Value(aiValuationQuery),
      createdAt: Value(createdAt),
    );
  }

  factory AccountRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AccountRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      type: serializer.fromJson<String>(json['type']),
      assetSubtype: serializer.fromJson<String?>(json['assetSubtype']),
      liabilitySubtype: serializer.fromJson<String?>(json['liabilitySubtype']),
      institution: serializer.fromJson<String?>(json['institution']),
      currencyCode: serializer.fromJson<String>(json['currencyCode']),
      ownershipN: serializer.fromJson<String?>(json['ownershipN']),
      ownershipD: serializer.fromJson<String?>(json['ownershipD']),
      includeInNetWorth: serializer.fromJson<bool>(json['includeInNetWorth']),
      creditLimitMinor: serializer.fromJson<BigInt?>(json['creditLimitMinor']),
      statementDay: serializer.fromJson<int?>(json['statementDay']),
      dueDay: serializer.fromJson<int?>(json['dueDay']),
      isSystem: serializer.fromJson<bool>(json['isSystem']),
      archived: serializer.fromJson<bool>(json['archived']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      notes: serializer.fromJson<String?>(json['notes']),
      costBasisAccountId: serializer.fromJson<String?>(
        json['costBasisAccountId'],
      ),
      securityId: serializer.fromJson<String?>(json['securityId']),
      locationLat: serializer.fromJson<double?>(json['locationLat']),
      locationLon: serializer.fromJson<double?>(json['locationLon']),
      locationName: serializer.fromJson<String?>(json['locationName']),
      aiValuationEnabled: serializer.fromJson<bool>(json['aiValuationEnabled']),
      aiValuationQuery: serializer.fromJson<String?>(json['aiValuationQuery']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<String>(type),
      'assetSubtype': serializer.toJson<String?>(assetSubtype),
      'liabilitySubtype': serializer.toJson<String?>(liabilitySubtype),
      'institution': serializer.toJson<String?>(institution),
      'currencyCode': serializer.toJson<String>(currencyCode),
      'ownershipN': serializer.toJson<String?>(ownershipN),
      'ownershipD': serializer.toJson<String?>(ownershipD),
      'includeInNetWorth': serializer.toJson<bool>(includeInNetWorth),
      'creditLimitMinor': serializer.toJson<BigInt?>(creditLimitMinor),
      'statementDay': serializer.toJson<int?>(statementDay),
      'dueDay': serializer.toJson<int?>(dueDay),
      'isSystem': serializer.toJson<bool>(isSystem),
      'archived': serializer.toJson<bool>(archived),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'notes': serializer.toJson<String?>(notes),
      'costBasisAccountId': serializer.toJson<String?>(costBasisAccountId),
      'securityId': serializer.toJson<String?>(securityId),
      'locationLat': serializer.toJson<double?>(locationLat),
      'locationLon': serializer.toJson<double?>(locationLon),
      'locationName': serializer.toJson<String?>(locationName),
      'aiValuationEnabled': serializer.toJson<bool>(aiValuationEnabled),
      'aiValuationQuery': serializer.toJson<String?>(aiValuationQuery),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  AccountRow copyWith({
    String? id,
    String? name,
    String? type,
    Value<String?> assetSubtype = const Value.absent(),
    Value<String?> liabilitySubtype = const Value.absent(),
    Value<String?> institution = const Value.absent(),
    String? currencyCode,
    Value<String?> ownershipN = const Value.absent(),
    Value<String?> ownershipD = const Value.absent(),
    bool? includeInNetWorth,
    Value<BigInt?> creditLimitMinor = const Value.absent(),
    Value<int?> statementDay = const Value.absent(),
    Value<int?> dueDay = const Value.absent(),
    bool? isSystem,
    bool? archived,
    int? sortOrder,
    Value<String?> notes = const Value.absent(),
    Value<String?> costBasisAccountId = const Value.absent(),
    Value<String?> securityId = const Value.absent(),
    Value<double?> locationLat = const Value.absent(),
    Value<double?> locationLon = const Value.absent(),
    Value<String?> locationName = const Value.absent(),
    bool? aiValuationEnabled,
    Value<String?> aiValuationQuery = const Value.absent(),
    DateTime? createdAt,
  }) => AccountRow(
    id: id ?? this.id,
    name: name ?? this.name,
    type: type ?? this.type,
    assetSubtype: assetSubtype.present ? assetSubtype.value : this.assetSubtype,
    liabilitySubtype: liabilitySubtype.present
        ? liabilitySubtype.value
        : this.liabilitySubtype,
    institution: institution.present ? institution.value : this.institution,
    currencyCode: currencyCode ?? this.currencyCode,
    ownershipN: ownershipN.present ? ownershipN.value : this.ownershipN,
    ownershipD: ownershipD.present ? ownershipD.value : this.ownershipD,
    includeInNetWorth: includeInNetWorth ?? this.includeInNetWorth,
    creditLimitMinor: creditLimitMinor.present
        ? creditLimitMinor.value
        : this.creditLimitMinor,
    statementDay: statementDay.present ? statementDay.value : this.statementDay,
    dueDay: dueDay.present ? dueDay.value : this.dueDay,
    isSystem: isSystem ?? this.isSystem,
    archived: archived ?? this.archived,
    sortOrder: sortOrder ?? this.sortOrder,
    notes: notes.present ? notes.value : this.notes,
    costBasisAccountId: costBasisAccountId.present
        ? costBasisAccountId.value
        : this.costBasisAccountId,
    securityId: securityId.present ? securityId.value : this.securityId,
    locationLat: locationLat.present ? locationLat.value : this.locationLat,
    locationLon: locationLon.present ? locationLon.value : this.locationLon,
    locationName: locationName.present ? locationName.value : this.locationName,
    aiValuationEnabled: aiValuationEnabled ?? this.aiValuationEnabled,
    aiValuationQuery: aiValuationQuery.present
        ? aiValuationQuery.value
        : this.aiValuationQuery,
    createdAt: createdAt ?? this.createdAt,
  );
  AccountRow copyWithCompanion(AccountsCompanion data) {
    return AccountRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      assetSubtype: data.assetSubtype.present
          ? data.assetSubtype.value
          : this.assetSubtype,
      liabilitySubtype: data.liabilitySubtype.present
          ? data.liabilitySubtype.value
          : this.liabilitySubtype,
      institution: data.institution.present
          ? data.institution.value
          : this.institution,
      currencyCode: data.currencyCode.present
          ? data.currencyCode.value
          : this.currencyCode,
      ownershipN: data.ownershipN.present
          ? data.ownershipN.value
          : this.ownershipN,
      ownershipD: data.ownershipD.present
          ? data.ownershipD.value
          : this.ownershipD,
      includeInNetWorth: data.includeInNetWorth.present
          ? data.includeInNetWorth.value
          : this.includeInNetWorth,
      creditLimitMinor: data.creditLimitMinor.present
          ? data.creditLimitMinor.value
          : this.creditLimitMinor,
      statementDay: data.statementDay.present
          ? data.statementDay.value
          : this.statementDay,
      dueDay: data.dueDay.present ? data.dueDay.value : this.dueDay,
      isSystem: data.isSystem.present ? data.isSystem.value : this.isSystem,
      archived: data.archived.present ? data.archived.value : this.archived,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      notes: data.notes.present ? data.notes.value : this.notes,
      costBasisAccountId: data.costBasisAccountId.present
          ? data.costBasisAccountId.value
          : this.costBasisAccountId,
      securityId: data.securityId.present
          ? data.securityId.value
          : this.securityId,
      locationLat: data.locationLat.present
          ? data.locationLat.value
          : this.locationLat,
      locationLon: data.locationLon.present
          ? data.locationLon.value
          : this.locationLon,
      locationName: data.locationName.present
          ? data.locationName.value
          : this.locationName,
      aiValuationEnabled: data.aiValuationEnabled.present
          ? data.aiValuationEnabled.value
          : this.aiValuationEnabled,
      aiValuationQuery: data.aiValuationQuery.present
          ? data.aiValuationQuery.value
          : this.aiValuationQuery,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AccountRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('assetSubtype: $assetSubtype, ')
          ..write('liabilitySubtype: $liabilitySubtype, ')
          ..write('institution: $institution, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('ownershipN: $ownershipN, ')
          ..write('ownershipD: $ownershipD, ')
          ..write('includeInNetWorth: $includeInNetWorth, ')
          ..write('creditLimitMinor: $creditLimitMinor, ')
          ..write('statementDay: $statementDay, ')
          ..write('dueDay: $dueDay, ')
          ..write('isSystem: $isSystem, ')
          ..write('archived: $archived, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('notes: $notes, ')
          ..write('costBasisAccountId: $costBasisAccountId, ')
          ..write('securityId: $securityId, ')
          ..write('locationLat: $locationLat, ')
          ..write('locationLon: $locationLon, ')
          ..write('locationName: $locationName, ')
          ..write('aiValuationEnabled: $aiValuationEnabled, ')
          ..write('aiValuationQuery: $aiValuationQuery, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    name,
    type,
    assetSubtype,
    liabilitySubtype,
    institution,
    currencyCode,
    ownershipN,
    ownershipD,
    includeInNetWorth,
    creditLimitMinor,
    statementDay,
    dueDay,
    isSystem,
    archived,
    sortOrder,
    notes,
    costBasisAccountId,
    securityId,
    locationLat,
    locationLon,
    locationName,
    aiValuationEnabled,
    aiValuationQuery,
    createdAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AccountRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.type == this.type &&
          other.assetSubtype == this.assetSubtype &&
          other.liabilitySubtype == this.liabilitySubtype &&
          other.institution == this.institution &&
          other.currencyCode == this.currencyCode &&
          other.ownershipN == this.ownershipN &&
          other.ownershipD == this.ownershipD &&
          other.includeInNetWorth == this.includeInNetWorth &&
          other.creditLimitMinor == this.creditLimitMinor &&
          other.statementDay == this.statementDay &&
          other.dueDay == this.dueDay &&
          other.isSystem == this.isSystem &&
          other.archived == this.archived &&
          other.sortOrder == this.sortOrder &&
          other.notes == this.notes &&
          other.costBasisAccountId == this.costBasisAccountId &&
          other.securityId == this.securityId &&
          other.locationLat == this.locationLat &&
          other.locationLon == this.locationLon &&
          other.locationName == this.locationName &&
          other.aiValuationEnabled == this.aiValuationEnabled &&
          other.aiValuationQuery == this.aiValuationQuery &&
          other.createdAt == this.createdAt);
}

class AccountsCompanion extends UpdateCompanion<AccountRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> type;
  final Value<String?> assetSubtype;
  final Value<String?> liabilitySubtype;
  final Value<String?> institution;
  final Value<String> currencyCode;
  final Value<String?> ownershipN;
  final Value<String?> ownershipD;
  final Value<bool> includeInNetWorth;
  final Value<BigInt?> creditLimitMinor;
  final Value<int?> statementDay;
  final Value<int?> dueDay;
  final Value<bool> isSystem;
  final Value<bool> archived;
  final Value<int> sortOrder;
  final Value<String?> notes;
  final Value<String?> costBasisAccountId;
  final Value<String?> securityId;
  final Value<double?> locationLat;
  final Value<double?> locationLon;
  final Value<String?> locationName;
  final Value<bool> aiValuationEnabled;
  final Value<String?> aiValuationQuery;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const AccountsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.assetSubtype = const Value.absent(),
    this.liabilitySubtype = const Value.absent(),
    this.institution = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.ownershipN = const Value.absent(),
    this.ownershipD = const Value.absent(),
    this.includeInNetWorth = const Value.absent(),
    this.creditLimitMinor = const Value.absent(),
    this.statementDay = const Value.absent(),
    this.dueDay = const Value.absent(),
    this.isSystem = const Value.absent(),
    this.archived = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.notes = const Value.absent(),
    this.costBasisAccountId = const Value.absent(),
    this.securityId = const Value.absent(),
    this.locationLat = const Value.absent(),
    this.locationLon = const Value.absent(),
    this.locationName = const Value.absent(),
    this.aiValuationEnabled = const Value.absent(),
    this.aiValuationQuery = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AccountsCompanion.insert({
    required String id,
    required String name,
    required String type,
    this.assetSubtype = const Value.absent(),
    this.liabilitySubtype = const Value.absent(),
    this.institution = const Value.absent(),
    required String currencyCode,
    this.ownershipN = const Value.absent(),
    this.ownershipD = const Value.absent(),
    this.includeInNetWorth = const Value.absent(),
    this.creditLimitMinor = const Value.absent(),
    this.statementDay = const Value.absent(),
    this.dueDay = const Value.absent(),
    this.isSystem = const Value.absent(),
    this.archived = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.notes = const Value.absent(),
    this.costBasisAccountId = const Value.absent(),
    this.securityId = const Value.absent(),
    this.locationLat = const Value.absent(),
    this.locationLon = const Value.absent(),
    this.locationName = const Value.absent(),
    this.aiValuationEnabled = const Value.absent(),
    this.aiValuationQuery = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       type = Value(type),
       currencyCode = Value(currencyCode);
  static Insertable<AccountRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? type,
    Expression<String>? assetSubtype,
    Expression<String>? liabilitySubtype,
    Expression<String>? institution,
    Expression<String>? currencyCode,
    Expression<String>? ownershipN,
    Expression<String>? ownershipD,
    Expression<bool>? includeInNetWorth,
    Expression<String>? creditLimitMinor,
    Expression<int>? statementDay,
    Expression<int>? dueDay,
    Expression<bool>? isSystem,
    Expression<bool>? archived,
    Expression<int>? sortOrder,
    Expression<String>? notes,
    Expression<String>? costBasisAccountId,
    Expression<String>? securityId,
    Expression<double>? locationLat,
    Expression<double>? locationLon,
    Expression<String>? locationName,
    Expression<bool>? aiValuationEnabled,
    Expression<String>? aiValuationQuery,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (assetSubtype != null) 'asset_subtype': assetSubtype,
      if (liabilitySubtype != null) 'liability_subtype': liabilitySubtype,
      if (institution != null) 'institution': institution,
      if (currencyCode != null) 'currency_code': currencyCode,
      if (ownershipN != null) 'ownership_n': ownershipN,
      if (ownershipD != null) 'ownership_d': ownershipD,
      if (includeInNetWorth != null) 'include_in_net_worth': includeInNetWorth,
      if (creditLimitMinor != null) 'credit_limit_minor': creditLimitMinor,
      if (statementDay != null) 'statement_day': statementDay,
      if (dueDay != null) 'due_day': dueDay,
      if (isSystem != null) 'is_system': isSystem,
      if (archived != null) 'archived': archived,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (notes != null) 'notes': notes,
      if (costBasisAccountId != null)
        'cost_basis_account_id': costBasisAccountId,
      if (securityId != null) 'security_id': securityId,
      if (locationLat != null) 'location_lat': locationLat,
      if (locationLon != null) 'location_lon': locationLon,
      if (locationName != null) 'location_name': locationName,
      if (aiValuationEnabled != null)
        'ai_valuation_enabled': aiValuationEnabled,
      if (aiValuationQuery != null) 'ai_valuation_query': aiValuationQuery,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AccountsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? type,
    Value<String?>? assetSubtype,
    Value<String?>? liabilitySubtype,
    Value<String?>? institution,
    Value<String>? currencyCode,
    Value<String?>? ownershipN,
    Value<String?>? ownershipD,
    Value<bool>? includeInNetWorth,
    Value<BigInt?>? creditLimitMinor,
    Value<int?>? statementDay,
    Value<int?>? dueDay,
    Value<bool>? isSystem,
    Value<bool>? archived,
    Value<int>? sortOrder,
    Value<String?>? notes,
    Value<String?>? costBasisAccountId,
    Value<String?>? securityId,
    Value<double?>? locationLat,
    Value<double?>? locationLon,
    Value<String?>? locationName,
    Value<bool>? aiValuationEnabled,
    Value<String?>? aiValuationQuery,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return AccountsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      assetSubtype: assetSubtype ?? this.assetSubtype,
      liabilitySubtype: liabilitySubtype ?? this.liabilitySubtype,
      institution: institution ?? this.institution,
      currencyCode: currencyCode ?? this.currencyCode,
      ownershipN: ownershipN ?? this.ownershipN,
      ownershipD: ownershipD ?? this.ownershipD,
      includeInNetWorth: includeInNetWorth ?? this.includeInNetWorth,
      creditLimitMinor: creditLimitMinor ?? this.creditLimitMinor,
      statementDay: statementDay ?? this.statementDay,
      dueDay: dueDay ?? this.dueDay,
      isSystem: isSystem ?? this.isSystem,
      archived: archived ?? this.archived,
      sortOrder: sortOrder ?? this.sortOrder,
      notes: notes ?? this.notes,
      costBasisAccountId: costBasisAccountId ?? this.costBasisAccountId,
      securityId: securityId ?? this.securityId,
      locationLat: locationLat ?? this.locationLat,
      locationLon: locationLon ?? this.locationLon,
      locationName: locationName ?? this.locationName,
      aiValuationEnabled: aiValuationEnabled ?? this.aiValuationEnabled,
      aiValuationQuery: aiValuationQuery ?? this.aiValuationQuery,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (assetSubtype.present) {
      map['asset_subtype'] = Variable<String>(assetSubtype.value);
    }
    if (liabilitySubtype.present) {
      map['liability_subtype'] = Variable<String>(liabilitySubtype.value);
    }
    if (institution.present) {
      map['institution'] = Variable<String>(institution.value);
    }
    if (currencyCode.present) {
      map['currency_code'] = Variable<String>(currencyCode.value);
    }
    if (ownershipN.present) {
      map['ownership_n'] = Variable<String>(ownershipN.value);
    }
    if (ownershipD.present) {
      map['ownership_d'] = Variable<String>(ownershipD.value);
    }
    if (includeInNetWorth.present) {
      map['include_in_net_worth'] = Variable<bool>(includeInNetWorth.value);
    }
    if (creditLimitMinor.present) {
      map['credit_limit_minor'] = Variable<String>(
        $AccountsTable.$convertercreditLimitMinorn.toSql(
          creditLimitMinor.value,
        ),
      );
    }
    if (statementDay.present) {
      map['statement_day'] = Variable<int>(statementDay.value);
    }
    if (dueDay.present) {
      map['due_day'] = Variable<int>(dueDay.value);
    }
    if (isSystem.present) {
      map['is_system'] = Variable<bool>(isSystem.value);
    }
    if (archived.present) {
      map['archived'] = Variable<bool>(archived.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (costBasisAccountId.present) {
      map['cost_basis_account_id'] = Variable<String>(costBasisAccountId.value);
    }
    if (securityId.present) {
      map['security_id'] = Variable<String>(securityId.value);
    }
    if (locationLat.present) {
      map['location_lat'] = Variable<double>(locationLat.value);
    }
    if (locationLon.present) {
      map['location_lon'] = Variable<double>(locationLon.value);
    }
    if (locationName.present) {
      map['location_name'] = Variable<String>(locationName.value);
    }
    if (aiValuationEnabled.present) {
      map['ai_valuation_enabled'] = Variable<bool>(aiValuationEnabled.value);
    }
    if (aiValuationQuery.present) {
      map['ai_valuation_query'] = Variable<String>(aiValuationQuery.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AccountsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('assetSubtype: $assetSubtype, ')
          ..write('liabilitySubtype: $liabilitySubtype, ')
          ..write('institution: $institution, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('ownershipN: $ownershipN, ')
          ..write('ownershipD: $ownershipD, ')
          ..write('includeInNetWorth: $includeInNetWorth, ')
          ..write('creditLimitMinor: $creditLimitMinor, ')
          ..write('statementDay: $statementDay, ')
          ..write('dueDay: $dueDay, ')
          ..write('isSystem: $isSystem, ')
          ..write('archived: $archived, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('notes: $notes, ')
          ..write('costBasisAccountId: $costBasisAccountId, ')
          ..write('securityId: $securityId, ')
          ..write('locationLat: $locationLat, ')
          ..write('locationLon: $locationLon, ')
          ..write('locationName: $locationName, ')
          ..write('aiValuationEnabled: $aiValuationEnabled, ')
          ..write('aiValuationQuery: $aiValuationQuery, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SecuritiesTable extends Securities
    with TableInfo<$SecuritiesTable, SecurityRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SecuritiesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
    'code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currencyCodeMeta = const VerificationMeta(
    'currencyCode',
  );
  @override
  late final GeneratedColumn<String> currencyCode = GeneratedColumn<String>(
    'currency_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    code,
    name,
    type,
    currencyCode,
    notes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'securities';
  @override
  VerificationContext validateIntegrity(
    Insertable<SecurityRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('code')) {
      context.handle(
        _codeMeta,
        code.isAcceptableOrUnknown(data['code']!, _codeMeta),
      );
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('currency_code')) {
      context.handle(
        _currencyCodeMeta,
        currencyCode.isAcceptableOrUnknown(
          data['currency_code']!,
          _currencyCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_currencyCodeMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SecurityRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SecurityRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      code: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      currencyCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency_code'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
    );
  }

  @override
  $SecuritiesTable createAlias(String alias) {
    return $SecuritiesTable(attachedDatabase, alias);
  }
}

class SecurityRow extends DataClass implements Insertable<SecurityRow> {
  final String id;
  final String code;
  final String name;
  final String type;
  final String currencyCode;
  final String? notes;
  const SecurityRow({
    required this.id,
    required this.code,
    required this.name,
    required this.type,
    required this.currencyCode,
    this.notes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['code'] = Variable<String>(code);
    map['name'] = Variable<String>(name);
    map['type'] = Variable<String>(type);
    map['currency_code'] = Variable<String>(currencyCode);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    return map;
  }

  SecuritiesCompanion toCompanion(bool nullToAbsent) {
    return SecuritiesCompanion(
      id: Value(id),
      code: Value(code),
      name: Value(name),
      type: Value(type),
      currencyCode: Value(currencyCode),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
    );
  }

  factory SecurityRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SecurityRow(
      id: serializer.fromJson<String>(json['id']),
      code: serializer.fromJson<String>(json['code']),
      name: serializer.fromJson<String>(json['name']),
      type: serializer.fromJson<String>(json['type']),
      currencyCode: serializer.fromJson<String>(json['currencyCode']),
      notes: serializer.fromJson<String?>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'code': serializer.toJson<String>(code),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<String>(type),
      'currencyCode': serializer.toJson<String>(currencyCode),
      'notes': serializer.toJson<String?>(notes),
    };
  }

  SecurityRow copyWith({
    String? id,
    String? code,
    String? name,
    String? type,
    String? currencyCode,
    Value<String?> notes = const Value.absent(),
  }) => SecurityRow(
    id: id ?? this.id,
    code: code ?? this.code,
    name: name ?? this.name,
    type: type ?? this.type,
    currencyCode: currencyCode ?? this.currencyCode,
    notes: notes.present ? notes.value : this.notes,
  );
  SecurityRow copyWithCompanion(SecuritiesCompanion data) {
    return SecurityRow(
      id: data.id.present ? data.id.value : this.id,
      code: data.code.present ? data.code.value : this.code,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      currencyCode: data.currencyCode.present
          ? data.currencyCode.value
          : this.currencyCode,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SecurityRow(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, code, name, type, currencyCode, notes);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SecurityRow &&
          other.id == this.id &&
          other.code == this.code &&
          other.name == this.name &&
          other.type == this.type &&
          other.currencyCode == this.currencyCode &&
          other.notes == this.notes);
}

class SecuritiesCompanion extends UpdateCompanion<SecurityRow> {
  final Value<String> id;
  final Value<String> code;
  final Value<String> name;
  final Value<String> type;
  final Value<String> currencyCode;
  final Value<String?> notes;
  final Value<int> rowid;
  const SecuritiesCompanion({
    this.id = const Value.absent(),
    this.code = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SecuritiesCompanion.insert({
    required String id,
    required String code,
    required String name,
    required String type,
    required String currencyCode,
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       code = Value(code),
       name = Value(name),
       type = Value(type),
       currencyCode = Value(currencyCode);
  static Insertable<SecurityRow> custom({
    Expression<String>? id,
    Expression<String>? code,
    Expression<String>? name,
    Expression<String>? type,
    Expression<String>? currencyCode,
    Expression<String>? notes,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (code != null) 'code': code,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (currencyCode != null) 'currency_code': currencyCode,
      if (notes != null) 'notes': notes,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SecuritiesCompanion copyWith({
    Value<String>? id,
    Value<String>? code,
    Value<String>? name,
    Value<String>? type,
    Value<String>? currencyCode,
    Value<String?>? notes,
    Value<int>? rowid,
  }) {
    return SecuritiesCompanion(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      type: type ?? this.type,
      currencyCode: currencyCode ?? this.currencyCode,
      notes: notes ?? this.notes,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (currencyCode.present) {
      map['currency_code'] = Variable<String>(currencyCode.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SecuritiesCompanion(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('notes: $notes, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TransactionsTable extends Transactions
    with TableInfo<$TransactionsTable, TransactionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('posted'),
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _counterpartyMeta = const VerificationMeta(
    'counterparty',
  );
  @override
  late final GeneratedColumn<String> counterparty = GeneratedColumn<String>(
    'counterparty',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tagsJsonMeta = const VerificationMeta(
    'tagsJson',
  );
  @override
  late final GeneratedColumn<String> tagsJson = GeneratedColumn<String>(
    'tags_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _externalIdMeta = const VerificationMeta(
    'externalId',
  );
  @override
  late final GeneratedColumn<String> externalId = GeneratedColumn<String>(
    'external_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('manual'),
  );
  static const VerificationMeta _importBatchIdMeta = const VerificationMeta(
    'importBatchId',
  );
  @override
  late final GeneratedColumn<String> importBatchId = GeneratedColumn<String>(
    'import_batch_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isAdjustmentMeta = const VerificationMeta(
    'isAdjustment',
  );
  @override
  late final GeneratedColumn<bool> isAdjustment = GeneratedColumn<bool>(
    'is_adjustment',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_adjustment" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    date,
    kind,
    status,
    note,
    counterparty,
    categoryId,
    tagsJson,
    externalId,
    source,
    importBatchId,
    isAdjustment,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transactions';
  @override
  VerificationContext validateIntegrity(
    Insertable<TransactionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('counterparty')) {
      context.handle(
        _counterpartyMeta,
        counterparty.isAcceptableOrUnknown(
          data['counterparty']!,
          _counterpartyMeta,
        ),
      );
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    if (data.containsKey('tags_json')) {
      context.handle(
        _tagsJsonMeta,
        tagsJson.isAcceptableOrUnknown(data['tags_json']!, _tagsJsonMeta),
      );
    }
    if (data.containsKey('external_id')) {
      context.handle(
        _externalIdMeta,
        externalId.isAcceptableOrUnknown(data['external_id']!, _externalIdMeta),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    if (data.containsKey('import_batch_id')) {
      context.handle(
        _importBatchIdMeta,
        importBatchId.isAcceptableOrUnknown(
          data['import_batch_id']!,
          _importBatchIdMeta,
        ),
      );
    }
    if (data.containsKey('is_adjustment')) {
      context.handle(
        _isAdjustmentMeta,
        isAdjustment.isAcceptableOrUnknown(
          data['is_adjustment']!,
          _isAdjustmentMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TransactionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TransactionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      counterparty: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}counterparty'],
      ),
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      ),
      tagsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tags_json'],
      )!,
      externalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}external_id'],
      ),
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      importBatchId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}import_batch_id'],
      ),
      isAdjustment: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_adjustment'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $TransactionsTable createAlias(String alias) {
    return $TransactionsTable(attachedDatabase, alias);
  }
}

class TransactionRow extends DataClass implements Insertable<TransactionRow> {
  final String id;
  final DateTime date;

  /// TxKind.name / TxStatus.name / TxSource.name。
  final String kind;
  final String status;
  final String? note;
  final String? counterparty;
  final String? categoryId;
  final String tagsJson;
  final String? externalId;
  final String source;
  final String? importBatchId;
  final bool isAdjustment;
  final DateTime createdAt;
  final DateTime updatedAt;
  const TransactionRow({
    required this.id,
    required this.date,
    required this.kind,
    required this.status,
    this.note,
    this.counterparty,
    this.categoryId,
    required this.tagsJson,
    this.externalId,
    required this.source,
    this.importBatchId,
    required this.isAdjustment,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['date'] = Variable<DateTime>(date);
    map['kind'] = Variable<String>(kind);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    if (!nullToAbsent || counterparty != null) {
      map['counterparty'] = Variable<String>(counterparty);
    }
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
    }
    map['tags_json'] = Variable<String>(tagsJson);
    if (!nullToAbsent || externalId != null) {
      map['external_id'] = Variable<String>(externalId);
    }
    map['source'] = Variable<String>(source);
    if (!nullToAbsent || importBatchId != null) {
      map['import_batch_id'] = Variable<String>(importBatchId);
    }
    map['is_adjustment'] = Variable<bool>(isAdjustment);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  TransactionsCompanion toCompanion(bool nullToAbsent) {
    return TransactionsCompanion(
      id: Value(id),
      date: Value(date),
      kind: Value(kind),
      status: Value(status),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      counterparty: counterparty == null && nullToAbsent
          ? const Value.absent()
          : Value(counterparty),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      tagsJson: Value(tagsJson),
      externalId: externalId == null && nullToAbsent
          ? const Value.absent()
          : Value(externalId),
      source: Value(source),
      importBatchId: importBatchId == null && nullToAbsent
          ? const Value.absent()
          : Value(importBatchId),
      isAdjustment: Value(isAdjustment),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory TransactionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TransactionRow(
      id: serializer.fromJson<String>(json['id']),
      date: serializer.fromJson<DateTime>(json['date']),
      kind: serializer.fromJson<String>(json['kind']),
      status: serializer.fromJson<String>(json['status']),
      note: serializer.fromJson<String?>(json['note']),
      counterparty: serializer.fromJson<String?>(json['counterparty']),
      categoryId: serializer.fromJson<String?>(json['categoryId']),
      tagsJson: serializer.fromJson<String>(json['tagsJson']),
      externalId: serializer.fromJson<String?>(json['externalId']),
      source: serializer.fromJson<String>(json['source']),
      importBatchId: serializer.fromJson<String?>(json['importBatchId']),
      isAdjustment: serializer.fromJson<bool>(json['isAdjustment']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'date': serializer.toJson<DateTime>(date),
      'kind': serializer.toJson<String>(kind),
      'status': serializer.toJson<String>(status),
      'note': serializer.toJson<String?>(note),
      'counterparty': serializer.toJson<String?>(counterparty),
      'categoryId': serializer.toJson<String?>(categoryId),
      'tagsJson': serializer.toJson<String>(tagsJson),
      'externalId': serializer.toJson<String?>(externalId),
      'source': serializer.toJson<String>(source),
      'importBatchId': serializer.toJson<String?>(importBatchId),
      'isAdjustment': serializer.toJson<bool>(isAdjustment),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  TransactionRow copyWith({
    String? id,
    DateTime? date,
    String? kind,
    String? status,
    Value<String?> note = const Value.absent(),
    Value<String?> counterparty = const Value.absent(),
    Value<String?> categoryId = const Value.absent(),
    String? tagsJson,
    Value<String?> externalId = const Value.absent(),
    String? source,
    Value<String?> importBatchId = const Value.absent(),
    bool? isAdjustment,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => TransactionRow(
    id: id ?? this.id,
    date: date ?? this.date,
    kind: kind ?? this.kind,
    status: status ?? this.status,
    note: note.present ? note.value : this.note,
    counterparty: counterparty.present ? counterparty.value : this.counterparty,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    tagsJson: tagsJson ?? this.tagsJson,
    externalId: externalId.present ? externalId.value : this.externalId,
    source: source ?? this.source,
    importBatchId: importBatchId.present
        ? importBatchId.value
        : this.importBatchId,
    isAdjustment: isAdjustment ?? this.isAdjustment,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  TransactionRow copyWithCompanion(TransactionsCompanion data) {
    return TransactionRow(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      kind: data.kind.present ? data.kind.value : this.kind,
      status: data.status.present ? data.status.value : this.status,
      note: data.note.present ? data.note.value : this.note,
      counterparty: data.counterparty.present
          ? data.counterparty.value
          : this.counterparty,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      tagsJson: data.tagsJson.present ? data.tagsJson.value : this.tagsJson,
      externalId: data.externalId.present
          ? data.externalId.value
          : this.externalId,
      source: data.source.present ? data.source.value : this.source,
      importBatchId: data.importBatchId.present
          ? data.importBatchId.value
          : this.importBatchId,
      isAdjustment: data.isAdjustment.present
          ? data.isAdjustment.value
          : this.isAdjustment,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TransactionRow(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('kind: $kind, ')
          ..write('status: $status, ')
          ..write('note: $note, ')
          ..write('counterparty: $counterparty, ')
          ..write('categoryId: $categoryId, ')
          ..write('tagsJson: $tagsJson, ')
          ..write('externalId: $externalId, ')
          ..write('source: $source, ')
          ..write('importBatchId: $importBatchId, ')
          ..write('isAdjustment: $isAdjustment, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    date,
    kind,
    status,
    note,
    counterparty,
    categoryId,
    tagsJson,
    externalId,
    source,
    importBatchId,
    isAdjustment,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TransactionRow &&
          other.id == this.id &&
          other.date == this.date &&
          other.kind == this.kind &&
          other.status == this.status &&
          other.note == this.note &&
          other.counterparty == this.counterparty &&
          other.categoryId == this.categoryId &&
          other.tagsJson == this.tagsJson &&
          other.externalId == this.externalId &&
          other.source == this.source &&
          other.importBatchId == this.importBatchId &&
          other.isAdjustment == this.isAdjustment &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class TransactionsCompanion extends UpdateCompanion<TransactionRow> {
  final Value<String> id;
  final Value<DateTime> date;
  final Value<String> kind;
  final Value<String> status;
  final Value<String?> note;
  final Value<String?> counterparty;
  final Value<String?> categoryId;
  final Value<String> tagsJson;
  final Value<String?> externalId;
  final Value<String> source;
  final Value<String?> importBatchId;
  final Value<bool> isAdjustment;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const TransactionsCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.kind = const Value.absent(),
    this.status = const Value.absent(),
    this.note = const Value.absent(),
    this.counterparty = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.tagsJson = const Value.absent(),
    this.externalId = const Value.absent(),
    this.source = const Value.absent(),
    this.importBatchId = const Value.absent(),
    this.isAdjustment = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TransactionsCompanion.insert({
    required String id,
    required DateTime date,
    required String kind,
    this.status = const Value.absent(),
    this.note = const Value.absent(),
    this.counterparty = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.tagsJson = const Value.absent(),
    this.externalId = const Value.absent(),
    this.source = const Value.absent(),
    this.importBatchId = const Value.absent(),
    this.isAdjustment = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       date = Value(date),
       kind = Value(kind);
  static Insertable<TransactionRow> custom({
    Expression<String>? id,
    Expression<DateTime>? date,
    Expression<String>? kind,
    Expression<String>? status,
    Expression<String>? note,
    Expression<String>? counterparty,
    Expression<String>? categoryId,
    Expression<String>? tagsJson,
    Expression<String>? externalId,
    Expression<String>? source,
    Expression<String>? importBatchId,
    Expression<bool>? isAdjustment,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (kind != null) 'kind': kind,
      if (status != null) 'status': status,
      if (note != null) 'note': note,
      if (counterparty != null) 'counterparty': counterparty,
      if (categoryId != null) 'category_id': categoryId,
      if (tagsJson != null) 'tags_json': tagsJson,
      if (externalId != null) 'external_id': externalId,
      if (source != null) 'source': source,
      if (importBatchId != null) 'import_batch_id': importBatchId,
      if (isAdjustment != null) 'is_adjustment': isAdjustment,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TransactionsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? date,
    Value<String>? kind,
    Value<String>? status,
    Value<String?>? note,
    Value<String?>? counterparty,
    Value<String?>? categoryId,
    Value<String>? tagsJson,
    Value<String?>? externalId,
    Value<String>? source,
    Value<String?>? importBatchId,
    Value<bool>? isAdjustment,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return TransactionsCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      kind: kind ?? this.kind,
      status: status ?? this.status,
      note: note ?? this.note,
      counterparty: counterparty ?? this.counterparty,
      categoryId: categoryId ?? this.categoryId,
      tagsJson: tagsJson ?? this.tagsJson,
      externalId: externalId ?? this.externalId,
      source: source ?? this.source,
      importBatchId: importBatchId ?? this.importBatchId,
      isAdjustment: isAdjustment ?? this.isAdjustment,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (counterparty.present) {
      map['counterparty'] = Variable<String>(counterparty.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (tagsJson.present) {
      map['tags_json'] = Variable<String>(tagsJson.value);
    }
    if (externalId.present) {
      map['external_id'] = Variable<String>(externalId.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (importBatchId.present) {
      map['import_batch_id'] = Variable<String>(importBatchId.value);
    }
    if (isAdjustment.present) {
      map['is_adjustment'] = Variable<bool>(isAdjustment.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionsCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('kind: $kind, ')
          ..write('status: $status, ')
          ..write('note: $note, ')
          ..write('counterparty: $counterparty, ')
          ..write('categoryId: $categoryId, ')
          ..write('tagsJson: $tagsJson, ')
          ..write('externalId: $externalId, ')
          ..write('source: $source, ')
          ..write('importBatchId: $importBatchId, ')
          ..write('isAdjustment: $isAdjustment, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PostingsTable extends Postings
    with TableInfo<$PostingsTable, PostingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PostingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _txIdMeta = const VerificationMeta('txId');
  @override
  late final GeneratedColumn<String> txId = GeneratedColumn<String>(
    'tx_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<BigInt?, String> amountMinor =
      GeneratedColumn<String>(
        'amount_minor',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<BigInt?>($PostingsTable.$converteramountMinorn);
  static const VerificationMeta _currencyCodeMeta = const VerificationMeta(
    'currencyCode',
  );
  @override
  late final GeneratedColumn<String> currencyCode = GeneratedColumn<String>(
    'currency_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _securityIdMeta = const VerificationMeta(
    'securityId',
  );
  @override
  late final GeneratedColumn<String> securityId = GeneratedColumn<String>(
    'security_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<BigInt?, String> quantityN =
      GeneratedColumn<String>(
        'quantity_n',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<BigInt?>($PostingsTable.$converterquantityNn);
  @override
  late final GeneratedColumnWithTypeConverter<BigInt?, String> quantityD =
      GeneratedColumn<String>(
        'quantity_d',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<BigInt?>($PostingsTable.$converterquantityDn);
  static const VerificationMeta _memoMeta = const VerificationMeta('memo');
  @override
  late final GeneratedColumn<String> memo = GeneratedColumn<String>(
    'memo',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    txId,
    accountId,
    amountMinor,
    currencyCode,
    securityId,
    quantityN,
    quantityD,
    memo,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'postings';
  @override
  VerificationContext validateIntegrity(
    Insertable<PostingRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('tx_id')) {
      context.handle(
        _txIdMeta,
        txId.isAcceptableOrUnknown(data['tx_id']!, _txIdMeta),
      );
    } else if (isInserting) {
      context.missing(_txIdMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('currency_code')) {
      context.handle(
        _currencyCodeMeta,
        currencyCode.isAcceptableOrUnknown(
          data['currency_code']!,
          _currencyCodeMeta,
        ),
      );
    }
    if (data.containsKey('security_id')) {
      context.handle(
        _securityIdMeta,
        securityId.isAcceptableOrUnknown(data['security_id']!, _securityIdMeta),
      );
    }
    if (data.containsKey('memo')) {
      context.handle(
        _memoMeta,
        memo.isAcceptableOrUnknown(data['memo']!, _memoMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PostingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PostingRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      txId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tx_id'],
      )!,
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      amountMinor: $PostingsTable.$converteramountMinorn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}amount_minor'],
        ),
      ),
      currencyCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency_code'],
      ),
      securityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}security_id'],
      ),
      quantityN: $PostingsTable.$converterquantityNn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}quantity_n'],
        ),
      ),
      quantityD: $PostingsTable.$converterquantityDn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}quantity_d'],
        ),
      ),
      memo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}memo'],
      ),
    );
  }

  @override
  $PostingsTable createAlias(String alias) {
    return $PostingsTable(attachedDatabase, alias);
  }

  static TypeConverter<BigInt, String> $converteramountMinor =
      const BigIntText();
  static TypeConverter<BigInt?, String?> $converteramountMinorn =
      NullAwareTypeConverter.wrap($converteramountMinor);
  static TypeConverter<BigInt, String> $converterquantityN = const BigIntText();
  static TypeConverter<BigInt?, String?> $converterquantityNn =
      NullAwareTypeConverter.wrap($converterquantityN);
  static TypeConverter<BigInt, String> $converterquantityD = const BigIntText();
  static TypeConverter<BigInt?, String?> $converterquantityDn =
      NullAwareTypeConverter.wrap($converterquantityD);
}

class PostingRow extends DataClass implements Insertable<PostingRow> {
  final int id;
  final String txId;
  final String accountId;
  final BigInt? amountMinor;
  final String? currencyCode;
  final String? securityId;
  final BigInt? quantityN;
  final BigInt? quantityD;
  final String? memo;
  const PostingRow({
    required this.id,
    required this.txId,
    required this.accountId,
    this.amountMinor,
    this.currencyCode,
    this.securityId,
    this.quantityN,
    this.quantityD,
    this.memo,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['tx_id'] = Variable<String>(txId);
    map['account_id'] = Variable<String>(accountId);
    if (!nullToAbsent || amountMinor != null) {
      map['amount_minor'] = Variable<String>(
        $PostingsTable.$converteramountMinorn.toSql(amountMinor),
      );
    }
    if (!nullToAbsent || currencyCode != null) {
      map['currency_code'] = Variable<String>(currencyCode);
    }
    if (!nullToAbsent || securityId != null) {
      map['security_id'] = Variable<String>(securityId);
    }
    if (!nullToAbsent || quantityN != null) {
      map['quantity_n'] = Variable<String>(
        $PostingsTable.$converterquantityNn.toSql(quantityN),
      );
    }
    if (!nullToAbsent || quantityD != null) {
      map['quantity_d'] = Variable<String>(
        $PostingsTable.$converterquantityDn.toSql(quantityD),
      );
    }
    if (!nullToAbsent || memo != null) {
      map['memo'] = Variable<String>(memo);
    }
    return map;
  }

  PostingsCompanion toCompanion(bool nullToAbsent) {
    return PostingsCompanion(
      id: Value(id),
      txId: Value(txId),
      accountId: Value(accountId),
      amountMinor: amountMinor == null && nullToAbsent
          ? const Value.absent()
          : Value(amountMinor),
      currencyCode: currencyCode == null && nullToAbsent
          ? const Value.absent()
          : Value(currencyCode),
      securityId: securityId == null && nullToAbsent
          ? const Value.absent()
          : Value(securityId),
      quantityN: quantityN == null && nullToAbsent
          ? const Value.absent()
          : Value(quantityN),
      quantityD: quantityD == null && nullToAbsent
          ? const Value.absent()
          : Value(quantityD),
      memo: memo == null && nullToAbsent ? const Value.absent() : Value(memo),
    );
  }

  factory PostingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PostingRow(
      id: serializer.fromJson<int>(json['id']),
      txId: serializer.fromJson<String>(json['txId']),
      accountId: serializer.fromJson<String>(json['accountId']),
      amountMinor: serializer.fromJson<BigInt?>(json['amountMinor']),
      currencyCode: serializer.fromJson<String?>(json['currencyCode']),
      securityId: serializer.fromJson<String?>(json['securityId']),
      quantityN: serializer.fromJson<BigInt?>(json['quantityN']),
      quantityD: serializer.fromJson<BigInt?>(json['quantityD']),
      memo: serializer.fromJson<String?>(json['memo']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'txId': serializer.toJson<String>(txId),
      'accountId': serializer.toJson<String>(accountId),
      'amountMinor': serializer.toJson<BigInt?>(amountMinor),
      'currencyCode': serializer.toJson<String?>(currencyCode),
      'securityId': serializer.toJson<String?>(securityId),
      'quantityN': serializer.toJson<BigInt?>(quantityN),
      'quantityD': serializer.toJson<BigInt?>(quantityD),
      'memo': serializer.toJson<String?>(memo),
    };
  }

  PostingRow copyWith({
    int? id,
    String? txId,
    String? accountId,
    Value<BigInt?> amountMinor = const Value.absent(),
    Value<String?> currencyCode = const Value.absent(),
    Value<String?> securityId = const Value.absent(),
    Value<BigInt?> quantityN = const Value.absent(),
    Value<BigInt?> quantityD = const Value.absent(),
    Value<String?> memo = const Value.absent(),
  }) => PostingRow(
    id: id ?? this.id,
    txId: txId ?? this.txId,
    accountId: accountId ?? this.accountId,
    amountMinor: amountMinor.present ? amountMinor.value : this.amountMinor,
    currencyCode: currencyCode.present ? currencyCode.value : this.currencyCode,
    securityId: securityId.present ? securityId.value : this.securityId,
    quantityN: quantityN.present ? quantityN.value : this.quantityN,
    quantityD: quantityD.present ? quantityD.value : this.quantityD,
    memo: memo.present ? memo.value : this.memo,
  );
  PostingRow copyWithCompanion(PostingsCompanion data) {
    return PostingRow(
      id: data.id.present ? data.id.value : this.id,
      txId: data.txId.present ? data.txId.value : this.txId,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      amountMinor: data.amountMinor.present
          ? data.amountMinor.value
          : this.amountMinor,
      currencyCode: data.currencyCode.present
          ? data.currencyCode.value
          : this.currencyCode,
      securityId: data.securityId.present
          ? data.securityId.value
          : this.securityId,
      quantityN: data.quantityN.present ? data.quantityN.value : this.quantityN,
      quantityD: data.quantityD.present ? data.quantityD.value : this.quantityD,
      memo: data.memo.present ? data.memo.value : this.memo,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PostingRow(')
          ..write('id: $id, ')
          ..write('txId: $txId, ')
          ..write('accountId: $accountId, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('securityId: $securityId, ')
          ..write('quantityN: $quantityN, ')
          ..write('quantityD: $quantityD, ')
          ..write('memo: $memo')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    txId,
    accountId,
    amountMinor,
    currencyCode,
    securityId,
    quantityN,
    quantityD,
    memo,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PostingRow &&
          other.id == this.id &&
          other.txId == this.txId &&
          other.accountId == this.accountId &&
          other.amountMinor == this.amountMinor &&
          other.currencyCode == this.currencyCode &&
          other.securityId == this.securityId &&
          other.quantityN == this.quantityN &&
          other.quantityD == this.quantityD &&
          other.memo == this.memo);
}

class PostingsCompanion extends UpdateCompanion<PostingRow> {
  final Value<int> id;
  final Value<String> txId;
  final Value<String> accountId;
  final Value<BigInt?> amountMinor;
  final Value<String?> currencyCode;
  final Value<String?> securityId;
  final Value<BigInt?> quantityN;
  final Value<BigInt?> quantityD;
  final Value<String?> memo;
  const PostingsCompanion({
    this.id = const Value.absent(),
    this.txId = const Value.absent(),
    this.accountId = const Value.absent(),
    this.amountMinor = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.securityId = const Value.absent(),
    this.quantityN = const Value.absent(),
    this.quantityD = const Value.absent(),
    this.memo = const Value.absent(),
  });
  PostingsCompanion.insert({
    this.id = const Value.absent(),
    required String txId,
    required String accountId,
    this.amountMinor = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.securityId = const Value.absent(),
    this.quantityN = const Value.absent(),
    this.quantityD = const Value.absent(),
    this.memo = const Value.absent(),
  }) : txId = Value(txId),
       accountId = Value(accountId);
  static Insertable<PostingRow> custom({
    Expression<int>? id,
    Expression<String>? txId,
    Expression<String>? accountId,
    Expression<String>? amountMinor,
    Expression<String>? currencyCode,
    Expression<String>? securityId,
    Expression<String>? quantityN,
    Expression<String>? quantityD,
    Expression<String>? memo,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (txId != null) 'tx_id': txId,
      if (accountId != null) 'account_id': accountId,
      if (amountMinor != null) 'amount_minor': amountMinor,
      if (currencyCode != null) 'currency_code': currencyCode,
      if (securityId != null) 'security_id': securityId,
      if (quantityN != null) 'quantity_n': quantityN,
      if (quantityD != null) 'quantity_d': quantityD,
      if (memo != null) 'memo': memo,
    });
  }

  PostingsCompanion copyWith({
    Value<int>? id,
    Value<String>? txId,
    Value<String>? accountId,
    Value<BigInt?>? amountMinor,
    Value<String?>? currencyCode,
    Value<String?>? securityId,
    Value<BigInt?>? quantityN,
    Value<BigInt?>? quantityD,
    Value<String?>? memo,
  }) {
    return PostingsCompanion(
      id: id ?? this.id,
      txId: txId ?? this.txId,
      accountId: accountId ?? this.accountId,
      amountMinor: amountMinor ?? this.amountMinor,
      currencyCode: currencyCode ?? this.currencyCode,
      securityId: securityId ?? this.securityId,
      quantityN: quantityN ?? this.quantityN,
      quantityD: quantityD ?? this.quantityD,
      memo: memo ?? this.memo,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (txId.present) {
      map['tx_id'] = Variable<String>(txId.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (amountMinor.present) {
      map['amount_minor'] = Variable<String>(
        $PostingsTable.$converteramountMinorn.toSql(amountMinor.value),
      );
    }
    if (currencyCode.present) {
      map['currency_code'] = Variable<String>(currencyCode.value);
    }
    if (securityId.present) {
      map['security_id'] = Variable<String>(securityId.value);
    }
    if (quantityN.present) {
      map['quantity_n'] = Variable<String>(
        $PostingsTable.$converterquantityNn.toSql(quantityN.value),
      );
    }
    if (quantityD.present) {
      map['quantity_d'] = Variable<String>(
        $PostingsTable.$converterquantityDn.toSql(quantityD.value),
      );
    }
    if (memo.present) {
      map['memo'] = Variable<String>(memo.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PostingsCompanion(')
          ..write('id: $id, ')
          ..write('txId: $txId, ')
          ..write('accountId: $accountId, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('securityId: $securityId, ')
          ..write('quantityN: $quantityN, ')
          ..write('quantityD: $quantityD, ')
          ..write('memo: $memo')
          ..write(')'))
        .toString();
  }
}

class $BudgetsTable extends Budgets with TableInfo<$BudgetsTable, BudgetRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BudgetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scopeMeta = const VerificationMeta('scope');
  @override
  late final GeneratedColumn<String> scope = GeneratedColumn<String>(
    'scope',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<BigInt, String> limitMinor =
      GeneratedColumn<String>(
        'limit_minor',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<BigInt>($BudgetsTable.$converterlimitMinor);
  static const VerificationMeta _currencyCodeMeta = const VerificationMeta(
    'currencyCode',
  );
  @override
  late final GeneratedColumn<String> currencyCode = GeneratedColumn<String>(
    'currency_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startMonthMeta = const VerificationMeta(
    'startMonth',
  );
  @override
  late final GeneratedColumn<String> startMonth = GeneratedColumn<String>(
    'start_month',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endMonthMeta = const VerificationMeta(
    'endMonth',
  );
  @override
  late final GeneratedColumn<String> endMonth = GeneratedColumn<String>(
    'end_month',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rolloverMeta = const VerificationMeta(
    'rollover',
  );
  @override
  late final GeneratedColumn<String> rollover = GeneratedColumn<String>(
    'rollover',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('none'),
  );
  @override
  late final GeneratedColumnWithTypeConverter<BigInt?, String>
  rolloverCapMinor = GeneratedColumn<String>(
    'rollover_cap_minor',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  ).withConverter<BigInt?>($BudgetsTable.$converterrolloverCapMinorn);
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
    'active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    scope,
    limitMinor,
    currencyCode,
    startMonth,
    endMonth,
    categoryId,
    rollover,
    rolloverCapMinor,
    active,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'budgets';
  @override
  VerificationContext validateIntegrity(
    Insertable<BudgetRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('scope')) {
      context.handle(
        _scopeMeta,
        scope.isAcceptableOrUnknown(data['scope']!, _scopeMeta),
      );
    } else if (isInserting) {
      context.missing(_scopeMeta);
    }
    if (data.containsKey('currency_code')) {
      context.handle(
        _currencyCodeMeta,
        currencyCode.isAcceptableOrUnknown(
          data['currency_code']!,
          _currencyCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_currencyCodeMeta);
    }
    if (data.containsKey('start_month')) {
      context.handle(
        _startMonthMeta,
        startMonth.isAcceptableOrUnknown(data['start_month']!, _startMonthMeta),
      );
    } else if (isInserting) {
      context.missing(_startMonthMeta);
    }
    if (data.containsKey('end_month')) {
      context.handle(
        _endMonthMeta,
        endMonth.isAcceptableOrUnknown(data['end_month']!, _endMonthMeta),
      );
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    if (data.containsKey('rollover')) {
      context.handle(
        _rolloverMeta,
        rollover.isAcceptableOrUnknown(data['rollover']!, _rolloverMeta),
      );
    }
    if (data.containsKey('active')) {
      context.handle(
        _activeMeta,
        active.isAcceptableOrUnknown(data['active']!, _activeMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BudgetRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BudgetRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      scope: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scope'],
      )!,
      limitMinor: $BudgetsTable.$converterlimitMinor.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}limit_minor'],
        )!,
      ),
      currencyCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency_code'],
      )!,
      startMonth: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}start_month'],
      )!,
      endMonth: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}end_month'],
      ),
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      ),
      rollover: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rollover'],
      )!,
      rolloverCapMinor: $BudgetsTable.$converterrolloverCapMinorn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}rollover_cap_minor'],
        ),
      ),
      active: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}active'],
      )!,
    );
  }

  @override
  $BudgetsTable createAlias(String alias) {
    return $BudgetsTable(attachedDatabase, alias);
  }

  static TypeConverter<BigInt, String> $converterlimitMinor =
      const BigIntText();
  static TypeConverter<BigInt, String> $converterrolloverCapMinor =
      const BigIntText();
  static TypeConverter<BigInt?, String?> $converterrolloverCapMinorn =
      NullAwareTypeConverter.wrap($converterrolloverCapMinor);
}

class BudgetRow extends DataClass implements Insertable<BudgetRow> {
  final String id;
  final String name;
  final String scope;
  final BigInt limitMinor;
  final String currencyCode;
  final String startMonth;
  final String? endMonth;
  final String? categoryId;
  final String rollover;
  final BigInt? rolloverCapMinor;
  final bool active;
  const BudgetRow({
    required this.id,
    required this.name,
    required this.scope,
    required this.limitMinor,
    required this.currencyCode,
    required this.startMonth,
    this.endMonth,
    this.categoryId,
    required this.rollover,
    this.rolloverCapMinor,
    required this.active,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['scope'] = Variable<String>(scope);
    {
      map['limit_minor'] = Variable<String>(
        $BudgetsTable.$converterlimitMinor.toSql(limitMinor),
      );
    }
    map['currency_code'] = Variable<String>(currencyCode);
    map['start_month'] = Variable<String>(startMonth);
    if (!nullToAbsent || endMonth != null) {
      map['end_month'] = Variable<String>(endMonth);
    }
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
    }
    map['rollover'] = Variable<String>(rollover);
    if (!nullToAbsent || rolloverCapMinor != null) {
      map['rollover_cap_minor'] = Variable<String>(
        $BudgetsTable.$converterrolloverCapMinorn.toSql(rolloverCapMinor),
      );
    }
    map['active'] = Variable<bool>(active);
    return map;
  }

  BudgetsCompanion toCompanion(bool nullToAbsent) {
    return BudgetsCompanion(
      id: Value(id),
      name: Value(name),
      scope: Value(scope),
      limitMinor: Value(limitMinor),
      currencyCode: Value(currencyCode),
      startMonth: Value(startMonth),
      endMonth: endMonth == null && nullToAbsent
          ? const Value.absent()
          : Value(endMonth),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      rollover: Value(rollover),
      rolloverCapMinor: rolloverCapMinor == null && nullToAbsent
          ? const Value.absent()
          : Value(rolloverCapMinor),
      active: Value(active),
    );
  }

  factory BudgetRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BudgetRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      scope: serializer.fromJson<String>(json['scope']),
      limitMinor: serializer.fromJson<BigInt>(json['limitMinor']),
      currencyCode: serializer.fromJson<String>(json['currencyCode']),
      startMonth: serializer.fromJson<String>(json['startMonth']),
      endMonth: serializer.fromJson<String?>(json['endMonth']),
      categoryId: serializer.fromJson<String?>(json['categoryId']),
      rollover: serializer.fromJson<String>(json['rollover']),
      rolloverCapMinor: serializer.fromJson<BigInt?>(json['rolloverCapMinor']),
      active: serializer.fromJson<bool>(json['active']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'scope': serializer.toJson<String>(scope),
      'limitMinor': serializer.toJson<BigInt>(limitMinor),
      'currencyCode': serializer.toJson<String>(currencyCode),
      'startMonth': serializer.toJson<String>(startMonth),
      'endMonth': serializer.toJson<String?>(endMonth),
      'categoryId': serializer.toJson<String?>(categoryId),
      'rollover': serializer.toJson<String>(rollover),
      'rolloverCapMinor': serializer.toJson<BigInt?>(rolloverCapMinor),
      'active': serializer.toJson<bool>(active),
    };
  }

  BudgetRow copyWith({
    String? id,
    String? name,
    String? scope,
    BigInt? limitMinor,
    String? currencyCode,
    String? startMonth,
    Value<String?> endMonth = const Value.absent(),
    Value<String?> categoryId = const Value.absent(),
    String? rollover,
    Value<BigInt?> rolloverCapMinor = const Value.absent(),
    bool? active,
  }) => BudgetRow(
    id: id ?? this.id,
    name: name ?? this.name,
    scope: scope ?? this.scope,
    limitMinor: limitMinor ?? this.limitMinor,
    currencyCode: currencyCode ?? this.currencyCode,
    startMonth: startMonth ?? this.startMonth,
    endMonth: endMonth.present ? endMonth.value : this.endMonth,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    rollover: rollover ?? this.rollover,
    rolloverCapMinor: rolloverCapMinor.present
        ? rolloverCapMinor.value
        : this.rolloverCapMinor,
    active: active ?? this.active,
  );
  BudgetRow copyWithCompanion(BudgetsCompanion data) {
    return BudgetRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      scope: data.scope.present ? data.scope.value : this.scope,
      limitMinor: data.limitMinor.present
          ? data.limitMinor.value
          : this.limitMinor,
      currencyCode: data.currencyCode.present
          ? data.currencyCode.value
          : this.currencyCode,
      startMonth: data.startMonth.present
          ? data.startMonth.value
          : this.startMonth,
      endMonth: data.endMonth.present ? data.endMonth.value : this.endMonth,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      rollover: data.rollover.present ? data.rollover.value : this.rollover,
      rolloverCapMinor: data.rolloverCapMinor.present
          ? data.rolloverCapMinor.value
          : this.rolloverCapMinor,
      active: data.active.present ? data.active.value : this.active,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BudgetRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('scope: $scope, ')
          ..write('limitMinor: $limitMinor, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('startMonth: $startMonth, ')
          ..write('endMonth: $endMonth, ')
          ..write('categoryId: $categoryId, ')
          ..write('rollover: $rollover, ')
          ..write('rolloverCapMinor: $rolloverCapMinor, ')
          ..write('active: $active')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    scope,
    limitMinor,
    currencyCode,
    startMonth,
    endMonth,
    categoryId,
    rollover,
    rolloverCapMinor,
    active,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BudgetRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.scope == this.scope &&
          other.limitMinor == this.limitMinor &&
          other.currencyCode == this.currencyCode &&
          other.startMonth == this.startMonth &&
          other.endMonth == this.endMonth &&
          other.categoryId == this.categoryId &&
          other.rollover == this.rollover &&
          other.rolloverCapMinor == this.rolloverCapMinor &&
          other.active == this.active);
}

class BudgetsCompanion extends UpdateCompanion<BudgetRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> scope;
  final Value<BigInt> limitMinor;
  final Value<String> currencyCode;
  final Value<String> startMonth;
  final Value<String?> endMonth;
  final Value<String?> categoryId;
  final Value<String> rollover;
  final Value<BigInt?> rolloverCapMinor;
  final Value<bool> active;
  final Value<int> rowid;
  const BudgetsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.scope = const Value.absent(),
    this.limitMinor = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.startMonth = const Value.absent(),
    this.endMonth = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.rollover = const Value.absent(),
    this.rolloverCapMinor = const Value.absent(),
    this.active = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BudgetsCompanion.insert({
    required String id,
    required String name,
    required String scope,
    required BigInt limitMinor,
    required String currencyCode,
    required String startMonth,
    this.endMonth = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.rollover = const Value.absent(),
    this.rolloverCapMinor = const Value.absent(),
    this.active = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       scope = Value(scope),
       limitMinor = Value(limitMinor),
       currencyCode = Value(currencyCode),
       startMonth = Value(startMonth);
  static Insertable<BudgetRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? scope,
    Expression<String>? limitMinor,
    Expression<String>? currencyCode,
    Expression<String>? startMonth,
    Expression<String>? endMonth,
    Expression<String>? categoryId,
    Expression<String>? rollover,
    Expression<String>? rolloverCapMinor,
    Expression<bool>? active,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (scope != null) 'scope': scope,
      if (limitMinor != null) 'limit_minor': limitMinor,
      if (currencyCode != null) 'currency_code': currencyCode,
      if (startMonth != null) 'start_month': startMonth,
      if (endMonth != null) 'end_month': endMonth,
      if (categoryId != null) 'category_id': categoryId,
      if (rollover != null) 'rollover': rollover,
      if (rolloverCapMinor != null) 'rollover_cap_minor': rolloverCapMinor,
      if (active != null) 'active': active,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BudgetsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? scope,
    Value<BigInt>? limitMinor,
    Value<String>? currencyCode,
    Value<String>? startMonth,
    Value<String?>? endMonth,
    Value<String?>? categoryId,
    Value<String>? rollover,
    Value<BigInt?>? rolloverCapMinor,
    Value<bool>? active,
    Value<int>? rowid,
  }) {
    return BudgetsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      scope: scope ?? this.scope,
      limitMinor: limitMinor ?? this.limitMinor,
      currencyCode: currencyCode ?? this.currencyCode,
      startMonth: startMonth ?? this.startMonth,
      endMonth: endMonth ?? this.endMonth,
      categoryId: categoryId ?? this.categoryId,
      rollover: rollover ?? this.rollover,
      rolloverCapMinor: rolloverCapMinor ?? this.rolloverCapMinor,
      active: active ?? this.active,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (scope.present) {
      map['scope'] = Variable<String>(scope.value);
    }
    if (limitMinor.present) {
      map['limit_minor'] = Variable<String>(
        $BudgetsTable.$converterlimitMinor.toSql(limitMinor.value),
      );
    }
    if (currencyCode.present) {
      map['currency_code'] = Variable<String>(currencyCode.value);
    }
    if (startMonth.present) {
      map['start_month'] = Variable<String>(startMonth.value);
    }
    if (endMonth.present) {
      map['end_month'] = Variable<String>(endMonth.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (rollover.present) {
      map['rollover'] = Variable<String>(rollover.value);
    }
    if (rolloverCapMinor.present) {
      map['rollover_cap_minor'] = Variable<String>(
        $BudgetsTable.$converterrolloverCapMinorn.toSql(rolloverCapMinor.value),
      );
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BudgetsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('scope: $scope, ')
          ..write('limitMinor: $limitMinor, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('startMonth: $startMonth, ')
          ..write('endMonth: $endMonth, ')
          ..write('categoryId: $categoryId, ')
          ..write('rollover: $rollover, ')
          ..write('rolloverCapMinor: $rolloverCapMinor, ')
          ..write('active: $active, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ScheduledEventsTable extends ScheduledEvents
    with TableInfo<$ScheduledEventsTable, ScheduledEventRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ScheduledEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _directionMeta = const VerificationMeta(
    'direction',
  );
  @override
  late final GeneratedColumn<String> direction = GeneratedColumn<String>(
    'direction',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currencyCodeMeta = const VerificationMeta(
    'currencyCode',
  );
  @override
  late final GeneratedColumn<String> currencyCode = GeneratedColumn<String>(
    'currency_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cadenceMeta = const VerificationMeta(
    'cadence',
  );
  @override
  late final GeneratedColumn<String> cadence = GeneratedColumn<String>(
    'cadence',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _anchorDateMeta = const VerificationMeta(
    'anchorDate',
  );
  @override
  late final GeneratedColumn<DateTime> anchorDate = GeneratedColumn<DateTime>(
    'anchor_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<BigInt?, String> amountMinor =
      GeneratedColumn<String>(
        'amount_minor',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<BigInt?>($ScheduledEventsTable.$converteramountMinorn);
  @override
  late final GeneratedColumnWithTypeConverter<BigInt?, String> amountLowMinor =
      GeneratedColumn<String>(
        'amount_low_minor',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<BigInt?>($ScheduledEventsTable.$converteramountLowMinorn);
  @override
  late final GeneratedColumnWithTypeConverter<BigInt?, String> amountHighMinor =
      GeneratedColumn<String>(
        'amount_high_minor',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<BigInt?>(
        $ScheduledEventsTable.$converteramountHighMinorn,
      );
  static const VerificationMeta _intervalValueMeta = const VerificationMeta(
    'intervalValue',
  );
  @override
  late final GeneratedColumn<int> intervalValue = GeneratedColumn<int>(
    'interval_value',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _monthEndPolicyMeta = const VerificationMeta(
    'monthEndPolicy',
  );
  @override
  late final GeneratedColumn<String> monthEndPolicy = GeneratedColumn<String>(
    'month_end_policy',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('clampToMonthEnd'),
  );
  static const VerificationMeta _endDateMeta = const VerificationMeta(
    'endDate',
  );
  @override
  late final GeneratedColumn<DateTime> endDate = GeneratedColumn<DateTime>(
    'end_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _paymentAccountIdMeta = const VerificationMeta(
    'paymentAccountId',
  );
  @override
  late final GeneratedColumn<String> paymentAccountId = GeneratedColumn<String>(
    'payment_account_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _autoPostMeta = const VerificationMeta(
    'autoPost',
  );
  @override
  late final GeneratedColumn<bool> autoPost = GeneratedColumn<bool>(
    'auto_post',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("auto_post" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('active'),
  );
  static const VerificationMeta _skippedMonthsJsonMeta = const VerificationMeta(
    'skippedMonthsJson',
  );
  @override
  late final GeneratedColumn<String> skippedMonthsJson =
      GeneratedColumn<String>(
        'skipped_months_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('[]'),
      );
  static const VerificationMeta _skippedDatesJsonMeta = const VerificationMeta(
    'skippedDatesJson',
  );
  @override
  late final GeneratedColumn<String> skippedDatesJson = GeneratedColumn<String>(
    'skipped_dates_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _amountOverridesJsonMeta =
      const VerificationMeta('amountOverridesJson');
  @override
  late final GeneratedColumn<String> amountOverridesJson =
      GeneratedColumn<String>(
        'amount_overrides_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('{}'),
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    direction,
    currencyCode,
    cadence,
    anchorDate,
    amountMinor,
    amountLowMinor,
    amountHighMinor,
    intervalValue,
    monthEndPolicy,
    endDate,
    paymentAccountId,
    categoryId,
    autoPost,
    notes,
    status,
    skippedMonthsJson,
    skippedDatesJson,
    amountOverridesJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'scheduled_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<ScheduledEventRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('direction')) {
      context.handle(
        _directionMeta,
        direction.isAcceptableOrUnknown(data['direction']!, _directionMeta),
      );
    } else if (isInserting) {
      context.missing(_directionMeta);
    }
    if (data.containsKey('currency_code')) {
      context.handle(
        _currencyCodeMeta,
        currencyCode.isAcceptableOrUnknown(
          data['currency_code']!,
          _currencyCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_currencyCodeMeta);
    }
    if (data.containsKey('cadence')) {
      context.handle(
        _cadenceMeta,
        cadence.isAcceptableOrUnknown(data['cadence']!, _cadenceMeta),
      );
    } else if (isInserting) {
      context.missing(_cadenceMeta);
    }
    if (data.containsKey('anchor_date')) {
      context.handle(
        _anchorDateMeta,
        anchorDate.isAcceptableOrUnknown(data['anchor_date']!, _anchorDateMeta),
      );
    } else if (isInserting) {
      context.missing(_anchorDateMeta);
    }
    if (data.containsKey('interval_value')) {
      context.handle(
        _intervalValueMeta,
        intervalValue.isAcceptableOrUnknown(
          data['interval_value']!,
          _intervalValueMeta,
        ),
      );
    }
    if (data.containsKey('month_end_policy')) {
      context.handle(
        _monthEndPolicyMeta,
        monthEndPolicy.isAcceptableOrUnknown(
          data['month_end_policy']!,
          _monthEndPolicyMeta,
        ),
      );
    }
    if (data.containsKey('end_date')) {
      context.handle(
        _endDateMeta,
        endDate.isAcceptableOrUnknown(data['end_date']!, _endDateMeta),
      );
    }
    if (data.containsKey('payment_account_id')) {
      context.handle(
        _paymentAccountIdMeta,
        paymentAccountId.isAcceptableOrUnknown(
          data['payment_account_id']!,
          _paymentAccountIdMeta,
        ),
      );
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    if (data.containsKey('auto_post')) {
      context.handle(
        _autoPostMeta,
        autoPost.isAcceptableOrUnknown(data['auto_post']!, _autoPostMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('skipped_months_json')) {
      context.handle(
        _skippedMonthsJsonMeta,
        skippedMonthsJson.isAcceptableOrUnknown(
          data['skipped_months_json']!,
          _skippedMonthsJsonMeta,
        ),
      );
    }
    if (data.containsKey('skipped_dates_json')) {
      context.handle(
        _skippedDatesJsonMeta,
        skippedDatesJson.isAcceptableOrUnknown(
          data['skipped_dates_json']!,
          _skippedDatesJsonMeta,
        ),
      );
    }
    if (data.containsKey('amount_overrides_json')) {
      context.handle(
        _amountOverridesJsonMeta,
        amountOverridesJson.isAcceptableOrUnknown(
          data['amount_overrides_json']!,
          _amountOverridesJsonMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ScheduledEventRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ScheduledEventRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      direction: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}direction'],
      )!,
      currencyCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency_code'],
      )!,
      cadence: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cadence'],
      )!,
      anchorDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}anchor_date'],
      )!,
      amountMinor: $ScheduledEventsTable.$converteramountMinorn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}amount_minor'],
        ),
      ),
      amountLowMinor: $ScheduledEventsTable.$converteramountLowMinorn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}amount_low_minor'],
        ),
      ),
      amountHighMinor: $ScheduledEventsTable.$converteramountHighMinorn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}amount_high_minor'],
        ),
      ),
      intervalValue: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}interval_value'],
      )!,
      monthEndPolicy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}month_end_policy'],
      )!,
      endDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}end_date'],
      ),
      paymentAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payment_account_id'],
      ),
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      ),
      autoPost: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}auto_post'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      skippedMonthsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}skipped_months_json'],
      )!,
      skippedDatesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}skipped_dates_json'],
      )!,
      amountOverridesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}amount_overrides_json'],
      )!,
    );
  }

  @override
  $ScheduledEventsTable createAlias(String alias) {
    return $ScheduledEventsTable(attachedDatabase, alias);
  }

  static TypeConverter<BigInt, String> $converteramountMinor =
      const BigIntText();
  static TypeConverter<BigInt?, String?> $converteramountMinorn =
      NullAwareTypeConverter.wrap($converteramountMinor);
  static TypeConverter<BigInt, String> $converteramountLowMinor =
      const BigIntText();
  static TypeConverter<BigInt?, String?> $converteramountLowMinorn =
      NullAwareTypeConverter.wrap($converteramountLowMinor);
  static TypeConverter<BigInt, String> $converteramountHighMinor =
      const BigIntText();
  static TypeConverter<BigInt?, String?> $converteramountHighMinorn =
      NullAwareTypeConverter.wrap($converteramountHighMinor);
}

class ScheduledEventRow extends DataClass
    implements Insertable<ScheduledEventRow> {
  final String id;
  final String name;
  final String direction;
  final String currencyCode;
  final String cadence;
  final DateTime anchorDate;
  final BigInt? amountMinor;
  final BigInt? amountLowMinor;
  final BigInt? amountHighMinor;
  final int intervalValue;
  final String monthEndPolicy;
  final DateTime? endDate;
  final String? paymentAccountId;
  final String? categoryId;
  final bool autoPost;
  final String? notes;
  final String status;
  final String skippedMonthsJson;
  final String skippedDatesJson;
  final String amountOverridesJson;
  const ScheduledEventRow({
    required this.id,
    required this.name,
    required this.direction,
    required this.currencyCode,
    required this.cadence,
    required this.anchorDate,
    this.amountMinor,
    this.amountLowMinor,
    this.amountHighMinor,
    required this.intervalValue,
    required this.monthEndPolicy,
    this.endDate,
    this.paymentAccountId,
    this.categoryId,
    required this.autoPost,
    this.notes,
    required this.status,
    required this.skippedMonthsJson,
    required this.skippedDatesJson,
    required this.amountOverridesJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['direction'] = Variable<String>(direction);
    map['currency_code'] = Variable<String>(currencyCode);
    map['cadence'] = Variable<String>(cadence);
    map['anchor_date'] = Variable<DateTime>(anchorDate);
    if (!nullToAbsent || amountMinor != null) {
      map['amount_minor'] = Variable<String>(
        $ScheduledEventsTable.$converteramountMinorn.toSql(amountMinor),
      );
    }
    if (!nullToAbsent || amountLowMinor != null) {
      map['amount_low_minor'] = Variable<String>(
        $ScheduledEventsTable.$converteramountLowMinorn.toSql(amountLowMinor),
      );
    }
    if (!nullToAbsent || amountHighMinor != null) {
      map['amount_high_minor'] = Variable<String>(
        $ScheduledEventsTable.$converteramountHighMinorn.toSql(amountHighMinor),
      );
    }
    map['interval_value'] = Variable<int>(intervalValue);
    map['month_end_policy'] = Variable<String>(monthEndPolicy);
    if (!nullToAbsent || endDate != null) {
      map['end_date'] = Variable<DateTime>(endDate);
    }
    if (!nullToAbsent || paymentAccountId != null) {
      map['payment_account_id'] = Variable<String>(paymentAccountId);
    }
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
    }
    map['auto_post'] = Variable<bool>(autoPost);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['status'] = Variable<String>(status);
    map['skipped_months_json'] = Variable<String>(skippedMonthsJson);
    map['skipped_dates_json'] = Variable<String>(skippedDatesJson);
    map['amount_overrides_json'] = Variable<String>(amountOverridesJson);
    return map;
  }

  ScheduledEventsCompanion toCompanion(bool nullToAbsent) {
    return ScheduledEventsCompanion(
      id: Value(id),
      name: Value(name),
      direction: Value(direction),
      currencyCode: Value(currencyCode),
      cadence: Value(cadence),
      anchorDate: Value(anchorDate),
      amountMinor: amountMinor == null && nullToAbsent
          ? const Value.absent()
          : Value(amountMinor),
      amountLowMinor: amountLowMinor == null && nullToAbsent
          ? const Value.absent()
          : Value(amountLowMinor),
      amountHighMinor: amountHighMinor == null && nullToAbsent
          ? const Value.absent()
          : Value(amountHighMinor),
      intervalValue: Value(intervalValue),
      monthEndPolicy: Value(monthEndPolicy),
      endDate: endDate == null && nullToAbsent
          ? const Value.absent()
          : Value(endDate),
      paymentAccountId: paymentAccountId == null && nullToAbsent
          ? const Value.absent()
          : Value(paymentAccountId),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      autoPost: Value(autoPost),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      status: Value(status),
      skippedMonthsJson: Value(skippedMonthsJson),
      skippedDatesJson: Value(skippedDatesJson),
      amountOverridesJson: Value(amountOverridesJson),
    );
  }

  factory ScheduledEventRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ScheduledEventRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      direction: serializer.fromJson<String>(json['direction']),
      currencyCode: serializer.fromJson<String>(json['currencyCode']),
      cadence: serializer.fromJson<String>(json['cadence']),
      anchorDate: serializer.fromJson<DateTime>(json['anchorDate']),
      amountMinor: serializer.fromJson<BigInt?>(json['amountMinor']),
      amountLowMinor: serializer.fromJson<BigInt?>(json['amountLowMinor']),
      amountHighMinor: serializer.fromJson<BigInt?>(json['amountHighMinor']),
      intervalValue: serializer.fromJson<int>(json['intervalValue']),
      monthEndPolicy: serializer.fromJson<String>(json['monthEndPolicy']),
      endDate: serializer.fromJson<DateTime?>(json['endDate']),
      paymentAccountId: serializer.fromJson<String?>(json['paymentAccountId']),
      categoryId: serializer.fromJson<String?>(json['categoryId']),
      autoPost: serializer.fromJson<bool>(json['autoPost']),
      notes: serializer.fromJson<String?>(json['notes']),
      status: serializer.fromJson<String>(json['status']),
      skippedMonthsJson: serializer.fromJson<String>(json['skippedMonthsJson']),
      skippedDatesJson: serializer.fromJson<String>(json['skippedDatesJson']),
      amountOverridesJson: serializer.fromJson<String>(
        json['amountOverridesJson'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'direction': serializer.toJson<String>(direction),
      'currencyCode': serializer.toJson<String>(currencyCode),
      'cadence': serializer.toJson<String>(cadence),
      'anchorDate': serializer.toJson<DateTime>(anchorDate),
      'amountMinor': serializer.toJson<BigInt?>(amountMinor),
      'amountLowMinor': serializer.toJson<BigInt?>(amountLowMinor),
      'amountHighMinor': serializer.toJson<BigInt?>(amountHighMinor),
      'intervalValue': serializer.toJson<int>(intervalValue),
      'monthEndPolicy': serializer.toJson<String>(monthEndPolicy),
      'endDate': serializer.toJson<DateTime?>(endDate),
      'paymentAccountId': serializer.toJson<String?>(paymentAccountId),
      'categoryId': serializer.toJson<String?>(categoryId),
      'autoPost': serializer.toJson<bool>(autoPost),
      'notes': serializer.toJson<String?>(notes),
      'status': serializer.toJson<String>(status),
      'skippedMonthsJson': serializer.toJson<String>(skippedMonthsJson),
      'skippedDatesJson': serializer.toJson<String>(skippedDatesJson),
      'amountOverridesJson': serializer.toJson<String>(amountOverridesJson),
    };
  }

  ScheduledEventRow copyWith({
    String? id,
    String? name,
    String? direction,
    String? currencyCode,
    String? cadence,
    DateTime? anchorDate,
    Value<BigInt?> amountMinor = const Value.absent(),
    Value<BigInt?> amountLowMinor = const Value.absent(),
    Value<BigInt?> amountHighMinor = const Value.absent(),
    int? intervalValue,
    String? monthEndPolicy,
    Value<DateTime?> endDate = const Value.absent(),
    Value<String?> paymentAccountId = const Value.absent(),
    Value<String?> categoryId = const Value.absent(),
    bool? autoPost,
    Value<String?> notes = const Value.absent(),
    String? status,
    String? skippedMonthsJson,
    String? skippedDatesJson,
    String? amountOverridesJson,
  }) => ScheduledEventRow(
    id: id ?? this.id,
    name: name ?? this.name,
    direction: direction ?? this.direction,
    currencyCode: currencyCode ?? this.currencyCode,
    cadence: cadence ?? this.cadence,
    anchorDate: anchorDate ?? this.anchorDate,
    amountMinor: amountMinor.present ? amountMinor.value : this.amountMinor,
    amountLowMinor: amountLowMinor.present
        ? amountLowMinor.value
        : this.amountLowMinor,
    amountHighMinor: amountHighMinor.present
        ? amountHighMinor.value
        : this.amountHighMinor,
    intervalValue: intervalValue ?? this.intervalValue,
    monthEndPolicy: monthEndPolicy ?? this.monthEndPolicy,
    endDate: endDate.present ? endDate.value : this.endDate,
    paymentAccountId: paymentAccountId.present
        ? paymentAccountId.value
        : this.paymentAccountId,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    autoPost: autoPost ?? this.autoPost,
    notes: notes.present ? notes.value : this.notes,
    status: status ?? this.status,
    skippedMonthsJson: skippedMonthsJson ?? this.skippedMonthsJson,
    skippedDatesJson: skippedDatesJson ?? this.skippedDatesJson,
    amountOverridesJson: amountOverridesJson ?? this.amountOverridesJson,
  );
  ScheduledEventRow copyWithCompanion(ScheduledEventsCompanion data) {
    return ScheduledEventRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      direction: data.direction.present ? data.direction.value : this.direction,
      currencyCode: data.currencyCode.present
          ? data.currencyCode.value
          : this.currencyCode,
      cadence: data.cadence.present ? data.cadence.value : this.cadence,
      anchorDate: data.anchorDate.present
          ? data.anchorDate.value
          : this.anchorDate,
      amountMinor: data.amountMinor.present
          ? data.amountMinor.value
          : this.amountMinor,
      amountLowMinor: data.amountLowMinor.present
          ? data.amountLowMinor.value
          : this.amountLowMinor,
      amountHighMinor: data.amountHighMinor.present
          ? data.amountHighMinor.value
          : this.amountHighMinor,
      intervalValue: data.intervalValue.present
          ? data.intervalValue.value
          : this.intervalValue,
      monthEndPolicy: data.monthEndPolicy.present
          ? data.monthEndPolicy.value
          : this.monthEndPolicy,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
      paymentAccountId: data.paymentAccountId.present
          ? data.paymentAccountId.value
          : this.paymentAccountId,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      autoPost: data.autoPost.present ? data.autoPost.value : this.autoPost,
      notes: data.notes.present ? data.notes.value : this.notes,
      status: data.status.present ? data.status.value : this.status,
      skippedMonthsJson: data.skippedMonthsJson.present
          ? data.skippedMonthsJson.value
          : this.skippedMonthsJson,
      skippedDatesJson: data.skippedDatesJson.present
          ? data.skippedDatesJson.value
          : this.skippedDatesJson,
      amountOverridesJson: data.amountOverridesJson.present
          ? data.amountOverridesJson.value
          : this.amountOverridesJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ScheduledEventRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('direction: $direction, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('cadence: $cadence, ')
          ..write('anchorDate: $anchorDate, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('amountLowMinor: $amountLowMinor, ')
          ..write('amountHighMinor: $amountHighMinor, ')
          ..write('intervalValue: $intervalValue, ')
          ..write('monthEndPolicy: $monthEndPolicy, ')
          ..write('endDate: $endDate, ')
          ..write('paymentAccountId: $paymentAccountId, ')
          ..write('categoryId: $categoryId, ')
          ..write('autoPost: $autoPost, ')
          ..write('notes: $notes, ')
          ..write('status: $status, ')
          ..write('skippedMonthsJson: $skippedMonthsJson, ')
          ..write('skippedDatesJson: $skippedDatesJson, ')
          ..write('amountOverridesJson: $amountOverridesJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    direction,
    currencyCode,
    cadence,
    anchorDate,
    amountMinor,
    amountLowMinor,
    amountHighMinor,
    intervalValue,
    monthEndPolicy,
    endDate,
    paymentAccountId,
    categoryId,
    autoPost,
    notes,
    status,
    skippedMonthsJson,
    skippedDatesJson,
    amountOverridesJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ScheduledEventRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.direction == this.direction &&
          other.currencyCode == this.currencyCode &&
          other.cadence == this.cadence &&
          other.anchorDate == this.anchorDate &&
          other.amountMinor == this.amountMinor &&
          other.amountLowMinor == this.amountLowMinor &&
          other.amountHighMinor == this.amountHighMinor &&
          other.intervalValue == this.intervalValue &&
          other.monthEndPolicy == this.monthEndPolicy &&
          other.endDate == this.endDate &&
          other.paymentAccountId == this.paymentAccountId &&
          other.categoryId == this.categoryId &&
          other.autoPost == this.autoPost &&
          other.notes == this.notes &&
          other.status == this.status &&
          other.skippedMonthsJson == this.skippedMonthsJson &&
          other.skippedDatesJson == this.skippedDatesJson &&
          other.amountOverridesJson == this.amountOverridesJson);
}

class ScheduledEventsCompanion extends UpdateCompanion<ScheduledEventRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> direction;
  final Value<String> currencyCode;
  final Value<String> cadence;
  final Value<DateTime> anchorDate;
  final Value<BigInt?> amountMinor;
  final Value<BigInt?> amountLowMinor;
  final Value<BigInt?> amountHighMinor;
  final Value<int> intervalValue;
  final Value<String> monthEndPolicy;
  final Value<DateTime?> endDate;
  final Value<String?> paymentAccountId;
  final Value<String?> categoryId;
  final Value<bool> autoPost;
  final Value<String?> notes;
  final Value<String> status;
  final Value<String> skippedMonthsJson;
  final Value<String> skippedDatesJson;
  final Value<String> amountOverridesJson;
  final Value<int> rowid;
  const ScheduledEventsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.direction = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.cadence = const Value.absent(),
    this.anchorDate = const Value.absent(),
    this.amountMinor = const Value.absent(),
    this.amountLowMinor = const Value.absent(),
    this.amountHighMinor = const Value.absent(),
    this.intervalValue = const Value.absent(),
    this.monthEndPolicy = const Value.absent(),
    this.endDate = const Value.absent(),
    this.paymentAccountId = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.autoPost = const Value.absent(),
    this.notes = const Value.absent(),
    this.status = const Value.absent(),
    this.skippedMonthsJson = const Value.absent(),
    this.skippedDatesJson = const Value.absent(),
    this.amountOverridesJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ScheduledEventsCompanion.insert({
    required String id,
    required String name,
    required String direction,
    required String currencyCode,
    required String cadence,
    required DateTime anchorDate,
    this.amountMinor = const Value.absent(),
    this.amountLowMinor = const Value.absent(),
    this.amountHighMinor = const Value.absent(),
    this.intervalValue = const Value.absent(),
    this.monthEndPolicy = const Value.absent(),
    this.endDate = const Value.absent(),
    this.paymentAccountId = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.autoPost = const Value.absent(),
    this.notes = const Value.absent(),
    this.status = const Value.absent(),
    this.skippedMonthsJson = const Value.absent(),
    this.skippedDatesJson = const Value.absent(),
    this.amountOverridesJson = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       direction = Value(direction),
       currencyCode = Value(currencyCode),
       cadence = Value(cadence),
       anchorDate = Value(anchorDate);
  static Insertable<ScheduledEventRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? direction,
    Expression<String>? currencyCode,
    Expression<String>? cadence,
    Expression<DateTime>? anchorDate,
    Expression<String>? amountMinor,
    Expression<String>? amountLowMinor,
    Expression<String>? amountHighMinor,
    Expression<int>? intervalValue,
    Expression<String>? monthEndPolicy,
    Expression<DateTime>? endDate,
    Expression<String>? paymentAccountId,
    Expression<String>? categoryId,
    Expression<bool>? autoPost,
    Expression<String>? notes,
    Expression<String>? status,
    Expression<String>? skippedMonthsJson,
    Expression<String>? skippedDatesJson,
    Expression<String>? amountOverridesJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (direction != null) 'direction': direction,
      if (currencyCode != null) 'currency_code': currencyCode,
      if (cadence != null) 'cadence': cadence,
      if (anchorDate != null) 'anchor_date': anchorDate,
      if (amountMinor != null) 'amount_minor': amountMinor,
      if (amountLowMinor != null) 'amount_low_minor': amountLowMinor,
      if (amountHighMinor != null) 'amount_high_minor': amountHighMinor,
      if (intervalValue != null) 'interval_value': intervalValue,
      if (monthEndPolicy != null) 'month_end_policy': monthEndPolicy,
      if (endDate != null) 'end_date': endDate,
      if (paymentAccountId != null) 'payment_account_id': paymentAccountId,
      if (categoryId != null) 'category_id': categoryId,
      if (autoPost != null) 'auto_post': autoPost,
      if (notes != null) 'notes': notes,
      if (status != null) 'status': status,
      if (skippedMonthsJson != null) 'skipped_months_json': skippedMonthsJson,
      if (skippedDatesJson != null) 'skipped_dates_json': skippedDatesJson,
      if (amountOverridesJson != null)
        'amount_overrides_json': amountOverridesJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ScheduledEventsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? direction,
    Value<String>? currencyCode,
    Value<String>? cadence,
    Value<DateTime>? anchorDate,
    Value<BigInt?>? amountMinor,
    Value<BigInt?>? amountLowMinor,
    Value<BigInt?>? amountHighMinor,
    Value<int>? intervalValue,
    Value<String>? monthEndPolicy,
    Value<DateTime?>? endDate,
    Value<String?>? paymentAccountId,
    Value<String?>? categoryId,
    Value<bool>? autoPost,
    Value<String?>? notes,
    Value<String>? status,
    Value<String>? skippedMonthsJson,
    Value<String>? skippedDatesJson,
    Value<String>? amountOverridesJson,
    Value<int>? rowid,
  }) {
    return ScheduledEventsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      direction: direction ?? this.direction,
      currencyCode: currencyCode ?? this.currencyCode,
      cadence: cadence ?? this.cadence,
      anchorDate: anchorDate ?? this.anchorDate,
      amountMinor: amountMinor ?? this.amountMinor,
      amountLowMinor: amountLowMinor ?? this.amountLowMinor,
      amountHighMinor: amountHighMinor ?? this.amountHighMinor,
      intervalValue: intervalValue ?? this.intervalValue,
      monthEndPolicy: monthEndPolicy ?? this.monthEndPolicy,
      endDate: endDate ?? this.endDate,
      paymentAccountId: paymentAccountId ?? this.paymentAccountId,
      categoryId: categoryId ?? this.categoryId,
      autoPost: autoPost ?? this.autoPost,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      skippedMonthsJson: skippedMonthsJson ?? this.skippedMonthsJson,
      skippedDatesJson: skippedDatesJson ?? this.skippedDatesJson,
      amountOverridesJson: amountOverridesJson ?? this.amountOverridesJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (direction.present) {
      map['direction'] = Variable<String>(direction.value);
    }
    if (currencyCode.present) {
      map['currency_code'] = Variable<String>(currencyCode.value);
    }
    if (cadence.present) {
      map['cadence'] = Variable<String>(cadence.value);
    }
    if (anchorDate.present) {
      map['anchor_date'] = Variable<DateTime>(anchorDate.value);
    }
    if (amountMinor.present) {
      map['amount_minor'] = Variable<String>(
        $ScheduledEventsTable.$converteramountMinorn.toSql(amountMinor.value),
      );
    }
    if (amountLowMinor.present) {
      map['amount_low_minor'] = Variable<String>(
        $ScheduledEventsTable.$converteramountLowMinorn.toSql(
          amountLowMinor.value,
        ),
      );
    }
    if (amountHighMinor.present) {
      map['amount_high_minor'] = Variable<String>(
        $ScheduledEventsTable.$converteramountHighMinorn.toSql(
          amountHighMinor.value,
        ),
      );
    }
    if (intervalValue.present) {
      map['interval_value'] = Variable<int>(intervalValue.value);
    }
    if (monthEndPolicy.present) {
      map['month_end_policy'] = Variable<String>(monthEndPolicy.value);
    }
    if (endDate.present) {
      map['end_date'] = Variable<DateTime>(endDate.value);
    }
    if (paymentAccountId.present) {
      map['payment_account_id'] = Variable<String>(paymentAccountId.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (autoPost.present) {
      map['auto_post'] = Variable<bool>(autoPost.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (skippedMonthsJson.present) {
      map['skipped_months_json'] = Variable<String>(skippedMonthsJson.value);
    }
    if (skippedDatesJson.present) {
      map['skipped_dates_json'] = Variable<String>(skippedDatesJson.value);
    }
    if (amountOverridesJson.present) {
      map['amount_overrides_json'] = Variable<String>(
        amountOverridesJson.value,
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ScheduledEventsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('direction: $direction, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('cadence: $cadence, ')
          ..write('anchorDate: $anchorDate, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('amountLowMinor: $amountLowMinor, ')
          ..write('amountHighMinor: $amountHighMinor, ')
          ..write('intervalValue: $intervalValue, ')
          ..write('monthEndPolicy: $monthEndPolicy, ')
          ..write('endDate: $endDate, ')
          ..write('paymentAccountId: $paymentAccountId, ')
          ..write('categoryId: $categoryId, ')
          ..write('autoPost: $autoPost, ')
          ..write('notes: $notes, ')
          ..write('status: $status, ')
          ..write('skippedMonthsJson: $skippedMonthsJson, ')
          ..write('skippedDatesJson: $skippedDatesJson, ')
          ..write('amountOverridesJson: $amountOverridesJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GoalsTable extends Goals with TableInfo<$GoalsTable, GoalRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GoalsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<BigInt, String> targetMinor =
      GeneratedColumn<String>(
        'target_minor',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<BigInt>($GoalsTable.$convertertargetMinor);
  static const VerificationMeta _targetDateMeta = const VerificationMeta(
    'targetDate',
  );
  @override
  late final GeneratedColumn<DateTime> targetDate = GeneratedColumn<DateTime>(
    'target_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _priorityMeta = const VerificationMeta(
    'priority',
  );
  @override
  late final GeneratedColumn<int> priority = GeneratedColumn<int>(
    'priority',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  late final GeneratedColumnWithTypeConverter<BigInt, String> reservedMinor =
      GeneratedColumn<String>(
        'reserved_minor',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('0'),
      ).withConverter<BigInt>($GoalsTable.$converterreservedMinor);
  static const VerificationMeta _fundingAccountIdsJsonMeta =
      const VerificationMeta('fundingAccountIdsJson');
  @override
  late final GeneratedColumn<String> fundingAccountIdsJson =
      GeneratedColumn<String>(
        'funding_account_ids_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('[]'),
      );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('active'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    targetMinor,
    targetDate,
    priority,
    reservedMinor,
    fundingAccountIdsJson,
    notes,
    status,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'goals';
  @override
  VerificationContext validateIntegrity(
    Insertable<GoalRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('target_date')) {
      context.handle(
        _targetDateMeta,
        targetDate.isAcceptableOrUnknown(data['target_date']!, _targetDateMeta),
      );
    } else if (isInserting) {
      context.missing(_targetDateMeta);
    }
    if (data.containsKey('priority')) {
      context.handle(
        _priorityMeta,
        priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta),
      );
    }
    if (data.containsKey('funding_account_ids_json')) {
      context.handle(
        _fundingAccountIdsJsonMeta,
        fundingAccountIdsJson.isAcceptableOrUnknown(
          data['funding_account_ids_json']!,
          _fundingAccountIdsJsonMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GoalRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GoalRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      targetMinor: $GoalsTable.$convertertargetMinor.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}target_minor'],
        )!,
      ),
      targetDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}target_date'],
      )!,
      priority: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}priority'],
      )!,
      reservedMinor: $GoalsTable.$converterreservedMinor.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}reserved_minor'],
        )!,
      ),
      fundingAccountIdsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}funding_account_ids_json'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
    );
  }

  @override
  $GoalsTable createAlias(String alias) {
    return $GoalsTable(attachedDatabase, alias);
  }

  static TypeConverter<BigInt, String> $convertertargetMinor =
      const BigIntText();
  static TypeConverter<BigInt, String> $converterreservedMinor =
      const BigIntText();
}

class GoalRow extends DataClass implements Insertable<GoalRow> {
  final String id;
  final String name;
  final BigInt targetMinor;
  final DateTime targetDate;
  final int priority;
  final BigInt reservedMinor;
  final String fundingAccountIdsJson;
  final String? notes;
  final String status;
  const GoalRow({
    required this.id,
    required this.name,
    required this.targetMinor,
    required this.targetDate,
    required this.priority,
    required this.reservedMinor,
    required this.fundingAccountIdsJson,
    this.notes,
    required this.status,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    {
      map['target_minor'] = Variable<String>(
        $GoalsTable.$convertertargetMinor.toSql(targetMinor),
      );
    }
    map['target_date'] = Variable<DateTime>(targetDate);
    map['priority'] = Variable<int>(priority);
    {
      map['reserved_minor'] = Variable<String>(
        $GoalsTable.$converterreservedMinor.toSql(reservedMinor),
      );
    }
    map['funding_account_ids_json'] = Variable<String>(fundingAccountIdsJson);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['status'] = Variable<String>(status);
    return map;
  }

  GoalsCompanion toCompanion(bool nullToAbsent) {
    return GoalsCompanion(
      id: Value(id),
      name: Value(name),
      targetMinor: Value(targetMinor),
      targetDate: Value(targetDate),
      priority: Value(priority),
      reservedMinor: Value(reservedMinor),
      fundingAccountIdsJson: Value(fundingAccountIdsJson),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      status: Value(status),
    );
  }

  factory GoalRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GoalRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      targetMinor: serializer.fromJson<BigInt>(json['targetMinor']),
      targetDate: serializer.fromJson<DateTime>(json['targetDate']),
      priority: serializer.fromJson<int>(json['priority']),
      reservedMinor: serializer.fromJson<BigInt>(json['reservedMinor']),
      fundingAccountIdsJson: serializer.fromJson<String>(
        json['fundingAccountIdsJson'],
      ),
      notes: serializer.fromJson<String?>(json['notes']),
      status: serializer.fromJson<String>(json['status']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'targetMinor': serializer.toJson<BigInt>(targetMinor),
      'targetDate': serializer.toJson<DateTime>(targetDate),
      'priority': serializer.toJson<int>(priority),
      'reservedMinor': serializer.toJson<BigInt>(reservedMinor),
      'fundingAccountIdsJson': serializer.toJson<String>(fundingAccountIdsJson),
      'notes': serializer.toJson<String?>(notes),
      'status': serializer.toJson<String>(status),
    };
  }

  GoalRow copyWith({
    String? id,
    String? name,
    BigInt? targetMinor,
    DateTime? targetDate,
    int? priority,
    BigInt? reservedMinor,
    String? fundingAccountIdsJson,
    Value<String?> notes = const Value.absent(),
    String? status,
  }) => GoalRow(
    id: id ?? this.id,
    name: name ?? this.name,
    targetMinor: targetMinor ?? this.targetMinor,
    targetDate: targetDate ?? this.targetDate,
    priority: priority ?? this.priority,
    reservedMinor: reservedMinor ?? this.reservedMinor,
    fundingAccountIdsJson: fundingAccountIdsJson ?? this.fundingAccountIdsJson,
    notes: notes.present ? notes.value : this.notes,
    status: status ?? this.status,
  );
  GoalRow copyWithCompanion(GoalsCompanion data) {
    return GoalRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      targetMinor: data.targetMinor.present
          ? data.targetMinor.value
          : this.targetMinor,
      targetDate: data.targetDate.present
          ? data.targetDate.value
          : this.targetDate,
      priority: data.priority.present ? data.priority.value : this.priority,
      reservedMinor: data.reservedMinor.present
          ? data.reservedMinor.value
          : this.reservedMinor,
      fundingAccountIdsJson: data.fundingAccountIdsJson.present
          ? data.fundingAccountIdsJson.value
          : this.fundingAccountIdsJson,
      notes: data.notes.present ? data.notes.value : this.notes,
      status: data.status.present ? data.status.value : this.status,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GoalRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('targetMinor: $targetMinor, ')
          ..write('targetDate: $targetDate, ')
          ..write('priority: $priority, ')
          ..write('reservedMinor: $reservedMinor, ')
          ..write('fundingAccountIdsJson: $fundingAccountIdsJson, ')
          ..write('notes: $notes, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    targetMinor,
    targetDate,
    priority,
    reservedMinor,
    fundingAccountIdsJson,
    notes,
    status,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GoalRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.targetMinor == this.targetMinor &&
          other.targetDate == this.targetDate &&
          other.priority == this.priority &&
          other.reservedMinor == this.reservedMinor &&
          other.fundingAccountIdsJson == this.fundingAccountIdsJson &&
          other.notes == this.notes &&
          other.status == this.status);
}

class GoalsCompanion extends UpdateCompanion<GoalRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<BigInt> targetMinor;
  final Value<DateTime> targetDate;
  final Value<int> priority;
  final Value<BigInt> reservedMinor;
  final Value<String> fundingAccountIdsJson;
  final Value<String?> notes;
  final Value<String> status;
  final Value<int> rowid;
  const GoalsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.targetMinor = const Value.absent(),
    this.targetDate = const Value.absent(),
    this.priority = const Value.absent(),
    this.reservedMinor = const Value.absent(),
    this.fundingAccountIdsJson = const Value.absent(),
    this.notes = const Value.absent(),
    this.status = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GoalsCompanion.insert({
    required String id,
    required String name,
    required BigInt targetMinor,
    required DateTime targetDate,
    this.priority = const Value.absent(),
    this.reservedMinor = const Value.absent(),
    this.fundingAccountIdsJson = const Value.absent(),
    this.notes = const Value.absent(),
    this.status = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       targetMinor = Value(targetMinor),
       targetDate = Value(targetDate);
  static Insertable<GoalRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? targetMinor,
    Expression<DateTime>? targetDate,
    Expression<int>? priority,
    Expression<String>? reservedMinor,
    Expression<String>? fundingAccountIdsJson,
    Expression<String>? notes,
    Expression<String>? status,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (targetMinor != null) 'target_minor': targetMinor,
      if (targetDate != null) 'target_date': targetDate,
      if (priority != null) 'priority': priority,
      if (reservedMinor != null) 'reserved_minor': reservedMinor,
      if (fundingAccountIdsJson != null)
        'funding_account_ids_json': fundingAccountIdsJson,
      if (notes != null) 'notes': notes,
      if (status != null) 'status': status,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GoalsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<BigInt>? targetMinor,
    Value<DateTime>? targetDate,
    Value<int>? priority,
    Value<BigInt>? reservedMinor,
    Value<String>? fundingAccountIdsJson,
    Value<String?>? notes,
    Value<String>? status,
    Value<int>? rowid,
  }) {
    return GoalsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      targetMinor: targetMinor ?? this.targetMinor,
      targetDate: targetDate ?? this.targetDate,
      priority: priority ?? this.priority,
      reservedMinor: reservedMinor ?? this.reservedMinor,
      fundingAccountIdsJson:
          fundingAccountIdsJson ?? this.fundingAccountIdsJson,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (targetMinor.present) {
      map['target_minor'] = Variable<String>(
        $GoalsTable.$convertertargetMinor.toSql(targetMinor.value),
      );
    }
    if (targetDate.present) {
      map['target_date'] = Variable<DateTime>(targetDate.value);
    }
    if (priority.present) {
      map['priority'] = Variable<int>(priority.value);
    }
    if (reservedMinor.present) {
      map['reserved_minor'] = Variable<String>(
        $GoalsTable.$converterreservedMinor.toSql(reservedMinor.value),
      );
    }
    if (fundingAccountIdsJson.present) {
      map['funding_account_ids_json'] = Variable<String>(
        fundingAccountIdsJson.value,
      );
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GoalsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('targetMinor: $targetMinor, ')
          ..write('targetDate: $targetDate, ')
          ..write('priority: $priority, ')
          ..write('reservedMinor: $reservedMinor, ')
          ..write('fundingAccountIdsJson: $fundingAccountIdsJson, ')
          ..write('notes: $notes, ')
          ..write('status: $status, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DebtContractsTable extends DebtContracts
    with TableInfo<$DebtContractsTable, DebtContractRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DebtContractsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _liabilityAccountIdMeta =
      const VerificationMeta('liabilityAccountId');
  @override
  late final GeneratedColumn<String> liabilityAccountId =
      GeneratedColumn<String>(
        'liability_account_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  @override
  late final GeneratedColumnWithTypeConverter<BigInt, String>
  principalOriginalMinor = GeneratedColumn<String>(
    'principal_original_minor',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<BigInt>($DebtContractsTable.$converterprincipalOriginalMinor);
  static const VerificationMeta _aprPercentMeta = const VerificationMeta(
    'aprPercent',
  );
  @override
  late final GeneratedColumn<String> aprPercent = GeneratedColumn<String>(
    'apr_percent',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _methodMeta = const VerificationMeta('method');
  @override
  late final GeneratedColumn<String> method = GeneratedColumn<String>(
    'method',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _termMonthsMeta = const VerificationMeta(
    'termMonths',
  );
  @override
  late final GeneratedColumn<int> termMonths = GeneratedColumn<int>(
    'term_months',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  @override
  late final GeneratedColumn<DateTime> startDate = GeneratedColumn<DateTime>(
    'start_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _firstPaymentDateMeta = const VerificationMeta(
    'firstPaymentDate',
  );
  @override
  late final GeneratedColumn<DateTime> firstPaymentDate =
      GeneratedColumn<DateTime>(
        'first_payment_date',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _repaymentDayMeta = const VerificationMeta(
    'repaymentDay',
  );
  @override
  late final GeneratedColumn<int> repaymentDay = GeneratedColumn<int>(
    'repayment_day',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<BigInt?, String> monthlyFeeMinor =
      GeneratedColumn<String>(
        'monthly_fee_minor',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<BigInt?>($DebtContractsTable.$convertermonthlyFeeMinorn);
  static const VerificationMeta _basisMeta = const VerificationMeta('basis');
  @override
  late final GeneratedColumn<String> basis = GeneratedColumn<String>(
    'basis',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('monthlyRate'),
  );
  static const VerificationMeta _prepayFeePercentMeta = const VerificationMeta(
    'prepayFeePercent',
  );
  @override
  late final GeneratedColumn<String> prepayFeePercent = GeneratedColumn<String>(
    'prepay_fee_percent',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _scheduleCacheJsonMeta = const VerificationMeta(
    'scheduleCacheJson',
  );
  @override
  late final GeneratedColumn<String> scheduleCacheJson =
      GeneratedColumn<String>(
        'schedule_cache_json',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    liabilityAccountId,
    principalOriginalMinor,
    aprPercent,
    method,
    termMonths,
    startDate,
    firstPaymentDate,
    repaymentDay,
    monthlyFeeMinor,
    basis,
    prepayFeePercent,
    scheduleCacheJson,
    notes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'debt_contracts';
  @override
  VerificationContext validateIntegrity(
    Insertable<DebtContractRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('liability_account_id')) {
      context.handle(
        _liabilityAccountIdMeta,
        liabilityAccountId.isAcceptableOrUnknown(
          data['liability_account_id']!,
          _liabilityAccountIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_liabilityAccountIdMeta);
    }
    if (data.containsKey('apr_percent')) {
      context.handle(
        _aprPercentMeta,
        aprPercent.isAcceptableOrUnknown(data['apr_percent']!, _aprPercentMeta),
      );
    } else if (isInserting) {
      context.missing(_aprPercentMeta);
    }
    if (data.containsKey('method')) {
      context.handle(
        _methodMeta,
        method.isAcceptableOrUnknown(data['method']!, _methodMeta),
      );
    } else if (isInserting) {
      context.missing(_methodMeta);
    }
    if (data.containsKey('term_months')) {
      context.handle(
        _termMonthsMeta,
        termMonths.isAcceptableOrUnknown(data['term_months']!, _termMonthsMeta),
      );
    } else if (isInserting) {
      context.missing(_termMonthsMeta);
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('first_payment_date')) {
      context.handle(
        _firstPaymentDateMeta,
        firstPaymentDate.isAcceptableOrUnknown(
          data['first_payment_date']!,
          _firstPaymentDateMeta,
        ),
      );
    }
    if (data.containsKey('repayment_day')) {
      context.handle(
        _repaymentDayMeta,
        repaymentDay.isAcceptableOrUnknown(
          data['repayment_day']!,
          _repaymentDayMeta,
        ),
      );
    }
    if (data.containsKey('basis')) {
      context.handle(
        _basisMeta,
        basis.isAcceptableOrUnknown(data['basis']!, _basisMeta),
      );
    }
    if (data.containsKey('prepay_fee_percent')) {
      context.handle(
        _prepayFeePercentMeta,
        prepayFeePercent.isAcceptableOrUnknown(
          data['prepay_fee_percent']!,
          _prepayFeePercentMeta,
        ),
      );
    }
    if (data.containsKey('schedule_cache_json')) {
      context.handle(
        _scheduleCacheJsonMeta,
        scheduleCacheJson.isAcceptableOrUnknown(
          data['schedule_cache_json']!,
          _scheduleCacheJsonMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {liabilityAccountId};
  @override
  DebtContractRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DebtContractRow(
      liabilityAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}liability_account_id'],
      )!,
      principalOriginalMinor: $DebtContractsTable
          .$converterprincipalOriginalMinor
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.string,
              data['${effectivePrefix}principal_original_minor'],
            )!,
          ),
      aprPercent: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}apr_percent'],
      )!,
      method: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}method'],
      )!,
      termMonths: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}term_months'],
      )!,
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start_date'],
      )!,
      firstPaymentDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}first_payment_date'],
      ),
      repaymentDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}repayment_day'],
      ),
      monthlyFeeMinor: $DebtContractsTable.$convertermonthlyFeeMinorn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}monthly_fee_minor'],
        ),
      ),
      basis: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}basis'],
      )!,
      prepayFeePercent: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}prepay_fee_percent'],
      ),
      scheduleCacheJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}schedule_cache_json'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
    );
  }

  @override
  $DebtContractsTable createAlias(String alias) {
    return $DebtContractsTable(attachedDatabase, alias);
  }

  static TypeConverter<BigInt, String> $converterprincipalOriginalMinor =
      const BigIntText();
  static TypeConverter<BigInt, String> $convertermonthlyFeeMinor =
      const BigIntText();
  static TypeConverter<BigInt?, String?> $convertermonthlyFeeMinorn =
      NullAwareTypeConverter.wrap($convertermonthlyFeeMinor);
}

class DebtContractRow extends DataClass implements Insertable<DebtContractRow> {
  final String liabilityAccountId;
  final BigInt principalOriginalMinor;

  /// 名义年利率（十进制字符串，如 "3.85" 表示 3.85%）。
  final String aprPercent;
  final String method;
  final int termMonths;
  final DateTime startDate;
  final DateTime? firstPaymentDate;
  final int? repaymentDay;
  final BigInt? monthlyFeeMinor;
  final String basis;
  final String? prepayFeePercent;
  final String? scheduleCacheJson;
  final String? notes;
  const DebtContractRow({
    required this.liabilityAccountId,
    required this.principalOriginalMinor,
    required this.aprPercent,
    required this.method,
    required this.termMonths,
    required this.startDate,
    this.firstPaymentDate,
    this.repaymentDay,
    this.monthlyFeeMinor,
    required this.basis,
    this.prepayFeePercent,
    this.scheduleCacheJson,
    this.notes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['liability_account_id'] = Variable<String>(liabilityAccountId);
    {
      map['principal_original_minor'] = Variable<String>(
        $DebtContractsTable.$converterprincipalOriginalMinor.toSql(
          principalOriginalMinor,
        ),
      );
    }
    map['apr_percent'] = Variable<String>(aprPercent);
    map['method'] = Variable<String>(method);
    map['term_months'] = Variable<int>(termMonths);
    map['start_date'] = Variable<DateTime>(startDate);
    if (!nullToAbsent || firstPaymentDate != null) {
      map['first_payment_date'] = Variable<DateTime>(firstPaymentDate);
    }
    if (!nullToAbsent || repaymentDay != null) {
      map['repayment_day'] = Variable<int>(repaymentDay);
    }
    if (!nullToAbsent || monthlyFeeMinor != null) {
      map['monthly_fee_minor'] = Variable<String>(
        $DebtContractsTable.$convertermonthlyFeeMinorn.toSql(monthlyFeeMinor),
      );
    }
    map['basis'] = Variable<String>(basis);
    if (!nullToAbsent || prepayFeePercent != null) {
      map['prepay_fee_percent'] = Variable<String>(prepayFeePercent);
    }
    if (!nullToAbsent || scheduleCacheJson != null) {
      map['schedule_cache_json'] = Variable<String>(scheduleCacheJson);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    return map;
  }

  DebtContractsCompanion toCompanion(bool nullToAbsent) {
    return DebtContractsCompanion(
      liabilityAccountId: Value(liabilityAccountId),
      principalOriginalMinor: Value(principalOriginalMinor),
      aprPercent: Value(aprPercent),
      method: Value(method),
      termMonths: Value(termMonths),
      startDate: Value(startDate),
      firstPaymentDate: firstPaymentDate == null && nullToAbsent
          ? const Value.absent()
          : Value(firstPaymentDate),
      repaymentDay: repaymentDay == null && nullToAbsent
          ? const Value.absent()
          : Value(repaymentDay),
      monthlyFeeMinor: monthlyFeeMinor == null && nullToAbsent
          ? const Value.absent()
          : Value(monthlyFeeMinor),
      basis: Value(basis),
      prepayFeePercent: prepayFeePercent == null && nullToAbsent
          ? const Value.absent()
          : Value(prepayFeePercent),
      scheduleCacheJson: scheduleCacheJson == null && nullToAbsent
          ? const Value.absent()
          : Value(scheduleCacheJson),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
    );
  }

  factory DebtContractRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DebtContractRow(
      liabilityAccountId: serializer.fromJson<String>(
        json['liabilityAccountId'],
      ),
      principalOriginalMinor: serializer.fromJson<BigInt>(
        json['principalOriginalMinor'],
      ),
      aprPercent: serializer.fromJson<String>(json['aprPercent']),
      method: serializer.fromJson<String>(json['method']),
      termMonths: serializer.fromJson<int>(json['termMonths']),
      startDate: serializer.fromJson<DateTime>(json['startDate']),
      firstPaymentDate: serializer.fromJson<DateTime?>(
        json['firstPaymentDate'],
      ),
      repaymentDay: serializer.fromJson<int?>(json['repaymentDay']),
      monthlyFeeMinor: serializer.fromJson<BigInt?>(json['monthlyFeeMinor']),
      basis: serializer.fromJson<String>(json['basis']),
      prepayFeePercent: serializer.fromJson<String?>(json['prepayFeePercent']),
      scheduleCacheJson: serializer.fromJson<String?>(
        json['scheduleCacheJson'],
      ),
      notes: serializer.fromJson<String?>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'liabilityAccountId': serializer.toJson<String>(liabilityAccountId),
      'principalOriginalMinor': serializer.toJson<BigInt>(
        principalOriginalMinor,
      ),
      'aprPercent': serializer.toJson<String>(aprPercent),
      'method': serializer.toJson<String>(method),
      'termMonths': serializer.toJson<int>(termMonths),
      'startDate': serializer.toJson<DateTime>(startDate),
      'firstPaymentDate': serializer.toJson<DateTime?>(firstPaymentDate),
      'repaymentDay': serializer.toJson<int?>(repaymentDay),
      'monthlyFeeMinor': serializer.toJson<BigInt?>(monthlyFeeMinor),
      'basis': serializer.toJson<String>(basis),
      'prepayFeePercent': serializer.toJson<String?>(prepayFeePercent),
      'scheduleCacheJson': serializer.toJson<String?>(scheduleCacheJson),
      'notes': serializer.toJson<String?>(notes),
    };
  }

  DebtContractRow copyWith({
    String? liabilityAccountId,
    BigInt? principalOriginalMinor,
    String? aprPercent,
    String? method,
    int? termMonths,
    DateTime? startDate,
    Value<DateTime?> firstPaymentDate = const Value.absent(),
    Value<int?> repaymentDay = const Value.absent(),
    Value<BigInt?> monthlyFeeMinor = const Value.absent(),
    String? basis,
    Value<String?> prepayFeePercent = const Value.absent(),
    Value<String?> scheduleCacheJson = const Value.absent(),
    Value<String?> notes = const Value.absent(),
  }) => DebtContractRow(
    liabilityAccountId: liabilityAccountId ?? this.liabilityAccountId,
    principalOriginalMinor:
        principalOriginalMinor ?? this.principalOriginalMinor,
    aprPercent: aprPercent ?? this.aprPercent,
    method: method ?? this.method,
    termMonths: termMonths ?? this.termMonths,
    startDate: startDate ?? this.startDate,
    firstPaymentDate: firstPaymentDate.present
        ? firstPaymentDate.value
        : this.firstPaymentDate,
    repaymentDay: repaymentDay.present ? repaymentDay.value : this.repaymentDay,
    monthlyFeeMinor: monthlyFeeMinor.present
        ? monthlyFeeMinor.value
        : this.monthlyFeeMinor,
    basis: basis ?? this.basis,
    prepayFeePercent: prepayFeePercent.present
        ? prepayFeePercent.value
        : this.prepayFeePercent,
    scheduleCacheJson: scheduleCacheJson.present
        ? scheduleCacheJson.value
        : this.scheduleCacheJson,
    notes: notes.present ? notes.value : this.notes,
  );
  DebtContractRow copyWithCompanion(DebtContractsCompanion data) {
    return DebtContractRow(
      liabilityAccountId: data.liabilityAccountId.present
          ? data.liabilityAccountId.value
          : this.liabilityAccountId,
      principalOriginalMinor: data.principalOriginalMinor.present
          ? data.principalOriginalMinor.value
          : this.principalOriginalMinor,
      aprPercent: data.aprPercent.present
          ? data.aprPercent.value
          : this.aprPercent,
      method: data.method.present ? data.method.value : this.method,
      termMonths: data.termMonths.present
          ? data.termMonths.value
          : this.termMonths,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      firstPaymentDate: data.firstPaymentDate.present
          ? data.firstPaymentDate.value
          : this.firstPaymentDate,
      repaymentDay: data.repaymentDay.present
          ? data.repaymentDay.value
          : this.repaymentDay,
      monthlyFeeMinor: data.monthlyFeeMinor.present
          ? data.monthlyFeeMinor.value
          : this.monthlyFeeMinor,
      basis: data.basis.present ? data.basis.value : this.basis,
      prepayFeePercent: data.prepayFeePercent.present
          ? data.prepayFeePercent.value
          : this.prepayFeePercent,
      scheduleCacheJson: data.scheduleCacheJson.present
          ? data.scheduleCacheJson.value
          : this.scheduleCacheJson,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DebtContractRow(')
          ..write('liabilityAccountId: $liabilityAccountId, ')
          ..write('principalOriginalMinor: $principalOriginalMinor, ')
          ..write('aprPercent: $aprPercent, ')
          ..write('method: $method, ')
          ..write('termMonths: $termMonths, ')
          ..write('startDate: $startDate, ')
          ..write('firstPaymentDate: $firstPaymentDate, ')
          ..write('repaymentDay: $repaymentDay, ')
          ..write('monthlyFeeMinor: $monthlyFeeMinor, ')
          ..write('basis: $basis, ')
          ..write('prepayFeePercent: $prepayFeePercent, ')
          ..write('scheduleCacheJson: $scheduleCacheJson, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    liabilityAccountId,
    principalOriginalMinor,
    aprPercent,
    method,
    termMonths,
    startDate,
    firstPaymentDate,
    repaymentDay,
    monthlyFeeMinor,
    basis,
    prepayFeePercent,
    scheduleCacheJson,
    notes,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DebtContractRow &&
          other.liabilityAccountId == this.liabilityAccountId &&
          other.principalOriginalMinor == this.principalOriginalMinor &&
          other.aprPercent == this.aprPercent &&
          other.method == this.method &&
          other.termMonths == this.termMonths &&
          other.startDate == this.startDate &&
          other.firstPaymentDate == this.firstPaymentDate &&
          other.repaymentDay == this.repaymentDay &&
          other.monthlyFeeMinor == this.monthlyFeeMinor &&
          other.basis == this.basis &&
          other.prepayFeePercent == this.prepayFeePercent &&
          other.scheduleCacheJson == this.scheduleCacheJson &&
          other.notes == this.notes);
}

class DebtContractsCompanion extends UpdateCompanion<DebtContractRow> {
  final Value<String> liabilityAccountId;
  final Value<BigInt> principalOriginalMinor;
  final Value<String> aprPercent;
  final Value<String> method;
  final Value<int> termMonths;
  final Value<DateTime> startDate;
  final Value<DateTime?> firstPaymentDate;
  final Value<int?> repaymentDay;
  final Value<BigInt?> monthlyFeeMinor;
  final Value<String> basis;
  final Value<String?> prepayFeePercent;
  final Value<String?> scheduleCacheJson;
  final Value<String?> notes;
  final Value<int> rowid;
  const DebtContractsCompanion({
    this.liabilityAccountId = const Value.absent(),
    this.principalOriginalMinor = const Value.absent(),
    this.aprPercent = const Value.absent(),
    this.method = const Value.absent(),
    this.termMonths = const Value.absent(),
    this.startDate = const Value.absent(),
    this.firstPaymentDate = const Value.absent(),
    this.repaymentDay = const Value.absent(),
    this.monthlyFeeMinor = const Value.absent(),
    this.basis = const Value.absent(),
    this.prepayFeePercent = const Value.absent(),
    this.scheduleCacheJson = const Value.absent(),
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DebtContractsCompanion.insert({
    required String liabilityAccountId,
    required BigInt principalOriginalMinor,
    required String aprPercent,
    required String method,
    required int termMonths,
    required DateTime startDate,
    this.firstPaymentDate = const Value.absent(),
    this.repaymentDay = const Value.absent(),
    this.monthlyFeeMinor = const Value.absent(),
    this.basis = const Value.absent(),
    this.prepayFeePercent = const Value.absent(),
    this.scheduleCacheJson = const Value.absent(),
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : liabilityAccountId = Value(liabilityAccountId),
       principalOriginalMinor = Value(principalOriginalMinor),
       aprPercent = Value(aprPercent),
       method = Value(method),
       termMonths = Value(termMonths),
       startDate = Value(startDate);
  static Insertable<DebtContractRow> custom({
    Expression<String>? liabilityAccountId,
    Expression<String>? principalOriginalMinor,
    Expression<String>? aprPercent,
    Expression<String>? method,
    Expression<int>? termMonths,
    Expression<DateTime>? startDate,
    Expression<DateTime>? firstPaymentDate,
    Expression<int>? repaymentDay,
    Expression<String>? monthlyFeeMinor,
    Expression<String>? basis,
    Expression<String>? prepayFeePercent,
    Expression<String>? scheduleCacheJson,
    Expression<String>? notes,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (liabilityAccountId != null)
        'liability_account_id': liabilityAccountId,
      if (principalOriginalMinor != null)
        'principal_original_minor': principalOriginalMinor,
      if (aprPercent != null) 'apr_percent': aprPercent,
      if (method != null) 'method': method,
      if (termMonths != null) 'term_months': termMonths,
      if (startDate != null) 'start_date': startDate,
      if (firstPaymentDate != null) 'first_payment_date': firstPaymentDate,
      if (repaymentDay != null) 'repayment_day': repaymentDay,
      if (monthlyFeeMinor != null) 'monthly_fee_minor': monthlyFeeMinor,
      if (basis != null) 'basis': basis,
      if (prepayFeePercent != null) 'prepay_fee_percent': prepayFeePercent,
      if (scheduleCacheJson != null) 'schedule_cache_json': scheduleCacheJson,
      if (notes != null) 'notes': notes,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DebtContractsCompanion copyWith({
    Value<String>? liabilityAccountId,
    Value<BigInt>? principalOriginalMinor,
    Value<String>? aprPercent,
    Value<String>? method,
    Value<int>? termMonths,
    Value<DateTime>? startDate,
    Value<DateTime?>? firstPaymentDate,
    Value<int?>? repaymentDay,
    Value<BigInt?>? monthlyFeeMinor,
    Value<String>? basis,
    Value<String?>? prepayFeePercent,
    Value<String?>? scheduleCacheJson,
    Value<String?>? notes,
    Value<int>? rowid,
  }) {
    return DebtContractsCompanion(
      liabilityAccountId: liabilityAccountId ?? this.liabilityAccountId,
      principalOriginalMinor:
          principalOriginalMinor ?? this.principalOriginalMinor,
      aprPercent: aprPercent ?? this.aprPercent,
      method: method ?? this.method,
      termMonths: termMonths ?? this.termMonths,
      startDate: startDate ?? this.startDate,
      firstPaymentDate: firstPaymentDate ?? this.firstPaymentDate,
      repaymentDay: repaymentDay ?? this.repaymentDay,
      monthlyFeeMinor: monthlyFeeMinor ?? this.monthlyFeeMinor,
      basis: basis ?? this.basis,
      prepayFeePercent: prepayFeePercent ?? this.prepayFeePercent,
      scheduleCacheJson: scheduleCacheJson ?? this.scheduleCacheJson,
      notes: notes ?? this.notes,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (liabilityAccountId.present) {
      map['liability_account_id'] = Variable<String>(liabilityAccountId.value);
    }
    if (principalOriginalMinor.present) {
      map['principal_original_minor'] = Variable<String>(
        $DebtContractsTable.$converterprincipalOriginalMinor.toSql(
          principalOriginalMinor.value,
        ),
      );
    }
    if (aprPercent.present) {
      map['apr_percent'] = Variable<String>(aprPercent.value);
    }
    if (method.present) {
      map['method'] = Variable<String>(method.value);
    }
    if (termMonths.present) {
      map['term_months'] = Variable<int>(termMonths.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<DateTime>(startDate.value);
    }
    if (firstPaymentDate.present) {
      map['first_payment_date'] = Variable<DateTime>(firstPaymentDate.value);
    }
    if (repaymentDay.present) {
      map['repayment_day'] = Variable<int>(repaymentDay.value);
    }
    if (monthlyFeeMinor.present) {
      map['monthly_fee_minor'] = Variable<String>(
        $DebtContractsTable.$convertermonthlyFeeMinorn.toSql(
          monthlyFeeMinor.value,
        ),
      );
    }
    if (basis.present) {
      map['basis'] = Variable<String>(basis.value);
    }
    if (prepayFeePercent.present) {
      map['prepay_fee_percent'] = Variable<String>(prepayFeePercent.value);
    }
    if (scheduleCacheJson.present) {
      map['schedule_cache_json'] = Variable<String>(scheduleCacheJson.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DebtContractsCompanion(')
          ..write('liabilityAccountId: $liabilityAccountId, ')
          ..write('principalOriginalMinor: $principalOriginalMinor, ')
          ..write('aprPercent: $aprPercent, ')
          ..write('method: $method, ')
          ..write('termMonths: $termMonths, ')
          ..write('startDate: $startDate, ')
          ..write('firstPaymentDate: $firstPaymentDate, ')
          ..write('repaymentDay: $repaymentDay, ')
          ..write('monthlyFeeMinor: $monthlyFeeMinor, ')
          ..write('basis: $basis, ')
          ..write('prepayFeePercent: $prepayFeePercent, ')
          ..write('scheduleCacheJson: $scheduleCacheJson, ')
          ..write('notes: $notes, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ValuationsTable extends Valuations
    with TableInfo<$ValuationsTable, ValuationRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ValuationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<BigInt?, String> unitPriceN =
      GeneratedColumn<String>(
        'unit_price_n',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<BigInt?>($ValuationsTable.$converterunitPriceNn);
  @override
  late final GeneratedColumnWithTypeConverter<BigInt?, String> unitPriceD =
      GeneratedColumn<String>(
        'unit_price_d',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<BigInt?>($ValuationsTable.$converterunitPriceDn);
  @override
  late final GeneratedColumnWithTypeConverter<BigInt?, String> totalValueMinor =
      GeneratedColumn<String>(
        'total_value_minor',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<BigInt?>($ValuationsTable.$convertertotalValueMinorn);
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('manual'),
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    accountId,
    date,
    kind,
    unitPriceN,
    unitPriceD,
    totalValueMinor,
    source,
    note,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'valuations';
  @override
  VerificationContext validateIntegrity(
    Insertable<ValuationRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ValuationRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ValuationRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      unitPriceN: $ValuationsTable.$converterunitPriceNn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}unit_price_n'],
        ),
      ),
      unitPriceD: $ValuationsTable.$converterunitPriceDn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}unit_price_d'],
        ),
      ),
      totalValueMinor: $ValuationsTable.$convertertotalValueMinorn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}total_value_minor'],
        ),
      ),
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
    );
  }

  @override
  $ValuationsTable createAlias(String alias) {
    return $ValuationsTable(attachedDatabase, alias);
  }

  static TypeConverter<BigInt, String> $converterunitPriceN =
      const BigIntText();
  static TypeConverter<BigInt?, String?> $converterunitPriceNn =
      NullAwareTypeConverter.wrap($converterunitPriceN);
  static TypeConverter<BigInt, String> $converterunitPriceD =
      const BigIntText();
  static TypeConverter<BigInt?, String?> $converterunitPriceDn =
      NullAwareTypeConverter.wrap($converterunitPriceD);
  static TypeConverter<BigInt, String> $convertertotalValueMinor =
      const BigIntText();
  static TypeConverter<BigInt?, String?> $convertertotalValueMinorn =
      NullAwareTypeConverter.wrap($convertertotalValueMinor);
}

class ValuationRow extends DataClass implements Insertable<ValuationRow> {
  final int id;
  final String accountId;
  final DateTime date;

  /// ValuationKind.name: unitPrice / totalValue。
  final String kind;

  /// 单价（分子/分母）或总价值（最小单位）。
  final BigInt? unitPriceN;
  final BigInt? unitPriceD;
  final BigInt? totalValueMinor;
  final String source;
  final String? note;
  const ValuationRow({
    required this.id,
    required this.accountId,
    required this.date,
    required this.kind,
    this.unitPriceN,
    this.unitPriceD,
    this.totalValueMinor,
    required this.source,
    this.note,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['account_id'] = Variable<String>(accountId);
    map['date'] = Variable<DateTime>(date);
    map['kind'] = Variable<String>(kind);
    if (!nullToAbsent || unitPriceN != null) {
      map['unit_price_n'] = Variable<String>(
        $ValuationsTable.$converterunitPriceNn.toSql(unitPriceN),
      );
    }
    if (!nullToAbsent || unitPriceD != null) {
      map['unit_price_d'] = Variable<String>(
        $ValuationsTable.$converterunitPriceDn.toSql(unitPriceD),
      );
    }
    if (!nullToAbsent || totalValueMinor != null) {
      map['total_value_minor'] = Variable<String>(
        $ValuationsTable.$convertertotalValueMinorn.toSql(totalValueMinor),
      );
    }
    map['source'] = Variable<String>(source);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    return map;
  }

  ValuationsCompanion toCompanion(bool nullToAbsent) {
    return ValuationsCompanion(
      id: Value(id),
      accountId: Value(accountId),
      date: Value(date),
      kind: Value(kind),
      unitPriceN: unitPriceN == null && nullToAbsent
          ? const Value.absent()
          : Value(unitPriceN),
      unitPriceD: unitPriceD == null && nullToAbsent
          ? const Value.absent()
          : Value(unitPriceD),
      totalValueMinor: totalValueMinor == null && nullToAbsent
          ? const Value.absent()
          : Value(totalValueMinor),
      source: Value(source),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
    );
  }

  factory ValuationRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ValuationRow(
      id: serializer.fromJson<int>(json['id']),
      accountId: serializer.fromJson<String>(json['accountId']),
      date: serializer.fromJson<DateTime>(json['date']),
      kind: serializer.fromJson<String>(json['kind']),
      unitPriceN: serializer.fromJson<BigInt?>(json['unitPriceN']),
      unitPriceD: serializer.fromJson<BigInt?>(json['unitPriceD']),
      totalValueMinor: serializer.fromJson<BigInt?>(json['totalValueMinor']),
      source: serializer.fromJson<String>(json['source']),
      note: serializer.fromJson<String?>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'accountId': serializer.toJson<String>(accountId),
      'date': serializer.toJson<DateTime>(date),
      'kind': serializer.toJson<String>(kind),
      'unitPriceN': serializer.toJson<BigInt?>(unitPriceN),
      'unitPriceD': serializer.toJson<BigInt?>(unitPriceD),
      'totalValueMinor': serializer.toJson<BigInt?>(totalValueMinor),
      'source': serializer.toJson<String>(source),
      'note': serializer.toJson<String?>(note),
    };
  }

  ValuationRow copyWith({
    int? id,
    String? accountId,
    DateTime? date,
    String? kind,
    Value<BigInt?> unitPriceN = const Value.absent(),
    Value<BigInt?> unitPriceD = const Value.absent(),
    Value<BigInt?> totalValueMinor = const Value.absent(),
    String? source,
    Value<String?> note = const Value.absent(),
  }) => ValuationRow(
    id: id ?? this.id,
    accountId: accountId ?? this.accountId,
    date: date ?? this.date,
    kind: kind ?? this.kind,
    unitPriceN: unitPriceN.present ? unitPriceN.value : this.unitPriceN,
    unitPriceD: unitPriceD.present ? unitPriceD.value : this.unitPriceD,
    totalValueMinor: totalValueMinor.present
        ? totalValueMinor.value
        : this.totalValueMinor,
    source: source ?? this.source,
    note: note.present ? note.value : this.note,
  );
  ValuationRow copyWithCompanion(ValuationsCompanion data) {
    return ValuationRow(
      id: data.id.present ? data.id.value : this.id,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      date: data.date.present ? data.date.value : this.date,
      kind: data.kind.present ? data.kind.value : this.kind,
      unitPriceN: data.unitPriceN.present
          ? data.unitPriceN.value
          : this.unitPriceN,
      unitPriceD: data.unitPriceD.present
          ? data.unitPriceD.value
          : this.unitPriceD,
      totalValueMinor: data.totalValueMinor.present
          ? data.totalValueMinor.value
          : this.totalValueMinor,
      source: data.source.present ? data.source.value : this.source,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ValuationRow(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('date: $date, ')
          ..write('kind: $kind, ')
          ..write('unitPriceN: $unitPriceN, ')
          ..write('unitPriceD: $unitPriceD, ')
          ..write('totalValueMinor: $totalValueMinor, ')
          ..write('source: $source, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    accountId,
    date,
    kind,
    unitPriceN,
    unitPriceD,
    totalValueMinor,
    source,
    note,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ValuationRow &&
          other.id == this.id &&
          other.accountId == this.accountId &&
          other.date == this.date &&
          other.kind == this.kind &&
          other.unitPriceN == this.unitPriceN &&
          other.unitPriceD == this.unitPriceD &&
          other.totalValueMinor == this.totalValueMinor &&
          other.source == this.source &&
          other.note == this.note);
}

class ValuationsCompanion extends UpdateCompanion<ValuationRow> {
  final Value<int> id;
  final Value<String> accountId;
  final Value<DateTime> date;
  final Value<String> kind;
  final Value<BigInt?> unitPriceN;
  final Value<BigInt?> unitPriceD;
  final Value<BigInt?> totalValueMinor;
  final Value<String> source;
  final Value<String?> note;
  const ValuationsCompanion({
    this.id = const Value.absent(),
    this.accountId = const Value.absent(),
    this.date = const Value.absent(),
    this.kind = const Value.absent(),
    this.unitPriceN = const Value.absent(),
    this.unitPriceD = const Value.absent(),
    this.totalValueMinor = const Value.absent(),
    this.source = const Value.absent(),
    this.note = const Value.absent(),
  });
  ValuationsCompanion.insert({
    this.id = const Value.absent(),
    required String accountId,
    required DateTime date,
    required String kind,
    this.unitPriceN = const Value.absent(),
    this.unitPriceD = const Value.absent(),
    this.totalValueMinor = const Value.absent(),
    this.source = const Value.absent(),
    this.note = const Value.absent(),
  }) : accountId = Value(accountId),
       date = Value(date),
       kind = Value(kind);
  static Insertable<ValuationRow> custom({
    Expression<int>? id,
    Expression<String>? accountId,
    Expression<DateTime>? date,
    Expression<String>? kind,
    Expression<String>? unitPriceN,
    Expression<String>? unitPriceD,
    Expression<String>? totalValueMinor,
    Expression<String>? source,
    Expression<String>? note,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (accountId != null) 'account_id': accountId,
      if (date != null) 'date': date,
      if (kind != null) 'kind': kind,
      if (unitPriceN != null) 'unit_price_n': unitPriceN,
      if (unitPriceD != null) 'unit_price_d': unitPriceD,
      if (totalValueMinor != null) 'total_value_minor': totalValueMinor,
      if (source != null) 'source': source,
      if (note != null) 'note': note,
    });
  }

  ValuationsCompanion copyWith({
    Value<int>? id,
    Value<String>? accountId,
    Value<DateTime>? date,
    Value<String>? kind,
    Value<BigInt?>? unitPriceN,
    Value<BigInt?>? unitPriceD,
    Value<BigInt?>? totalValueMinor,
    Value<String>? source,
    Value<String?>? note,
  }) {
    return ValuationsCompanion(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      date: date ?? this.date,
      kind: kind ?? this.kind,
      unitPriceN: unitPriceN ?? this.unitPriceN,
      unitPriceD: unitPriceD ?? this.unitPriceD,
      totalValueMinor: totalValueMinor ?? this.totalValueMinor,
      source: source ?? this.source,
      note: note ?? this.note,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (unitPriceN.present) {
      map['unit_price_n'] = Variable<String>(
        $ValuationsTable.$converterunitPriceNn.toSql(unitPriceN.value),
      );
    }
    if (unitPriceD.present) {
      map['unit_price_d'] = Variable<String>(
        $ValuationsTable.$converterunitPriceDn.toSql(unitPriceD.value),
      );
    }
    if (totalValueMinor.present) {
      map['total_value_minor'] = Variable<String>(
        $ValuationsTable.$convertertotalValueMinorn.toSql(
          totalValueMinor.value,
        ),
      );
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ValuationsCompanion(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('date: $date, ')
          ..write('kind: $kind, ')
          ..write('unitPriceN: $unitPriceN, ')
          ..write('unitPriceD: $unitPriceD, ')
          ..write('totalValueMinor: $totalValueMinor, ')
          ..write('source: $source, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }
}

class $FxRatesTable extends FxRates with TableInfo<$FxRatesTable, FxRateRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FxRatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _baseCcyMeta = const VerificationMeta(
    'baseCcy',
  );
  @override
  late final GeneratedColumn<String> baseCcy = GeneratedColumn<String>(
    'base_ccy',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quoteCcyMeta = const VerificationMeta(
    'quoteCcy',
  );
  @override
  late final GeneratedColumn<String> quoteCcy = GeneratedColumn<String>(
    'quote_ccy',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<BigInt, String> rateN =
      GeneratedColumn<String>(
        'rate_n',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<BigInt>($FxRatesTable.$converterrateN);
  @override
  late final GeneratedColumnWithTypeConverter<BigInt, String> rateD =
      GeneratedColumn<String>(
        'rate_d',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<BigInt>($FxRatesTable.$converterrateD);
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('manual'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    baseCcy,
    quoteCcy,
    date,
    rateN,
    rateD,
    source,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'fx_rates';
  @override
  VerificationContext validateIntegrity(
    Insertable<FxRateRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('base_ccy')) {
      context.handle(
        _baseCcyMeta,
        baseCcy.isAcceptableOrUnknown(data['base_ccy']!, _baseCcyMeta),
      );
    } else if (isInserting) {
      context.missing(_baseCcyMeta);
    }
    if (data.containsKey('quote_ccy')) {
      context.handle(
        _quoteCcyMeta,
        quoteCcy.isAcceptableOrUnknown(data['quote_ccy']!, _quoteCcyMeta),
      );
    } else if (isInserting) {
      context.missing(_quoteCcyMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FxRateRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FxRateRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      baseCcy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}base_ccy'],
      )!,
      quoteCcy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}quote_ccy'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      rateN: $FxRatesTable.$converterrateN.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}rate_n'],
        )!,
      ),
      rateD: $FxRatesTable.$converterrateD.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}rate_d'],
        )!,
      ),
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
    );
  }

  @override
  $FxRatesTable createAlias(String alias) {
    return $FxRatesTable(attachedDatabase, alias);
  }

  static TypeConverter<BigInt, String> $converterrateN = const BigIntText();
  static TypeConverter<BigInt, String> $converterrateD = const BigIntText();
}

class FxRateRow extends DataClass implements Insertable<FxRateRow> {
  final int id;
  final String baseCcy;
  final String quoteCcy;
  final DateTime date;
  final BigInt rateN;
  final BigInt rateD;
  final String source;
  const FxRateRow({
    required this.id,
    required this.baseCcy,
    required this.quoteCcy,
    required this.date,
    required this.rateN,
    required this.rateD,
    required this.source,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['base_ccy'] = Variable<String>(baseCcy);
    map['quote_ccy'] = Variable<String>(quoteCcy);
    map['date'] = Variable<DateTime>(date);
    {
      map['rate_n'] = Variable<String>(
        $FxRatesTable.$converterrateN.toSql(rateN),
      );
    }
    {
      map['rate_d'] = Variable<String>(
        $FxRatesTable.$converterrateD.toSql(rateD),
      );
    }
    map['source'] = Variable<String>(source);
    return map;
  }

  FxRatesCompanion toCompanion(bool nullToAbsent) {
    return FxRatesCompanion(
      id: Value(id),
      baseCcy: Value(baseCcy),
      quoteCcy: Value(quoteCcy),
      date: Value(date),
      rateN: Value(rateN),
      rateD: Value(rateD),
      source: Value(source),
    );
  }

  factory FxRateRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FxRateRow(
      id: serializer.fromJson<int>(json['id']),
      baseCcy: serializer.fromJson<String>(json['baseCcy']),
      quoteCcy: serializer.fromJson<String>(json['quoteCcy']),
      date: serializer.fromJson<DateTime>(json['date']),
      rateN: serializer.fromJson<BigInt>(json['rateN']),
      rateD: serializer.fromJson<BigInt>(json['rateD']),
      source: serializer.fromJson<String>(json['source']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'baseCcy': serializer.toJson<String>(baseCcy),
      'quoteCcy': serializer.toJson<String>(quoteCcy),
      'date': serializer.toJson<DateTime>(date),
      'rateN': serializer.toJson<BigInt>(rateN),
      'rateD': serializer.toJson<BigInt>(rateD),
      'source': serializer.toJson<String>(source),
    };
  }

  FxRateRow copyWith({
    int? id,
    String? baseCcy,
    String? quoteCcy,
    DateTime? date,
    BigInt? rateN,
    BigInt? rateD,
    String? source,
  }) => FxRateRow(
    id: id ?? this.id,
    baseCcy: baseCcy ?? this.baseCcy,
    quoteCcy: quoteCcy ?? this.quoteCcy,
    date: date ?? this.date,
    rateN: rateN ?? this.rateN,
    rateD: rateD ?? this.rateD,
    source: source ?? this.source,
  );
  FxRateRow copyWithCompanion(FxRatesCompanion data) {
    return FxRateRow(
      id: data.id.present ? data.id.value : this.id,
      baseCcy: data.baseCcy.present ? data.baseCcy.value : this.baseCcy,
      quoteCcy: data.quoteCcy.present ? data.quoteCcy.value : this.quoteCcy,
      date: data.date.present ? data.date.value : this.date,
      rateN: data.rateN.present ? data.rateN.value : this.rateN,
      rateD: data.rateD.present ? data.rateD.value : this.rateD,
      source: data.source.present ? data.source.value : this.source,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FxRateRow(')
          ..write('id: $id, ')
          ..write('baseCcy: $baseCcy, ')
          ..write('quoteCcy: $quoteCcy, ')
          ..write('date: $date, ')
          ..write('rateN: $rateN, ')
          ..write('rateD: $rateD, ')
          ..write('source: $source')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, baseCcy, quoteCcy, date, rateN, rateD, source);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FxRateRow &&
          other.id == this.id &&
          other.baseCcy == this.baseCcy &&
          other.quoteCcy == this.quoteCcy &&
          other.date == this.date &&
          other.rateN == this.rateN &&
          other.rateD == this.rateD &&
          other.source == this.source);
}

class FxRatesCompanion extends UpdateCompanion<FxRateRow> {
  final Value<int> id;
  final Value<String> baseCcy;
  final Value<String> quoteCcy;
  final Value<DateTime> date;
  final Value<BigInt> rateN;
  final Value<BigInt> rateD;
  final Value<String> source;
  const FxRatesCompanion({
    this.id = const Value.absent(),
    this.baseCcy = const Value.absent(),
    this.quoteCcy = const Value.absent(),
    this.date = const Value.absent(),
    this.rateN = const Value.absent(),
    this.rateD = const Value.absent(),
    this.source = const Value.absent(),
  });
  FxRatesCompanion.insert({
    this.id = const Value.absent(),
    required String baseCcy,
    required String quoteCcy,
    required DateTime date,
    required BigInt rateN,
    required BigInt rateD,
    this.source = const Value.absent(),
  }) : baseCcy = Value(baseCcy),
       quoteCcy = Value(quoteCcy),
       date = Value(date),
       rateN = Value(rateN),
       rateD = Value(rateD);
  static Insertable<FxRateRow> custom({
    Expression<int>? id,
    Expression<String>? baseCcy,
    Expression<String>? quoteCcy,
    Expression<DateTime>? date,
    Expression<String>? rateN,
    Expression<String>? rateD,
    Expression<String>? source,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (baseCcy != null) 'base_ccy': baseCcy,
      if (quoteCcy != null) 'quote_ccy': quoteCcy,
      if (date != null) 'date': date,
      if (rateN != null) 'rate_n': rateN,
      if (rateD != null) 'rate_d': rateD,
      if (source != null) 'source': source,
    });
  }

  FxRatesCompanion copyWith({
    Value<int>? id,
    Value<String>? baseCcy,
    Value<String>? quoteCcy,
    Value<DateTime>? date,
    Value<BigInt>? rateN,
    Value<BigInt>? rateD,
    Value<String>? source,
  }) {
    return FxRatesCompanion(
      id: id ?? this.id,
      baseCcy: baseCcy ?? this.baseCcy,
      quoteCcy: quoteCcy ?? this.quoteCcy,
      date: date ?? this.date,
      rateN: rateN ?? this.rateN,
      rateD: rateD ?? this.rateD,
      source: source ?? this.source,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (baseCcy.present) {
      map['base_ccy'] = Variable<String>(baseCcy.value);
    }
    if (quoteCcy.present) {
      map['quote_ccy'] = Variable<String>(quoteCcy.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (rateN.present) {
      map['rate_n'] = Variable<String>(
        $FxRatesTable.$converterrateN.toSql(rateN.value),
      );
    }
    if (rateD.present) {
      map['rate_d'] = Variable<String>(
        $FxRatesTable.$converterrateD.toSql(rateD.value),
      );
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FxRatesCompanion(')
          ..write('id: $id, ')
          ..write('baseCcy: $baseCcy, ')
          ..write('quoteCcy: $quoteCcy, ')
          ..write('date: $date, ')
          ..write('rateN: $rateN, ')
          ..write('rateD: $rateD, ')
          ..write('source: $source')
          ..write(')'))
        .toString();
  }
}

class $SnapshotsTable extends Snapshots
    with TableInfo<$SnapshotsTable, SnapshotRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SnapshotsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _monthMeta = const VerificationMeta('month');
  @override
  late final GeneratedColumn<String> month = GeneratedColumn<String>(
    'month',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [month, payloadJson, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'snapshots';
  @override
  VerificationContext validateIntegrity(
    Insertable<SnapshotRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('month')) {
      context.handle(
        _monthMeta,
        month.isAcceptableOrUnknown(data['month']!, _monthMeta),
      );
    } else if (isInserting) {
      context.missing(_monthMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {month};
  @override
  SnapshotRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SnapshotRow(
      month: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}month'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $SnapshotsTable createAlias(String alias) {
    return $SnapshotsTable(attachedDatabase, alias);
  }
}

class SnapshotRow extends DataClass implements Insertable<SnapshotRow> {
  final String month;
  final String payloadJson;
  final DateTime updatedAt;
  const SnapshotRow({
    required this.month,
    required this.payloadJson,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['month'] = Variable<String>(month);
    map['payload_json'] = Variable<String>(payloadJson);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SnapshotsCompanion toCompanion(bool nullToAbsent) {
    return SnapshotsCompanion(
      month: Value(month),
      payloadJson: Value(payloadJson),
      updatedAt: Value(updatedAt),
    );
  }

  factory SnapshotRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SnapshotRow(
      month: serializer.fromJson<String>(json['month']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'month': serializer.toJson<String>(month),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  SnapshotRow copyWith({
    String? month,
    String? payloadJson,
    DateTime? updatedAt,
  }) => SnapshotRow(
    month: month ?? this.month,
    payloadJson: payloadJson ?? this.payloadJson,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  SnapshotRow copyWithCompanion(SnapshotsCompanion data) {
    return SnapshotRow(
      month: data.month.present ? data.month.value : this.month,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SnapshotRow(')
          ..write('month: $month, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(month, payloadJson, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SnapshotRow &&
          other.month == this.month &&
          other.payloadJson == this.payloadJson &&
          other.updatedAt == this.updatedAt);
}

class SnapshotsCompanion extends UpdateCompanion<SnapshotRow> {
  final Value<String> month;
  final Value<String> payloadJson;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const SnapshotsCompanion({
    this.month = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SnapshotsCompanion.insert({
    required String month,
    required String payloadJson,
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : month = Value(month),
       payloadJson = Value(payloadJson);
  static Insertable<SnapshotRow> custom({
    Expression<String>? month,
    Expression<String>? payloadJson,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (month != null) 'month': month,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SnapshotsCompanion copyWith({
    Value<String>? month,
    Value<String>? payloadJson,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return SnapshotsCompanion(
      month: month ?? this.month,
      payloadJson: payloadJson ?? this.payloadJson,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (month.present) {
      map['month'] = Variable<String>(month.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SnapshotsCompanion(')
          ..write('month: $month, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ImportBatchesTable extends ImportBatches
    with TableInfo<$ImportBatchesTable, ImportBatchRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ImportBatchesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _filenameMeta = const VerificationMeta(
    'filename',
  );
  @override
  late final GeneratedColumn<String> filename = GeneratedColumn<String>(
    'filename',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _importedAtMeta = const VerificationMeta(
    'importedAt',
  );
  @override
  late final GeneratedColumn<DateTime> importedAt = GeneratedColumn<DateTime>(
    'imported_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _parserVersionMeta = const VerificationMeta(
    'parserVersion',
  );
  @override
  late final GeneratedColumn<String> parserVersion = GeneratedColumn<String>(
    'parser_version',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _countsJsonMeta = const VerificationMeta(
    'countsJson',
  );
  @override
  late final GeneratedColumn<String> countsJson = GeneratedColumn<String>(
    'counts_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    source,
    filename,
    importedAt,
    parserVersion,
    status,
    countsJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'import_batches';
  @override
  VerificationContext validateIntegrity(
    Insertable<ImportBatchRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('filename')) {
      context.handle(
        _filenameMeta,
        filename.isAcceptableOrUnknown(data['filename']!, _filenameMeta),
      );
    } else if (isInserting) {
      context.missing(_filenameMeta);
    }
    if (data.containsKey('imported_at')) {
      context.handle(
        _importedAtMeta,
        importedAt.isAcceptableOrUnknown(data['imported_at']!, _importedAtMeta),
      );
    }
    if (data.containsKey('parser_version')) {
      context.handle(
        _parserVersionMeta,
        parserVersion.isAcceptableOrUnknown(
          data['parser_version']!,
          _parserVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_parserVersionMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('counts_json')) {
      context.handle(
        _countsJsonMeta,
        countsJson.isAcceptableOrUnknown(data['counts_json']!, _countsJsonMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  ImportBatchRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ImportBatchRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      filename: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}filename'],
      )!,
      importedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}imported_at'],
      )!,
      parserVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parser_version'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      countsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}counts_json'],
      )!,
    );
  }

  @override
  $ImportBatchesTable createAlias(String alias) {
    return $ImportBatchesTable(attachedDatabase, alias);
  }
}

class ImportBatchRow extends DataClass implements Insertable<ImportBatchRow> {
  final String id;
  final String source;
  final String filename;
  final DateTime importedAt;
  final String parserVersion;
  final String status;
  final String countsJson;
  const ImportBatchRow({
    required this.id,
    required this.source,
    required this.filename,
    required this.importedAt,
    required this.parserVersion,
    required this.status,
    required this.countsJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['source'] = Variable<String>(source);
    map['filename'] = Variable<String>(filename);
    map['imported_at'] = Variable<DateTime>(importedAt);
    map['parser_version'] = Variable<String>(parserVersion);
    map['status'] = Variable<String>(status);
    map['counts_json'] = Variable<String>(countsJson);
    return map;
  }

  ImportBatchesCompanion toCompanion(bool nullToAbsent) {
    return ImportBatchesCompanion(
      id: Value(id),
      source: Value(source),
      filename: Value(filename),
      importedAt: Value(importedAt),
      parserVersion: Value(parserVersion),
      status: Value(status),
      countsJson: Value(countsJson),
    );
  }

  factory ImportBatchRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ImportBatchRow(
      id: serializer.fromJson<String>(json['id']),
      source: serializer.fromJson<String>(json['source']),
      filename: serializer.fromJson<String>(json['filename']),
      importedAt: serializer.fromJson<DateTime>(json['importedAt']),
      parserVersion: serializer.fromJson<String>(json['parserVersion']),
      status: serializer.fromJson<String>(json['status']),
      countsJson: serializer.fromJson<String>(json['countsJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'source': serializer.toJson<String>(source),
      'filename': serializer.toJson<String>(filename),
      'importedAt': serializer.toJson<DateTime>(importedAt),
      'parserVersion': serializer.toJson<String>(parserVersion),
      'status': serializer.toJson<String>(status),
      'countsJson': serializer.toJson<String>(countsJson),
    };
  }

  ImportBatchRow copyWith({
    String? id,
    String? source,
    String? filename,
    DateTime? importedAt,
    String? parserVersion,
    String? status,
    String? countsJson,
  }) => ImportBatchRow(
    id: id ?? this.id,
    source: source ?? this.source,
    filename: filename ?? this.filename,
    importedAt: importedAt ?? this.importedAt,
    parserVersion: parserVersion ?? this.parserVersion,
    status: status ?? this.status,
    countsJson: countsJson ?? this.countsJson,
  );
  ImportBatchRow copyWithCompanion(ImportBatchesCompanion data) {
    return ImportBatchRow(
      id: data.id.present ? data.id.value : this.id,
      source: data.source.present ? data.source.value : this.source,
      filename: data.filename.present ? data.filename.value : this.filename,
      importedAt: data.importedAt.present
          ? data.importedAt.value
          : this.importedAt,
      parserVersion: data.parserVersion.present
          ? data.parserVersion.value
          : this.parserVersion,
      status: data.status.present ? data.status.value : this.status,
      countsJson: data.countsJson.present
          ? data.countsJson.value
          : this.countsJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ImportBatchRow(')
          ..write('id: $id, ')
          ..write('source: $source, ')
          ..write('filename: $filename, ')
          ..write('importedAt: $importedAt, ')
          ..write('parserVersion: $parserVersion, ')
          ..write('status: $status, ')
          ..write('countsJson: $countsJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    source,
    filename,
    importedAt,
    parserVersion,
    status,
    countsJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ImportBatchRow &&
          other.id == this.id &&
          other.source == this.source &&
          other.filename == this.filename &&
          other.importedAt == this.importedAt &&
          other.parserVersion == this.parserVersion &&
          other.status == this.status &&
          other.countsJson == this.countsJson);
}

class ImportBatchesCompanion extends UpdateCompanion<ImportBatchRow> {
  final Value<String> id;
  final Value<String> source;
  final Value<String> filename;
  final Value<DateTime> importedAt;
  final Value<String> parserVersion;
  final Value<String> status;
  final Value<String> countsJson;
  final Value<int> rowid;
  const ImportBatchesCompanion({
    this.id = const Value.absent(),
    this.source = const Value.absent(),
    this.filename = const Value.absent(),
    this.importedAt = const Value.absent(),
    this.parserVersion = const Value.absent(),
    this.status = const Value.absent(),
    this.countsJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ImportBatchesCompanion.insert({
    required String id,
    required String source,
    required String filename,
    this.importedAt = const Value.absent(),
    required String parserVersion,
    this.status = const Value.absent(),
    this.countsJson = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       source = Value(source),
       filename = Value(filename),
       parserVersion = Value(parserVersion);
  static Insertable<ImportBatchRow> custom({
    Expression<String>? id,
    Expression<String>? source,
    Expression<String>? filename,
    Expression<DateTime>? importedAt,
    Expression<String>? parserVersion,
    Expression<String>? status,
    Expression<String>? countsJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (source != null) 'source': source,
      if (filename != null) 'filename': filename,
      if (importedAt != null) 'imported_at': importedAt,
      if (parserVersion != null) 'parser_version': parserVersion,
      if (status != null) 'status': status,
      if (countsJson != null) 'counts_json': countsJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ImportBatchesCompanion copyWith({
    Value<String>? id,
    Value<String>? source,
    Value<String>? filename,
    Value<DateTime>? importedAt,
    Value<String>? parserVersion,
    Value<String>? status,
    Value<String>? countsJson,
    Value<int>? rowid,
  }) {
    return ImportBatchesCompanion(
      id: id ?? this.id,
      source: source ?? this.source,
      filename: filename ?? this.filename,
      importedAt: importedAt ?? this.importedAt,
      parserVersion: parserVersion ?? this.parserVersion,
      status: status ?? this.status,
      countsJson: countsJson ?? this.countsJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (filename.present) {
      map['filename'] = Variable<String>(filename.value);
    }
    if (importedAt.present) {
      map['imported_at'] = Variable<DateTime>(importedAt.value);
    }
    if (parserVersion.present) {
      map['parser_version'] = Variable<String>(parserVersion.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (countsJson.present) {
      map['counts_json'] = Variable<String>(countsJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ImportBatchesCompanion(')
          ..write('id: $id, ')
          ..write('source: $source, ')
          ..write('filename: $filename, ')
          ..write('importedAt: $importedAt, ')
          ..write('parserVersion: $parserVersion, ')
          ..write('status: $status, ')
          ..write('countsJson: $countsJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SettingsTable extends Settings
    with TableInfo<$SettingsTable, SettingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueJsonMeta = const VerificationMeta(
    'valueJson',
  );
  @override
  late final GeneratedColumn<String> valueJson = GeneratedColumn<String>(
    'value_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, valueJson];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<SettingRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value_json')) {
      context.handle(
        _valueJsonMeta,
        valueJson.isAcceptableOrUnknown(data['value_json']!, _valueJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_valueJsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SettingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      valueJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value_json'],
      )!,
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class SettingRow extends DataClass implements Insertable<SettingRow> {
  final String key;
  final String valueJson;
  const SettingRow({required this.key, required this.valueJson});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value_json'] = Variable<String>(valueJson);
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(key: Value(key), valueJson: Value(valueJson));
  }

  factory SettingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingRow(
      key: serializer.fromJson<String>(json['key']),
      valueJson: serializer.fromJson<String>(json['valueJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'valueJson': serializer.toJson<String>(valueJson),
    };
  }

  SettingRow copyWith({String? key, String? valueJson}) =>
      SettingRow(key: key ?? this.key, valueJson: valueJson ?? this.valueJson);
  SettingRow copyWithCompanion(SettingsCompanion data) {
    return SettingRow(
      key: data.key.present ? data.key.value : this.key,
      valueJson: data.valueJson.present ? data.valueJson.value : this.valueJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingRow(')
          ..write('key: $key, ')
          ..write('valueJson: $valueJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, valueJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettingRow &&
          other.key == this.key &&
          other.valueJson == this.valueJson);
}

class SettingsCompanion extends UpdateCompanion<SettingRow> {
  final Value<String> key;
  final Value<String> valueJson;
  final Value<int> rowid;
  const SettingsCompanion({
    this.key = const Value.absent(),
    this.valueJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsCompanion.insert({
    required String key,
    required String valueJson,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       valueJson = Value(valueJson);
  static Insertable<SettingRow> custom({
    Expression<String>? key,
    Expression<String>? valueJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (valueJson != null) 'value_json': valueJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? valueJson,
    Value<int>? rowid,
  }) {
    return SettingsCompanion(
      key: key ?? this.key,
      valueJson: valueJson ?? this.valueJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (valueJson.present) {
      map['value_json'] = Variable<String>(valueJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('key: $key, ')
          ..write('valueJson: $valueJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $AccountsTable accounts = $AccountsTable(this);
  late final $SecuritiesTable securities = $SecuritiesTable(this);
  late final $TransactionsTable transactions = $TransactionsTable(this);
  late final $PostingsTable postings = $PostingsTable(this);
  late final $BudgetsTable budgets = $BudgetsTable(this);
  late final $ScheduledEventsTable scheduledEvents = $ScheduledEventsTable(
    this,
  );
  late final $GoalsTable goals = $GoalsTable(this);
  late final $DebtContractsTable debtContracts = $DebtContractsTable(this);
  late final $ValuationsTable valuations = $ValuationsTable(this);
  late final $FxRatesTable fxRates = $FxRatesTable(this);
  late final $SnapshotsTable snapshots = $SnapshotsTable(this);
  late final $ImportBatchesTable importBatches = $ImportBatchesTable(this);
  late final $SettingsTable settings = $SettingsTable(this);
  late final Index idxTransactionsDate = Index(
    'idx_transactions_date',
    'CREATE INDEX idx_transactions_date ON transactions (date)',
  );
  late final Index idxPostingsTx = Index(
    'idx_postings_tx',
    'CREATE INDEX idx_postings_tx ON postings (tx_id)',
  );
  late final Index idxPostingsAccount = Index(
    'idx_postings_account',
    'CREATE INDEX idx_postings_account ON postings (account_id)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    accounts,
    securities,
    transactions,
    postings,
    budgets,
    scheduledEvents,
    goals,
    debtContracts,
    valuations,
    fxRates,
    snapshots,
    importBatches,
    settings,
    idxTransactionsDate,
    idxPostingsTx,
    idxPostingsAccount,
  ];
}

typedef $$AccountsTableCreateCompanionBuilder =
    AccountsCompanion Function({
      required String id,
      required String name,
      required String type,
      Value<String?> assetSubtype,
      Value<String?> liabilitySubtype,
      Value<String?> institution,
      required String currencyCode,
      Value<String?> ownershipN,
      Value<String?> ownershipD,
      Value<bool> includeInNetWorth,
      Value<BigInt?> creditLimitMinor,
      Value<int?> statementDay,
      Value<int?> dueDay,
      Value<bool> isSystem,
      Value<bool> archived,
      Value<int> sortOrder,
      Value<String?> notes,
      Value<String?> costBasisAccountId,
      Value<String?> securityId,
      Value<double?> locationLat,
      Value<double?> locationLon,
      Value<String?> locationName,
      Value<bool> aiValuationEnabled,
      Value<String?> aiValuationQuery,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$AccountsTableUpdateCompanionBuilder =
    AccountsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> type,
      Value<String?> assetSubtype,
      Value<String?> liabilitySubtype,
      Value<String?> institution,
      Value<String> currencyCode,
      Value<String?> ownershipN,
      Value<String?> ownershipD,
      Value<bool> includeInNetWorth,
      Value<BigInt?> creditLimitMinor,
      Value<int?> statementDay,
      Value<int?> dueDay,
      Value<bool> isSystem,
      Value<bool> archived,
      Value<int> sortOrder,
      Value<String?> notes,
      Value<String?> costBasisAccountId,
      Value<String?> securityId,
      Value<double?> locationLat,
      Value<double?> locationLon,
      Value<String?> locationName,
      Value<bool> aiValuationEnabled,
      Value<String?> aiValuationQuery,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$AccountsTableFilterComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get assetSubtype => $composableBuilder(
    column: $table.assetSubtype,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get liabilitySubtype => $composableBuilder(
    column: $table.liabilitySubtype,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get institution => $composableBuilder(
    column: $table.institution,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ownershipN => $composableBuilder(
    column: $table.ownershipN,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ownershipD => $composableBuilder(
    column: $table.ownershipD,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get includeInNetWorth => $composableBuilder(
    column: $table.includeInNetWorth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<BigInt?, BigInt, String>
  get creditLimitMinor => $composableBuilder(
    column: $table.creditLimitMinor,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get statementDay => $composableBuilder(
    column: $table.statementDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dueDay => $composableBuilder(
    column: $table.dueDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSystem => $composableBuilder(
    column: $table.isSystem,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get costBasisAccountId => $composableBuilder(
    column: $table.costBasisAccountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get securityId => $composableBuilder(
    column: $table.securityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get locationLat => $composableBuilder(
    column: $table.locationLat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get locationLon => $composableBuilder(
    column: $table.locationLon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get locationName => $composableBuilder(
    column: $table.locationName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get aiValuationEnabled => $composableBuilder(
    column: $table.aiValuationEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get aiValuationQuery => $composableBuilder(
    column: $table.aiValuationQuery,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AccountsTableOrderingComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get assetSubtype => $composableBuilder(
    column: $table.assetSubtype,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get liabilitySubtype => $composableBuilder(
    column: $table.liabilitySubtype,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get institution => $composableBuilder(
    column: $table.institution,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ownershipN => $composableBuilder(
    column: $table.ownershipN,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ownershipD => $composableBuilder(
    column: $table.ownershipD,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get includeInNetWorth => $composableBuilder(
    column: $table.includeInNetWorth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get creditLimitMinor => $composableBuilder(
    column: $table.creditLimitMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get statementDay => $composableBuilder(
    column: $table.statementDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dueDay => $composableBuilder(
    column: $table.dueDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSystem => $composableBuilder(
    column: $table.isSystem,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get costBasisAccountId => $composableBuilder(
    column: $table.costBasisAccountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get securityId => $composableBuilder(
    column: $table.securityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get locationLat => $composableBuilder(
    column: $table.locationLat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get locationLon => $composableBuilder(
    column: $table.locationLon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get locationName => $composableBuilder(
    column: $table.locationName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get aiValuationEnabled => $composableBuilder(
    column: $table.aiValuationEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get aiValuationQuery => $composableBuilder(
    column: $table.aiValuationQuery,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AccountsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get assetSubtype => $composableBuilder(
    column: $table.assetSubtype,
    builder: (column) => column,
  );

  GeneratedColumn<String> get liabilitySubtype => $composableBuilder(
    column: $table.liabilitySubtype,
    builder: (column) => column,
  );

  GeneratedColumn<String> get institution => $composableBuilder(
    column: $table.institution,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get ownershipN => $composableBuilder(
    column: $table.ownershipN,
    builder: (column) => column,
  );

  GeneratedColumn<String> get ownershipD => $composableBuilder(
    column: $table.ownershipD,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get includeInNetWorth => $composableBuilder(
    column: $table.includeInNetWorth,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<BigInt?, String> get creditLimitMinor =>
      $composableBuilder(
        column: $table.creditLimitMinor,
        builder: (column) => column,
      );

  GeneratedColumn<int> get statementDay => $composableBuilder(
    column: $table.statementDay,
    builder: (column) => column,
  );

  GeneratedColumn<int> get dueDay =>
      $composableBuilder(column: $table.dueDay, builder: (column) => column);

  GeneratedColumn<bool> get isSystem =>
      $composableBuilder(column: $table.isSystem, builder: (column) => column);

  GeneratedColumn<bool> get archived =>
      $composableBuilder(column: $table.archived, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get costBasisAccountId => $composableBuilder(
    column: $table.costBasisAccountId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get securityId => $composableBuilder(
    column: $table.securityId,
    builder: (column) => column,
  );

  GeneratedColumn<double> get locationLat => $composableBuilder(
    column: $table.locationLat,
    builder: (column) => column,
  );

  GeneratedColumn<double> get locationLon => $composableBuilder(
    column: $table.locationLon,
    builder: (column) => column,
  );

  GeneratedColumn<String> get locationName => $composableBuilder(
    column: $table.locationName,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get aiValuationEnabled => $composableBuilder(
    column: $table.aiValuationEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<String> get aiValuationQuery => $composableBuilder(
    column: $table.aiValuationQuery,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$AccountsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AccountsTable,
          AccountRow,
          $$AccountsTableFilterComposer,
          $$AccountsTableOrderingComposer,
          $$AccountsTableAnnotationComposer,
          $$AccountsTableCreateCompanionBuilder,
          $$AccountsTableUpdateCompanionBuilder,
          (
            AccountRow,
            BaseReferences<_$AppDatabase, $AccountsTable, AccountRow>,
          ),
          AccountRow,
          PrefetchHooks Function()
        > {
  $$AccountsTableTableManager(_$AppDatabase db, $AccountsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AccountsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AccountsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AccountsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String?> assetSubtype = const Value.absent(),
                Value<String?> liabilitySubtype = const Value.absent(),
                Value<String?> institution = const Value.absent(),
                Value<String> currencyCode = const Value.absent(),
                Value<String?> ownershipN = const Value.absent(),
                Value<String?> ownershipD = const Value.absent(),
                Value<bool> includeInNetWorth = const Value.absent(),
                Value<BigInt?> creditLimitMinor = const Value.absent(),
                Value<int?> statementDay = const Value.absent(),
                Value<int?> dueDay = const Value.absent(),
                Value<bool> isSystem = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> costBasisAccountId = const Value.absent(),
                Value<String?> securityId = const Value.absent(),
                Value<double?> locationLat = const Value.absent(),
                Value<double?> locationLon = const Value.absent(),
                Value<String?> locationName = const Value.absent(),
                Value<bool> aiValuationEnabled = const Value.absent(),
                Value<String?> aiValuationQuery = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AccountsCompanion(
                id: id,
                name: name,
                type: type,
                assetSubtype: assetSubtype,
                liabilitySubtype: liabilitySubtype,
                institution: institution,
                currencyCode: currencyCode,
                ownershipN: ownershipN,
                ownershipD: ownershipD,
                includeInNetWorth: includeInNetWorth,
                creditLimitMinor: creditLimitMinor,
                statementDay: statementDay,
                dueDay: dueDay,
                isSystem: isSystem,
                archived: archived,
                sortOrder: sortOrder,
                notes: notes,
                costBasisAccountId: costBasisAccountId,
                securityId: securityId,
                locationLat: locationLat,
                locationLon: locationLon,
                locationName: locationName,
                aiValuationEnabled: aiValuationEnabled,
                aiValuationQuery: aiValuationQuery,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String type,
                Value<String?> assetSubtype = const Value.absent(),
                Value<String?> liabilitySubtype = const Value.absent(),
                Value<String?> institution = const Value.absent(),
                required String currencyCode,
                Value<String?> ownershipN = const Value.absent(),
                Value<String?> ownershipD = const Value.absent(),
                Value<bool> includeInNetWorth = const Value.absent(),
                Value<BigInt?> creditLimitMinor = const Value.absent(),
                Value<int?> statementDay = const Value.absent(),
                Value<int?> dueDay = const Value.absent(),
                Value<bool> isSystem = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> costBasisAccountId = const Value.absent(),
                Value<String?> securityId = const Value.absent(),
                Value<double?> locationLat = const Value.absent(),
                Value<double?> locationLon = const Value.absent(),
                Value<String?> locationName = const Value.absent(),
                Value<bool> aiValuationEnabled = const Value.absent(),
                Value<String?> aiValuationQuery = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AccountsCompanion.insert(
                id: id,
                name: name,
                type: type,
                assetSubtype: assetSubtype,
                liabilitySubtype: liabilitySubtype,
                institution: institution,
                currencyCode: currencyCode,
                ownershipN: ownershipN,
                ownershipD: ownershipD,
                includeInNetWorth: includeInNetWorth,
                creditLimitMinor: creditLimitMinor,
                statementDay: statementDay,
                dueDay: dueDay,
                isSystem: isSystem,
                archived: archived,
                sortOrder: sortOrder,
                notes: notes,
                costBasisAccountId: costBasisAccountId,
                securityId: securityId,
                locationLat: locationLat,
                locationLon: locationLon,
                locationName: locationName,
                aiValuationEnabled: aiValuationEnabled,
                aiValuationQuery: aiValuationQuery,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AccountsTable, AccountRow>(table),
                  BaseReferences<_$AppDatabase, $AccountsTable, AccountRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AccountsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AccountsTable,
      AccountRow,
      $$AccountsTableFilterComposer,
      $$AccountsTableOrderingComposer,
      $$AccountsTableAnnotationComposer,
      $$AccountsTableCreateCompanionBuilder,
      $$AccountsTableUpdateCompanionBuilder,
      (AccountRow, BaseReferences<_$AppDatabase, $AccountsTable, AccountRow>),
      AccountRow,
      PrefetchHooks Function()
    >;
typedef $$SecuritiesTableCreateCompanionBuilder =
    SecuritiesCompanion Function({
      required String id,
      required String code,
      required String name,
      required String type,
      required String currencyCode,
      Value<String?> notes,
      Value<int> rowid,
    });
typedef $$SecuritiesTableUpdateCompanionBuilder =
    SecuritiesCompanion Function({
      Value<String> id,
      Value<String> code,
      Value<String> name,
      Value<String> type,
      Value<String> currencyCode,
      Value<String?> notes,
      Value<int> rowid,
    });

class $$SecuritiesTableFilterComposer
    extends Composer<_$AppDatabase, $SecuritiesTable> {
  $$SecuritiesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SecuritiesTableOrderingComposer
    extends Composer<_$AppDatabase, $SecuritiesTable> {
  $$SecuritiesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SecuritiesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SecuritiesTable> {
  $$SecuritiesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);
}

class $$SecuritiesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SecuritiesTable,
          SecurityRow,
          $$SecuritiesTableFilterComposer,
          $$SecuritiesTableOrderingComposer,
          $$SecuritiesTableAnnotationComposer,
          $$SecuritiesTableCreateCompanionBuilder,
          $$SecuritiesTableUpdateCompanionBuilder,
          (
            SecurityRow,
            BaseReferences<_$AppDatabase, $SecuritiesTable, SecurityRow>,
          ),
          SecurityRow,
          PrefetchHooks Function()
        > {
  $$SecuritiesTableTableManager(_$AppDatabase db, $SecuritiesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SecuritiesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SecuritiesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SecuritiesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> code = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> currencyCode = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SecuritiesCompanion(
                id: id,
                code: code,
                name: name,
                type: type,
                currencyCode: currencyCode,
                notes: notes,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String code,
                required String name,
                required String type,
                required String currencyCode,
                Value<String?> notes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SecuritiesCompanion.insert(
                id: id,
                code: code,
                name: name,
                type: type,
                currencyCode: currencyCode,
                notes: notes,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SecuritiesTable, SecurityRow>(table),
                  BaseReferences<_$AppDatabase, $SecuritiesTable, SecurityRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SecuritiesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SecuritiesTable,
      SecurityRow,
      $$SecuritiesTableFilterComposer,
      $$SecuritiesTableOrderingComposer,
      $$SecuritiesTableAnnotationComposer,
      $$SecuritiesTableCreateCompanionBuilder,
      $$SecuritiesTableUpdateCompanionBuilder,
      (
        SecurityRow,
        BaseReferences<_$AppDatabase, $SecuritiesTable, SecurityRow>,
      ),
      SecurityRow,
      PrefetchHooks Function()
    >;
typedef $$TransactionsTableCreateCompanionBuilder =
    TransactionsCompanion Function({
      required String id,
      required DateTime date,
      required String kind,
      Value<String> status,
      Value<String?> note,
      Value<String?> counterparty,
      Value<String?> categoryId,
      Value<String> tagsJson,
      Value<String?> externalId,
      Value<String> source,
      Value<String?> importBatchId,
      Value<bool> isAdjustment,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$TransactionsTableUpdateCompanionBuilder =
    TransactionsCompanion Function({
      Value<String> id,
      Value<DateTime> date,
      Value<String> kind,
      Value<String> status,
      Value<String?> note,
      Value<String?> counterparty,
      Value<String?> categoryId,
      Value<String> tagsJson,
      Value<String?> externalId,
      Value<String> source,
      Value<String?> importBatchId,
      Value<bool> isAdjustment,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$TransactionsTableFilterComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get counterparty => $composableBuilder(
    column: $table.counterparty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tagsJson => $composableBuilder(
    column: $table.tagsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get externalId => $composableBuilder(
    column: $table.externalId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get importBatchId => $composableBuilder(
    column: $table.importBatchId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isAdjustment => $composableBuilder(
    column: $table.isAdjustment,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TransactionsTableOrderingComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get counterparty => $composableBuilder(
    column: $table.counterparty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tagsJson => $composableBuilder(
    column: $table.tagsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get externalId => $composableBuilder(
    column: $table.externalId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get importBatchId => $composableBuilder(
    column: $table.importBatchId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isAdjustment => $composableBuilder(
    column: $table.isAdjustment,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TransactionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get counterparty => $composableBuilder(
    column: $table.counterparty,
    builder: (column) => column,
  );

  GeneratedColumn<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tagsJson =>
      $composableBuilder(column: $table.tagsJson, builder: (column) => column);

  GeneratedColumn<String> get externalId => $composableBuilder(
    column: $table.externalId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get importBatchId => $composableBuilder(
    column: $table.importBatchId,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isAdjustment => $composableBuilder(
    column: $table.isAdjustment,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$TransactionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TransactionsTable,
          TransactionRow,
          $$TransactionsTableFilterComposer,
          $$TransactionsTableOrderingComposer,
          $$TransactionsTableAnnotationComposer,
          $$TransactionsTableCreateCompanionBuilder,
          $$TransactionsTableUpdateCompanionBuilder,
          (
            TransactionRow,
            BaseReferences<_$AppDatabase, $TransactionsTable, TransactionRow>,
          ),
          TransactionRow,
          PrefetchHooks Function()
        > {
  $$TransactionsTableTableManager(_$AppDatabase db, $TransactionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransactionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransactionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String?> counterparty = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<String> tagsJson = const Value.absent(),
                Value<String?> externalId = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String?> importBatchId = const Value.absent(),
                Value<bool> isAdjustment = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TransactionsCompanion(
                id: id,
                date: date,
                kind: kind,
                status: status,
                note: note,
                counterparty: counterparty,
                categoryId: categoryId,
                tagsJson: tagsJson,
                externalId: externalId,
                source: source,
                importBatchId: importBatchId,
                isAdjustment: isAdjustment,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime date,
                required String kind,
                Value<String> status = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String?> counterparty = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<String> tagsJson = const Value.absent(),
                Value<String?> externalId = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String?> importBatchId = const Value.absent(),
                Value<bool> isAdjustment = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TransactionsCompanion.insert(
                id: id,
                date: date,
                kind: kind,
                status: status,
                note: note,
                counterparty: counterparty,
                categoryId: categoryId,
                tagsJson: tagsJson,
                externalId: externalId,
                source: source,
                importBatchId: importBatchId,
                isAdjustment: isAdjustment,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TransactionsTable, TransactionRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $TransactionsTable,
                    TransactionRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TransactionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TransactionsTable,
      TransactionRow,
      $$TransactionsTableFilterComposer,
      $$TransactionsTableOrderingComposer,
      $$TransactionsTableAnnotationComposer,
      $$TransactionsTableCreateCompanionBuilder,
      $$TransactionsTableUpdateCompanionBuilder,
      (
        TransactionRow,
        BaseReferences<_$AppDatabase, $TransactionsTable, TransactionRow>,
      ),
      TransactionRow,
      PrefetchHooks Function()
    >;
typedef $$PostingsTableCreateCompanionBuilder =
    PostingsCompanion Function({
      Value<int> id,
      required String txId,
      required String accountId,
      Value<BigInt?> amountMinor,
      Value<String?> currencyCode,
      Value<String?> securityId,
      Value<BigInt?> quantityN,
      Value<BigInt?> quantityD,
      Value<String?> memo,
    });
typedef $$PostingsTableUpdateCompanionBuilder =
    PostingsCompanion Function({
      Value<int> id,
      Value<String> txId,
      Value<String> accountId,
      Value<BigInt?> amountMinor,
      Value<String?> currencyCode,
      Value<String?> securityId,
      Value<BigInt?> quantityN,
      Value<BigInt?> quantityD,
      Value<String?> memo,
    });

class $$PostingsTableFilterComposer
    extends Composer<_$AppDatabase, $PostingsTable> {
  $$PostingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get txId => $composableBuilder(
    column: $table.txId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<BigInt?, BigInt, String> get amountMinor =>
      $composableBuilder(
        column: $table.amountMinor,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get securityId => $composableBuilder(
    column: $table.securityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<BigInt?, BigInt, String> get quantityN =>
      $composableBuilder(
        column: $table.quantityN,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<BigInt?, BigInt, String> get quantityD =>
      $composableBuilder(
        column: $table.quantityD,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get memo => $composableBuilder(
    column: $table.memo,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PostingsTableOrderingComposer
    extends Composer<_$AppDatabase, $PostingsTable> {
  $$PostingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get txId => $composableBuilder(
    column: $table.txId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get securityId => $composableBuilder(
    column: $table.securityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get quantityN => $composableBuilder(
    column: $table.quantityN,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get quantityD => $composableBuilder(
    column: $table.quantityD,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get memo => $composableBuilder(
    column: $table.memo,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PostingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PostingsTable> {
  $$PostingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get txId =>
      $composableBuilder(column: $table.txId, builder: (column) => column);

  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<BigInt?, String> get amountMinor =>
      $composableBuilder(
        column: $table.amountMinor,
        builder: (column) => column,
      );

  GeneratedColumn<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get securityId => $composableBuilder(
    column: $table.securityId,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<BigInt?, String> get quantityN =>
      $composableBuilder(column: $table.quantityN, builder: (column) => column);

  GeneratedColumnWithTypeConverter<BigInt?, String> get quantityD =>
      $composableBuilder(column: $table.quantityD, builder: (column) => column);

  GeneratedColumn<String> get memo =>
      $composableBuilder(column: $table.memo, builder: (column) => column);
}

class $$PostingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PostingsTable,
          PostingRow,
          $$PostingsTableFilterComposer,
          $$PostingsTableOrderingComposer,
          $$PostingsTableAnnotationComposer,
          $$PostingsTableCreateCompanionBuilder,
          $$PostingsTableUpdateCompanionBuilder,
          (
            PostingRow,
            BaseReferences<_$AppDatabase, $PostingsTable, PostingRow>,
          ),
          PostingRow,
          PrefetchHooks Function()
        > {
  $$PostingsTableTableManager(_$AppDatabase db, $PostingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PostingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PostingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PostingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> txId = const Value.absent(),
                Value<String> accountId = const Value.absent(),
                Value<BigInt?> amountMinor = const Value.absent(),
                Value<String?> currencyCode = const Value.absent(),
                Value<String?> securityId = const Value.absent(),
                Value<BigInt?> quantityN = const Value.absent(),
                Value<BigInt?> quantityD = const Value.absent(),
                Value<String?> memo = const Value.absent(),
              }) => PostingsCompanion(
                id: id,
                txId: txId,
                accountId: accountId,
                amountMinor: amountMinor,
                currencyCode: currencyCode,
                securityId: securityId,
                quantityN: quantityN,
                quantityD: quantityD,
                memo: memo,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String txId,
                required String accountId,
                Value<BigInt?> amountMinor = const Value.absent(),
                Value<String?> currencyCode = const Value.absent(),
                Value<String?> securityId = const Value.absent(),
                Value<BigInt?> quantityN = const Value.absent(),
                Value<BigInt?> quantityD = const Value.absent(),
                Value<String?> memo = const Value.absent(),
              }) => PostingsCompanion.insert(
                id: id,
                txId: txId,
                accountId: accountId,
                amountMinor: amountMinor,
                currencyCode: currencyCode,
                securityId: securityId,
                quantityN: quantityN,
                quantityD: quantityD,
                memo: memo,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PostingsTable, PostingRow>(table),
                  BaseReferences<_$AppDatabase, $PostingsTable, PostingRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PostingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PostingsTable,
      PostingRow,
      $$PostingsTableFilterComposer,
      $$PostingsTableOrderingComposer,
      $$PostingsTableAnnotationComposer,
      $$PostingsTableCreateCompanionBuilder,
      $$PostingsTableUpdateCompanionBuilder,
      (PostingRow, BaseReferences<_$AppDatabase, $PostingsTable, PostingRow>),
      PostingRow,
      PrefetchHooks Function()
    >;
typedef $$BudgetsTableCreateCompanionBuilder =
    BudgetsCompanion Function({
      required String id,
      required String name,
      required String scope,
      required BigInt limitMinor,
      required String currencyCode,
      required String startMonth,
      Value<String?> endMonth,
      Value<String?> categoryId,
      Value<String> rollover,
      Value<BigInt?> rolloverCapMinor,
      Value<bool> active,
      Value<int> rowid,
    });
typedef $$BudgetsTableUpdateCompanionBuilder =
    BudgetsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> scope,
      Value<BigInt> limitMinor,
      Value<String> currencyCode,
      Value<String> startMonth,
      Value<String?> endMonth,
      Value<String?> categoryId,
      Value<String> rollover,
      Value<BigInt?> rolloverCapMinor,
      Value<bool> active,
      Value<int> rowid,
    });

class $$BudgetsTableFilterComposer
    extends Composer<_$AppDatabase, $BudgetsTable> {
  $$BudgetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scope => $composableBuilder(
    column: $table.scope,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<BigInt, BigInt, String> get limitMinor =>
      $composableBuilder(
        column: $table.limitMinor,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startMonth => $composableBuilder(
    column: $table.startMonth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get endMonth => $composableBuilder(
    column: $table.endMonth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rollover => $composableBuilder(
    column: $table.rollover,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<BigInt?, BigInt, String>
  get rolloverCapMinor => $composableBuilder(
    column: $table.rolloverCapMinor,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BudgetsTableOrderingComposer
    extends Composer<_$AppDatabase, $BudgetsTable> {
  $$BudgetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scope => $composableBuilder(
    column: $table.scope,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get limitMinor => $composableBuilder(
    column: $table.limitMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startMonth => $composableBuilder(
    column: $table.startMonth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endMonth => $composableBuilder(
    column: $table.endMonth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rollover => $composableBuilder(
    column: $table.rollover,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rolloverCapMinor => $composableBuilder(
    column: $table.rolloverCapMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BudgetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BudgetsTable> {
  $$BudgetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get scope =>
      $composableBuilder(column: $table.scope, builder: (column) => column);

  GeneratedColumnWithTypeConverter<BigInt, String> get limitMinor =>
      $composableBuilder(
        column: $table.limitMinor,
        builder: (column) => column,
      );

  GeneratedColumn<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get startMonth => $composableBuilder(
    column: $table.startMonth,
    builder: (column) => column,
  );

  GeneratedColumn<String> get endMonth =>
      $composableBuilder(column: $table.endMonth, builder: (column) => column);

  GeneratedColumn<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rollover =>
      $composableBuilder(column: $table.rollover, builder: (column) => column);

  GeneratedColumnWithTypeConverter<BigInt?, String> get rolloverCapMinor =>
      $composableBuilder(
        column: $table.rolloverCapMinor,
        builder: (column) => column,
      );

  GeneratedColumn<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => column);
}

class $$BudgetsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BudgetsTable,
          BudgetRow,
          $$BudgetsTableFilterComposer,
          $$BudgetsTableOrderingComposer,
          $$BudgetsTableAnnotationComposer,
          $$BudgetsTableCreateCompanionBuilder,
          $$BudgetsTableUpdateCompanionBuilder,
          (BudgetRow, BaseReferences<_$AppDatabase, $BudgetsTable, BudgetRow>),
          BudgetRow,
          PrefetchHooks Function()
        > {
  $$BudgetsTableTableManager(_$AppDatabase db, $BudgetsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BudgetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BudgetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BudgetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> scope = const Value.absent(),
                Value<BigInt> limitMinor = const Value.absent(),
                Value<String> currencyCode = const Value.absent(),
                Value<String> startMonth = const Value.absent(),
                Value<String?> endMonth = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<String> rollover = const Value.absent(),
                Value<BigInt?> rolloverCapMinor = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BudgetsCompanion(
                id: id,
                name: name,
                scope: scope,
                limitMinor: limitMinor,
                currencyCode: currencyCode,
                startMonth: startMonth,
                endMonth: endMonth,
                categoryId: categoryId,
                rollover: rollover,
                rolloverCapMinor: rolloverCapMinor,
                active: active,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String scope,
                required BigInt limitMinor,
                required String currencyCode,
                required String startMonth,
                Value<String?> endMonth = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<String> rollover = const Value.absent(),
                Value<BigInt?> rolloverCapMinor = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BudgetsCompanion.insert(
                id: id,
                name: name,
                scope: scope,
                limitMinor: limitMinor,
                currencyCode: currencyCode,
                startMonth: startMonth,
                endMonth: endMonth,
                categoryId: categoryId,
                rollover: rollover,
                rolloverCapMinor: rolloverCapMinor,
                active: active,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BudgetsTable, BudgetRow>(table),
                  BaseReferences<_$AppDatabase, $BudgetsTable, BudgetRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BudgetsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BudgetsTable,
      BudgetRow,
      $$BudgetsTableFilterComposer,
      $$BudgetsTableOrderingComposer,
      $$BudgetsTableAnnotationComposer,
      $$BudgetsTableCreateCompanionBuilder,
      $$BudgetsTableUpdateCompanionBuilder,
      (BudgetRow, BaseReferences<_$AppDatabase, $BudgetsTable, BudgetRow>),
      BudgetRow,
      PrefetchHooks Function()
    >;
typedef $$ScheduledEventsTableCreateCompanionBuilder =
    ScheduledEventsCompanion Function({
      required String id,
      required String name,
      required String direction,
      required String currencyCode,
      required String cadence,
      required DateTime anchorDate,
      Value<BigInt?> amountMinor,
      Value<BigInt?> amountLowMinor,
      Value<BigInt?> amountHighMinor,
      Value<int> intervalValue,
      Value<String> monthEndPolicy,
      Value<DateTime?> endDate,
      Value<String?> paymentAccountId,
      Value<String?> categoryId,
      Value<bool> autoPost,
      Value<String?> notes,
      Value<String> status,
      Value<String> skippedMonthsJson,
      Value<String> skippedDatesJson,
      Value<String> amountOverridesJson,
      Value<int> rowid,
    });
typedef $$ScheduledEventsTableUpdateCompanionBuilder =
    ScheduledEventsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> direction,
      Value<String> currencyCode,
      Value<String> cadence,
      Value<DateTime> anchorDate,
      Value<BigInt?> amountMinor,
      Value<BigInt?> amountLowMinor,
      Value<BigInt?> amountHighMinor,
      Value<int> intervalValue,
      Value<String> monthEndPolicy,
      Value<DateTime?> endDate,
      Value<String?> paymentAccountId,
      Value<String?> categoryId,
      Value<bool> autoPost,
      Value<String?> notes,
      Value<String> status,
      Value<String> skippedMonthsJson,
      Value<String> skippedDatesJson,
      Value<String> amountOverridesJson,
      Value<int> rowid,
    });

class $$ScheduledEventsTableFilterComposer
    extends Composer<_$AppDatabase, $ScheduledEventsTable> {
  $$ScheduledEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get direction => $composableBuilder(
    column: $table.direction,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cadence => $composableBuilder(
    column: $table.cadence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get anchorDate => $composableBuilder(
    column: $table.anchorDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<BigInt?, BigInt, String> get amountMinor =>
      $composableBuilder(
        column: $table.amountMinor,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<BigInt?, BigInt, String> get amountLowMinor =>
      $composableBuilder(
        column: $table.amountLowMinor,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<BigInt?, BigInt, String> get amountHighMinor =>
      $composableBuilder(
        column: $table.amountHighMinor,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get intervalValue => $composableBuilder(
    column: $table.intervalValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get monthEndPolicy => $composableBuilder(
    column: $table.monthEndPolicy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paymentAccountId => $composableBuilder(
    column: $table.paymentAccountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get autoPost => $composableBuilder(
    column: $table.autoPost,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get skippedMonthsJson => $composableBuilder(
    column: $table.skippedMonthsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get skippedDatesJson => $composableBuilder(
    column: $table.skippedDatesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get amountOverridesJson => $composableBuilder(
    column: $table.amountOverridesJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ScheduledEventsTableOrderingComposer
    extends Composer<_$AppDatabase, $ScheduledEventsTable> {
  $$ScheduledEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get direction => $composableBuilder(
    column: $table.direction,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cadence => $composableBuilder(
    column: $table.cadence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get anchorDate => $composableBuilder(
    column: $table.anchorDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get amountLowMinor => $composableBuilder(
    column: $table.amountLowMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get amountHighMinor => $composableBuilder(
    column: $table.amountHighMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get intervalValue => $composableBuilder(
    column: $table.intervalValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get monthEndPolicy => $composableBuilder(
    column: $table.monthEndPolicy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paymentAccountId => $composableBuilder(
    column: $table.paymentAccountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get autoPost => $composableBuilder(
    column: $table.autoPost,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get skippedMonthsJson => $composableBuilder(
    column: $table.skippedMonthsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get skippedDatesJson => $composableBuilder(
    column: $table.skippedDatesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get amountOverridesJson => $composableBuilder(
    column: $table.amountOverridesJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ScheduledEventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ScheduledEventsTable> {
  $$ScheduledEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get direction =>
      $composableBuilder(column: $table.direction, builder: (column) => column);

  GeneratedColumn<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cadence =>
      $composableBuilder(column: $table.cadence, builder: (column) => column);

  GeneratedColumn<DateTime> get anchorDate => $composableBuilder(
    column: $table.anchorDate,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<BigInt?, String> get amountMinor =>
      $composableBuilder(
        column: $table.amountMinor,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<BigInt?, String> get amountLowMinor =>
      $composableBuilder(
        column: $table.amountLowMinor,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<BigInt?, String> get amountHighMinor =>
      $composableBuilder(
        column: $table.amountHighMinor,
        builder: (column) => column,
      );

  GeneratedColumn<int> get intervalValue => $composableBuilder(
    column: $table.intervalValue,
    builder: (column) => column,
  );

  GeneratedColumn<String> get monthEndPolicy => $composableBuilder(
    column: $table.monthEndPolicy,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get endDate =>
      $composableBuilder(column: $table.endDate, builder: (column) => column);

  GeneratedColumn<String> get paymentAccountId => $composableBuilder(
    column: $table.paymentAccountId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get autoPost =>
      $composableBuilder(column: $table.autoPost, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get skippedMonthsJson => $composableBuilder(
    column: $table.skippedMonthsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get skippedDatesJson => $composableBuilder(
    column: $table.skippedDatesJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get amountOverridesJson => $composableBuilder(
    column: $table.amountOverridesJson,
    builder: (column) => column,
  );
}

class $$ScheduledEventsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ScheduledEventsTable,
          ScheduledEventRow,
          $$ScheduledEventsTableFilterComposer,
          $$ScheduledEventsTableOrderingComposer,
          $$ScheduledEventsTableAnnotationComposer,
          $$ScheduledEventsTableCreateCompanionBuilder,
          $$ScheduledEventsTableUpdateCompanionBuilder,
          (
            ScheduledEventRow,
            BaseReferences<
              _$AppDatabase,
              $ScheduledEventsTable,
              ScheduledEventRow
            >,
          ),
          ScheduledEventRow,
          PrefetchHooks Function()
        > {
  $$ScheduledEventsTableTableManager(
    _$AppDatabase db,
    $ScheduledEventsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ScheduledEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ScheduledEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ScheduledEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> direction = const Value.absent(),
                Value<String> currencyCode = const Value.absent(),
                Value<String> cadence = const Value.absent(),
                Value<DateTime> anchorDate = const Value.absent(),
                Value<BigInt?> amountMinor = const Value.absent(),
                Value<BigInt?> amountLowMinor = const Value.absent(),
                Value<BigInt?> amountHighMinor = const Value.absent(),
                Value<int> intervalValue = const Value.absent(),
                Value<String> monthEndPolicy = const Value.absent(),
                Value<DateTime?> endDate = const Value.absent(),
                Value<String?> paymentAccountId = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<bool> autoPost = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> skippedMonthsJson = const Value.absent(),
                Value<String> skippedDatesJson = const Value.absent(),
                Value<String> amountOverridesJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ScheduledEventsCompanion(
                id: id,
                name: name,
                direction: direction,
                currencyCode: currencyCode,
                cadence: cadence,
                anchorDate: anchorDate,
                amountMinor: amountMinor,
                amountLowMinor: amountLowMinor,
                amountHighMinor: amountHighMinor,
                intervalValue: intervalValue,
                monthEndPolicy: monthEndPolicy,
                endDate: endDate,
                paymentAccountId: paymentAccountId,
                categoryId: categoryId,
                autoPost: autoPost,
                notes: notes,
                status: status,
                skippedMonthsJson: skippedMonthsJson,
                skippedDatesJson: skippedDatesJson,
                amountOverridesJson: amountOverridesJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String direction,
                required String currencyCode,
                required String cadence,
                required DateTime anchorDate,
                Value<BigInt?> amountMinor = const Value.absent(),
                Value<BigInt?> amountLowMinor = const Value.absent(),
                Value<BigInt?> amountHighMinor = const Value.absent(),
                Value<int> intervalValue = const Value.absent(),
                Value<String> monthEndPolicy = const Value.absent(),
                Value<DateTime?> endDate = const Value.absent(),
                Value<String?> paymentAccountId = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<bool> autoPost = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> skippedMonthsJson = const Value.absent(),
                Value<String> skippedDatesJson = const Value.absent(),
                Value<String> amountOverridesJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ScheduledEventsCompanion.insert(
                id: id,
                name: name,
                direction: direction,
                currencyCode: currencyCode,
                cadence: cadence,
                anchorDate: anchorDate,
                amountMinor: amountMinor,
                amountLowMinor: amountLowMinor,
                amountHighMinor: amountHighMinor,
                intervalValue: intervalValue,
                monthEndPolicy: monthEndPolicy,
                endDate: endDate,
                paymentAccountId: paymentAccountId,
                categoryId: categoryId,
                autoPost: autoPost,
                notes: notes,
                status: status,
                skippedMonthsJson: skippedMonthsJson,
                skippedDatesJson: skippedDatesJson,
                amountOverridesJson: amountOverridesJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ScheduledEventsTable, ScheduledEventRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $ScheduledEventsTable,
                    ScheduledEventRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ScheduledEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ScheduledEventsTable,
      ScheduledEventRow,
      $$ScheduledEventsTableFilterComposer,
      $$ScheduledEventsTableOrderingComposer,
      $$ScheduledEventsTableAnnotationComposer,
      $$ScheduledEventsTableCreateCompanionBuilder,
      $$ScheduledEventsTableUpdateCompanionBuilder,
      (
        ScheduledEventRow,
        BaseReferences<_$AppDatabase, $ScheduledEventsTable, ScheduledEventRow>,
      ),
      ScheduledEventRow,
      PrefetchHooks Function()
    >;
typedef $$GoalsTableCreateCompanionBuilder =
    GoalsCompanion Function({
      required String id,
      required String name,
      required BigInt targetMinor,
      required DateTime targetDate,
      Value<int> priority,
      Value<BigInt> reservedMinor,
      Value<String> fundingAccountIdsJson,
      Value<String?> notes,
      Value<String> status,
      Value<int> rowid,
    });
typedef $$GoalsTableUpdateCompanionBuilder =
    GoalsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<BigInt> targetMinor,
      Value<DateTime> targetDate,
      Value<int> priority,
      Value<BigInt> reservedMinor,
      Value<String> fundingAccountIdsJson,
      Value<String?> notes,
      Value<String> status,
      Value<int> rowid,
    });

class $$GoalsTableFilterComposer extends Composer<_$AppDatabase, $GoalsTable> {
  $$GoalsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<BigInt, BigInt, String> get targetMinor =>
      $composableBuilder(
        column: $table.targetMinor,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<DateTime> get targetDate => $composableBuilder(
    column: $table.targetDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<BigInt, BigInt, String> get reservedMinor =>
      $composableBuilder(
        column: $table.reservedMinor,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get fundingAccountIdsJson => $composableBuilder(
    column: $table.fundingAccountIdsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );
}

class $$GoalsTableOrderingComposer
    extends Composer<_$AppDatabase, $GoalsTable> {
  $$GoalsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetMinor => $composableBuilder(
    column: $table.targetMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get targetDate => $composableBuilder(
    column: $table.targetDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reservedMinor => $composableBuilder(
    column: $table.reservedMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fundingAccountIdsJson => $composableBuilder(
    column: $table.fundingAccountIdsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GoalsTableAnnotationComposer
    extends Composer<_$AppDatabase, $GoalsTable> {
  $$GoalsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumnWithTypeConverter<BigInt, String> get targetMinor =>
      $composableBuilder(
        column: $table.targetMinor,
        builder: (column) => column,
      );

  GeneratedColumn<DateTime> get targetDate => $composableBuilder(
    column: $table.targetDate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumnWithTypeConverter<BigInt, String> get reservedMinor =>
      $composableBuilder(
        column: $table.reservedMinor,
        builder: (column) => column,
      );

  GeneratedColumn<String> get fundingAccountIdsJson => $composableBuilder(
    column: $table.fundingAccountIdsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);
}

class $$GoalsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GoalsTable,
          GoalRow,
          $$GoalsTableFilterComposer,
          $$GoalsTableOrderingComposer,
          $$GoalsTableAnnotationComposer,
          $$GoalsTableCreateCompanionBuilder,
          $$GoalsTableUpdateCompanionBuilder,
          (GoalRow, BaseReferences<_$AppDatabase, $GoalsTable, GoalRow>),
          GoalRow,
          PrefetchHooks Function()
        > {
  $$GoalsTableTableManager(_$AppDatabase db, $GoalsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GoalsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GoalsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GoalsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<BigInt> targetMinor = const Value.absent(),
                Value<DateTime> targetDate = const Value.absent(),
                Value<int> priority = const Value.absent(),
                Value<BigInt> reservedMinor = const Value.absent(),
                Value<String> fundingAccountIdsJson = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GoalsCompanion(
                id: id,
                name: name,
                targetMinor: targetMinor,
                targetDate: targetDate,
                priority: priority,
                reservedMinor: reservedMinor,
                fundingAccountIdsJson: fundingAccountIdsJson,
                notes: notes,
                status: status,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required BigInt targetMinor,
                required DateTime targetDate,
                Value<int> priority = const Value.absent(),
                Value<BigInt> reservedMinor = const Value.absent(),
                Value<String> fundingAccountIdsJson = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GoalsCompanion.insert(
                id: id,
                name: name,
                targetMinor: targetMinor,
                targetDate: targetDate,
                priority: priority,
                reservedMinor: reservedMinor,
                fundingAccountIdsJson: fundingAccountIdsJson,
                notes: notes,
                status: status,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$GoalsTable, GoalRow>(table),
                  BaseReferences<_$AppDatabase, $GoalsTable, GoalRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$GoalsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GoalsTable,
      GoalRow,
      $$GoalsTableFilterComposer,
      $$GoalsTableOrderingComposer,
      $$GoalsTableAnnotationComposer,
      $$GoalsTableCreateCompanionBuilder,
      $$GoalsTableUpdateCompanionBuilder,
      (GoalRow, BaseReferences<_$AppDatabase, $GoalsTable, GoalRow>),
      GoalRow,
      PrefetchHooks Function()
    >;
typedef $$DebtContractsTableCreateCompanionBuilder =
    DebtContractsCompanion Function({
      required String liabilityAccountId,
      required BigInt principalOriginalMinor,
      required String aprPercent,
      required String method,
      required int termMonths,
      required DateTime startDate,
      Value<DateTime?> firstPaymentDate,
      Value<int?> repaymentDay,
      Value<BigInt?> monthlyFeeMinor,
      Value<String> basis,
      Value<String?> prepayFeePercent,
      Value<String?> scheduleCacheJson,
      Value<String?> notes,
      Value<int> rowid,
    });
typedef $$DebtContractsTableUpdateCompanionBuilder =
    DebtContractsCompanion Function({
      Value<String> liabilityAccountId,
      Value<BigInt> principalOriginalMinor,
      Value<String> aprPercent,
      Value<String> method,
      Value<int> termMonths,
      Value<DateTime> startDate,
      Value<DateTime?> firstPaymentDate,
      Value<int?> repaymentDay,
      Value<BigInt?> monthlyFeeMinor,
      Value<String> basis,
      Value<String?> prepayFeePercent,
      Value<String?> scheduleCacheJson,
      Value<String?> notes,
      Value<int> rowid,
    });

class $$DebtContractsTableFilterComposer
    extends Composer<_$AppDatabase, $DebtContractsTable> {
  $$DebtContractsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get liabilityAccountId => $composableBuilder(
    column: $table.liabilityAccountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<BigInt, BigInt, String>
  get principalOriginalMinor => $composableBuilder(
    column: $table.principalOriginalMinor,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get aprPercent => $composableBuilder(
    column: $table.aprPercent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get method => $composableBuilder(
    column: $table.method,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get termMonths => $composableBuilder(
    column: $table.termMonths,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get firstPaymentDate => $composableBuilder(
    column: $table.firstPaymentDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get repaymentDay => $composableBuilder(
    column: $table.repaymentDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<BigInt?, BigInt, String> get monthlyFeeMinor =>
      $composableBuilder(
        column: $table.monthlyFeeMinor,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get basis => $composableBuilder(
    column: $table.basis,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get prepayFeePercent => $composableBuilder(
    column: $table.prepayFeePercent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scheduleCacheJson => $composableBuilder(
    column: $table.scheduleCacheJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DebtContractsTableOrderingComposer
    extends Composer<_$AppDatabase, $DebtContractsTable> {
  $$DebtContractsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get liabilityAccountId => $composableBuilder(
    column: $table.liabilityAccountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get principalOriginalMinor => $composableBuilder(
    column: $table.principalOriginalMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get aprPercent => $composableBuilder(
    column: $table.aprPercent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get method => $composableBuilder(
    column: $table.method,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get termMonths => $composableBuilder(
    column: $table.termMonths,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get firstPaymentDate => $composableBuilder(
    column: $table.firstPaymentDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get repaymentDay => $composableBuilder(
    column: $table.repaymentDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get monthlyFeeMinor => $composableBuilder(
    column: $table.monthlyFeeMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get basis => $composableBuilder(
    column: $table.basis,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get prepayFeePercent => $composableBuilder(
    column: $table.prepayFeePercent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scheduleCacheJson => $composableBuilder(
    column: $table.scheduleCacheJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DebtContractsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DebtContractsTable> {
  $$DebtContractsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get liabilityAccountId => $composableBuilder(
    column: $table.liabilityAccountId,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<BigInt, String> get principalOriginalMinor =>
      $composableBuilder(
        column: $table.principalOriginalMinor,
        builder: (column) => column,
      );

  GeneratedColumn<String> get aprPercent => $composableBuilder(
    column: $table.aprPercent,
    builder: (column) => column,
  );

  GeneratedColumn<String> get method =>
      $composableBuilder(column: $table.method, builder: (column) => column);

  GeneratedColumn<int> get termMonths => $composableBuilder(
    column: $table.termMonths,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<DateTime> get firstPaymentDate => $composableBuilder(
    column: $table.firstPaymentDate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get repaymentDay => $composableBuilder(
    column: $table.repaymentDay,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<BigInt?, String> get monthlyFeeMinor =>
      $composableBuilder(
        column: $table.monthlyFeeMinor,
        builder: (column) => column,
      );

  GeneratedColumn<String> get basis =>
      $composableBuilder(column: $table.basis, builder: (column) => column);

  GeneratedColumn<String> get prepayFeePercent => $composableBuilder(
    column: $table.prepayFeePercent,
    builder: (column) => column,
  );

  GeneratedColumn<String> get scheduleCacheJson => $composableBuilder(
    column: $table.scheduleCacheJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);
}

class $$DebtContractsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DebtContractsTable,
          DebtContractRow,
          $$DebtContractsTableFilterComposer,
          $$DebtContractsTableOrderingComposer,
          $$DebtContractsTableAnnotationComposer,
          $$DebtContractsTableCreateCompanionBuilder,
          $$DebtContractsTableUpdateCompanionBuilder,
          (
            DebtContractRow,
            BaseReferences<_$AppDatabase, $DebtContractsTable, DebtContractRow>,
          ),
          DebtContractRow,
          PrefetchHooks Function()
        > {
  $$DebtContractsTableTableManager(_$AppDatabase db, $DebtContractsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DebtContractsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DebtContractsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DebtContractsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> liabilityAccountId = const Value.absent(),
                Value<BigInt> principalOriginalMinor = const Value.absent(),
                Value<String> aprPercent = const Value.absent(),
                Value<String> method = const Value.absent(),
                Value<int> termMonths = const Value.absent(),
                Value<DateTime> startDate = const Value.absent(),
                Value<DateTime?> firstPaymentDate = const Value.absent(),
                Value<int?> repaymentDay = const Value.absent(),
                Value<BigInt?> monthlyFeeMinor = const Value.absent(),
                Value<String> basis = const Value.absent(),
                Value<String?> prepayFeePercent = const Value.absent(),
                Value<String?> scheduleCacheJson = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DebtContractsCompanion(
                liabilityAccountId: liabilityAccountId,
                principalOriginalMinor: principalOriginalMinor,
                aprPercent: aprPercent,
                method: method,
                termMonths: termMonths,
                startDate: startDate,
                firstPaymentDate: firstPaymentDate,
                repaymentDay: repaymentDay,
                monthlyFeeMinor: monthlyFeeMinor,
                basis: basis,
                prepayFeePercent: prepayFeePercent,
                scheduleCacheJson: scheduleCacheJson,
                notes: notes,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String liabilityAccountId,
                required BigInt principalOriginalMinor,
                required String aprPercent,
                required String method,
                required int termMonths,
                required DateTime startDate,
                Value<DateTime?> firstPaymentDate = const Value.absent(),
                Value<int?> repaymentDay = const Value.absent(),
                Value<BigInt?> monthlyFeeMinor = const Value.absent(),
                Value<String> basis = const Value.absent(),
                Value<String?> prepayFeePercent = const Value.absent(),
                Value<String?> scheduleCacheJson = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DebtContractsCompanion.insert(
                liabilityAccountId: liabilityAccountId,
                principalOriginalMinor: principalOriginalMinor,
                aprPercent: aprPercent,
                method: method,
                termMonths: termMonths,
                startDate: startDate,
                firstPaymentDate: firstPaymentDate,
                repaymentDay: repaymentDay,
                monthlyFeeMinor: monthlyFeeMinor,
                basis: basis,
                prepayFeePercent: prepayFeePercent,
                scheduleCacheJson: scheduleCacheJson,
                notes: notes,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DebtContractsTable, DebtContractRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $DebtContractsTable,
                    DebtContractRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DebtContractsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DebtContractsTable,
      DebtContractRow,
      $$DebtContractsTableFilterComposer,
      $$DebtContractsTableOrderingComposer,
      $$DebtContractsTableAnnotationComposer,
      $$DebtContractsTableCreateCompanionBuilder,
      $$DebtContractsTableUpdateCompanionBuilder,
      (
        DebtContractRow,
        BaseReferences<_$AppDatabase, $DebtContractsTable, DebtContractRow>,
      ),
      DebtContractRow,
      PrefetchHooks Function()
    >;
typedef $$ValuationsTableCreateCompanionBuilder =
    ValuationsCompanion Function({
      Value<int> id,
      required String accountId,
      required DateTime date,
      required String kind,
      Value<BigInt?> unitPriceN,
      Value<BigInt?> unitPriceD,
      Value<BigInt?> totalValueMinor,
      Value<String> source,
      Value<String?> note,
    });
typedef $$ValuationsTableUpdateCompanionBuilder =
    ValuationsCompanion Function({
      Value<int> id,
      Value<String> accountId,
      Value<DateTime> date,
      Value<String> kind,
      Value<BigInt?> unitPriceN,
      Value<BigInt?> unitPriceD,
      Value<BigInt?> totalValueMinor,
      Value<String> source,
      Value<String?> note,
    });

class $$ValuationsTableFilterComposer
    extends Composer<_$AppDatabase, $ValuationsTable> {
  $$ValuationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<BigInt?, BigInt, String> get unitPriceN =>
      $composableBuilder(
        column: $table.unitPriceN,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<BigInt?, BigInt, String> get unitPriceD =>
      $composableBuilder(
        column: $table.unitPriceD,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<BigInt?, BigInt, String> get totalValueMinor =>
      $composableBuilder(
        column: $table.totalValueMinor,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ValuationsTableOrderingComposer
    extends Composer<_$AppDatabase, $ValuationsTable> {
  $$ValuationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unitPriceN => $composableBuilder(
    column: $table.unitPriceN,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unitPriceD => $composableBuilder(
    column: $table.unitPriceD,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get totalValueMinor => $composableBuilder(
    column: $table.totalValueMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ValuationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ValuationsTable> {
  $$ValuationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumnWithTypeConverter<BigInt?, String> get unitPriceN =>
      $composableBuilder(
        column: $table.unitPriceN,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<BigInt?, String> get unitPriceD =>
      $composableBuilder(
        column: $table.unitPriceD,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<BigInt?, String> get totalValueMinor =>
      $composableBuilder(
        column: $table.totalValueMinor,
        builder: (column) => column,
      );

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);
}

class $$ValuationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ValuationsTable,
          ValuationRow,
          $$ValuationsTableFilterComposer,
          $$ValuationsTableOrderingComposer,
          $$ValuationsTableAnnotationComposer,
          $$ValuationsTableCreateCompanionBuilder,
          $$ValuationsTableUpdateCompanionBuilder,
          (
            ValuationRow,
            BaseReferences<_$AppDatabase, $ValuationsTable, ValuationRow>,
          ),
          ValuationRow,
          PrefetchHooks Function()
        > {
  $$ValuationsTableTableManager(_$AppDatabase db, $ValuationsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ValuationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ValuationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ValuationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> accountId = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<BigInt?> unitPriceN = const Value.absent(),
                Value<BigInt?> unitPriceD = const Value.absent(),
                Value<BigInt?> totalValueMinor = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String?> note = const Value.absent(),
              }) => ValuationsCompanion(
                id: id,
                accountId: accountId,
                date: date,
                kind: kind,
                unitPriceN: unitPriceN,
                unitPriceD: unitPriceD,
                totalValueMinor: totalValueMinor,
                source: source,
                note: note,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String accountId,
                required DateTime date,
                required String kind,
                Value<BigInt?> unitPriceN = const Value.absent(),
                Value<BigInt?> unitPriceD = const Value.absent(),
                Value<BigInt?> totalValueMinor = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String?> note = const Value.absent(),
              }) => ValuationsCompanion.insert(
                id: id,
                accountId: accountId,
                date: date,
                kind: kind,
                unitPriceN: unitPriceN,
                unitPriceD: unitPriceD,
                totalValueMinor: totalValueMinor,
                source: source,
                note: note,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ValuationsTable, ValuationRow>(table),
                  BaseReferences<_$AppDatabase, $ValuationsTable, ValuationRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ValuationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ValuationsTable,
      ValuationRow,
      $$ValuationsTableFilterComposer,
      $$ValuationsTableOrderingComposer,
      $$ValuationsTableAnnotationComposer,
      $$ValuationsTableCreateCompanionBuilder,
      $$ValuationsTableUpdateCompanionBuilder,
      (
        ValuationRow,
        BaseReferences<_$AppDatabase, $ValuationsTable, ValuationRow>,
      ),
      ValuationRow,
      PrefetchHooks Function()
    >;
typedef $$FxRatesTableCreateCompanionBuilder =
    FxRatesCompanion Function({
      Value<int> id,
      required String baseCcy,
      required String quoteCcy,
      required DateTime date,
      required BigInt rateN,
      required BigInt rateD,
      Value<String> source,
    });
typedef $$FxRatesTableUpdateCompanionBuilder =
    FxRatesCompanion Function({
      Value<int> id,
      Value<String> baseCcy,
      Value<String> quoteCcy,
      Value<DateTime> date,
      Value<BigInt> rateN,
      Value<BigInt> rateD,
      Value<String> source,
    });

class $$FxRatesTableFilterComposer
    extends Composer<_$AppDatabase, $FxRatesTable> {
  $$FxRatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get baseCcy => $composableBuilder(
    column: $table.baseCcy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get quoteCcy => $composableBuilder(
    column: $table.quoteCcy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<BigInt, BigInt, String> get rateN =>
      $composableBuilder(
        column: $table.rateN,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<BigInt, BigInt, String> get rateD =>
      $composableBuilder(
        column: $table.rateD,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FxRatesTableOrderingComposer
    extends Composer<_$AppDatabase, $FxRatesTable> {
  $$FxRatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get baseCcy => $composableBuilder(
    column: $table.baseCcy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get quoteCcy => $composableBuilder(
    column: $table.quoteCcy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rateN => $composableBuilder(
    column: $table.rateN,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rateD => $composableBuilder(
    column: $table.rateD,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FxRatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $FxRatesTable> {
  $$FxRatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get baseCcy =>
      $composableBuilder(column: $table.baseCcy, builder: (column) => column);

  GeneratedColumn<String> get quoteCcy =>
      $composableBuilder(column: $table.quoteCcy, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumnWithTypeConverter<BigInt, String> get rateN =>
      $composableBuilder(column: $table.rateN, builder: (column) => column);

  GeneratedColumnWithTypeConverter<BigInt, String> get rateD =>
      $composableBuilder(column: $table.rateD, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);
}

class $$FxRatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FxRatesTable,
          FxRateRow,
          $$FxRatesTableFilterComposer,
          $$FxRatesTableOrderingComposer,
          $$FxRatesTableAnnotationComposer,
          $$FxRatesTableCreateCompanionBuilder,
          $$FxRatesTableUpdateCompanionBuilder,
          (FxRateRow, BaseReferences<_$AppDatabase, $FxRatesTable, FxRateRow>),
          FxRateRow,
          PrefetchHooks Function()
        > {
  $$FxRatesTableTableManager(_$AppDatabase db, $FxRatesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FxRatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FxRatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FxRatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> baseCcy = const Value.absent(),
                Value<String> quoteCcy = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<BigInt> rateN = const Value.absent(),
                Value<BigInt> rateD = const Value.absent(),
                Value<String> source = const Value.absent(),
              }) => FxRatesCompanion(
                id: id,
                baseCcy: baseCcy,
                quoteCcy: quoteCcy,
                date: date,
                rateN: rateN,
                rateD: rateD,
                source: source,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String baseCcy,
                required String quoteCcy,
                required DateTime date,
                required BigInt rateN,
                required BigInt rateD,
                Value<String> source = const Value.absent(),
              }) => FxRatesCompanion.insert(
                id: id,
                baseCcy: baseCcy,
                quoteCcy: quoteCcy,
                date: date,
                rateN: rateN,
                rateD: rateD,
                source: source,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FxRatesTable, FxRateRow>(table),
                  BaseReferences<_$AppDatabase, $FxRatesTable, FxRateRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FxRatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FxRatesTable,
      FxRateRow,
      $$FxRatesTableFilterComposer,
      $$FxRatesTableOrderingComposer,
      $$FxRatesTableAnnotationComposer,
      $$FxRatesTableCreateCompanionBuilder,
      $$FxRatesTableUpdateCompanionBuilder,
      (FxRateRow, BaseReferences<_$AppDatabase, $FxRatesTable, FxRateRow>),
      FxRateRow,
      PrefetchHooks Function()
    >;
typedef $$SnapshotsTableCreateCompanionBuilder =
    SnapshotsCompanion Function({
      required String month,
      required String payloadJson,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$SnapshotsTableUpdateCompanionBuilder =
    SnapshotsCompanion Function({
      Value<String> month,
      Value<String> payloadJson,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$SnapshotsTableFilterComposer
    extends Composer<_$AppDatabase, $SnapshotsTable> {
  $$SnapshotsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get month => $composableBuilder(
    column: $table.month,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SnapshotsTableOrderingComposer
    extends Composer<_$AppDatabase, $SnapshotsTable> {
  $$SnapshotsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get month => $composableBuilder(
    column: $table.month,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SnapshotsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SnapshotsTable> {
  $$SnapshotsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get month =>
      $composableBuilder(column: $table.month, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SnapshotsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SnapshotsTable,
          SnapshotRow,
          $$SnapshotsTableFilterComposer,
          $$SnapshotsTableOrderingComposer,
          $$SnapshotsTableAnnotationComposer,
          $$SnapshotsTableCreateCompanionBuilder,
          $$SnapshotsTableUpdateCompanionBuilder,
          (
            SnapshotRow,
            BaseReferences<_$AppDatabase, $SnapshotsTable, SnapshotRow>,
          ),
          SnapshotRow,
          PrefetchHooks Function()
        > {
  $$SnapshotsTableTableManager(_$AppDatabase db, $SnapshotsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SnapshotsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SnapshotsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SnapshotsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> month = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SnapshotsCompanion(
                month: month,
                payloadJson: payloadJson,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String month,
                required String payloadJson,
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SnapshotsCompanion.insert(
                month: month,
                payloadJson: payloadJson,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SnapshotsTable, SnapshotRow>(table),
                  BaseReferences<_$AppDatabase, $SnapshotsTable, SnapshotRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SnapshotsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SnapshotsTable,
      SnapshotRow,
      $$SnapshotsTableFilterComposer,
      $$SnapshotsTableOrderingComposer,
      $$SnapshotsTableAnnotationComposer,
      $$SnapshotsTableCreateCompanionBuilder,
      $$SnapshotsTableUpdateCompanionBuilder,
      (
        SnapshotRow,
        BaseReferences<_$AppDatabase, $SnapshotsTable, SnapshotRow>,
      ),
      SnapshotRow,
      PrefetchHooks Function()
    >;
typedef $$ImportBatchesTableCreateCompanionBuilder =
    ImportBatchesCompanion Function({
      required String id,
      required String source,
      required String filename,
      Value<DateTime> importedAt,
      required String parserVersion,
      Value<String> status,
      Value<String> countsJson,
      Value<int> rowid,
    });
typedef $$ImportBatchesTableUpdateCompanionBuilder =
    ImportBatchesCompanion Function({
      Value<String> id,
      Value<String> source,
      Value<String> filename,
      Value<DateTime> importedAt,
      Value<String> parserVersion,
      Value<String> status,
      Value<String> countsJson,
      Value<int> rowid,
    });

class $$ImportBatchesTableFilterComposer
    extends Composer<_$AppDatabase, $ImportBatchesTable> {
  $$ImportBatchesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filename => $composableBuilder(
    column: $table.filename,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get importedAt => $composableBuilder(
    column: $table.importedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get parserVersion => $composableBuilder(
    column: $table.parserVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get countsJson => $composableBuilder(
    column: $table.countsJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ImportBatchesTableOrderingComposer
    extends Composer<_$AppDatabase, $ImportBatchesTable> {
  $$ImportBatchesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filename => $composableBuilder(
    column: $table.filename,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get importedAt => $composableBuilder(
    column: $table.importedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get parserVersion => $composableBuilder(
    column: $table.parserVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get countsJson => $composableBuilder(
    column: $table.countsJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ImportBatchesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ImportBatchesTable> {
  $$ImportBatchesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get filename =>
      $composableBuilder(column: $table.filename, builder: (column) => column);

  GeneratedColumn<DateTime> get importedAt => $composableBuilder(
    column: $table.importedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get parserVersion => $composableBuilder(
    column: $table.parserVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get countsJson => $composableBuilder(
    column: $table.countsJson,
    builder: (column) => column,
  );
}

class $$ImportBatchesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ImportBatchesTable,
          ImportBatchRow,
          $$ImportBatchesTableFilterComposer,
          $$ImportBatchesTableOrderingComposer,
          $$ImportBatchesTableAnnotationComposer,
          $$ImportBatchesTableCreateCompanionBuilder,
          $$ImportBatchesTableUpdateCompanionBuilder,
          (
            ImportBatchRow,
            BaseReferences<_$AppDatabase, $ImportBatchesTable, ImportBatchRow>,
          ),
          ImportBatchRow,
          PrefetchHooks Function()
        > {
  $$ImportBatchesTableTableManager(_$AppDatabase db, $ImportBatchesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ImportBatchesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ImportBatchesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ImportBatchesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String> filename = const Value.absent(),
                Value<DateTime> importedAt = const Value.absent(),
                Value<String> parserVersion = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> countsJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ImportBatchesCompanion(
                id: id,
                source: source,
                filename: filename,
                importedAt: importedAt,
                parserVersion: parserVersion,
                status: status,
                countsJson: countsJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String source,
                required String filename,
                Value<DateTime> importedAt = const Value.absent(),
                required String parserVersion,
                Value<String> status = const Value.absent(),
                Value<String> countsJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ImportBatchesCompanion.insert(
                id: id,
                source: source,
                filename: filename,
                importedAt: importedAt,
                parserVersion: parserVersion,
                status: status,
                countsJson: countsJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ImportBatchesTable, ImportBatchRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $ImportBatchesTable,
                    ImportBatchRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ImportBatchesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ImportBatchesTable,
      ImportBatchRow,
      $$ImportBatchesTableFilterComposer,
      $$ImportBatchesTableOrderingComposer,
      $$ImportBatchesTableAnnotationComposer,
      $$ImportBatchesTableCreateCompanionBuilder,
      $$ImportBatchesTableUpdateCompanionBuilder,
      (
        ImportBatchRow,
        BaseReferences<_$AppDatabase, $ImportBatchesTable, ImportBatchRow>,
      ),
      ImportBatchRow,
      PrefetchHooks Function()
    >;
typedef $$SettingsTableCreateCompanionBuilder =
    SettingsCompanion Function({
      required String key,
      required String valueJson,
      Value<int> rowid,
    });
typedef $$SettingsTableUpdateCompanionBuilder =
    SettingsCompanion Function({
      Value<String> key,
      Value<String> valueJson,
      Value<int> rowid,
    });

class $$SettingsTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get valueJson => $composableBuilder(
    column: $table.valueJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get valueJson => $composableBuilder(
    column: $table.valueJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get valueJson =>
      $composableBuilder(column: $table.valueJson, builder: (column) => column);
}

class $$SettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingsTable,
          SettingRow,
          $$SettingsTableFilterComposer,
          $$SettingsTableOrderingComposer,
          $$SettingsTableAnnotationComposer,
          $$SettingsTableCreateCompanionBuilder,
          $$SettingsTableUpdateCompanionBuilder,
          (
            SettingRow,
            BaseReferences<_$AppDatabase, $SettingsTable, SettingRow>,
          ),
          SettingRow,
          PrefetchHooks Function()
        > {
  $$SettingsTableTableManager(_$AppDatabase db, $SettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> valueJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SettingsCompanion(
                key: key,
                valueJson: valueJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required String valueJson,
                Value<int> rowid = const Value.absent(),
              }) => SettingsCompanion.insert(
                key: key,
                valueJson: valueJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SettingsTable, SettingRow>(table),
                  BaseReferences<_$AppDatabase, $SettingsTable, SettingRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingsTable,
      SettingRow,
      $$SettingsTableFilterComposer,
      $$SettingsTableOrderingComposer,
      $$SettingsTableAnnotationComposer,
      $$SettingsTableCreateCompanionBuilder,
      $$SettingsTableUpdateCompanionBuilder,
      (SettingRow, BaseReferences<_$AppDatabase, $SettingsTable, SettingRow>),
      SettingRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$AccountsTableTableManager get accounts =>
      $$AccountsTableTableManager(_db, _db.accounts);
  $$SecuritiesTableTableManager get securities =>
      $$SecuritiesTableTableManager(_db, _db.securities);
  $$TransactionsTableTableManager get transactions =>
      $$TransactionsTableTableManager(_db, _db.transactions);
  $$PostingsTableTableManager get postings =>
      $$PostingsTableTableManager(_db, _db.postings);
  $$BudgetsTableTableManager get budgets =>
      $$BudgetsTableTableManager(_db, _db.budgets);
  $$ScheduledEventsTableTableManager get scheduledEvents =>
      $$ScheduledEventsTableTableManager(_db, _db.scheduledEvents);
  $$GoalsTableTableManager get goals =>
      $$GoalsTableTableManager(_db, _db.goals);
  $$DebtContractsTableTableManager get debtContracts =>
      $$DebtContractsTableTableManager(_db, _db.debtContracts);
  $$ValuationsTableTableManager get valuations =>
      $$ValuationsTableTableManager(_db, _db.valuations);
  $$FxRatesTableTableManager get fxRates =>
      $$FxRatesTableTableManager(_db, _db.fxRates);
  $$SnapshotsTableTableManager get snapshots =>
      $$SnapshotsTableTableManager(_db, _db.snapshots);
  $$ImportBatchesTableTableManager get importBatches =>
      $$ImportBatchesTableTableManager(_db, _db.importBatches);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
}
