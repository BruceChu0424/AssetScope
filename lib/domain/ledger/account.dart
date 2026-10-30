import '../money/fx_rate.dart';

/// 账户五大类型（复式记账）。
enum AccountType { asset, liability, equity, income, expense }

/// 资产子类型。`isHolding` 为true 表示“持仓账户”：
/// 记数量账（份额），其货币价值由估值（价格×数量×汇率）得出，
/// 并配有一个镜像“成本账户”（系统资产账户）保证货币守恒。
enum AssetSubtype {
  cash('现金', liquidityDays: 0),
  alipay('支付宝余额', liquidityDays: 0),
  wechat('微信余额', liquidityDays: 0),
  bank('银行活期', liquidityDays: 0),
  timeDeposit('定期存款', liquidityDays: 90),
  moneyFund('货币基金', liquidityDays: 1),
  wealthMgmt('银行理财', liquidityDays: 30),
  brokerCash('券商现金', liquidityDays: 1),
  stock('股票持仓', liquidityDays: 2, isHolding: true),
  fund('基金持仓', liquidityDays: 3, isHolding: true),
  bond('债券持仓', liquidityDays: 3, isHolding: true),
  preciousMetal('贵金属', liquidityDays: 2, isHolding: true),
  crypto('加密资产', liquidityDays: 1, isHolding: true),
  realEstate('房产', liquidityDays: 9999),
  vehicle('车辆', liquidityDays: 9999),
  equityOwnership('公司股权', liquidityDays: 9999),
  pension('养老金', liquidityDays: 9999),
  providentFund('公积金', liquidityDays: 9999),
  depositPaid('押金', liquidityDays: 90),
  receivable('应收款/借出款', liquidityDays: 90),
  insuranceCashValue('保险现金价值', liquidityDays: 9999),
  otherAsset('其他资产', liquidityDays: 90);

  const AssetSubtype(
    this.labelZh, {
    required this.liquidityDays,
    this.isHolding = false,
  });

  final String labelZh;
  final int liquidityDays;
  final bool isHolding;
}

/// 负债子类型。
enum LiabilitySubtype {
  creditCard('信用卡'),
  huabei('花呗/信用付'),
  consumerLoan('消费贷'),
  mortgage('房贷'),
  carLoan('车贷'),
  studentLoan('助学贷款'),
  installment('商品分期'),
  privateLoan('私人借款'),
  otherDebt('其他负债');

  const LiabilitySubtype(this.labelZh);
  final String labelZh;
}

/// 估值方式。
enum ValuationMethod {
  /// 现金类：账本余额即价值。
  ledger,

  /// 持仓类：数量 × 市场价格（估值记录提供单价）。
  marketPrice,

  /// 手工估值（房产、车辆等）：估值记录提供总价值。
  manualValue,
}

/// 账户（资产、负债、分类、权益的统一实体）。
class Account {
  const Account({
    required this.id,
    required this.name,
    required this.type,
    this.assetSubtype,
    this.liabilitySubtype,
    this.institution,
    required this.currencyCode,
    this.ownership,
    this.includeInNetWorth = true,
    this.creditLimitMinor,
    this.statementDay,
    this.dueDay,
    this.isSystem = false,
    this.archived = false,
    this.sortOrder = 0,
    this.notes,
    this.costBasisAccountId,
    this.securityId,
    this.locationLat,
    this.locationLon,
    this.locationName,
    this.aiValuationEnabled = false,
    this.aiValuationQuery,
  });

  final String id;
  final String name;
  final AccountType type;
  final AssetSubtype? assetSubtype;
  final LiabilitySubtype? liabilitySubtype;
  final String? institution;

  /// 记账币种（持仓账户为其计价币种，如 A 股为 CNY）。
  final String currencyCode;

  /// 归属比例（家庭账本场景：本人份额）。null 表示 100%。
  final Rational? ownership;

  /// 有效归属比例（1 = 全部归本人）。
  Rational get effectiveOwnership => ownership ?? (Rational.one);

  final bool includeInNetWorth;

  /// 信用额度（仅元数据，不计入资产）。
  final BigInt? creditLimitMinor;
  final int? statementDay;
  final int? dueDay;
  final bool isSystem;
  final bool archived;
  final int sortOrder;
  final String? notes;

  /// 持仓账户的成本镜像账户 id。
  final String? costBasisAccountId;
  final String? securityId;

  /// 固定资产位置（3D 地球视图）。纬度 [-90,90]，经度 [-180,180]。
  final double? locationLat;
  final double? locationLon;

  /// 位置名（城市/小区名，如"上海·前滩"）。
  final String? locationName;

  /// 是否启用 AI 每日自动估值（房产/车辆等 manualValue 类资产）。
  final bool aiValuationEnabled;

  /// AI 估值检索线索（小区/栋/室、年款型号）；null = 由名称+位置推导。
  final String? aiValuationQuery;

  /// AI 估值有效检索词：用户线索优先，否则 名称 + 位置 拼接。
  String get effectiveAiValuationQuery {
    final q = aiValuationQuery?.trim();
    if (q != null && q.isNotEmpty) return q;
    final loc = locationName?.trim();
    if (loc == null || loc.isEmpty) return name;
    return '$name（$loc）';
  }

  /// 是否已设置位置（地球标记用）。
  bool get hasLocation => locationLat != null && locationLon != null;

  bool get isHolding => assetSubtype?.isHolding ?? false;

  /// 按子类型判断估值方式（静态版，建表单在账户落库前就需要知道口径）。
  static ValuationMethod valuationMethodOf(AssetSubtype? subtype) {
    if (subtype?.isHolding ?? false) return ValuationMethod.marketPrice;
    return switch (subtype) {
      AssetSubtype.realEstate ||
      AssetSubtype.vehicle ||
      AssetSubtype.pension ||
      AssetSubtype.insuranceCashValue ||
      AssetSubtype.equityOwnership ||
      AssetSubtype.providentFund ||
      AssetSubtype.otherAsset ||
      AssetSubtype.timeDeposit ||
      AssetSubtype.wealthMgmt ||
      AssetSubtype.depositPaid => ValuationMethod.manualValue,
      _ => ValuationMethod.ledger,
    };
  }

  ValuationMethod get valuationMethod => valuationMethodOf(assetSubtype);

  /// 变现速度（天）。0=即时可用。
  int get liquidityDays => assetSubtype?.liquidityDays ?? 0;

  Account copyWith({
    String? name,
    String? institution,
    Rational? ownership,
    bool? includeInNetWorth,
    BigInt? creditLimitMinor,
    int? statementDay,
    int? dueDay,
    bool? archived,
    int? sortOrder,
    String? notes,
    double? locationLat,
    double? locationLon,
    String? locationName,
    bool? aiValuationEnabled,
    String? aiValuationQuery,
    bool clearAiValuationQuery = false,
  }) => Account(
    id: id,
    name: name ?? this.name,
    type: type,
    assetSubtype: assetSubtype,
    liabilitySubtype: liabilitySubtype,
    institution: institution ?? this.institution,
    currencyCode: currencyCode,
    ownership: ownership ?? this.ownership,
    includeInNetWorth: includeInNetWorth ?? this.includeInNetWorth,
    creditLimitMinor: creditLimitMinor ?? this.creditLimitMinor,
    statementDay: statementDay ?? this.statementDay,
    dueDay: dueDay ?? this.dueDay,
    isSystem: isSystem,
    archived: archived ?? this.archived,
    sortOrder: sortOrder ?? this.sortOrder,
    notes: notes ?? this.notes,
    costBasisAccountId: costBasisAccountId,
    securityId: securityId,
    locationLat: locationLat ?? this.locationLat,
    locationLon: locationLon ?? this.locationLon,
    locationName: locationName ?? this.locationName,
    aiValuationEnabled: aiValuationEnabled ?? this.aiValuationEnabled,
    aiValuationQuery: clearAiValuationQuery
        ? null
        : (aiValuationQuery ?? this.aiValuationQuery),
  );

  /// 系统账户 id 常量（唯一实例）。
  static const sysEquityOpening = 'sys:equity:opening';
  static const sysEquityAdjustment = 'sys:equity:adjustment';
  static const sysExpenseFx = 'sys:expense:fx';
  static const sysExpenseRounding = 'sys:expense:rounding';
  static const sysIncomeRealizedPnl = 'sys:income:realized-pnl';
  static const sysIncomeDividend = 'sys:income:dividend';

  static List<Account> systemAccounts() => const [
    Account(
      id: sysEquityOpening,
      name: '期初余额权益',
      type: AccountType.equity,
      currencyCode: 'CNY',
      isSystem: true,
    ),
    Account(
      id: sysEquityAdjustment,
      name: '对账调整',
      type: AccountType.equity,
      currencyCode: 'CNY',
      isSystem: true,
    ),
    Account(
      id: sysExpenseFx,
      name: '汇兑损益',
      type: AccountType.expense,
      currencyCode: 'CNY',
      isSystem: true,
    ),
    Account(
      id: sysExpenseRounding,
      name: '尾差',
      type: AccountType.expense,
      currencyCode: 'CNY',
      isSystem: true,
    ),
    Account(
      id: sysIncomeRealizedPnl,
      name: '已实现投资损益',
      type: AccountType.income,
      currencyCode: 'CNY',
      isSystem: true,
    ),
    Account(
      id: sysIncomeDividend,
      name: '股息与分红',
      type: AccountType.income,
      currencyCode: 'CNY',
      isSystem: true,
    ),
  ];
}
