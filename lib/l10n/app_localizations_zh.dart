// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '资观 AssetScope';

  @override
  String get aiCfgTestMissingInput => '请先填写 Base URL 与 API Key';

  @override
  String aiCfgTestConnected(String reply) {
    return '连接成功：$reply';
  }

  @override
  String get aiCfgGlmCodingPlanKeyHint =>
      '若这是编程套餐（Coding Plan）Key，请改选「智谱 GLM Coding Plan」';

  @override
  String get aiCfgGlmRegularKeyHint => '套餐端点只认编程套餐 Key；普通 API Key 请改选「智谱 GLM」';

  @override
  String get aiCfgKeyPrivacyTip =>
      'API Key 加密存储在本地账本库，仅用于行情/汇率抓取与 AI 助手；抓取时只发送查询名称与币种对，绝不发送余额与金额。';

  @override
  String get aiCfgOpenAiCompatibleNote => 'OpenAI 兼容端点';

  @override
  String get aiCfgWebSearchOnTip => '联网搜索已开：行情抓取带联网工具，价格来自实时网页';

  @override
  String get aiCfgWebSearchOffTip => '联网搜索已关：行情价格可能来自模型记忆';

  @override
  String get aiCfgNoWebSearchSupportTip => '该服务商 chat 接口不支持联网工具，行情价格可能来自模型记忆';

  @override
  String get aiCfgDialogTitle => 'AI 服务配置';

  @override
  String get aiCfgProvider => '服务商';

  @override
  String get aiCfgBaseUrlLabel => 'Base URL（https://…，不含 /chat/completions）';

  @override
  String get aiCfgModelLabel => '模型（须支持联网搜索）';

  @override
  String get aiCfgWebSearch => '联网搜索';

  @override
  String get aiCfgTestConnection => '测试连接';

  @override
  String get aiCfgUsageTitle => '用量与额度';

  @override
  String get aiCfgUsageTooltip =>
      '调用次数由本应用本地统计（设置页关闭后重新打开刷新）；额度来自服务商接口，免费模型不扣费';

  @override
  String get aiCfgStatToday => '今日调用';

  @override
  String get aiCfgStatLast7Days => '近 7 天';

  @override
  String get aiCfgStatTotal => '累计';

  @override
  String aiCfgCalls(num n) {
    return '$n 次';
  }

  @override
  String get aiCfgNoBalanceApi => '该服务商暂无余额查询接口，可到其控制台查看';

  @override
  String get aiCfgBalanceGlm => '服务商余额（智谱）';

  @override
  String aiCfgBalanceTotal(String v) {
    return '总额度 ¥$v';
  }

  @override
  String aiCfgBalanceVoucher(String v) {
    return '免费额度 ¥$v';
  }

  @override
  String aiCfgBalanceCash(String v) {
    return '现金 ¥$v';
  }

  @override
  String get aiCfgBalanceNoFields => '接口未返回额度字段';

  @override
  String aiCfgBalanceQueryFailed(String e) {
    return '查询失败：$e';
  }

  @override
  String get aiCfgBalanceQuery => '查询';

  @override
  String get aiCfgBalanceRefresh => '刷新';

  @override
  String get aiCfgServiceHint => '智谱/Kimi/千问/OpenAI/Claude/自定义；Key 加密存本地';

  @override
  String get categoryManagerTitle => '分类与规则';

  @override
  String get categoryRulePriorityHint => '关键词规则在导入时优先于历史学习命中。';

  @override
  String get categoryExpenseGroup => '支出分类';

  @override
  String get categoryIncomeGroup => '收入分类';

  @override
  String get categoryKeywordRules => '关键词规则';

  @override
  String get categoryNoRulesHint => '还没有显式规则。导入与日常记账会自动学习对手方→分类的对应关系。';

  @override
  String categoryRuleKeyword(String kw) {
    return '「$kw」';
  }

  @override
  String get categoryAddExpense => '新增支出分类';

  @override
  String get categoryAddIncome => '新增收入分类';

  @override
  String get categoryRename => '重命名分类';

  @override
  String get categoryAddRule => '新增关键词规则';

  @override
  String get categoryRuleKeywordLabel => '关键词（如 美团、NETFLIX）';

  @override
  String get categoryRuleTargetLabel => '命中后归类到';

  @override
  String get categoryManagerHint => '管理收支分类、商户→分类关键词规则';

  @override
  String get fxManagerTitle => '汇率管理';

  @override
  String get fxManagerHint => '净值折算取\"当日或之前最近\"的一条；倒序存入即可覆盖历史。';

  @override
  String get fxAddRate => '新增汇率';

  @override
  String get fxAiFetch => 'AI 抓取';

  @override
  String get fxNoRatesHint => '还没有汇率记录。多币种账户折算需要至少一条对该币种的汇率。';

  @override
  String get fxEditRateTitle => '录入汇率';

  @override
  String get fxFromCurrency => '原币种';

  @override
  String get fxToCurrency => '目标币种';

  @override
  String get fxRateLabel => '1 原币种 = ? 目标币种（如 7.25）';

  @override
  String get fxRateSaved => '汇率已保存';

  @override
  String get fxRateInvalid => '汇率格式不正确';

  @override
  String get fxManualHint => '手工录入各币种对本位币汇率';

  @override
  String mergeDecryptFailed(Object e) {
    return '备份无法解密（口令不对或文件损坏）：$e';
  }

  @override
  String mergeSchemaTooNew(num v) {
    return '备份来自更新版本的应用（schema $v），请先升级再合并';
  }

  @override
  String get mergeLineageMismatch => '这份备份属于另一个账本（谱系指纹不一致），不能合并。恢复请用\"从备份恢复\"';

  @override
  String mergeVerifyFailed(Object e) {
    return '备份内容校验失败：$e';
  }

  @override
  String get mergeNothingToMerge => '两份账本已一致，没有需要合并的内容';

  @override
  String get mergeDone => '合并完成';

  @override
  String mergeSafetyBackupNote(String path) {
    return '合并前的安全备份：\n$path\n各页面回到前台会自动刷新。';
  }

  @override
  String mergeFailed(Object e) {
    return '合并失败（账本未改动，已整体回滚）：$e';
  }

  @override
  String get mergePassphraseLabel => '这份 .asbk 的导出口令';

  @override
  String get mergeConfirmTitle => '确认合并';

  @override
  String mergeWillImport(String summary) {
    return '将并入：$summary。';
  }

  @override
  String get mergeConfirmNote =>
      '交易按\"更新时间新者胜\"合并，其余内容按表策略并入；合并会先自动生成一份安全备份，可随时用\"从备份恢复\"退回。';

  @override
  String get mergeLegacyWarning => '注意：这份备份由旧版本导出、没有账本身份标识。请确认它确实来自同一本账。';

  @override
  String get mergeBackupAndMerge => '安全备份并合并';

  @override
  String quoteAppliedCount(num n) {
    return '已写入 $n 条行情/汇率';
  }

  @override
  String quoteWriteFailed(Object e) {
    return '写入失败：$e';
  }

  @override
  String get quoteFetchTitle => '行情 / 汇率抓取';

  @override
  String get quoteFetchIntro =>
      '直连官方行情源（免费无 key、秒回）；查不到的再试 AI 联网搜索。预览确认后才写入，来源可审计。无论哪种方式，都只发送证券代码与币种对。';

  @override
  String get quoteQueryingDirect => '正在向官方行情源查询…';

  @override
  String get quoteQueryingAi => 'AI 正在联网搜索行情，约需 10–60 秒…';

  @override
  String get quoteNoWebSearchWarning => '当前 AI 配置未开启联网搜索，模型可能返回记忆中的过时价格，请谨慎确认。';

  @override
  String get quoteWillQuery => '本次将查询：';

  @override
  String get quoteNoTargets => '没有在持的证券持仓，也没有需要折算的外币账户。';

  @override
  String quoteHoldingPrices(num n, String names) {
    return '· 持仓价格（$n）：$names';
  }

  @override
  String quoteFxPairs(num n, String pairs, String base) {
    return '· 汇率（$n）：$pairs → $base';
  }

  @override
  String get quoteRoutingHint =>
      '直连路由：A股/场内基金 → 腾讯行情；港股/美股 → stooq；汇率 → 欧央行。行情代码可在持仓账户详情设置（如 600519 / 00700 / AAPL）。';

  @override
  String get quoteDirectFetchButton => '直连官方行情源（推荐 · 免费 · 秒回）';

  @override
  String get quoteAiFetchFallback => 'AI 联网搜索（查不到时兜底）';

  @override
  String get quoteAiFetchNeedsConfig => 'AI 联网搜索（需先配置 AI 服务）';

  @override
  String get quoteAssetPrices => '资产价格';

  @override
  String get quoteFxRates => '汇率';

  @override
  String get quoteNotes => '提示';

  @override
  String quoteSelectedCount(num p, num r) {
    return '已选 $p 条价格 + $r 条汇率';
  }

  @override
  String get quoteBack => '返回';

  @override
  String get quoteApplyButton => '确认写入';

  @override
  String get quoteUnmatchedTooltip => '未匹配到在持仓账户，不入账';

  @override
  String quoteCurrencyMismatchTooltip(String ccy) {
    return '币种与账户不一致（$ccy vs 账户币种），默认不勾选';
  }

  @override
  String get quoteFetchHint => 'AI 联网搜索最新价格与汇率，预览确认后入账';

  @override
  String settingsFailed(Object e) {
    return '失败：$e';
  }

  @override
  String get settingsFailedPrefix => '失败';

  @override
  String get settingsCancel => '取消';

  @override
  String get settingsSave => '保存';

  @override
  String get settingsGotIt => '知道了';

  @override
  String get settingsBackupFileType => '备份';

  @override
  String get settingsBackupPassphraseTitle => '输入备份口令';

  @override
  String get settingsVerify => '校验';

  @override
  String get settingsChangePassphrase => '修改主口令';

  @override
  String get settingsCurrentPassphrase => '当前主口令';

  @override
  String get settingsNewPassphraseLabel => '新主口令（≥12位更安全）';

  @override
  String get settingsConfirm => '确认';

  @override
  String get settingsPassphraseUpdated => '主口令已更新';

  @override
  String get settingsNewRecoveryCode => '新恢复码（离线保存）';

  @override
  String get settingsBackupPassphrase => '备份口令';

  @override
  String get settingsBackupPassphraseLabel => '备份文件口令（≥8 位，建议 12 位以上）';

  @override
  String get settingsExport => '导出';

  @override
  String settingsExportedTo(String path) {
    return '已导出：$path';
  }

  @override
  String settingsExportFailed(Object e) {
    return '导出失败：$e';
  }

  @override
  String get settingsVerifyAndRestore => '校验并恢复';

  @override
  String get settingsRestoreDone => '恢复完成，已用新数据锁定；请用主口令解锁（原库保留为 .bak）';

  @override
  String settingsRestoreFailed(Object e) {
    return '恢复失败（原账本未受影响）：$e';
  }

  @override
  String get settingsBaseCurrency => '本位币';

  @override
  String settingsBaseCurrencySet(String code) {
    return '本位币已设为 $code';
  }

  @override
  String get settingsNotUnlocked => '未解锁';

  @override
  String get settingsGroupSecurity => '安全';

  @override
  String get settingsGroupBackup => '备份与恢复';

  @override
  String get settingsGroupPreferences => '偏好';

  @override
  String get settingsGroupData => '数据管理';

  @override
  String get settingsGroupAiQuotes => 'AI 与行情';

  @override
  String get settingsGroupAbout => '关于';

  @override
  String get settingsLockNow => '立即锁定';

  @override
  String get settingsLockNowHint => '关闭数据库并清除内存密钥；无操作也会自动锁定';

  @override
  String get settingsChangePassphraseHint => '只重新包裹密钥，数据不需要重加密';

  @override
  String get settingsRegenRecoveryCode => '重新生成恢复码';

  @override
  String get settingsRegenRecoveryCodeHint => '旧恢复码立即失效';

  @override
  String get settingsExportBackup => '导出加密备份';

  @override
  String get settingsExportBackupHint => '生成 .asbk 加密容器，请用独立口令并离线保存';

  @override
  String get settingsRestoreBackup => '从备份恢复';

  @override
  String get settingsRestoreBackupHint => '先隔离校验，通过后才替换当前账本（原库保留 .bak）';

  @override
  String get settingsMergeBackup => '从备份合并（多设备）';

  @override
  String get settingsMergeBackupHint => '把另一设备的 .asbk 并入当前账本：交易按时间新者胜，先自动安全备份';

  @override
  String get settingsBaseCurrencyHint => '统计、净资产与预测的基准货币';

  @override
  String get settingsImportCsv => '导入账单 CSV';

  @override
  String get settingsImportCsvHint => 'UTF-8/GBK 自动识别，去重幂等，智慧分类建议';

  @override
  String get settingsExportJson => '导出全量 JSON';

  @override
  String get settingsExportJsonHint => '账户/估值/交易/计划/预算的明文快照（不含密钥），可审计可迁移';

  @override
  String get settingsPageTitle => '设置';

  @override
  String get settingsFullJsonExported => '已导出全量 JSON（明文，不含任何密钥）';

  @override
  String get settingsAboutTagline => '本地优先的个人资产、负债与财务规划系统。数据全程加密存储，任何联网功能默认关闭。';

  @override
  String get settingsAppearance => '外观';

  @override
  String get settingsAppearanceHint => '浅色冷雾白 / 深色财富终端，跟随系统自动切换';

  @override
  String get settingsThemeSystem => '跟随系统';

  @override
  String get settingsThemeLight => '浅色';

  @override
  String get settingsThemeDark => '深色';

  @override
  String get settingsAutoLock => '自动锁定';

  @override
  String get settingsAutoLockHint => '无操作达到该时长后自动锁定账本';

  @override
  String settingsMinutes(num n) {
    return '$n 分钟';
  }

  @override
  String get settingsAutoLockDialogTitle => '无操作自动锁定';

  @override
  String settingsAutoLockSet(num n) {
    return '自动锁定已设为 $n 分钟';
  }

  @override
  String get settingsCashHorizon => '现金预测期';

  @override
  String get settingsCashHorizonHint => '首页「还能花多少」的推演天数';

  @override
  String settingsDays(num n) {
    return '$n 天';
  }

  @override
  String settingsCashHorizonSet(num n) {
    return '现金预测期已设为 $n 天';
  }

  @override
  String get settingsCashFloor => '现金底线';

  @override
  String get settingsCashFloorHint => '低于此值视为现金短缺（预测与可支配上限会扣除）';

  @override
  String get settingsCashFloorSaved => '现金底线已保存';

  @override
  String get cancel => '取消';

  @override
  String get confirm => '确定';

  @override
  String get save => '保存';

  @override
  String get edit => '编辑';

  @override
  String get delete => '删除';

  @override
  String get remove => '移除';

  @override
  String loadFailed(Object error) {
    return '加载失败：$error';
  }

  @override
  String yearsN(String n) {
    return '$n 年';
  }

  @override
  String monthsN(num n) {
    return '$n 月';
  }

  @override
  String daysLaterN(num n) {
    return '$n 天后';
  }

  @override
  String get lifeEventAddTitle => '添加人生事件';

  @override
  String get lifeEventBuyHome => '买房（含贷款）';

  @override
  String get lifeEventChildRearing => '生孩子 / 抚养';

  @override
  String get lifeEventIncomeChangeOption => '收入跳变（升职/失业）';

  @override
  String get lifeEventRetirement => '退休';

  @override
  String get lifeEventBigPurchaseOption => '大件购置（换车等）';

  @override
  String get lifeEventLumpSum => '一次性大额收支';

  @override
  String get lifeEventIncomeChange => '收入跳变';

  @override
  String get lifeEventBigPurchase => '大件购置';

  @override
  String get lifeEventYearsLater => '几年后';

  @override
  String get lifeEventTotalPrice => '总价（元）';

  @override
  String get lifeEventDownPayment => '首付（元）';

  @override
  String get lifeEventAnnualRateHint => '年利率 %（如 3.6）';

  @override
  String get lifeEventLoanTerm => '贷款年限';

  @override
  String get lifeEventYearsUntilBirth => '几年后出生';

  @override
  String get lifeEventMonthlyRearingCost => '每月养育成本（元）';

  @override
  String get lifeEventCollegeExtra => '大学阶段每月额外（元，可空）';

  @override
  String get lifeEventChangePctHint => '变化 %（+30 涨三成 / −100 归零）';

  @override
  String get lifeEventYearsUntilRetire => '几年后退休';

  @override
  String get lifeEventRetirementNote => '退休后：收入 ×0.4（养老金替代率）、支出 ×0.75';

  @override
  String get lifeEventPurchaseCost => '购置支出（元）';

  @override
  String get lifeEventResidualValue => '残值计入固定资产（元，可空）';

  @override
  String get lifeEventAmountInOut => '金额（元，负数 = 流出）';

  @override
  String get lifePlanTitle => '人生规划 · 多年度推演';

  @override
  String lifePlanIntro(num years) {
    return '把买房、育儿、换车、退休等大事放进同一条时间线，逐月推演未来 $years 年的现金流与净资产（名义口径，收入支出按通胀增长）。只读模拟，不写账本。';
  }

  @override
  String get lifePlanRerun => '重新推演';

  @override
  String get lifePlanInvestableAssets => '可投资净资产（元）';

  @override
  String get lifePlanFixedAssets => '固定资产等（元）';

  @override
  String get lifePlanMonthlyIncome => '月收入（元）';

  @override
  String get lifePlanMonthlyExpense => '月支出（元）';

  @override
  String get lifePlanNominalReturn => '名义收益 %/年';

  @override
  String get lifePlanInflation => '通胀 %/年';

  @override
  String get lifePlanHorizonYears => '推演年限';

  @override
  String get lifePlanEvents => '人生事件';

  @override
  String get lifePlanAddEvent => '添加事件';

  @override
  String get lifePlanNoEvents => '还没有事件。加一个试试：三年后买房、明年生孩子……';

  @override
  String get lifePlanResults => '推演结论';

  @override
  String lifePlanNetWorthInYears(num years) {
    return '$years 年后净资产';
  }

  @override
  String get lifePlanPeakNetWorth => '峰值净资产';

  @override
  String get lifePlanNewLoanInterest => '新增贷款总利息';

  @override
  String get lifePlanCashExhaustionRisk => '现金耗尽风险';

  @override
  String get lifePlanNoGap => '推演期内无缺口 ✓';

  @override
  String lifePlanExhaustedAt(num year, String date) {
    return '第 $year 年（$date 前后）';
  }

  @override
  String get lifePlanNetWorthCurve => '净资产曲线（万元）';

  @override
  String lifePlanCurveTooltip(String year, String value) {
    return '第 $year 年  $value';
  }

  @override
  String get planNew => '新建计划';

  @override
  String get planEdit => '编辑计划';

  @override
  String get planNameLabel => '名称（如 房租 / 工资）';

  @override
  String get planOutflow => '支出';

  @override
  String get planInflow => '收入';

  @override
  String get planCadence => '周期';

  @override
  String get planAnchorMonthly => '起始日（每月此日发生）';

  @override
  String get planAnchorDate => '起始日';

  @override
  String get planEndDate => '结束日（可选）';

  @override
  String get planAutoPostTitle => '到期自动记入账本';

  @override
  String get planAutoPostSubtitle => '解锁应用时自动落账；已入账/作废不会重复记';

  @override
  String get planPayAccount => '支付账户';

  @override
  String get planIncomeAccount => '入账账户';

  @override
  String planNoAccountForCurrency(String currency) {
    return '没有 $currency 账户可选，请先建账户';
  }

  @override
  String get planCategory => '分类';

  @override
  String planPostTitle(String name) {
    return '记入账本 · $name';
  }

  @override
  String planPostDateNote(String date) {
    return '落账日 $date（发生日）';
  }

  @override
  String get planPostEstimateNote => ' · 估算金额取中位数，可修改';

  @override
  String planAccountsLoadFailed(String error) {
    return '账户加载失败：$error';
  }

  @override
  String planPostFailed(String error) {
    return '入账失败：$error';
  }

  @override
  String get planSkipOnce => '这次不记';

  @override
  String get planPostNow => '记入账本';

  @override
  String get planPosting => '入账中…';

  @override
  String get plansPageTitle => '计划';

  @override
  String get planMonthlyRhythm => '本月节奏';

  @override
  String get planDueUnposted => '到期未记入';

  @override
  String planCount(num n) {
    return '$n 笔';
  }

  @override
  String get planDueTooltip => '到期未入账的计划事件，逐笔或一键记入账本';

  @override
  String get planNext30Days => '未来 30 天';

  @override
  String get planNext30Tooltip => '含已入账与未入账的全部发生额';

  @override
  String get planNext30Net => '未来 30 天净流';

  @override
  String get planNetSignTooltip => '正为净流入，负为净流出';

  @override
  String planDueTitle(num n) {
    return '待落地 · $n 笔到期';
  }

  @override
  String get planPostAll => '全部记入';

  @override
  String get planEstimateTooltip => '估算金额，确认时可修改';

  @override
  String get planEstimateBadge => '估';

  @override
  String planMoreDue(num n) {
    return '…另有 $n 笔，\"全部记入\"可一次处理';
  }

  @override
  String planNetEffect(String amount) {
    return '净影响 $amount';
  }

  @override
  String planBlockedCount(num n) {
    return ' · $n 笔需先在确认页选账户';
  }

  @override
  String planPostedCount(num n) {
    return '已记入 $n 笔计划';
  }

  @override
  String get planNothingToPost => '没有可直接记入的计划（需先在确认页选账户）';

  @override
  String get planNoUpcoming => '暂无预定支出';

  @override
  String get planAllPlans => '全部计划';

  @override
  String get planEmptyHint => '点右下角「新建计划」，或用识别功能从流水中生成。';

  @override
  String get planEstimateAmount => ' · 估算金额';

  @override
  String get planActions => '计划操作';

  @override
  String get planPause => '暂停';

  @override
  String get planResume => '恢复';

  @override
  String get planMarkFinished => '标记完成';

  @override
  String get planDeleteTitle => '删除计划';

  @override
  String planDeleteMessage(String name) {
    return '删除\"$name\"不影响已入账的交易。';
  }

  @override
  String get recurringTitle => '识别到的固定收支';

  @override
  String get recurringIntro =>
      '从近 18 个月流水中识别（同对手方、间隔规整、≥3 次）。转为计划后将计入现金预测与预算的\"已计划\"。';

  @override
  String get recurringOpenTooltip => '从流水识别固定收支';

  @override
  String get recurringEmpty => '暂未识别到固定收支。多记录几个月的房租/订阅/工资等\n规律流水后再来试试。';

  @override
  String recurringStatLine1(String cadence, num n, String pct) {
    return '$cadence · $n 次 · 置信 $pct%';
  }

  @override
  String recurringStatLine2(String amount, num m, num d) {
    return '中位 $amount · 下次预计 $m/$d';
  }

  @override
  String get recurringAlreadyPlanned => '已建计划';

  @override
  String get recurringConvertToPlan => '转计划';

  @override
  String get scenarioTitle => '情景模拟 · 现金压力测试';

  @override
  String get scenarioIntro =>
      '把\"如果……会怎样\"放进 180 天现金预测：计划、债务还款与准备金不变，只冲击收入/支出，看低谷多深、钱会不会断。不写账本。';

  @override
  String get scenarioExtraMonthlyLabel => '情景：额外月支出';

  @override
  String get scenarioOneOffLabel => '情景：一次性支出';

  @override
  String scenarioRunFailed(String error) {
    return '模拟失败：$error';
  }

  @override
  String get scenarioRun => '运行模拟';

  @override
  String get scenarioRunning => '模拟中…';

  @override
  String get scenarioExtrasTitle => '叠加自定义冲击（可选）';

  @override
  String get scenarioExtraMonthlyAmount => '额外月支出（元/月）';

  @override
  String get scenarioMonthsCount => '月数';

  @override
  String get scenarioOneOffAmount => '一次性支出（元）';

  @override
  String get scenarioOccursOn => '发生在';

  @override
  String scenarioResultTitle(String name) {
    return '结果 · $name';
  }

  @override
  String get scenarioMinCashBaseline => '最低现金 · 基线';

  @override
  String get scenarioMinCashScenario => '最低现金 · 情景';

  @override
  String get scenarioTroughDelta => '低谷变化';

  @override
  String get scenarioWorstDay => '最难受的一天（相对基线）';

  @override
  String get scenarioCashOutDate => '现金耗尽日';

  @override
  String scenarioCashOutValue(String date, num days) {
    return '$date（还剩 $days 天）';
  }

  @override
  String get scenarioNoCashOut => '预测期内未耗尽';

  @override
  String get scenarioNewShortfalls => '新增缺口（基线没有、情景触发的）';

  @override
  String get scenarioBelowReserve => '低于准备金与底线';

  @override
  String scenarioShortfallCount(num n) {
    return '…共 $n 条';
  }

  @override
  String scenarioSurvives(String amount) {
    return '情景可承受：无新增缺口、现金未耗尽。底线之外仍有余量 $amount。';
  }

  @override
  String get scenarioHurts => '该情景会造成伤害：考虑提高准备金、推迟可选支出或安排信用额度备用。';

  @override
  String get scenarioMethodNote => '口径：与现金预测同引擎重放（docs/05 §12）；准备金、债务还款与底线不变。';

  @override
  String get saveChanges => '保存修改';

  @override
  String get allReady => '全部就绪';

  @override
  String get assetsTitle => '资产';

  @override
  String get assetsTitleHint => '全部账户的台账与净值：点任一账户看价值、编辑资料、记估值与买卖';

  @override
  String get assetAdd => '添加资产';

  @override
  String get assetNew => '新建资产';

  @override
  String get assetCreate => '创建资产';

  @override
  String get assetsEmptyTitle => '还没有资产或负债';

  @override
  String get assetsEmptyMessage => '添加第一笔资产：现金、银行卡、房产、股票持仓……保存后地球首页会点亮它的坐标。';

  @override
  String get assetNameLabel => '名称';

  @override
  String get assetNameRequired => '请填写资产名称';

  @override
  String get assetValuePositiveRequired => '价值需为正数（如 1280000）';

  @override
  String get assetLocationRequired => '请选择资产位置——保存后将在地球首页点亮对应坐标';

  @override
  String get assetLocationTooltip => '资产需选位置——保存后弹窗将碎成光束，飞往地球点亮该坐标';

  @override
  String get assetCurrentValue => '当前价值';

  @override
  String get assetOpeningDebtNote => '期初欠款';

  @override
  String get accountEditProfile => '编辑资料';

  @override
  String get accountUpdateValuation => '更新估值';

  @override
  String get accountOpeningBalance => '期初余额';

  @override
  String get accountOpeningBalanceTitle => '记期初余额（历史补录，不算当月收入）';

  @override
  String get accountReconcileAdjust => '对账调整';

  @override
  String get accountReconcileAdjustTitle => '对账调整（填差额，可负）';

  @override
  String get accountQuoteCode => '行情代码';

  @override
  String get accountQuoteCodeTitle => '行情代码（直连行情源用）';

  @override
  String get accountQuoteCodeHint => 'A股 600519 / 港股 00700 / 美股 AAPL';

  @override
  String get accountQuoteCodeHelp =>
      'A股 6 位数字自动判交易所；港股填数字；美股填字母代码。修改只影响行情查询，不影响任何账目。';

  @override
  String get accountArchive => '归档';

  @override
  String get accountUnarchive => '取消归档';

  @override
  String get accountArchived => '已归档';

  @override
  String get accountArchivedHint => '不计入净资产统计';

  @override
  String get accountValuationMissing => '缺估值';

  @override
  String get accountMissingValuationHint => '尚无估值记录，未计入净资产——点「更新估值」补录';

  @override
  String get accountMissingValuationTip => '缺估值：未计入净资产';

  @override
  String get accountValuationStale => '估值过期';

  @override
  String get accountStaleValuationHint => '超过 30 天未更新';

  @override
  String get accountStaleValuationTip => '估值已过期（>30 天）';

  @override
  String get accountDebtBaseLabel => '当前欠款（本位币）';

  @override
  String get accountValueBaseLabel => '当前价值（本位币）';

  @override
  String accountOriginalBalance(String amount) {
    return '原币余额 $amount';
  }

  @override
  String accountMyShareDetail(String value, String share) {
    return '本人份额 $value（$share%）';
  }

  @override
  String accountMineShare(String share) {
    return '我 $share%';
  }

  @override
  String get accountRecentTransactions => '近期交易';

  @override
  String get accountUnitPriceLabel => '单价（每单位）';

  @override
  String get accountTotalValueLabel => '当前总价值';

  @override
  String get accountCurrentBalance => '当前余额';

  @override
  String get accountLocated => '已定位';

  @override
  String get accountGroupCash => '现金与活期';

  @override
  String get accountGroupSteady => '稳健理财';

  @override
  String get accountGroupHoldings => '持仓';

  @override
  String get accountGroupReal => '实物与权益';

  @override
  String get accountGroupLiabilities => '负债';

  @override
  String get liabilityCurrentDebt => '当前欠款';

  @override
  String get netWorth => '净资产';

  @override
  String get netWorthMyShare => '净资产（本人份额）';

  @override
  String get netWorthMyShareHint => '存在归属份额 <100% 的账户，此处为本人份额口径；全户口径见右侧合计';

  @override
  String get totalAssets => '资产合计';

  @override
  String get totalLiabilities => '负债合计';

  @override
  String get valuationStatusLabel => '估值状态';

  @override
  String itemsMissingValuation(num count) {
    return '$count 项缺估值';
  }

  @override
  String itemsStaleValuation(num count) {
    return '$count 项已过期';
  }

  @override
  String get selectAccountHint => '选择左侧账户查看详情';

  @override
  String get subtypeLabel => '类型';

  @override
  String get currencyLabel => '币种';

  @override
  String get locationLabel => '位置';

  @override
  String get institutionLabel => '机构';

  @override
  String get securityCodeLabel => '证券代码';

  @override
  String get ownershipTitle => '归属份额';

  @override
  String get ownershipMyShareLabel => '本人份额（%）';

  @override
  String get ownershipShareLabel => '份额';

  @override
  String get ownershipHelper => '100 = 全额本人；夫妻共同账户各填 50。只影响净资产/我的份额统计，不改流水。';

  @override
  String get ownershipRangeError => '份额需在 0–100 之间（例如 50 或 33.3）';

  @override
  String get tradeBuy => '买入';

  @override
  String get tradeSell => '卖出';

  @override
  String get tradeDividendInterest => '分红/利息';

  @override
  String tradeBuyTitle(String name) {
    return '买入 · $name';
  }

  @override
  String tradeSellTitle(String name) {
    return '卖出 · $name';
  }

  @override
  String get tradeDividendTitle => '分红/利息入账';

  @override
  String tradeHoldingSummary(String qty, String cost) {
    return '持有 $qty 份 · 成本 $cost';
  }

  @override
  String get tradeCashAccount => '现金账户';

  @override
  String get tradeCashAccountCredited => '入账现金账户';

  @override
  String get tradeQuantityLabel => '数量（份）';

  @override
  String get tradeTotalCostLabel => '总花费（含费用）';

  @override
  String get tradeNetProceedsLabel => '净到账金额';

  @override
  String get tradeDividendAmountLabel => '分红/利息金额';

  @override
  String get tradeNoteLabel => '备注（可选）';

  @override
  String get lotSectionTitle => '成本批次（FIFO）';

  @override
  String lotRealizedTotal(String amount) {
    return '累计已实现 $amount';
  }

  @override
  String lotRealizedYear(num year, String amount) {
    return '$year 年已实现 $amount';
  }

  @override
  String lotLineItem(String qty, String price) {
    return '$qty 份 × 单价 $price';
  }

  @override
  String lotShortfall(String qty) {
    return '⚠ $qty 份卖出早于首笔买入（历史缺口，以零成本配对）';
  }

  @override
  String get lotMethodologyNote => '口径：先买先卖逐批配对，与账面平均成本法并行披露（docs/05 §11）';

  @override
  String get aiRecognize => 'AI 识别';

  @override
  String get aiFillNameFirst => '先填写资产名称，AI 才能识别';

  @override
  String get aiNotBound => '尚未绑定 AI：设置 → AI 服务';

  @override
  String get aiRecognizing => 'AI 识别中…';

  @override
  String get aiFilledConfirmValue => 'AI 已填充，请确认价值';

  @override
  String get aiValTitle => 'AI 估值';

  @override
  String get aiValDaily => '每日 AI 估值';

  @override
  String get aiValDailyTooltip =>
      '开启后每天联网检索该资产真实市价并自动更新价值（房产看成交行情、车辆看二手估值，多源交叉剔除营销噪音）；你随时可在账户详情纠正，当日人工值优先';

  @override
  String get aiValSectionTooltip => '每天解锁后自动联网检索真实市价并更新价值；你手动改过的估值当日优先，AI 不覆盖';

  @override
  String get aiValQueryLabel => '检索线索（小区/栋/室 · 年款型号）';

  @override
  String get aiValSaveQuery => '保存线索';

  @override
  String get aiValSearching => '检索中…';

  @override
  String get aiValEstimateNow => '立即估值';

  @override
  String aiValQueryFallback(String query) {
    return '检索词空 = 「$query」';
  }

  @override
  String get aiValQuerySaved => 'AI 估值线索已保存';

  @override
  String get aiValBindKeyFirst => '先在 设置 → AI 服务 绑定你的 AI Key';

  @override
  String aiValUpdated(String value) {
    return '已更新估值：$value';
  }

  @override
  String aiValError(Object error) {
    return 'AI 估值：$error';
  }

  @override
  String get aiValResultTitle => 'AI 估值结果';

  @override
  String get aiValRange => '区间';

  @override
  String get aiValConfidence => '置信度';

  @override
  String get aiValRationale => '依据';

  @override
  String get aiValSource => '来源';

  @override
  String get aiValDismiss => '不用';

  @override
  String get aiValAdopt => '采用';

  @override
  String get aiValNoRecords => '暂无估值记录';

  @override
  String get locSet => '设置位置';

  @override
  String get locChange => '修改位置';

  @override
  String get locClear => '清除位置';

  @override
  String locLocatedBuiltin(String name) {
    return '已定位：$name（内置城市坐标）';
  }

  @override
  String locLocatedAiPrecise(String name) {
    return 'AI 已定位：$name（精确位置）';
  }

  @override
  String locLocatedAiCity(String name) {
    return 'AI 已定位：$name（城市中心）';
  }

  @override
  String locLocatedFallback(String name) {
    return '已定位：$name';
  }

  @override
  String locDialogTitle(String name) {
    return '「$name」的位置';
  }

  @override
  String get locDialogSubtitle => '设置后该资产将以呼吸标记出现在 3D 资产地球上';

  @override
  String get locNameLabel => '位置名（如 上海·前滩）';

  @override
  String get locLatitudeLabel => '纬度 (-90 ~ 90)';

  @override
  String get locLongitudeLabel => '经度 (-180 ~ 180)';

  @override
  String get locCoordNote => '坐标为 WGS84；国内资产可用城市快选后在地图 App 里查小区坐标微调';

  @override
  String loadFailedReports(String e) {
    return '加载失败：$e';
  }

  @override
  String get reportCancel => '取消';

  @override
  String get reportSave => '保存';

  @override
  String get assetAllocation => '资产配置';

  @override
  String get setTargetAllocation => '设置目标配置';

  @override
  String get allocNoAssetsHint => '还没有资产。记账后这里会展示你的资产结构。';

  @override
  String allocMissingValuations(num n) {
    return '⚠ $n 个账户估值缺失（按 0 计入占比）';
  }

  @override
  String get rebalanceAdviceTitle => '再平衡建议（5/25 带宽法）';

  @override
  String get rebalanceAdviceNote =>
      '偏离超过 max(5 个百分点, 目标的 25%) 时提醒，交易回带边（非回到目标，降低换手）。';

  @override
  String get allocWithinBand => '配置均在目标带宽内 ✓';

  @override
  String allocTargetPct(num n) {
    return '目标 $n%';
  }

  @override
  String get rebalanceBuy => '买入';

  @override
  String get rebalanceSell => '卖出';

  @override
  String rebalanceAdviceDetail(String current, String target) {
    return '当前 $current% → 回到带宽边 $target%±带';
  }

  @override
  String get targetAllocationTitle => '目标配置';

  @override
  String get targetAllocationHint =>
      '各类占全部资产的百分比，合计 ≤ 100%。留空 = 不设目标（不参与再平衡提醒）。';

  @override
  String targetSumExceeded(num n) {
    return '合计 $n%（超过 100%）';
  }

  @override
  String targetSumRemaining(num sum, num rest) {
    return '合计 $sum% · 未设目标/未分配 $rest%';
  }

  @override
  String get fireTitle => '财务独立（FIRE）';

  @override
  String get fireTuneTooltip => '调整参数与模拟';

  @override
  String get fireEmptyHint =>
      '记录一段时间的收支后，这里会给出“多少钱可以财务自由”的测算。\n口径：FI 门槛 = 年支出 ÷ 提取率（4% 法则），可投资净资产 = 净资产 − 固定资产 − 长期权益。';

  @override
  String get fiNumberToday => 'FI 门槛（今天的钱）';

  @override
  String get investableCoverage => '可投资净资产覆盖';

  @override
  String coverageHistoryMonths(num n) {
    return '（历史 $n 个月）';
  }

  @override
  String get fiTimeToReach => '默认假设下达标';

  @override
  String get fiUnreachable => '不可达（提高储蓄或收益假设）';

  @override
  String get fiReached => '已达标 🎉';

  @override
  String fiYearsAway(num n) {
    return '≈ $n 年';
  }

  @override
  String get fireDefaultsNote =>
      '默认：名义收益 5% · 通胀 2.5% · 提取率 4% · 储蓄取近 12 个月实绩。点右上角调整并跑蒙特卡洛。';

  @override
  String get firePlannerTitle => '财务独立（FIRE）规划器';

  @override
  String get firePlannerNote =>
      'FI 门槛 = 年支出 ÷ 提取率；累积期逐月精确复利（名义收益、目标随通胀增长）。蒙特卡洛为实际口径（已扣通胀），固定种子可复现。';

  @override
  String get recalculate => '重新测算';

  @override
  String get investableNetWorthField => '可投资净资产（元）';

  @override
  String get annualSavingsField => '年储蓄（元，可负）';

  @override
  String get targetAnnualSpendField => '目标年支出（元）';

  @override
  String get nominalReturnField => '名义收益 %/年';

  @override
  String get inflationField => '通胀 %/年';

  @override
  String get withdrawalRateField => '提取率 %（4=4% 法则）';

  @override
  String withdrawalVolPct(String v) {
    return '提取期波动率 $v%';
  }

  @override
  String get calcResults => '测算结果';

  @override
  String get currentCoverage => '当前覆盖率';

  @override
  String get timeToFi => '达标时间';

  @override
  String fiUnreachableWithin(num n) {
    return '不可达（$n 年内）';
  }

  @override
  String fiYearsMonths(num years, num months) {
    return '≈ $years 年（$months 个月）';
  }

  @override
  String get requiredSavingsTitle => '反解：想 N 年达标每年要存多少';

  @override
  String fiWithinYears(num n) {
    return '$n 年内达标';
  }

  @override
  String get mcTitle => '蒙特卡洛 · 达标后提取 30 年';

  @override
  String get mcSurvivalLabel => '生存率（1000 条路径）';

  @override
  String get mcPercentileLabel => '期末余额分位（年支出倍数）';

  @override
  String mcNote(String vol) {
    return '期初 = FI 门槛（提取率倒数倍年支出），每年提取 1 倍并按随机实际收益增长；波动率 $vol%。模拟为启发式参考，不构成投资建议。';
  }

  @override
  String get fiUnreachableShort => '不可达';

  @override
  String get fiReachedShort => '已达标';

  @override
  String yearsShort(num n) {
    return '$n 年';
  }

  @override
  String get sensitivityTitle => '敏感性：收益 ±1pp × 支出 ±10%';

  @override
  String get baseline => '基准';

  @override
  String sensReturnRow(String sign, num n) {
    return '收益$sign$n pp';
  }

  @override
  String get sensitivityColsNote =>
      '列：支出 ×0.9 / ×1.0 / ×1.1（能省 10% 比多赚 1 个点更有力）';

  @override
  String get portfolioTitle => '投资组合';

  @override
  String get noHoldingsHint => '还没有持仓。在总览「添加资产」新建持仓账户后，用「买入」记录第一笔投资。';

  @override
  String holdingQtyShares(String q) {
    return '$q 份';
  }

  @override
  String holdingCostHint(String cost) {
    return ' · 成本 $cost';
  }

  @override
  String get missingPrice => '缺价';

  @override
  String skippedFxFlows(num n) {
    return '⚠ $n 笔含外币流水因缺历史汇率未计入 XIRR';
  }

  @override
  String get xirrTwrTooltip => 'XIRR 资金加权（含你的加减仓时点影响）；TWR 时间加权（剔除资金进出，衡量标的表现）';

  @override
  String annualizedXirr(String v) {
    return '年化 XIRR $v%';
  }

  @override
  String annualizedTwr(String v) {
    return '年化 TWR $v%';
  }

  @override
  String get myCpiTitle => '我的通胀 · 近 12 个月';

  @override
  String get myCpiEmptyHint =>
      '记账满 6 个月后，这里会用你自己的消费篮子计算“你的生活成本通胀”（固定篮子口径：维持基期消费结构不变，现在要多花多少）。';

  @override
  String aboveAssumedInflation(String v) {
    return '高于假设通胀 $v%';
  }

  @override
  String notAboveAssumedInflation(String v) {
    return '不高于假设通胀 $v%';
  }

  @override
  String basketCoverageWarning(String v) {
    return '⚠ 篮子覆盖率 $v%（消费结构变化较大，解读需谨慎）';
  }

  @override
  String cpiMethodNote(num base, num recent) {
    return '基期 $base 个月 vs 近期 $recent 个月的月均支出；口径：维持基期消费结构不变的价格指数近似（固定篮子 Laspeyres）。';
  }

  @override
  String basketShareHint(String share, String ratio) {
    return '占篮子 $share% · 近期/基期 ×$ratio';
  }

  @override
  String reportYearTitle(num year) {
    return '年度 · $year 年';
  }

  @override
  String reportMonthTitle(num year, num month) {
    return '月报 · $year 年 $month 月';
  }

  @override
  String get prevPeriod => '上一期';

  @override
  String get nextPeriod => '下一期';

  @override
  String get nwChangeBreakdown => '净资产变化分解';

  @override
  String get residualTooltip => '差额非 0 通常意味着缺估值、漏记或导入重复';

  @override
  String pendingReviewChip(String v) {
    return '待核对 $v';
  }

  @override
  String get netWorthOpening => '期初净资产';

  @override
  String get attributionIncomeExpense => '收支贡献';

  @override
  String get attributionRealized => '投资损益·已实现';

  @override
  String get attributionDividend => '投资损益·分红';

  @override
  String get attributionUnrealizedDelta => '投资损益·未实现变化';

  @override
  String get attributionFx => '汇兑影响';

  @override
  String get attributionOtherValuation => '其他估值变化';

  @override
  String get attributionCorrection => '范围/历史修正';

  @override
  String get attributionResidual => '待核对差额';

  @override
  String get netWorthClosing => '期末净资产';

  @override
  String get incomeMix => '收入构成';

  @override
  String get expenseMix => '消费构成';

  @override
  String get closingBalanceSheetMix => '期末资产负债构成';

  @override
  String get valuationMissingSuffix => '（缺估值）';

  @override
  String get valuationStaleSuffix => '（估值过期）';

  @override
  String get monthlyReport => '月报';

  @override
  String get yearlyReport => '年度';

  @override
  String get riskTitle => '风险与风险调整后收益';

  @override
  String get riskFreeRateTooltip => '无风险利率（Sharpe/Sortino 参数）';

  @override
  String riskNeedMorePoints(num n) {
    return '需要至少 2 个有效月末估值点（当前 $n 个）。\n每月给持仓更新一次价格，即可得到回撤、波动率等风险画像。';
  }

  @override
  String riskSmallSample(num n) {
    return '⚠ 有效样本 $n 个月（< 6），指标波动大，仅供参考';
  }

  @override
  String get annualizedReturnTwr => '年化收益（TWR）';

  @override
  String get annualizedVolatility => '年化波动率';

  @override
  String get sharpeRatio => 'Sharpe 比率';

  @override
  String get sharpeFormulaHint => '(年化收益 − 无风险) / 波动率';

  @override
  String get sortinoRatio => 'Sortino 比率';

  @override
  String get sortinoHint => '下行偏差版 Sharpe';

  @override
  String get bestWorstMonth => '最佳 / 最差月';

  @override
  String get monthWinRate => '月胜率';

  @override
  String riskBasisNote(num periods, num points, String rf) {
    return '基于 $periods 个月度子期间（近 36 个月中 $points 个有效月末估值点）· 无风险利率 $rf%';
  }

  @override
  String drawdownSpan(String peak, String trough) {
    return '$peak 峰 → $trough 谷';
  }

  @override
  String get maxDrawdown => '最大回撤';

  @override
  String get riskFreeRateDialogTitle => '无风险利率（年化 %）';

  @override
  String get riskFreeRateHint => '如 2.0（十年期国债收益率附近）';

  @override
  String yearSummaryTitle(num year) {
    return '$year 年总览';
  }

  @override
  String get yearTotalIncome => '全年收入';

  @override
  String get yearTotalExpense => '全年消费';

  @override
  String get surplus => '结余';

  @override
  String get savingsRate => '储蓄率';

  @override
  String get savingsRateTooltip => '结余 / 收入';

  @override
  String get positiveSurplusMonths => '结余为正的月份';

  @override
  String get interestPaid => '支付利息';

  @override
  String get interestPaidTooltip => '全年债务成本';

  @override
  String get realizedPnl => '已实现投资损益';

  @override
  String get realizedPnlTooltip => '卖出落袋（账面口径）';

  @override
  String get dividends => '分红派息';

  @override
  String get netInvestmentGain => '投资净收益';

  @override
  String get netInvestmentGainTooltip => '已实现 + 分红';

  @override
  String get monthlyCashflow => '月度收支';

  @override
  String get incomeLabel => '收入';

  @override
  String get expenseLabel => '支出';

  @override
  String barTooltipMonth(num n, String amount) {
    return '$n 月\n$amount';
  }

  @override
  String get yearExpenseRanking => '全年消费排行';

  @override
  String get yearHighlights => '年度亮点';

  @override
  String biggestExpense(String label) {
    return '最大单笔：$label';
  }

  @override
  String get expenseFallback => '消费';

  @override
  String get loanPrincipalRepaid => '全年还贷本金';

  @override
  String incomeCategoryEntry(String name) {
    return '收入 · $name';
  }

  @override
  String get globeTitle => '资产地球';

  @override
  String get globeBackToOverview => '返回总览';

  @override
  String get globeResetView => '复位视角';

  @override
  String get globeFullscreen => '全屏地球';

  @override
  String get globeAssetCategory => '资产类别';

  @override
  String get globeInstitution => '机构';

  @override
  String get globeCurrentValue => '当前价值';

  @override
  String get globeValuationMissingExcluded => '缺估值（不计净资产）';

  @override
  String get globeValuationStale => '已过期（>30 天未更新）';

  @override
  String get globeDenominationCurrency => '计价币种';

  @override
  String get globeViewAndEdit => '查看与编辑';

  @override
  String globeMoreSameLocation(num n) {
    return '同址还有 $n 处资产';
  }

  @override
  String get globeValuationMissing => '缺估值';

  @override
  String homeLoadFailed(Object error) {
    return '加载失败：$error';
  }

  @override
  String get homeTodoTooltip => '待办事项';

  @override
  String homeTodoPending(num n) {
    return '待办 · $n 项待处理，点击查看';
  }

  @override
  String get homeAiTooltip => 'AI 助手';

  @override
  String get homeSettingsTooltip => '设置';

  @override
  String get homeLocateCurrentTooltip => '定位当前位置';

  @override
  String get homeLocating => '定位中…';

  @override
  String homeLocatedExact(String city) {
    return '已定位当前位置：$city';
  }

  @override
  String homeLocatedEstimate(String city) {
    return '定位服务不可用，已按本地时区估计：$city';
  }

  @override
  String get homeAddAsset => '添加资产';

  @override
  String get homeAddAssetTooltip => '新建资产/负债账户，为资产选位置即点亮地球';

  @override
  String get homeLogTransaction => '记一笔';

  @override
  String get homeLogTransactionTooltip => '上报消费 / 收入 / 转账等日常流水';

  @override
  String get homeCollapse => '收起';

  @override
  String get homeQuickAdd => '记一笔 / 添加资产';

  @override
  String get homeCollapseQuickMenu => '收起快捷菜单';

  @override
  String get homeAddSemantic => '添加：记一笔或添加资产';

  @override
  String get homeRefreshing => '刷新中…';

  @override
  String get homeRefreshData => '刷新数据';

  @override
  String get homeNwCardHint => '月报 · 净资产变化分解';

  @override
  String get homeFlowCardHint => '流水 · 本月全部收支';

  @override
  String get homeHealthCardHint => '月报 · 体检与构成明细';

  @override
  String get homeAssetsCardHint => '资产 · 全部账户台账与编辑';

  @override
  String get homeBudgetCardHint => '预算 · 额度与配速';

  @override
  String get homeTrendCardHint => '月报 · 历史走势与归因';

  @override
  String get homePlansCardHint => '计划 · 固定开销与预定支出';

  @override
  String homeAutoPosted(num n) {
    return '已按计划自动记入 $n 笔交易，可在流水中查看（来源：计划）';
  }

  @override
  String get dashNetWorth => '净资产';

  @override
  String dashAsOf(String date) {
    return '截至 $date';
  }

  @override
  String dashMyShare(String amount) {
    return '我的份额 $amount';
  }

  @override
  String dashAssetsAmount(String amount) {
    return '资产 $amount';
  }

  @override
  String dashLiabAmount(String amount) {
    return '负债 $amount';
  }

  @override
  String get dashResidualTooltip => '差额非 0 通常意味着缺估值、漏记或导入重复（月报页有明细）';

  @override
  String dashPendingReview(String amount) {
    return '待核对 $amount';
  }

  @override
  String get dashTotalAssets => '总资产';

  @override
  String get dashTotalLiabilities => '总负债';

  @override
  String dashMonthFlow(num m) {
    return '本月收支（$m 月）';
  }

  @override
  String get dashIncome => '收入';

  @override
  String get dashSpendFees => '消费与费用';

  @override
  String get dashSurplus => '结余';

  @override
  String get dashInvestPnl => '投资损益';

  @override
  String get dashPrincipalRepaid => '还贷本金';

  @override
  String get dashInterestPaid => '支付利息';

  @override
  String dashSpendable(num n) {
    return '还能花多少（未来 $n 天）';
  }

  @override
  String dashForecastThrough(String date) {
    return '现金流预测截至 $date';
  }

  @override
  String get dashDiscretionaryCap => '计划外可支配上限';

  @override
  String get dashDiscretionaryCapHint => '已扣除固定计划、还款、准备金与现金底线';

  @override
  String get dashMonthSpendForecast => '本月消费预测';

  @override
  String get dashMonthSpendForecastHint => '按当前速度外推到月末';

  @override
  String get dashDailyAllowance => '剩余日均可花';

  @override
  String dashDaysElapsed(num n) {
    return '本月已过 $n 天';
  }

  @override
  String get dashCashLowPoint => '现金最低点';

  @override
  String dashShortfall(String label, String date) {
    return '$label（$date）短缺';
  }

  @override
  String get dashHealthTitle => '财务体检';

  @override
  String get dashSavingsRate => '储蓄率';

  @override
  String get dashSavingsRateHint => '本月（收入−消费）/收入';

  @override
  String get dashEmergencyMonths => '应急月数';

  @override
  String get dashEmergencyMonthsHint => '流动资产/月均消费';

  @override
  String get dashDebtToAsset => '资产负债率';

  @override
  String get dashDebtToAssetHint => '总负债/总资产';

  @override
  String get dashInsights => '智慧洞察';

  @override
  String get dashNwTrend => '净资产走势';

  @override
  String dashNwTrendMonths(num n) {
    return '净资产走势（近 $n 个月）';
  }

  @override
  String dashNwTrendHint(num n) {
    return '按住底部滚筒左右拖动：从 1 个月拉长到 $n 个月';
  }

  @override
  String dashRollerHint(num n) {
    return '按住滚筒左右拖动：1 ~ $n 个月';
  }

  @override
  String get dashUpcomingTitle => '未来 30 天要花的钱';

  @override
  String get dashNoUpcoming => '暂无计划支出';

  @override
  String dashPendingDue(num n) {
    return '$n 笔到期计划待入账（计划页可一键记入）';
  }

  @override
  String dashMissingValuations(num n) {
    return '$n 个账户缺估值（不计为 0，请编辑账户补录）';
  }

  @override
  String dashStaleValuations(num n) {
    return '$n 个账户估值已过期（>30 天）';
  }

  @override
  String dashResidualIssue(String amount) {
    return '本月归因存在待核对差额：$amount';
  }

  @override
  String get dashIssuesTitle => '待处理';

  @override
  String get dashBalanceSheet => '资产负债表';

  @override
  String get dashAssetsTotal => '资产合计';

  @override
  String get dashLiabilitiesTotal => '负债合计';

  @override
  String get dashIncludedAccounts => '计入账户';

  @override
  String dashAccountCount(num n) {
    return '$n 项';
  }

  @override
  String get dashValuationStatus => '估值状态';

  @override
  String dashMissingCount(num n) {
    return '$n 项缺估值';
  }

  @override
  String dashStaleCount(num n) {
    return '$n 项已过期';
  }

  @override
  String get aiAssistant => 'AI 助手';

  @override
  String get aiHistorySessions => '历史会话';

  @override
  String get aiBindKeyFirst => '先在 设置 → AI 服务 绑定你自己的 AI Key';

  @override
  String aiAssistantError(String error) {
    return 'AI 助手：$error';
  }

  @override
  String get aiSessions => '会话';

  @override
  String get aiNewChat => '新对话';

  @override
  String get aiNoSessionsHint => '还没有会话，点右上「+」开始第一段对话。';

  @override
  String get aiDeleteChat => '删除会话';

  @override
  String get aiLedgerContextOn => '已附带账本概况：净资产、本月收支等汇总数字会发给 AI（不含逐笔明细）';

  @override
  String get aiLedgerContextOff => '未附带账本数据：AI 只作通用回答';

  @override
  String get aiAskSomething => '问点什么，或从下面开始';

  @override
  String get aiInputHint => '问你的账房先生…（Enter 发送）';

  @override
  String get aiSend => '发送';

  @override
  String get aiPromptSpendWhere => '我的钱都花哪儿了？';

  @override
  String get aiPromptNwTrend => '净资产最近走势如何？';

  @override
  String get aiPromptSaveMonth => '这个月怎么省下一笔？';

  @override
  String get aiPromptPrepay => '现在适合提前还贷吗？';

  @override
  String aiValuationsUpdated(num n) {
    return 'AI 已更新 $n 项资产估值（来源可审计，可在账户详情纠正）';
  }

  @override
  String aiValuationsUpdatedFailed(num n) {
    return 'AI 已更新 $n 项资产估值（部分失败，可在账户详情查看）';
  }

  @override
  String get commonCancel => '取消';

  @override
  String get commonSave => '保存';

  @override
  String get commonEdit => '编辑';

  @override
  String get commonVoid => '作废';

  @override
  String get commonGotIt => '知道了';

  @override
  String get fieldType => '类型';

  @override
  String get dirIncome => '收入';

  @override
  String get dirExpense => '支出';

  @override
  String get txAddTitle => '记一笔';

  @override
  String get txEditTitle => '编辑交易';

  @override
  String get txPageTitle => '流水';

  @override
  String get txExportCsvTooltip => '导出 CSV（明文，自选位置）';

  @override
  String get txImportCsvTooltip => '导入账单 CSV';

  @override
  String get txSearchHint => '搜索全账本：备注、对方、标签';

  @override
  String get txEmptyTitle => '还没有流水';

  @override
  String get txNoMatchTitle => '没有匹配的交易';

  @override
  String get txEmptyHint => '右下角「记一笔」，或从设置导入账单 CSV。';

  @override
  String get txNoMatchHint => '换个关键词，或清除类型筛选再试。';

  @override
  String get txNoMatchHintWide => '换个关键词，或清除右侧类型筛选再试。';

  @override
  String get txExportedToast => '已导出流水 CSV（含 BOM，Excel 可直接打开）';

  @override
  String get txAccountLabel => '账户';

  @override
  String get txAccountPayFrom => '支付账户';

  @override
  String get txAccountDeposit => '入账账户';

  @override
  String get txAccountTransferFrom => '转出账户';

  @override
  String get txAccountTransferTo => '转入账户';

  @override
  String get txAccountRepayCard => '偿还卡片';

  @override
  String get txAccountRepayFrom => '还款来源';

  @override
  String get txAccountLoan => '贷款账户';

  @override
  String get txAccountBorrowTo => '借入到';

  @override
  String get txAccountBorrowToAsset => '借入到账账户（资产）';

  @override
  String get txAccountLendReceivable => '借出（挂应收）';

  @override
  String get txAccountReceiveBackTo => '收回至';

  @override
  String get txAccountCounterpartyCash => '对方现金账户';

  @override
  String get txAccountB => '账户 B';

  @override
  String get txInterestCategory => '利息分类';

  @override
  String get txCategory => '分类';

  @override
  String get txNoteOptional => '备注（可选）';

  @override
  String get txVoidedBadge => '已作废';

  @override
  String get txPostingsTitle => '分录（借贷平衡）';

  @override
  String txShares(String q) {
    return '$q 份';
  }

  @override
  String txExternalId(String id) {
    return '外部 ID：$id';
  }

  @override
  String get txVoidConfirmTitle => '作废此交易？';

  @override
  String get txVoidConfirmMessage => '作废后分录不再计入余额与统计，但保留审计痕迹。';

  @override
  String get monthExpense => '本月支出';

  @override
  String get monthIncome => '本月收入';

  @override
  String get monthSurplus => '本月结余';

  @override
  String get monthThis => '本月';

  @override
  String get monthSpent => '已支出';

  @override
  String get monthCnyOnlyTooltip => '仅统计人民币流水，避免混币求和失真';

  @override
  String get filterPanelHint => '按交易种类过滤台账；搜索不受此筛选限制';

  @override
  String get importTitle => '导入账单';

  @override
  String get importFileTypeBills => '账单';

  @override
  String importStepHeader(num n, String title) {
    return '第 $n/4 步 · $title';
  }

  @override
  String get importStepPickFile => '选择文件';

  @override
  String get importStepChooseAccount => '选择账户';

  @override
  String get importStepPreview => '预览与分类';

  @override
  String get importStepDone => '完成';

  @override
  String get importParsePreview => '解析预览';

  @override
  String get importConfirm => '确认入账';

  @override
  String get importPickFileHint =>
      '微信 / 支付宝导出的原生账单（CSV，GBK 或 UTF-8）自动识别列名与交易单号，无需改表头；其他 CSV 需表头含 date、type、amount 三列。';

  @override
  String get importChooseCsvFile => '选择 CSV 文件';

  @override
  String importParseFailed(String error) {
    return '解析失败：$error';
  }

  @override
  String get importTargetAccount => '入到哪个账户';

  @override
  String importFileName(String file) {
    return '文件：$file';
  }

  @override
  String importRowsDetected(num n) {
    return '已识别 $n 行';
  }

  @override
  String get importDefaultExpenseCategory => '支出默认分类';

  @override
  String get importDefaultIncomeCategory => '收入默认分类';

  @override
  String get importReadyToPost => '可入账';

  @override
  String importLineCount(num n) {
    return '$n 行';
  }

  @override
  String get importExactDuplicates => '精确重复跳过';

  @override
  String get importCategoryHits => '智慧分类命中';

  @override
  String importCategoryHitsDetail(num n) {
    return '$n 行（规则+历史学习）';
  }

  @override
  String get importParserSkipped => '原生解析跳过';

  @override
  String get importTransferSuggestions => '转账配对建议';

  @override
  String importTransferSuggestionDetail(num n) {
    return '$n 条（导入后可在流水页人工合并）';
  }

  @override
  String get importNoCounterparty => '(无对方)';

  @override
  String importPostedCount(num n) {
    return '已入账 $n 笔';
  }

  @override
  String get importDoneHint => '重复导入同一文件会自动跳过（外部 ID 幂等）。对手方分类已被学习，下次导入会自动建议。';

  @override
  String get strategyCompareTitle => '还款策略对比';

  @override
  String get strategySubtitle => '在最低还款之外，每月额外拿出一笔钱优先还某一笔债';

  @override
  String get strategyExtraMonthly => '每月额外还款额';

  @override
  String get strategyResimulate => '重新模拟';

  @override
  String get strategyNoDebt => '没有待还负债';

  @override
  String get strategyAvalancheTitle => '雪崩法 · 高利率优先';

  @override
  String get strategySnowballTitle => '雪球法 · 小额优先';

  @override
  String strategyAvalancheSaves(String amount) {
    return '雪崩法比雪球法少付利息 $amount；若你需要\"先清掉一笔\"的成就感，选雪球也完全合理。';
  }

  @override
  String get strategyPayoffTime => '还清时间';

  @override
  String strategyDuration(num years, num months) {
    return '$years 年 $months 个月';
  }

  @override
  String get strategyTotalInterest => '总利息';

  @override
  String get strategyPayoffOrder => '还清顺序';

  @override
  String get debtPageTitle => '负债';

  @override
  String get debtStrategyTooltip => '雪崩 vs 雪球策略对比';

  @override
  String get debtNew => '新建负债';

  @override
  String get debtEmptyTitle => '还没有负债';

  @override
  String get debtEmptyHint => '登记信用卡、房贷、花呗等负债后，这里给出还款计划与压力模拟。';

  @override
  String get debtOverviewTitle => '负债总览';

  @override
  String get debtTotalBase => '总负债（折本位币）';

  @override
  String get debtTotalBaseTooltip => '按账本内最近汇率折算本位币汇总；无汇率的外币计 0';

  @override
  String get debtCountLabel => '笔数';

  @override
  String debtCountValue(num n) {
    return '$n 笔';
  }

  @override
  String get debtWorstApr => '最高实际年化';

  @override
  String get debtWorstAprTooltip => 'IRR 口径；费用率类负债明显高于名义利率';

  @override
  String get debtRepayMethod => '还款方式';

  @override
  String get debtNominalApr => '名义年利率';

  @override
  String get debtNominalAprField => '名义年利率 %（如 3.85）';

  @override
  String get debtTermLabel => '期数';

  @override
  String debtTermCount(num n) {
    return '$n 期';
  }

  @override
  String get debtTermMonthsField => '期数（月）';

  @override
  String get debtEffectiveApr => '实际年化';

  @override
  String get debtEffectiveAprTooltip => 'IRR 口径，费用率类负债明显更高';

  @override
  String debtNextRepay(
    num month,
    num day,
    String total,
    String principal,
    String interest,
  ) {
    return '下期 $month/$day 还 $total（本金 $principal + 利息 $interest）';
  }

  @override
  String get debtRepayNext => '按计划还款';

  @override
  String get debtPrepaySim => '提前还款模拟';

  @override
  String get debtNoScheduleSnackBar => '没有待还期数（或为手工计划）';

  @override
  String debtPrepaySimTitle(String name) {
    return '提前还款模拟 · $name';
  }

  @override
  String debtRemainingPrincipal(String amount) {
    return '当前剩余本金 $amount';
  }

  @override
  String get debtExtraPayment => '额外偿还金额';

  @override
  String get debtSimulate => '模拟';

  @override
  String get debtSimResultTitle => '模拟结果';

  @override
  String debtSimFee(String fee) {
    return '手续费：$fee';
  }

  @override
  String debtSimInterestSaved(String saved) {
    return '利息净节省：$saved';
  }

  @override
  String debtSimRemaining(num n) {
    return '剩余期数：$n 期';
  }

  @override
  String debtSimMonthsSaved(num n) {
    return '（少 $n 期）';
  }

  @override
  String get debtNameField => '名称';

  @override
  String get debtPrincipal => '本金';

  @override
  String get debtStartDate => '起始日';

  @override
  String get wdgCancel => '取消';

  @override
  String get wdgConfirm => '确认';

  @override
  String get wdgSave => '保存';

  @override
  String get wdgDelete => '删除';

  @override
  String wdgLoadFailed(String e) {
    return '加载失败：$e';
  }

  @override
  String get wdgBack => '返回';

  @override
  String get wdgAmount => '金额';

  @override
  String get wdgDate => '日期';

  @override
  String get wdgCloseEsc => '关闭 (Esc)';

  @override
  String get wdgDialogBarrier => '关闭弹窗';

  @override
  String get wdgSheetBarrier => '关闭面板';

  @override
  String get wdgMinimize => '最小化';

  @override
  String get wdgRestoreDown => '向下还原';

  @override
  String get wdgMaximize => '最大化';

  @override
  String get wdgClose => '关闭';

  @override
  String wdgDeltaWithPercent(String amount, String arrow, String pct) {
    return '$amount（$arrow $pct%）';
  }

  @override
  String get budgetPageTitle => '预算';

  @override
  String get budgetCreate => '新建预算';

  @override
  String get budgetEmptyTitle => '还没有预算';

  @override
  String get budgetEmptyMessage =>
      '从月度总预算开始，或给餐饮、购物等分类单独设额度，首页会按当前消费速度预测月末是否超支。';

  @override
  String get budgetMonthTitle => '本月预算';

  @override
  String get budgetOverspentHero => '已超支';

  @override
  String get budgetRemainingHero => '剩余可花';

  @override
  String get budgetTotalLimit => '总额度';

  @override
  String get budgetSpent => '已花';

  @override
  String get budgetOverEnvelopes => '超支信封';

  @override
  String budgetEnvelopeCount(num n) {
    return '$n 只';
  }

  @override
  String budgetTotalUsagePct(String v) {
    return '总用量 $v%';
  }

  @override
  String get budgetMonthTotalLimit => '本月总额度';

  @override
  String get budgetRemaining => '剩余';

  @override
  String budgetOverAmount(String amount) {
    return '超支 $amount';
  }

  @override
  String budgetRemainingAmount(String amount) {
    return '剩余 $amount';
  }

  @override
  String get budgetEnvelopeActions => '信封操作';

  @override
  String get budgetDelete => '删除预算';

  @override
  String get budgetLimit => '额度';

  @override
  String get budgetPlanned => '计划占用';

  @override
  String get budgetPlannedTooltip => '未来计划将落在这只信封里的金额';

  @override
  String get budgetDeleteConfirmTitle => '删除预算？';

  @override
  String budgetDeleteConfirmMessage(String name) {
    return '「$name」的额度记录将被删除，已发生的消费不受影响。';
  }

  @override
  String budgetForecastExceed(String projected, String over) {
    return '按当前配速月底将花 $projected（超 $over）';
  }

  @override
  String budgetForecastOk(String projected, String daily) {
    return '按当前配速月底约花 $projected，剩余日均可花 $daily';
  }

  @override
  String get budgetMonthlyTotalName => '月度总预算';

  @override
  String get budgetCategoryBudget => '分类预算';

  @override
  String get budgetScopeTotal => '总预算';

  @override
  String get budgetCategoryField => '分类';

  @override
  String get budgetMonthlyLimitField => '每月额度（元）';

  @override
  String get budgetNameOptionalField => '名称（可选）';

  @override
  String get goalsPageTitle => '目标与准备金';

  @override
  String get goalNew => '新建目标';

  @override
  String get goalEmptyTitle => '还没有目标';

  @override
  String get goalEmptyMessage => '用目标为大额支出提前留钱：旅行、保费、学费、设备……';

  @override
  String get goalSummaryTitle => '目标合计';

  @override
  String get goalSummaryHint => '为大额支出提前留钱的准备金总览';

  @override
  String get goalReserved => '已留';

  @override
  String get goalTotalTarget => '目标总额';

  @override
  String get goalTotalGap => '总缺口';

  @override
  String get goalCount => '目标数';

  @override
  String goalItems(num n) {
    return '$n 个';
  }

  @override
  String get goalActions => '目标操作';

  @override
  String get goalAddReserve => '增加预留';

  @override
  String get goalDelete => '删除目标';

  @override
  String get goalTarget => '目标';

  @override
  String get goalGap => '缺口';

  @override
  String get goalMonthlyNeed => '每月需留';

  @override
  String get goalMonthlyNeedTooltip => '目标日已过或已留满，无需再留';

  @override
  String goalDaysLeft(num n) {
    return '还有 $n 天';
  }

  @override
  String goalOverdueBy(num n) {
    return '已过期 $n 天';
  }

  @override
  String get goalDeleteConfirmTitle => '删除目标？';

  @override
  String goalDeleteConfirmMessage(String name) {
    return '「$name」的预留记录将删除，已发生的转账不受影响。';
  }

  @override
  String goalReserveTitle(String name) {
    return '为「$name」增加预留';
  }

  @override
  String get goalNameField => '名称';

  @override
  String get goalAmountField => '目标金额';

  @override
  String get goalDateField => '目标日期';

  @override
  String get lockOpeningLedger => '正在打开加密账本…';

  @override
  String get lockWelcome => '欢迎来到资观';

  @override
  String lockOpenFailed(String e) {
    return '打开失败：$e';
  }

  @override
  String lockCreateFailed(String e) {
    return '创建失败：$e';
  }

  @override
  String get lockPassphraseRule => '主口令至少 8 位；建议 12 位以上 passphrase';

  @override
  String get lockPassMismatch => '两次输入不一致';

  @override
  String get lockWeakPassphrase => '口令强度不足：请更长或混合字符类型';

  @override
  String get lockEnterPrompt => '请输入主口令或恢复码';

  @override
  String get lockWrongCredential => '主口令或恢复码不正确';

  @override
  String lockUnlockFailed(String e) {
    return '解锁失败：$e';
  }

  @override
  String get lockUnlocking => '正在解锁加密账本…';

  @override
  String get lockUnlocked => '已解锁';

  @override
  String get lockSaveRecoveryTitle => '请离线保存恢复码';

  @override
  String get lockRecoveryIntro => '恢复码是丢失主口令后唯一的自救方式。请抄写在安全的地方（不要拍照存云端）。';

  @override
  String get lockRecoverySaved => '我已保存，进入账本';

  @override
  String get lockCreateHint => '创建加密账本：设定主口令（8 位以上）';

  @override
  String get lockPassphraseTooltip => '主口令派生密钥加密全部数据，无法找回，只能用恢复码自救';

  @override
  String get lockRepeatPassphrase => '再输入一遍主口令';

  @override
  String get lockUnlockHint => '输入主口令或恢复码';

  @override
  String get lockRecoveryNotice => '也可直接输入恢复码解锁';

  @override
  String get lockForgotPassphrase => '忘记主口令？使用恢复码';

  @override
  String get shellCollapseMenu => '收起分类菜单';

  @override
  String get shellExpandMenu => '展开分类菜单';

  @override
  String get shellMenuLabel => '分类菜单';

  @override
  String get shellNavTitle => '分类导航';

  @override
  String get shellPinnedTip => '已固定：菜单保持展开';

  @override
  String get shellUnpinnedTip => '未固定：跳转后自动收起';

  @override
  String get globeRestorePage => '恢复页面';

  @override
  String get globeClearScreen => '清屏地球：只留中央地球';

  @override
  String ovMonths(num n) {
    return '近 $n 个月';
  }

  @override
  String get ovTrGoReport => '查看月报归因';

  @override
  String get ovNwTitle => '净资产';

  @override
  String get ovNwHint => '全面了解资产总额、结构分布与账户变化。';

  @override
  String get ovNwMonthDelta => '较上月';

  @override
  String ovNwCoverage(num n, num m) {
    return '估值覆盖 $n/$m';
  }

  @override
  String get ovNwCoverageHint => '纳入净资产的账户中，已有当期估值的数量。缺失估值的账户按 0 计入并单独提示。';

  @override
  String get ovNwGlobe => '全球资产分布';

  @override
  String get ovNwGlobeHint => '已设置地理位置的资产在地球上发光；拖动旋转、滚轮缩放，点击光点查看账户。';

  @override
  String ovNwLocatedNote(num n, num m) {
    return '已定位 $n · 未定位 $m';
  }

  @override
  String get ovNwAssetTypes => '资产类型分布';

  @override
  String get ovNwAssetTypesHint => '按业务分组：现金活期、投资持仓、稳健理财、长期资产。';

  @override
  String get ovNwGroupCash => '现金活期';

  @override
  String get ovNwGroupHold => '投资持仓';

  @override
  String get ovNwGroupSteady => '稳健理财';

  @override
  String get ovNwGroupLong => '长期资产';

  @override
  String get ovNwNoAssets => '暂无资产';

  @override
  String get ovNwNoAssetsMsg => '在首页右上角添加第一笔资产，点亮你的地球。';

  @override
  String get ovNwGroupTitle => '账户分布';

  @override
  String get ovNwGroupHint => '按业务分组的资产占比。';

  @override
  String get ovNwTopAccounts => '主要资产账户';

  @override
  String get ovNwViewAll => '全部资产';

  @override
  String get ovNwMissingHint => '该账户缺当期估值，暂按 0 计入。';

  @override
  String get ovNwTrendEmpty => '走势待积累';

  @override
  String get ovNwTrendEmptyMsg => '账本满一个月后这里会长出第一条曲线。';

  @override
  String get ovNwAttribution => '本月变动归因';

  @override
  String get ovNwAttributionHint => '净资产变动拆解为收支、投资、汇率与其他估值变动；对不上的部分计入「待核对」。';

  @override
  String get ovNwNetChange => '净变动';

  @override
  String get ovNwAttrIncomeExpense => '收支结余';

  @override
  String get ovNwAttrIncomeHint => '常规收入减常规消费（不含转账与投资买卖）。';

  @override
  String get ovNwAttrInvest => '投资损益';

  @override
  String get ovNwAttrInvestHint => '已实现损益 + 分红 + 未实现损益变动。';

  @override
  String get ovNwAttrFx => '汇率影响';

  @override
  String get ovNwAttrFxHint => '外币头寸的重估影响与换汇损益。';

  @override
  String get ovNwAttrOther => '其他估值变动';

  @override
  String get ovNwAttrOtherHint => '房产等手工估值的期初期末变动。';

  @override
  String get ovNwAttrCorrection => '数据修正';

  @override
  String get ovNwAttrCorrectionHint => '权益类科目的调整（历史修正等）。';

  @override
  String get ovNwAttrResidual => '待核对';

  @override
  String get ovCfTitle => '本月收支';

  @override
  String get ovCfHint => '了解每一笔现金流，掌握消费结构与月度预算。';

  @override
  String get ovCfIncomeHint => '按收入科目账户汇总；投资收益在归因页单独披露。';

  @override
  String get ovCfExpenseHint => '实际消费与费用；信用卡消费计入当月。';

  @override
  String get ovCfSurplusHint => '收入减消费。内部转账不算收支，买入资产不算消费。';

  @override
  String get ovCfDailyTitle => '每日收支趋势';

  @override
  String get ovCfDailyHint => '双柱为当日收入/消费，亮线为累计净额；悬停查看当天明细。';

  @override
  String get ovCfNetLine => '累计净额';

  @override
  String get ovCfExpenseCatTitle => '消费分类';

  @override
  String get ovCfExpenseCatHint => '按支出科目账户汇总。';

  @override
  String get ovCfOthers => '其他';

  @override
  String get ovCfNoExpense => '本月还没有消费记录';

  @override
  String get ovCfMonthExpense => '本月消费';

  @override
  String get ovCfIncomeTitle => '收入来源';

  @override
  String get ovCfNoIncome => '本月还没有收入记录';

  @override
  String get ovCfBudgetTitle => '预算执行';

  @override
  String get ovCfBudgetHint => '本月总预算额度 vs 实际消费。';

  @override
  String get ovCfNoBudget => '未设置预算';

  @override
  String get ovCfNoBudgetMsg => '在预算页设置月度总预算后，这里会出现执行进度。';

  @override
  String ovCfBudgetOf(String x) {
    return '额度 $x';
  }

  @override
  String get ovCfBudgetUsed => '已用';

  @override
  String get ovCfOverBy => '已超支';

  @override
  String get ovCfBudgetLeft => '剩余';

  @override
  String get ovCfHeatTitle => '收支热力';

  @override
  String get ovCfHeatHint => '颜色越深金额越大：蓝=净流入日，红=净流出日。';

  @override
  String get ovCfRecentTitle => '近期交易';

  @override
  String get ovCfRecentHint => '本月最近的收支交易，点击查看详情。';

  @override
  String get ovCfNoTx => '暂无交易';

  @override
  String get ovCfUntitled => '未命名交易';

  @override
  String get ovHlTitle => '财务体检';

  @override
  String get ovHlHint => '储蓄、应急、杠杆与固定覆盖四个维度的健康评估。';

  @override
  String get ovHlTargetSave => '建议 ≥ 30%';

  @override
  String get ovHlTargetEmergency => '建议 ≥ 6 个月';

  @override
  String get ovHlTargetLeverage => '建议 ≤ 50%';

  @override
  String get ovHlTargetCushion => '建议 ≥ 100%';

  @override
  String get ovHlCushion => '固定覆盖';

  @override
  String get ovHlCushionHint => '月末固定收入可覆盖固定支出的比例。';

  @override
  String get ovHlScoreTitle => '健康评分';

  @override
  String get ovHlScoreHint => '可得指标归一化到建议带后的平均分；数据不足时如实显示「暂无法评分」。';

  @override
  String get ovHlNoScore => '暂无法评分';

  @override
  String get ovHlExcellent => '优秀';

  @override
  String get ovHlGood => '良好';

  @override
  String get ovHlAttention => '关注';

  @override
  String get ovHlRisk => '风险';

  @override
  String ovHlMissing(String x) {
    return '还差这些数据：$x';
  }

  @override
  String ovHlScoreNote(num n) {
    return '基于 $n 项真实指标';
  }

  @override
  String get ovHlOrbitTitle => '维度巡游';

  @override
  String get ovHlOrbitHint => '四颗维度星沿轨道巡游；颜色即状态：蓝=达标，金=关注，红=风险。';

  @override
  String get ovHlRadarTitle => '目标雷达';

  @override
  String get ovHlRadarHint => '当前值（蓝）对照建议带（金）。';

  @override
  String get ovHlCurrent => '当前';

  @override
  String get ovHlTarget => '目标';

  @override
  String get ovHlPace => '消费配速';

  @override
  String ovHlPaceDays(num n) {
    return '已过 $n 天';
  }

  @override
  String get ovHlCoverage => '估值覆盖';

  @override
  String get ovHlCoverageSub => '已覆盖账户';

  @override
  String get ovHlDiagTitle => '诊断';

  @override
  String get ovHlDiagHint => '按各维度得分自动分桶：≥75% 优势、40–75% 优化空间、<40% 风险。';

  @override
  String get ovHlDiagValuation => '估值缺口';

  @override
  String get ovHlDiagGood => '优势亮点';

  @override
  String get ovHlDiagRisk => '潜在风险';

  @override
  String get ovHlDiagImprove => '优化空间';

  @override
  String get ovHlDiagEmpty => '指标数据不足，先记账一段时间再看诊断。';

  @override
  String get ovHlDiagNone => '—';

  @override
  String get ovHlActTitle => '行动建议';

  @override
  String get ovHlActHint => '按最弱维度排序，每条直达对应业务页。';

  @override
  String ovHlActValuation(num n) {
    return '补齐 $n 项估值';
  }

  @override
  String get ovHlActValuationSub => '缺估值会拉低净资产的准确性';

  @override
  String get ovHlActSave => '提高储蓄率';

  @override
  String get ovHlActSaveSub => '设置预算，先存后花';

  @override
  String get ovHlActEmergency => '充实应急金';

  @override
  String get ovHlActEmergencySub => '目标：6 个月必要支出';

  @override
  String get ovHlActLeverage => '压降负债率';

  @override
  String get ovHlActLeverageSub => '优先偿还高息负债';

  @override
  String get ovHlActCushion => '平衡固定收支';

  @override
  String get ovHlActCushionSub => '检视周期计划与还款日程';

  @override
  String get ovHlActEmpty => '各维度都在轨道上，保持。';

  @override
  String get ovHlActGo => '去处理';

  @override
  String get ovBsTitle => '资产负债表';

  @override
  String get ovBsHint => '资产、负债与净资产结构的专业分析。';

  @override
  String get ovBsAssetsHint => '全部资产账户的本位币估值合计。';

  @override
  String get ovBsLiabHint => '全部负债账户的本位币估值合计。';

  @override
  String get ovBsScaleTitle => '资产负债天平';

  @override
  String get ovBsScaleHint => '横梁倾角示意负债率：50% 时水平。仅作视觉表达，不代表财务计算。';

  @override
  String get ovBsTreemapTitle => '资产结构树图';

  @override
  String get ovBsTreemapHint => '面积 = 金额占比；点击色块查看类别。';

  @override
  String get ovBsAssetTableTitle => '资产分类';

  @override
  String get ovBsAssetTableHint => '按资产子类型；环比为期初至今。';

  @override
  String get ovBsColClass => '类别';

  @override
  String get ovBsColAmount => '金额';

  @override
  String get ovBsColShare => '占比';

  @override
  String get ovBsColDelta => '环比';

  @override
  String get ovBsLiabTableTitle => '负债分类';

  @override
  String get ovBsLiabTableHint => '按负债子类型。';

  @override
  String get ovBsNoDebt => '没有负债';

  @override
  String get ovBsNoDebtMsg => '当前没有任何负债账户。';

  @override
  String get ovBsLiquidityTitle => '流动性结构';

  @override
  String get ovBsLiquidityHint => '按变现天数分桶：≤1 天、≤90 天、>90 天。';

  @override
  String get ovBsLiquidNow => '随时可用';

  @override
  String get ovBsLiquidMid => '短期可变现';

  @override
  String get ovBsLiquidLong => '长期资产';

  @override
  String get ovBsLiabMixTitle => '负债构成';

  @override
  String get ovBsLiabMixHint => '按负债子类型的占比。';

  @override
  String get ovBsDualTitle => '资产 vs 负债';

  @override
  String get ovBsDualHint => '近 12 个月双线对比。';

  @override
  String ovSpTitle(num n) {
    return '还能花多少（$n 天）';
  }

  @override
  String get ovSpHint => '在保留准备金与已知支出的前提下，未来还能安全花多少钱。';

  @override
  String ovSpHeroTitle(num n) {
    return '安全可支配 · $n 天';
  }

  @override
  String get ovSpHeroHint => '可支配 = 每日现金 − 准备金 − 现金底线的最小值；不是全部净资产。';

  @override
  String get ovSpHeroOk => '计划外可自由安排的上限';

  @override
  String get ovSpHeroZero => '现有计划已触及安全边界，暂无计划外空间';

  @override
  String get ovSpCashNow => '可用流动资金';

  @override
  String get ovSpPlannedOut => '未来必要流出';

  @override
  String get ovSpReserved => '已预留（目标+底线）';

  @override
  String get ovSpRemain => '计划外可支配';

  @override
  String get ovSpScenTitle => '情景模拟';

  @override
  String get ovSpScenHint => '同一份期初余额与准备金，只换事件流重放。';

  @override
  String get ovSpScenConservative => '保守';

  @override
  String get ovSpScenConsSub => '只信已确认收入';

  @override
  String get ovSpScenStandard => '标准';

  @override
  String get ovSpScenStdSub => '与首页预测同口径';

  @override
  String get ovSpScenOptimistic => '乐观';

  @override
  String get ovSpScenOptSub => '可压缩的估算支出不计';

  @override
  String ovSpKpiSafe(num n) {
    return '安全可支配（$n 天）';
  }

  @override
  String get ovSpKpiMonthCap => '建议月度消费上限';

  @override
  String ovSpKpiMonthCapHint(num n) {
    return '安全可支配按 $n 天折算到月。';
  }

  @override
  String get ovSpKpiDaily => '剩余日均可花';

  @override
  String ovSpKpiDailyHint(num n) {
    return '安全可支配 ÷ $n 天。';
  }

  @override
  String get ovSpKpiLow => '现金最低点';

  @override
  String get ovSpKpiLowHint => '预测期内无流出事件。';

  @override
  String ovSpKpiLowAt(String x) {
    return '出现在 $x';
  }

  @override
  String ovSpFcTitle(num n) {
    return '$n 天现金预测';
  }

  @override
  String get ovSpFcHint => '实线为逐日现金；虚线为安全底线（准备金+现金底线）；红点为缺口日。';

  @override
  String get ovSpFloorLabel => '安全底线';

  @override
  String get ovSpFlowTitle => '预计流入与流出';

  @override
  String get ovSpFlowHint => '期内全部现金事件（本位币）。';

  @override
  String get ovSpFlowIn => '预计流入';

  @override
  String get ovSpFlowOut => '预计流出';

  @override
  String get ovSpFlowNet => '净现金流';

  @override
  String get ovSpFlowPlanned => '计划支出';

  @override
  String get ovSpFlowDebt => '负债还款';

  @override
  String get ovSpFlowBudget => '预算基线';

  @override
  String get ovSpFlowIncome => '预期收入';

  @override
  String get ovSpFlowOther => '其他';

  @override
  String get ovSpMonthTitle => '月度消费分配';

  @override
  String get ovSpMonthHint => '蓝柱=当月计划流出；金柱=建议上限（计划+可支配摊月）。';

  @override
  String get ovSpMonthPlanned => '计划';

  @override
  String get ovSpMonthCap => '建议上限';

  @override
  String get ovSpCalTitle => '消费日历';

  @override
  String get ovSpCalHint => '流出强度着色；红点标记预测缺口日。';

  @override
  String ovSpCalDay(String x) {
    return '流出 $x';
  }

  @override
  String get ovSpCalShortfall => '缺口';

  @override
  String get ovSpRiskTitle => '风险与建议';

  @override
  String get ovSpRiskHint => '缺口来自预测重放；建议基于规则生成。';

  @override
  String ovSpRiskNone(num n) {
    return '未来 $n 天没有预测到资金缺口。';
  }

  @override
  String get ovSpAdviceTitle => '建议';

  @override
  String ovSpAdviceScenario(String x) {
    return '以保守情景规划：只按已确认收入，可支配为 $x。';
  }

  @override
  String get ovSpAdviceZero => '可支配为 0：先调整计划支出或补充流动资金。';

  @override
  String get ovSpAdviceReconcile => '保持账本与估值新鲜，预测才可信。';

  @override
  String get ovTrTitle => '净资产走势';

  @override
  String get ovTrHint => '以时间序列为中心的历史分析。';

  @override
  String get ovTrCurrent => '当前净资产';

  @override
  String get ovTrChange => '期间变化';

  @override
  String ovTrChangeHint(String a, String b) {
    return '$a → $b 的变化。';
  }

  @override
  String get ovTrGrowth => '期间增长率';

  @override
  String get ovTrGrowthHint => '期间变化 ÷ 期初绝对值。';

  @override
  String get ovTrMax => '期间最高';

  @override
  String get ovTrMin => '期间最低';

  @override
  String get ovTrChartTitle => '趋势大图';

  @override
  String get ovTrAll => '全部';

  @override
  String get ovTrInsightTitle => '关键洞察';

  @override
  String get ovTrInsightHint => '由真实序列推导；不预设增长。';

  @override
  String ovTrStreak(num n) {
    return '连涨 $n 个月';
  }

  @override
  String get ovTrStreakSub => '环比逐月抬升';

  @override
  String ovTrBigMove(String m, String x) {
    return '最大单月变动：$m（$x）';
  }

  @override
  String ovTrMilestone(num n, String m) {
    return '预计 $n 个月后（$m）触及下一整数关口';
  }

  @override
  String ovTrMilestoneSub(String x) {
    return 'Theil–Sen 稳健趋势：每月 $x';
  }

  @override
  String get ovTrAttributionGo => '当月拆解见归因瀑布与月报。';

  @override
  String get ovTrWfStart => '期初';

  @override
  String get ovTrWfEnd => '期末';

  @override
  String get ovTrWfTitle => '本月归因瀑布';

  @override
  String get ovUpTitle => '未来 30 天要花的钱';

  @override
  String get ovUpHint => '未来账单与支出计划中心。';

  @override
  String get ovUpPlanned30 => '30 天计划支出';

  @override
  String get ovUpPlannedHint => '已计划且未落地的流出合计。';

  @override
  String get ovUpDue7 => '7 天内到期';

  @override
  String get ovUpDue7Hint => '今天起 7 天内到期的计划流出。';

  @override
  String get ovUpOverdue => '已逾期';

  @override
  String get ovUpOverdueHint => '到期未落地的计划发生。';

  @override
  String get ovUpNone => '无';

  @override
  String get ovUpRecurring => '周期计划';

  @override
  String get ovUpRecurringHint => '处于激活状态的周期性事件数。';

  @override
  String get ovUpCalTitle => '支出日历';

  @override
  String get ovUpCalHint => '今天钢蓝描边；3 日内琥珀；逾期红框；已付绿点。点日期看当日明细。';

  @override
  String get ovUpModeCal => '日历';

  @override
  String get ovUpModeTimeline => '时间线';

  @override
  String ovUpItemCount(num n) {
    return '$n 项';
  }

  @override
  String get ovUpDueTitle => '即将到期';

  @override
  String get ovUpDueHint => '按日期紧迫排序；状态：待落地/已逾期/已付。';

  @override
  String get ovUpAllSettled => '未来 30 天没有待处理的支出';

  @override
  String get ovUpGoPost => '去计划页落地账单';

  @override
  String get ovUpFixedTitle => '定期固定收支';

  @override
  String get ovUpFixedHint => '周期事件及其下次执行日。';

  @override
  String get ovUpNoFixed => '暂无周期计划';

  @override
  String ovUpNextAt(String x) {
    return '下次 $x';
  }

  @override
  String get ovUpWeekTitle => '周流出分布';

  @override
  String get ovUpWeekHint => '未来五周每周计划流出（首周琥珀）。';

  @override
  String ovUpWeekLabel(num n) {
    return '第 $n 周';
  }

  @override
  String get ovIxTitle => '待处理';

  @override
  String get ovIxHint => '估值缺失、到期计划、对账差额与资金预警的统一处理中心。';

  @override
  String get ovIxStatHigh => '高优先级';

  @override
  String get ovIxStatMissing => '估值缺失';

  @override
  String get ovIxStatStale => '估值过期';

  @override
  String get ovIxStatReconcile => '对账与预警';

  @override
  String get ovIxTableTitle => '任务清单';

  @override
  String get ovIxTableHint => '全部来自真实业务记录；处理完成即自动消失。';

  @override
  String get ovIxFilterAll => '全部';

  @override
  String get ovIxFilterUrgent => '紧急';

  @override
  String get ovIxFilterToday => '今天';

  @override
  String get ovIxFilterWeek => '本周';

  @override
  String get ovIxColTask => '事项';

  @override
  String get ovIxColType => '类型';

  @override
  String get ovIxColPriority => '优先级';

  @override
  String get ovIxColDue => '截止';

  @override
  String get ovIxNoMatch => '该筛选下没有任务';

  @override
  String get ovIxTypeDue => '计划到期';

  @override
  String get ovIxTypeMissing => '缺估值';

  @override
  String get ovIxTypeStale => '估值过期';

  @override
  String get ovIxTypeResidual => '待核对';

  @override
  String get ovIxTypeShortfall => '资金预警';

  @override
  String get ovIxPriorityHigh => '高';

  @override
  String get ovIxPriorityMedium => '中';

  @override
  String get ovIxPriorityLow => '低';

  @override
  String ovIxResidualTask(String x) {
    return '本月归因差额 $x 待核对';
  }

  @override
  String get ovIxAction => '前往对应业务页处理';

  @override
  String get ovIxGo => '去处理';

  @override
  String get ovIxQuickTitle => '快捷操作';

  @override
  String get ovIxQuickHint => '高频处理入口。';

  @override
  String get ovIxAValuation => '补估值';

  @override
  String get ovIxAValuationSub => '为缺估值的资产补当期值';

  @override
  String get ovIxAPost => '落地计划';

  @override
  String get ovIxAPostSub => '把到期的计划变成真实交易';

  @override
  String get ovIxALedger => '对账';

  @override
  String get ovIxALedgerSub => '核对流水与归因差额';

  @override
  String get ovIxASpendable => '看资金预测';

  @override
  String get ovIxASpendableSub => '未来还能安全花多少';

  @override
  String get ovIxTimelineTitle => '提醒时间线';

  @override
  String get ovIxTimelineHint => '按日期与优先级排列。';

  @override
  String get ovIxNoDue => '无截止';

  @override
  String get ovIxEmptyTitle => '目前没有待处理事项。';

  @override
  String get ovIxEmptyMsg => '估值齐全、计划落地、账目对得上——保持。';

  @override
  String get settingsRelNow => '刚刚';

  @override
  String settingsRelMin(num n) {
    return '$n 分钟前';
  }

  @override
  String settingsRelHour(num n) {
    return '$n 小时前';
  }

  @override
  String settingsRelDay(num n) {
    return '$n 天前';
  }

  @override
  String get settingsSecHeroHint => '保护您的资产与隐私，确保所有数据只属于您自己。';

  @override
  String get settingsStatLocalEncrypt => '本地加密';

  @override
  String get settingsStatEnabled => '已启用';

  @override
  String get settingsStatLocalEncryptTip => '数据库在本机加密存储，密钥不出设备。';

  @override
  String get settingsStatPassphrase => '主口令';

  @override
  String get settingsStatSet => '已设置';

  @override
  String get settingsStatPassphraseTip => '解锁与备份加密使用的主口令。';

  @override
  String get settingsStatRecovery => '恢复码';

  @override
  String get settingsStatConfigured => '已配置';

  @override
  String get settingsStatNotConfigured => '未配置';

  @override
  String get settingsStatRecoveryTip => '忘记口令时的找回途径。';

  @override
  String get settingsSessionTitle => '会话与保护';

  @override
  String get settingsSessionHint => '管理应用的自动锁定与身份验证行为。';

  @override
  String get settingsAutoLockRowHint => '空闲一段时间后自动锁定。';

  @override
  String get settingsStartupVerify => '启动验证';

  @override
  String get settingsStartupVerifyHint => '启动应用时要求验证。';

  @override
  String get settingsStartupVerifyValue => '已开启';

  @override
  String get settingsRecentTitle => '最近安全操作';

  @override
  String get settingsRecentHint => '解锁、锁定、口令与恢复码变更记录，与账本同库加密保存。';

  @override
  String get settingsEvEmpty => '暂无安全事件记录';

  @override
  String get settingsEvLock => '应用锁定';

  @override
  String get settingsEvUnlock => '应用解锁';

  @override
  String get settingsEvPass => '主口令修改';

  @override
  String get settingsEvRecovery => '恢复码重新生成';

  @override
  String get settingsEvConfig => '安全配置变更';

  @override
  String get settingsAiStatusTitle => 'AI 服务状态';

  @override
  String get settingsAiStatusHint => '模型与联网搜索配置。';

  @override
  String get settingsAiOn => '已开启';

  @override
  String get settingsAiOff => '已关闭';

  @override
  String get settingsAiUnconfigured => '未配置';

  @override
  String get settingsAiProvider => '服务商';

  @override
  String get settingsAiModel => '模型';

  @override
  String get settingsAiCustom => '自定义';

  @override
  String get settingsAiWebSearch => '联网搜索';

  @override
  String get settingsBkOverviewTitle => '备份概览';

  @override
  String get settingsBkOverviewHint => '最近备份与备份容器。';

  @override
  String get settingsBkLastBackup => '最近备份';

  @override
  String get settingsBkLastBackupTip => '上次成功备份的时间。';

  @override
  String get settingsBkNever => '从未';

  @override
  String get settingsBkContainer => '备份容器';

  @override
  String get settingsBkContainerTip => '.asbk 加密容器：由独立备份口令加密，与主口令互不相关。';

  @override
  String get settingsDataOverviewTitle => '数据概览';

  @override
  String get settingsDataOverviewHint => '账本规模一览。';

  @override
  String get settingsDataAccounts => '账户';

  @override
  String get settingsDataTxns => '交易';

  @override
  String get settingsDataCurrencies => '币种';

  @override
  String get settingsPrefAppearanceTitle => '外观';

  @override
  String get settingsPrefAppearanceHint => '主题模式立即生效并持久化。';

  @override
  String get settingsPrefMoneyTitle => '货币';

  @override
  String get settingsPrefMoneyHint => '本位币与汇率。';

  @override
  String get settingsPrefForecastTitle => '预测';

  @override
  String get settingsPrefForecastHint => '现金预测口径。';

  @override
  String get settingsAboutVersion => '应用版本';

  @override
  String get settingsAboutVersionHint => '当前应用版本。';

  @override
  String get settingsPageHint => '管理账户安全、数据、系统偏好与智能服务。';

  @override
  String get settingsHeaderShield => '加密保护中';

  @override
  String get settingsHeaderShieldTip => '账本整库加密，密钥由主口令在本地派生，绝不离开这台设备。';

  @override
  String get settingsThemeModeLabel => '主题模式';
}
