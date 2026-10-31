import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In zh, this message translates to:
  /// **'资观 AssetScope'**
  String get appTitle;

  /// No description provided for @aiCfgTestMissingInput.
  ///
  /// In zh, this message translates to:
  /// **'请先填写 Base URL 与 API Key'**
  String get aiCfgTestMissingInput;

  /// No description provided for @aiCfgTestConnected.
  ///
  /// In zh, this message translates to:
  /// **'连接成功：{reply}'**
  String aiCfgTestConnected(String reply);

  /// No description provided for @aiCfgGlmCodingPlanKeyHint.
  ///
  /// In zh, this message translates to:
  /// **'若这是编程套餐（Coding Plan）Key，请改选「智谱 GLM Coding Plan」'**
  String get aiCfgGlmCodingPlanKeyHint;

  /// No description provided for @aiCfgGlmRegularKeyHint.
  ///
  /// In zh, this message translates to:
  /// **'套餐端点只认编程套餐 Key；普通 API Key 请改选「智谱 GLM」'**
  String get aiCfgGlmRegularKeyHint;

  /// No description provided for @aiCfgKeyPrivacyTip.
  ///
  /// In zh, this message translates to:
  /// **'API Key 加密存储在本地账本库，仅用于行情/汇率抓取与 AI 助手；抓取时只发送查询名称与币种对，绝不发送余额与金额。'**
  String get aiCfgKeyPrivacyTip;

  /// No description provided for @aiCfgOpenAiCompatibleNote.
  ///
  /// In zh, this message translates to:
  /// **'OpenAI 兼容端点'**
  String get aiCfgOpenAiCompatibleNote;

  /// No description provided for @aiCfgWebSearchOnTip.
  ///
  /// In zh, this message translates to:
  /// **'联网搜索已开：行情抓取带联网工具，价格来自实时网页'**
  String get aiCfgWebSearchOnTip;

  /// No description provided for @aiCfgWebSearchOffTip.
  ///
  /// In zh, this message translates to:
  /// **'联网搜索已关：行情价格可能来自模型记忆'**
  String get aiCfgWebSearchOffTip;

  /// No description provided for @aiCfgNoWebSearchSupportTip.
  ///
  /// In zh, this message translates to:
  /// **'该服务商 chat 接口不支持联网工具，行情价格可能来自模型记忆'**
  String get aiCfgNoWebSearchSupportTip;

  /// No description provided for @aiCfgDialogTitle.
  ///
  /// In zh, this message translates to:
  /// **'AI 服务配置'**
  String get aiCfgDialogTitle;

  /// No description provided for @aiCfgProvider.
  ///
  /// In zh, this message translates to:
  /// **'服务商'**
  String get aiCfgProvider;

  /// No description provided for @aiCfgBaseUrlLabel.
  ///
  /// In zh, this message translates to:
  /// **'Base URL（https://…，不含 /chat/completions）'**
  String get aiCfgBaseUrlLabel;

  /// No description provided for @aiCfgModelLabel.
  ///
  /// In zh, this message translates to:
  /// **'模型（须支持联网搜索）'**
  String get aiCfgModelLabel;

  /// No description provided for @aiCfgWebSearch.
  ///
  /// In zh, this message translates to:
  /// **'联网搜索'**
  String get aiCfgWebSearch;

  /// No description provided for @aiCfgTestConnection.
  ///
  /// In zh, this message translates to:
  /// **'测试连接'**
  String get aiCfgTestConnection;

  /// No description provided for @aiCfgUsageTitle.
  ///
  /// In zh, this message translates to:
  /// **'用量与额度'**
  String get aiCfgUsageTitle;

  /// No description provided for @aiCfgUsageTooltip.
  ///
  /// In zh, this message translates to:
  /// **'调用次数由本应用本地统计（设置页关闭后重新打开刷新）；额度来自服务商接口，免费模型不扣费'**
  String get aiCfgUsageTooltip;

  /// No description provided for @aiCfgStatToday.
  ///
  /// In zh, this message translates to:
  /// **'今日调用'**
  String get aiCfgStatToday;

  /// No description provided for @aiCfgStatLast7Days.
  ///
  /// In zh, this message translates to:
  /// **'近 7 天'**
  String get aiCfgStatLast7Days;

  /// No description provided for @aiCfgStatTotal.
  ///
  /// In zh, this message translates to:
  /// **'累计'**
  String get aiCfgStatTotal;

  /// No description provided for @aiCfgCalls.
  ///
  /// In zh, this message translates to:
  /// **'{n} 次'**
  String aiCfgCalls(num n);

  /// No description provided for @aiCfgNoBalanceApi.
  ///
  /// In zh, this message translates to:
  /// **'该服务商暂无余额查询接口，可到其控制台查看'**
  String get aiCfgNoBalanceApi;

  /// No description provided for @aiCfgBalanceGlm.
  ///
  /// In zh, this message translates to:
  /// **'服务商余额（智谱）'**
  String get aiCfgBalanceGlm;

  /// No description provided for @aiCfgBalanceTotal.
  ///
  /// In zh, this message translates to:
  /// **'总额度 ¥{v}'**
  String aiCfgBalanceTotal(String v);

  /// No description provided for @aiCfgBalanceVoucher.
  ///
  /// In zh, this message translates to:
  /// **'免费额度 ¥{v}'**
  String aiCfgBalanceVoucher(String v);

  /// No description provided for @aiCfgBalanceCash.
  ///
  /// In zh, this message translates to:
  /// **'现金 ¥{v}'**
  String aiCfgBalanceCash(String v);

  /// No description provided for @aiCfgBalanceNoFields.
  ///
  /// In zh, this message translates to:
  /// **'接口未返回额度字段'**
  String get aiCfgBalanceNoFields;

  /// No description provided for @aiCfgBalanceQueryFailed.
  ///
  /// In zh, this message translates to:
  /// **'查询失败：{e}'**
  String aiCfgBalanceQueryFailed(String e);

  /// No description provided for @aiCfgBalanceQuery.
  ///
  /// In zh, this message translates to:
  /// **'查询'**
  String get aiCfgBalanceQuery;

  /// No description provided for @aiCfgBalanceRefresh.
  ///
  /// In zh, this message translates to:
  /// **'刷新'**
  String get aiCfgBalanceRefresh;

  /// No description provided for @aiCfgServiceHint.
  ///
  /// In zh, this message translates to:
  /// **'智谱/Kimi/千问/OpenAI/Claude/自定义；Key 加密存本地'**
  String get aiCfgServiceHint;

  /// No description provided for @categoryManagerTitle.
  ///
  /// In zh, this message translates to:
  /// **'分类与规则'**
  String get categoryManagerTitle;

  /// No description provided for @categoryRulePriorityHint.
  ///
  /// In zh, this message translates to:
  /// **'关键词规则在导入时优先于历史学习命中。'**
  String get categoryRulePriorityHint;

  /// No description provided for @categoryExpenseGroup.
  ///
  /// In zh, this message translates to:
  /// **'支出分类'**
  String get categoryExpenseGroup;

  /// No description provided for @categoryIncomeGroup.
  ///
  /// In zh, this message translates to:
  /// **'收入分类'**
  String get categoryIncomeGroup;

  /// No description provided for @categoryKeywordRules.
  ///
  /// In zh, this message translates to:
  /// **'关键词规则'**
  String get categoryKeywordRules;

  /// No description provided for @categoryNoRulesHint.
  ///
  /// In zh, this message translates to:
  /// **'还没有显式规则。导入与日常记账会自动学习对手方→分类的对应关系。'**
  String get categoryNoRulesHint;

  /// No description provided for @categoryRuleKeyword.
  ///
  /// In zh, this message translates to:
  /// **'「{kw}」'**
  String categoryRuleKeyword(String kw);

  /// No description provided for @categoryAddExpense.
  ///
  /// In zh, this message translates to:
  /// **'新增支出分类'**
  String get categoryAddExpense;

  /// No description provided for @categoryAddIncome.
  ///
  /// In zh, this message translates to:
  /// **'新增收入分类'**
  String get categoryAddIncome;

  /// No description provided for @categoryRename.
  ///
  /// In zh, this message translates to:
  /// **'重命名分类'**
  String get categoryRename;

  /// No description provided for @categoryAddRule.
  ///
  /// In zh, this message translates to:
  /// **'新增关键词规则'**
  String get categoryAddRule;

  /// No description provided for @categoryRuleKeywordLabel.
  ///
  /// In zh, this message translates to:
  /// **'关键词（如 美团、NETFLIX）'**
  String get categoryRuleKeywordLabel;

  /// No description provided for @categoryRuleTargetLabel.
  ///
  /// In zh, this message translates to:
  /// **'命中后归类到'**
  String get categoryRuleTargetLabel;

  /// No description provided for @categoryManagerHint.
  ///
  /// In zh, this message translates to:
  /// **'管理收支分类、商户→分类关键词规则'**
  String get categoryManagerHint;

  /// No description provided for @fxManagerTitle.
  ///
  /// In zh, this message translates to:
  /// **'汇率管理'**
  String get fxManagerTitle;

  /// No description provided for @fxManagerHint.
  ///
  /// In zh, this message translates to:
  /// **'净值折算取\"当日或之前最近\"的一条；倒序存入即可覆盖历史。'**
  String get fxManagerHint;

  /// No description provided for @fxAddRate.
  ///
  /// In zh, this message translates to:
  /// **'新增汇率'**
  String get fxAddRate;

  /// No description provided for @fxAiFetch.
  ///
  /// In zh, this message translates to:
  /// **'AI 抓取'**
  String get fxAiFetch;

  /// No description provided for @fxNoRatesHint.
  ///
  /// In zh, this message translates to:
  /// **'还没有汇率记录。多币种账户折算需要至少一条对该币种的汇率。'**
  String get fxNoRatesHint;

  /// No description provided for @fxEditRateTitle.
  ///
  /// In zh, this message translates to:
  /// **'录入汇率'**
  String get fxEditRateTitle;

  /// No description provided for @fxFromCurrency.
  ///
  /// In zh, this message translates to:
  /// **'原币种'**
  String get fxFromCurrency;

  /// No description provided for @fxToCurrency.
  ///
  /// In zh, this message translates to:
  /// **'目标币种'**
  String get fxToCurrency;

  /// No description provided for @fxRateLabel.
  ///
  /// In zh, this message translates to:
  /// **'1 原币种 = ? 目标币种（如 7.25）'**
  String get fxRateLabel;

  /// No description provided for @fxRateSaved.
  ///
  /// In zh, this message translates to:
  /// **'汇率已保存'**
  String get fxRateSaved;

  /// No description provided for @fxRateInvalid.
  ///
  /// In zh, this message translates to:
  /// **'汇率格式不正确'**
  String get fxRateInvalid;

  /// No description provided for @fxManualHint.
  ///
  /// In zh, this message translates to:
  /// **'手工录入各币种对本位币汇率'**
  String get fxManualHint;

  /// No description provided for @mergeDecryptFailed.
  ///
  /// In zh, this message translates to:
  /// **'备份无法解密（口令不对或文件损坏）：{e}'**
  String mergeDecryptFailed(Object e);

  /// No description provided for @mergeSchemaTooNew.
  ///
  /// In zh, this message translates to:
  /// **'备份来自更新版本的应用（schema {v}），请先升级再合并'**
  String mergeSchemaTooNew(num v);

  /// No description provided for @mergeLineageMismatch.
  ///
  /// In zh, this message translates to:
  /// **'这份备份属于另一个账本（谱系指纹不一致），不能合并。恢复请用\"从备份恢复\"'**
  String get mergeLineageMismatch;

  /// No description provided for @mergeVerifyFailed.
  ///
  /// In zh, this message translates to:
  /// **'备份内容校验失败：{e}'**
  String mergeVerifyFailed(Object e);

  /// No description provided for @mergeNothingToMerge.
  ///
  /// In zh, this message translates to:
  /// **'两份账本已一致，没有需要合并的内容'**
  String get mergeNothingToMerge;

  /// No description provided for @mergeDone.
  ///
  /// In zh, this message translates to:
  /// **'合并完成'**
  String get mergeDone;

  /// No description provided for @mergeSafetyBackupNote.
  ///
  /// In zh, this message translates to:
  /// **'合并前的安全备份：\n{path}\n各页面回到前台会自动刷新。'**
  String mergeSafetyBackupNote(String path);

  /// No description provided for @mergeFailed.
  ///
  /// In zh, this message translates to:
  /// **'合并失败（账本未改动，已整体回滚）：{e}'**
  String mergeFailed(Object e);

  /// No description provided for @mergePassphraseLabel.
  ///
  /// In zh, this message translates to:
  /// **'这份 .asbk 的导出口令'**
  String get mergePassphraseLabel;

  /// No description provided for @mergeConfirmTitle.
  ///
  /// In zh, this message translates to:
  /// **'确认合并'**
  String get mergeConfirmTitle;

  /// No description provided for @mergeWillImport.
  ///
  /// In zh, this message translates to:
  /// **'将并入：{summary}。'**
  String mergeWillImport(String summary);

  /// No description provided for @mergeConfirmNote.
  ///
  /// In zh, this message translates to:
  /// **'交易按\"更新时间新者胜\"合并，其余内容按表策略并入；合并会先自动生成一份安全备份，可随时用\"从备份恢复\"退回。'**
  String get mergeConfirmNote;

  /// No description provided for @mergeLegacyWarning.
  ///
  /// In zh, this message translates to:
  /// **'注意：这份备份由旧版本导出、没有账本身份标识。请确认它确实来自同一本账。'**
  String get mergeLegacyWarning;

  /// No description provided for @mergeBackupAndMerge.
  ///
  /// In zh, this message translates to:
  /// **'安全备份并合并'**
  String get mergeBackupAndMerge;

  /// No description provided for @quoteAppliedCount.
  ///
  /// In zh, this message translates to:
  /// **'已写入 {n} 条行情/汇率'**
  String quoteAppliedCount(num n);

  /// No description provided for @quoteWriteFailed.
  ///
  /// In zh, this message translates to:
  /// **'写入失败：{e}'**
  String quoteWriteFailed(Object e);

  /// No description provided for @quoteFetchTitle.
  ///
  /// In zh, this message translates to:
  /// **'行情 / 汇率抓取'**
  String get quoteFetchTitle;

  /// No description provided for @quoteFetchIntro.
  ///
  /// In zh, this message translates to:
  /// **'直连官方行情源（免费无 key、秒回）；查不到的再试 AI 联网搜索。预览确认后才写入，来源可审计。无论哪种方式，都只发送证券代码与币种对。'**
  String get quoteFetchIntro;

  /// No description provided for @quoteQueryingDirect.
  ///
  /// In zh, this message translates to:
  /// **'正在向官方行情源查询…'**
  String get quoteQueryingDirect;

  /// No description provided for @quoteQueryingAi.
  ///
  /// In zh, this message translates to:
  /// **'AI 正在联网搜索行情，约需 10–60 秒…'**
  String get quoteQueryingAi;

  /// No description provided for @quoteNoWebSearchWarning.
  ///
  /// In zh, this message translates to:
  /// **'当前 AI 配置未开启联网搜索，模型可能返回记忆中的过时价格，请谨慎确认。'**
  String get quoteNoWebSearchWarning;

  /// No description provided for @quoteWillQuery.
  ///
  /// In zh, this message translates to:
  /// **'本次将查询：'**
  String get quoteWillQuery;

  /// No description provided for @quoteNoTargets.
  ///
  /// In zh, this message translates to:
  /// **'没有在持的证券持仓，也没有需要折算的外币账户。'**
  String get quoteNoTargets;

  /// No description provided for @quoteHoldingPrices.
  ///
  /// In zh, this message translates to:
  /// **'· 持仓价格（{n}）：{names}'**
  String quoteHoldingPrices(num n, String names);

  /// No description provided for @quoteFxPairs.
  ///
  /// In zh, this message translates to:
  /// **'· 汇率（{n}）：{pairs} → {base}'**
  String quoteFxPairs(num n, String pairs, String base);

  /// No description provided for @quoteRoutingHint.
  ///
  /// In zh, this message translates to:
  /// **'直连路由：A股/场内基金 → 腾讯行情；港股/美股 → stooq；汇率 → 欧央行。行情代码可在持仓账户详情设置（如 600519 / 00700 / AAPL）。'**
  String get quoteRoutingHint;

  /// No description provided for @quoteDirectFetchButton.
  ///
  /// In zh, this message translates to:
  /// **'直连官方行情源（推荐 · 免费 · 秒回）'**
  String get quoteDirectFetchButton;

  /// No description provided for @quoteAiFetchFallback.
  ///
  /// In zh, this message translates to:
  /// **'AI 联网搜索（查不到时兜底）'**
  String get quoteAiFetchFallback;

  /// No description provided for @quoteAiFetchNeedsConfig.
  ///
  /// In zh, this message translates to:
  /// **'AI 联网搜索（需先配置 AI 服务）'**
  String get quoteAiFetchNeedsConfig;

  /// No description provided for @quoteAssetPrices.
  ///
  /// In zh, this message translates to:
  /// **'资产价格'**
  String get quoteAssetPrices;

  /// No description provided for @quoteFxRates.
  ///
  /// In zh, this message translates to:
  /// **'汇率'**
  String get quoteFxRates;

  /// No description provided for @quoteNotes.
  ///
  /// In zh, this message translates to:
  /// **'提示'**
  String get quoteNotes;

  /// No description provided for @quoteSelectedCount.
  ///
  /// In zh, this message translates to:
  /// **'已选 {p} 条价格 + {r} 条汇率'**
  String quoteSelectedCount(num p, num r);

  /// No description provided for @quoteBack.
  ///
  /// In zh, this message translates to:
  /// **'返回'**
  String get quoteBack;

  /// No description provided for @quoteApplyButton.
  ///
  /// In zh, this message translates to:
  /// **'确认写入'**
  String get quoteApplyButton;

  /// No description provided for @quoteUnmatchedTooltip.
  ///
  /// In zh, this message translates to:
  /// **'未匹配到在持仓账户，不入账'**
  String get quoteUnmatchedTooltip;

  /// No description provided for @quoteCurrencyMismatchTooltip.
  ///
  /// In zh, this message translates to:
  /// **'币种与账户不一致（{ccy} vs 账户币种），默认不勾选'**
  String quoteCurrencyMismatchTooltip(String ccy);

  /// No description provided for @quoteFetchHint.
  ///
  /// In zh, this message translates to:
  /// **'AI 联网搜索最新价格与汇率，预览确认后入账'**
  String get quoteFetchHint;

  /// No description provided for @settingsFailed.
  ///
  /// In zh, this message translates to:
  /// **'失败：{e}'**
  String settingsFailed(Object e);

  /// No description provided for @settingsFailedPrefix.
  ///
  /// In zh, this message translates to:
  /// **'失败'**
  String get settingsFailedPrefix;

  /// No description provided for @settingsCancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get settingsCancel;

  /// No description provided for @settingsSave.
  ///
  /// In zh, this message translates to:
  /// **'保存'**
  String get settingsSave;

  /// No description provided for @settingsGotIt.
  ///
  /// In zh, this message translates to:
  /// **'知道了'**
  String get settingsGotIt;

  /// No description provided for @settingsBackupFileType.
  ///
  /// In zh, this message translates to:
  /// **'备份'**
  String get settingsBackupFileType;

  /// No description provided for @settingsBackupPassphraseTitle.
  ///
  /// In zh, this message translates to:
  /// **'输入备份口令'**
  String get settingsBackupPassphraseTitle;

  /// No description provided for @settingsVerify.
  ///
  /// In zh, this message translates to:
  /// **'校验'**
  String get settingsVerify;

  /// No description provided for @settingsChangePassphrase.
  ///
  /// In zh, this message translates to:
  /// **'修改主口令'**
  String get settingsChangePassphrase;

  /// No description provided for @settingsCurrentPassphrase.
  ///
  /// In zh, this message translates to:
  /// **'当前主口令'**
  String get settingsCurrentPassphrase;

  /// No description provided for @settingsNewPassphraseLabel.
  ///
  /// In zh, this message translates to:
  /// **'新主口令（≥12位更安全）'**
  String get settingsNewPassphraseLabel;

  /// No description provided for @settingsConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确认'**
  String get settingsConfirm;

  /// No description provided for @settingsPassphraseUpdated.
  ///
  /// In zh, this message translates to:
  /// **'主口令已更新'**
  String get settingsPassphraseUpdated;

  /// No description provided for @settingsNewRecoveryCode.
  ///
  /// In zh, this message translates to:
  /// **'新恢复码（离线保存）'**
  String get settingsNewRecoveryCode;

  /// No description provided for @settingsBackupPassphrase.
  ///
  /// In zh, this message translates to:
  /// **'备份口令'**
  String get settingsBackupPassphrase;

  /// No description provided for @settingsBackupPassphraseLabel.
  ///
  /// In zh, this message translates to:
  /// **'备份文件口令（≥8 位，建议 12 位以上）'**
  String get settingsBackupPassphraseLabel;

  /// No description provided for @settingsExport.
  ///
  /// In zh, this message translates to:
  /// **'导出'**
  String get settingsExport;

  /// No description provided for @settingsExportedTo.
  ///
  /// In zh, this message translates to:
  /// **'已导出：{path}'**
  String settingsExportedTo(String path);

  /// No description provided for @settingsExportFailed.
  ///
  /// In zh, this message translates to:
  /// **'导出失败：{e}'**
  String settingsExportFailed(Object e);

  /// No description provided for @settingsVerifyAndRestore.
  ///
  /// In zh, this message translates to:
  /// **'校验并恢复'**
  String get settingsVerifyAndRestore;

  /// No description provided for @settingsRestoreDone.
  ///
  /// In zh, this message translates to:
  /// **'恢复完成，已用新数据锁定；请用主口令解锁（原库保留为 .bak）'**
  String get settingsRestoreDone;

  /// No description provided for @settingsRestoreFailed.
  ///
  /// In zh, this message translates to:
  /// **'恢复失败（原账本未受影响）：{e}'**
  String settingsRestoreFailed(Object e);

  /// No description provided for @settingsBaseCurrency.
  ///
  /// In zh, this message translates to:
  /// **'本位币'**
  String get settingsBaseCurrency;

  /// No description provided for @settingsBaseCurrencySet.
  ///
  /// In zh, this message translates to:
  /// **'本位币已设为 {code}'**
  String settingsBaseCurrencySet(String code);

  /// No description provided for @settingsNotUnlocked.
  ///
  /// In zh, this message translates to:
  /// **'未解锁'**
  String get settingsNotUnlocked;

  /// No description provided for @settingsGroupSecurity.
  ///
  /// In zh, this message translates to:
  /// **'安全'**
  String get settingsGroupSecurity;

  /// No description provided for @settingsGroupBackup.
  ///
  /// In zh, this message translates to:
  /// **'备份与恢复'**
  String get settingsGroupBackup;

  /// No description provided for @settingsGroupPreferences.
  ///
  /// In zh, this message translates to:
  /// **'偏好'**
  String get settingsGroupPreferences;

  /// No description provided for @settingsGroupData.
  ///
  /// In zh, this message translates to:
  /// **'数据管理'**
  String get settingsGroupData;

  /// No description provided for @settingsGroupAiQuotes.
  ///
  /// In zh, this message translates to:
  /// **'AI 与行情'**
  String get settingsGroupAiQuotes;

  /// No description provided for @settingsGroupAbout.
  ///
  /// In zh, this message translates to:
  /// **'关于'**
  String get settingsGroupAbout;

  /// No description provided for @settingsLockNow.
  ///
  /// In zh, this message translates to:
  /// **'立即锁定'**
  String get settingsLockNow;

  /// No description provided for @settingsLockNowHint.
  ///
  /// In zh, this message translates to:
  /// **'关闭数据库并清除内存密钥；无操作也会自动锁定'**
  String get settingsLockNowHint;

  /// No description provided for @settingsChangePassphraseHint.
  ///
  /// In zh, this message translates to:
  /// **'只重新包裹密钥，数据不需要重加密'**
  String get settingsChangePassphraseHint;

  /// No description provided for @settingsRegenRecoveryCode.
  ///
  /// In zh, this message translates to:
  /// **'重新生成恢复码'**
  String get settingsRegenRecoveryCode;

  /// No description provided for @settingsRegenRecoveryCodeHint.
  ///
  /// In zh, this message translates to:
  /// **'旧恢复码立即失效'**
  String get settingsRegenRecoveryCodeHint;

  /// No description provided for @settingsExportBackup.
  ///
  /// In zh, this message translates to:
  /// **'导出加密备份'**
  String get settingsExportBackup;

  /// No description provided for @settingsExportBackupHint.
  ///
  /// In zh, this message translates to:
  /// **'生成 .asbk 加密容器，请用独立口令并离线保存'**
  String get settingsExportBackupHint;

  /// No description provided for @settingsRestoreBackup.
  ///
  /// In zh, this message translates to:
  /// **'从备份恢复'**
  String get settingsRestoreBackup;

  /// No description provided for @settingsRestoreBackupHint.
  ///
  /// In zh, this message translates to:
  /// **'先隔离校验，通过后才替换当前账本（原库保留 .bak）'**
  String get settingsRestoreBackupHint;

  /// No description provided for @settingsMergeBackup.
  ///
  /// In zh, this message translates to:
  /// **'从备份合并（多设备）'**
  String get settingsMergeBackup;

  /// No description provided for @settingsMergeBackupHint.
  ///
  /// In zh, this message translates to:
  /// **'把另一设备的 .asbk 并入当前账本：交易按时间新者胜，先自动安全备份'**
  String get settingsMergeBackupHint;

  /// No description provided for @settingsBaseCurrencyHint.
  ///
  /// In zh, this message translates to:
  /// **'统计、净资产与预测的基准货币'**
  String get settingsBaseCurrencyHint;

  /// No description provided for @settingsImportCsv.
  ///
  /// In zh, this message translates to:
  /// **'导入账单 CSV'**
  String get settingsImportCsv;

  /// No description provided for @settingsImportCsvHint.
  ///
  /// In zh, this message translates to:
  /// **'UTF-8/GBK 自动识别，去重幂等，智慧分类建议'**
  String get settingsImportCsvHint;

  /// No description provided for @settingsExportJson.
  ///
  /// In zh, this message translates to:
  /// **'导出全量 JSON'**
  String get settingsExportJson;

  /// No description provided for @settingsExportJsonHint.
  ///
  /// In zh, this message translates to:
  /// **'账户/估值/交易/计划/预算的明文快照（不含密钥），可审计可迁移'**
  String get settingsExportJsonHint;

  /// No description provided for @settingsPageTitle.
  ///
  /// In zh, this message translates to:
  /// **'设置'**
  String get settingsPageTitle;

  /// No description provided for @settingsFullJsonExported.
  ///
  /// In zh, this message translates to:
  /// **'已导出全量 JSON（明文，不含任何密钥）'**
  String get settingsFullJsonExported;

  /// No description provided for @settingsAboutTagline.
  ///
  /// In zh, this message translates to:
  /// **'本地优先的个人资产、负债与财务规划系统。数据全程加密存储，任何联网功能默认关闭。'**
  String get settingsAboutTagline;

  /// No description provided for @settingsAppearance.
  ///
  /// In zh, this message translates to:
  /// **'外观'**
  String get settingsAppearance;

  /// No description provided for @settingsAppearanceHint.
  ///
  /// In zh, this message translates to:
  /// **'浅色冷雾白 / 深色财富终端，跟随系统自动切换'**
  String get settingsAppearanceHint;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In zh, this message translates to:
  /// **'跟随系统'**
  String get settingsThemeSystem;

  /// No description provided for @settingsThemeLight.
  ///
  /// In zh, this message translates to:
  /// **'浅色'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In zh, this message translates to:
  /// **'深色'**
  String get settingsThemeDark;

  /// No description provided for @settingsAutoLock.
  ///
  /// In zh, this message translates to:
  /// **'自动锁定'**
  String get settingsAutoLock;

  /// No description provided for @settingsAutoLockHint.
  ///
  /// In zh, this message translates to:
  /// **'无操作达到该时长后自动锁定账本'**
  String get settingsAutoLockHint;

  /// No description provided for @settingsMinutes.
  ///
  /// In zh, this message translates to:
  /// **'{n} 分钟'**
  String settingsMinutes(num n);

  /// No description provided for @settingsAutoLockDialogTitle.
  ///
  /// In zh, this message translates to:
  /// **'无操作自动锁定'**
  String get settingsAutoLockDialogTitle;

  /// No description provided for @settingsAutoLockSet.
  ///
  /// In zh, this message translates to:
  /// **'自动锁定已设为 {n} 分钟'**
  String settingsAutoLockSet(num n);

  /// No description provided for @settingsCashHorizon.
  ///
  /// In zh, this message translates to:
  /// **'现金预测期'**
  String get settingsCashHorizon;

  /// No description provided for @settingsCashHorizonHint.
  ///
  /// In zh, this message translates to:
  /// **'首页「还能花多少」的推演天数'**
  String get settingsCashHorizonHint;

  /// No description provided for @settingsDays.
  ///
  /// In zh, this message translates to:
  /// **'{n} 天'**
  String settingsDays(num n);

  /// No description provided for @settingsCashHorizonSet.
  ///
  /// In zh, this message translates to:
  /// **'现金预测期已设为 {n} 天'**
  String settingsCashHorizonSet(num n);

  /// No description provided for @settingsCashFloor.
  ///
  /// In zh, this message translates to:
  /// **'现金底线'**
  String get settingsCashFloor;

  /// No description provided for @settingsCashFloorHint.
  ///
  /// In zh, this message translates to:
  /// **'低于此值视为现金短缺（预测与可支配上限会扣除）'**
  String get settingsCashFloorHint;

  /// No description provided for @settingsCashFloorSaved.
  ///
  /// In zh, this message translates to:
  /// **'现金底线已保存'**
  String get settingsCashFloorSaved;

  /// No description provided for @cancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In zh, this message translates to:
  /// **'确定'**
  String get confirm;

  /// No description provided for @save.
  ///
  /// In zh, this message translates to:
  /// **'保存'**
  String get save;

  /// No description provided for @edit.
  ///
  /// In zh, this message translates to:
  /// **'编辑'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In zh, this message translates to:
  /// **'删除'**
  String get delete;

  /// No description provided for @remove.
  ///
  /// In zh, this message translates to:
  /// **'移除'**
  String get remove;

  /// No description provided for @loadFailed.
  ///
  /// In zh, this message translates to:
  /// **'加载失败：{error}'**
  String loadFailed(Object error);

  /// No description provided for @yearsN.
  ///
  /// In zh, this message translates to:
  /// **'{n} 年'**
  String yearsN(String n);

  /// No description provided for @monthsN.
  ///
  /// In zh, this message translates to:
  /// **'{n} 月'**
  String monthsN(num n);

  /// No description provided for @daysLaterN.
  ///
  /// In zh, this message translates to:
  /// **'{n} 天后'**
  String daysLaterN(num n);

  /// No description provided for @lifeEventAddTitle.
  ///
  /// In zh, this message translates to:
  /// **'添加人生事件'**
  String get lifeEventAddTitle;

  /// No description provided for @lifeEventBuyHome.
  ///
  /// In zh, this message translates to:
  /// **'买房（含贷款）'**
  String get lifeEventBuyHome;

  /// No description provided for @lifeEventChildRearing.
  ///
  /// In zh, this message translates to:
  /// **'生孩子 / 抚养'**
  String get lifeEventChildRearing;

  /// No description provided for @lifeEventIncomeChangeOption.
  ///
  /// In zh, this message translates to:
  /// **'收入跳变（升职/失业）'**
  String get lifeEventIncomeChangeOption;

  /// No description provided for @lifeEventRetirement.
  ///
  /// In zh, this message translates to:
  /// **'退休'**
  String get lifeEventRetirement;

  /// No description provided for @lifeEventBigPurchaseOption.
  ///
  /// In zh, this message translates to:
  /// **'大件购置（换车等）'**
  String get lifeEventBigPurchaseOption;

  /// No description provided for @lifeEventLumpSum.
  ///
  /// In zh, this message translates to:
  /// **'一次性大额收支'**
  String get lifeEventLumpSum;

  /// No description provided for @lifeEventIncomeChange.
  ///
  /// In zh, this message translates to:
  /// **'收入跳变'**
  String get lifeEventIncomeChange;

  /// No description provided for @lifeEventBigPurchase.
  ///
  /// In zh, this message translates to:
  /// **'大件购置'**
  String get lifeEventBigPurchase;

  /// No description provided for @lifeEventYearsLater.
  ///
  /// In zh, this message translates to:
  /// **'几年后'**
  String get lifeEventYearsLater;

  /// No description provided for @lifeEventTotalPrice.
  ///
  /// In zh, this message translates to:
  /// **'总价（元）'**
  String get lifeEventTotalPrice;

  /// No description provided for @lifeEventDownPayment.
  ///
  /// In zh, this message translates to:
  /// **'首付（元）'**
  String get lifeEventDownPayment;

  /// No description provided for @lifeEventAnnualRateHint.
  ///
  /// In zh, this message translates to:
  /// **'年利率 %（如 3.6）'**
  String get lifeEventAnnualRateHint;

  /// No description provided for @lifeEventLoanTerm.
  ///
  /// In zh, this message translates to:
  /// **'贷款年限'**
  String get lifeEventLoanTerm;

  /// No description provided for @lifeEventYearsUntilBirth.
  ///
  /// In zh, this message translates to:
  /// **'几年后出生'**
  String get lifeEventYearsUntilBirth;

  /// No description provided for @lifeEventMonthlyRearingCost.
  ///
  /// In zh, this message translates to:
  /// **'每月养育成本（元）'**
  String get lifeEventMonthlyRearingCost;

  /// No description provided for @lifeEventCollegeExtra.
  ///
  /// In zh, this message translates to:
  /// **'大学阶段每月额外（元，可空）'**
  String get lifeEventCollegeExtra;

  /// No description provided for @lifeEventChangePctHint.
  ///
  /// In zh, this message translates to:
  /// **'变化 %（+30 涨三成 / −100 归零）'**
  String get lifeEventChangePctHint;

  /// No description provided for @lifeEventYearsUntilRetire.
  ///
  /// In zh, this message translates to:
  /// **'几年后退休'**
  String get lifeEventYearsUntilRetire;

  /// No description provided for @lifeEventRetirementNote.
  ///
  /// In zh, this message translates to:
  /// **'退休后：收入 ×0.4（养老金替代率）、支出 ×0.75'**
  String get lifeEventRetirementNote;

  /// No description provided for @lifeEventPurchaseCost.
  ///
  /// In zh, this message translates to:
  /// **'购置支出（元）'**
  String get lifeEventPurchaseCost;

  /// No description provided for @lifeEventResidualValue.
  ///
  /// In zh, this message translates to:
  /// **'残值计入固定资产（元，可空）'**
  String get lifeEventResidualValue;

  /// No description provided for @lifeEventAmountInOut.
  ///
  /// In zh, this message translates to:
  /// **'金额（元，负数 = 流出）'**
  String get lifeEventAmountInOut;

  /// No description provided for @lifePlanTitle.
  ///
  /// In zh, this message translates to:
  /// **'人生规划 · 多年度推演'**
  String get lifePlanTitle;

  /// No description provided for @lifePlanIntro.
  ///
  /// In zh, this message translates to:
  /// **'把买房、育儿、换车、退休等大事放进同一条时间线，逐月推演未来 {years} 年的现金流与净资产（名义口径，收入支出按通胀增长）。只读模拟，不写账本。'**
  String lifePlanIntro(num years);

  /// No description provided for @lifePlanRerun.
  ///
  /// In zh, this message translates to:
  /// **'重新推演'**
  String get lifePlanRerun;

  /// No description provided for @lifePlanInvestableAssets.
  ///
  /// In zh, this message translates to:
  /// **'可投资净资产（元）'**
  String get lifePlanInvestableAssets;

  /// No description provided for @lifePlanFixedAssets.
  ///
  /// In zh, this message translates to:
  /// **'固定资产等（元）'**
  String get lifePlanFixedAssets;

  /// No description provided for @lifePlanMonthlyIncome.
  ///
  /// In zh, this message translates to:
  /// **'月收入（元）'**
  String get lifePlanMonthlyIncome;

  /// No description provided for @lifePlanMonthlyExpense.
  ///
  /// In zh, this message translates to:
  /// **'月支出（元）'**
  String get lifePlanMonthlyExpense;

  /// No description provided for @lifePlanNominalReturn.
  ///
  /// In zh, this message translates to:
  /// **'名义收益 %/年'**
  String get lifePlanNominalReturn;

  /// No description provided for @lifePlanInflation.
  ///
  /// In zh, this message translates to:
  /// **'通胀 %/年'**
  String get lifePlanInflation;

  /// No description provided for @lifePlanHorizonYears.
  ///
  /// In zh, this message translates to:
  /// **'推演年限'**
  String get lifePlanHorizonYears;

  /// No description provided for @lifePlanEvents.
  ///
  /// In zh, this message translates to:
  /// **'人生事件'**
  String get lifePlanEvents;

  /// No description provided for @lifePlanAddEvent.
  ///
  /// In zh, this message translates to:
  /// **'添加事件'**
  String get lifePlanAddEvent;

  /// No description provided for @lifePlanNoEvents.
  ///
  /// In zh, this message translates to:
  /// **'还没有事件。加一个试试：三年后买房、明年生孩子……'**
  String get lifePlanNoEvents;

  /// No description provided for @lifePlanResults.
  ///
  /// In zh, this message translates to:
  /// **'推演结论'**
  String get lifePlanResults;

  /// No description provided for @lifePlanNetWorthInYears.
  ///
  /// In zh, this message translates to:
  /// **'{years} 年后净资产'**
  String lifePlanNetWorthInYears(num years);

  /// No description provided for @lifePlanPeakNetWorth.
  ///
  /// In zh, this message translates to:
  /// **'峰值净资产'**
  String get lifePlanPeakNetWorth;

  /// No description provided for @lifePlanNewLoanInterest.
  ///
  /// In zh, this message translates to:
  /// **'新增贷款总利息'**
  String get lifePlanNewLoanInterest;

  /// No description provided for @lifePlanCashExhaustionRisk.
  ///
  /// In zh, this message translates to:
  /// **'现金耗尽风险'**
  String get lifePlanCashExhaustionRisk;

  /// No description provided for @lifePlanNoGap.
  ///
  /// In zh, this message translates to:
  /// **'推演期内无缺口 ✓'**
  String get lifePlanNoGap;

  /// No description provided for @lifePlanExhaustedAt.
  ///
  /// In zh, this message translates to:
  /// **'第 {year} 年（{date} 前后）'**
  String lifePlanExhaustedAt(num year, String date);

  /// No description provided for @lifePlanNetWorthCurve.
  ///
  /// In zh, this message translates to:
  /// **'净资产曲线（万元）'**
  String get lifePlanNetWorthCurve;

  /// No description provided for @lifePlanCurveTooltip.
  ///
  /// In zh, this message translates to:
  /// **'第 {year} 年  {value}'**
  String lifePlanCurveTooltip(String year, String value);

  /// No description provided for @planNew.
  ///
  /// In zh, this message translates to:
  /// **'新建计划'**
  String get planNew;

  /// No description provided for @planEdit.
  ///
  /// In zh, this message translates to:
  /// **'编辑计划'**
  String get planEdit;

  /// No description provided for @planNameLabel.
  ///
  /// In zh, this message translates to:
  /// **'名称（如 房租 / 工资）'**
  String get planNameLabel;

  /// No description provided for @planOutflow.
  ///
  /// In zh, this message translates to:
  /// **'支出'**
  String get planOutflow;

  /// No description provided for @planInflow.
  ///
  /// In zh, this message translates to:
  /// **'收入'**
  String get planInflow;

  /// No description provided for @planCadence.
  ///
  /// In zh, this message translates to:
  /// **'周期'**
  String get planCadence;

  /// No description provided for @planAnchorMonthly.
  ///
  /// In zh, this message translates to:
  /// **'起始日（每月此日发生）'**
  String get planAnchorMonthly;

  /// No description provided for @planAnchorDate.
  ///
  /// In zh, this message translates to:
  /// **'起始日'**
  String get planAnchorDate;

  /// No description provided for @planEndDate.
  ///
  /// In zh, this message translates to:
  /// **'结束日（可选）'**
  String get planEndDate;

  /// No description provided for @planAutoPostTitle.
  ///
  /// In zh, this message translates to:
  /// **'到期自动记入账本'**
  String get planAutoPostTitle;

  /// No description provided for @planAutoPostSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'解锁应用时自动落账；已入账/作废不会重复记'**
  String get planAutoPostSubtitle;

  /// No description provided for @planPayAccount.
  ///
  /// In zh, this message translates to:
  /// **'支付账户'**
  String get planPayAccount;

  /// No description provided for @planIncomeAccount.
  ///
  /// In zh, this message translates to:
  /// **'入账账户'**
  String get planIncomeAccount;

  /// No description provided for @planNoAccountForCurrency.
  ///
  /// In zh, this message translates to:
  /// **'没有 {currency} 账户可选，请先建账户'**
  String planNoAccountForCurrency(String currency);

  /// No description provided for @planCategory.
  ///
  /// In zh, this message translates to:
  /// **'分类'**
  String get planCategory;

  /// No description provided for @planPostTitle.
  ///
  /// In zh, this message translates to:
  /// **'记入账本 · {name}'**
  String planPostTitle(String name);

  /// No description provided for @planPostDateNote.
  ///
  /// In zh, this message translates to:
  /// **'落账日 {date}（发生日）'**
  String planPostDateNote(String date);

  /// No description provided for @planPostEstimateNote.
  ///
  /// In zh, this message translates to:
  /// **' · 估算金额取中位数，可修改'**
  String get planPostEstimateNote;

  /// No description provided for @planAccountsLoadFailed.
  ///
  /// In zh, this message translates to:
  /// **'账户加载失败：{error}'**
  String planAccountsLoadFailed(String error);

  /// No description provided for @planPostFailed.
  ///
  /// In zh, this message translates to:
  /// **'入账失败：{error}'**
  String planPostFailed(String error);

  /// No description provided for @planSkipOnce.
  ///
  /// In zh, this message translates to:
  /// **'这次不记'**
  String get planSkipOnce;

  /// No description provided for @planPostNow.
  ///
  /// In zh, this message translates to:
  /// **'记入账本'**
  String get planPostNow;

  /// No description provided for @planPosting.
  ///
  /// In zh, this message translates to:
  /// **'入账中…'**
  String get planPosting;

  /// No description provided for @plansPageTitle.
  ///
  /// In zh, this message translates to:
  /// **'计划'**
  String get plansPageTitle;

  /// No description provided for @planMonthlyRhythm.
  ///
  /// In zh, this message translates to:
  /// **'本月节奏'**
  String get planMonthlyRhythm;

  /// No description provided for @planDueUnposted.
  ///
  /// In zh, this message translates to:
  /// **'到期未记入'**
  String get planDueUnposted;

  /// No description provided for @planCount.
  ///
  /// In zh, this message translates to:
  /// **'{n} 笔'**
  String planCount(num n);

  /// No description provided for @planDueTooltip.
  ///
  /// In zh, this message translates to:
  /// **'到期未入账的计划事件，逐笔或一键记入账本'**
  String get planDueTooltip;

  /// No description provided for @planNext30Days.
  ///
  /// In zh, this message translates to:
  /// **'未来 30 天'**
  String get planNext30Days;

  /// No description provided for @planNext30Tooltip.
  ///
  /// In zh, this message translates to:
  /// **'含已入账与未入账的全部发生额'**
  String get planNext30Tooltip;

  /// No description provided for @planNext30Net.
  ///
  /// In zh, this message translates to:
  /// **'未来 30 天净流'**
  String get planNext30Net;

  /// No description provided for @planNetSignTooltip.
  ///
  /// In zh, this message translates to:
  /// **'正为净流入，负为净流出'**
  String get planNetSignTooltip;

  /// No description provided for @planDueTitle.
  ///
  /// In zh, this message translates to:
  /// **'待落地 · {n} 笔到期'**
  String planDueTitle(num n);

  /// No description provided for @planPostAll.
  ///
  /// In zh, this message translates to:
  /// **'全部记入'**
  String get planPostAll;

  /// No description provided for @planEstimateTooltip.
  ///
  /// In zh, this message translates to:
  /// **'估算金额，确认时可修改'**
  String get planEstimateTooltip;

  /// No description provided for @planEstimateBadge.
  ///
  /// In zh, this message translates to:
  /// **'估'**
  String get planEstimateBadge;

  /// No description provided for @planMoreDue.
  ///
  /// In zh, this message translates to:
  /// **'…另有 {n} 笔，\"全部记入\"可一次处理'**
  String planMoreDue(num n);

  /// No description provided for @planNetEffect.
  ///
  /// In zh, this message translates to:
  /// **'净影响 {amount}'**
  String planNetEffect(String amount);

  /// No description provided for @planBlockedCount.
  ///
  /// In zh, this message translates to:
  /// **' · {n} 笔需先在确认页选账户'**
  String planBlockedCount(num n);

  /// No description provided for @planPostedCount.
  ///
  /// In zh, this message translates to:
  /// **'已记入 {n} 笔计划'**
  String planPostedCount(num n);

  /// No description provided for @planNothingToPost.
  ///
  /// In zh, this message translates to:
  /// **'没有可直接记入的计划（需先在确认页选账户）'**
  String get planNothingToPost;

  /// No description provided for @planNoUpcoming.
  ///
  /// In zh, this message translates to:
  /// **'暂无预定支出'**
  String get planNoUpcoming;

  /// No description provided for @planAllPlans.
  ///
  /// In zh, this message translates to:
  /// **'全部计划'**
  String get planAllPlans;

  /// No description provided for @planEmptyHint.
  ///
  /// In zh, this message translates to:
  /// **'点右下角「新建计划」，或用识别功能从流水中生成。'**
  String get planEmptyHint;

  /// No description provided for @planEstimateAmount.
  ///
  /// In zh, this message translates to:
  /// **' · 估算金额'**
  String get planEstimateAmount;

  /// No description provided for @planActions.
  ///
  /// In zh, this message translates to:
  /// **'计划操作'**
  String get planActions;

  /// No description provided for @planPause.
  ///
  /// In zh, this message translates to:
  /// **'暂停'**
  String get planPause;

  /// No description provided for @planResume.
  ///
  /// In zh, this message translates to:
  /// **'恢复'**
  String get planResume;

  /// No description provided for @planMarkFinished.
  ///
  /// In zh, this message translates to:
  /// **'标记完成'**
  String get planMarkFinished;

  /// No description provided for @planDeleteTitle.
  ///
  /// In zh, this message translates to:
  /// **'删除计划'**
  String get planDeleteTitle;

  /// No description provided for @planDeleteMessage.
  ///
  /// In zh, this message translates to:
  /// **'删除\"{name}\"不影响已入账的交易。'**
  String planDeleteMessage(String name);

  /// No description provided for @recurringTitle.
  ///
  /// In zh, this message translates to:
  /// **'识别到的固定收支'**
  String get recurringTitle;

  /// No description provided for @recurringIntro.
  ///
  /// In zh, this message translates to:
  /// **'从近 18 个月流水中识别（同对手方、间隔规整、≥3 次）。转为计划后将计入现金预测与预算的\"已计划\"。'**
  String get recurringIntro;

  /// No description provided for @recurringOpenTooltip.
  ///
  /// In zh, this message translates to:
  /// **'从流水识别固定收支'**
  String get recurringOpenTooltip;

  /// No description provided for @recurringEmpty.
  ///
  /// In zh, this message translates to:
  /// **'暂未识别到固定收支。多记录几个月的房租/订阅/工资等\n规律流水后再来试试。'**
  String get recurringEmpty;

  /// No description provided for @recurringStatLine1.
  ///
  /// In zh, this message translates to:
  /// **'{cadence} · {n} 次 · 置信 {pct}%'**
  String recurringStatLine1(String cadence, num n, String pct);

  /// No description provided for @recurringStatLine2.
  ///
  /// In zh, this message translates to:
  /// **'中位 {amount} · 下次预计 {m}/{d}'**
  String recurringStatLine2(String amount, num m, num d);

  /// No description provided for @recurringAlreadyPlanned.
  ///
  /// In zh, this message translates to:
  /// **'已建计划'**
  String get recurringAlreadyPlanned;

  /// No description provided for @recurringConvertToPlan.
  ///
  /// In zh, this message translates to:
  /// **'转计划'**
  String get recurringConvertToPlan;

  /// No description provided for @scenarioTitle.
  ///
  /// In zh, this message translates to:
  /// **'情景模拟 · 现金压力测试'**
  String get scenarioTitle;

  /// No description provided for @scenarioIntro.
  ///
  /// In zh, this message translates to:
  /// **'把\"如果……会怎样\"放进 180 天现金预测：计划、债务还款与准备金不变，只冲击收入/支出，看低谷多深、钱会不会断。不写账本。'**
  String get scenarioIntro;

  /// No description provided for @scenarioExtraMonthlyLabel.
  ///
  /// In zh, this message translates to:
  /// **'情景：额外月支出'**
  String get scenarioExtraMonthlyLabel;

  /// No description provided for @scenarioOneOffLabel.
  ///
  /// In zh, this message translates to:
  /// **'情景：一次性支出'**
  String get scenarioOneOffLabel;

  /// No description provided for @scenarioRunFailed.
  ///
  /// In zh, this message translates to:
  /// **'模拟失败：{error}'**
  String scenarioRunFailed(String error);

  /// No description provided for @scenarioRun.
  ///
  /// In zh, this message translates to:
  /// **'运行模拟'**
  String get scenarioRun;

  /// No description provided for @scenarioRunning.
  ///
  /// In zh, this message translates to:
  /// **'模拟中…'**
  String get scenarioRunning;

  /// No description provided for @scenarioExtrasTitle.
  ///
  /// In zh, this message translates to:
  /// **'叠加自定义冲击（可选）'**
  String get scenarioExtrasTitle;

  /// No description provided for @scenarioExtraMonthlyAmount.
  ///
  /// In zh, this message translates to:
  /// **'额外月支出（元/月）'**
  String get scenarioExtraMonthlyAmount;

  /// No description provided for @scenarioMonthsCount.
  ///
  /// In zh, this message translates to:
  /// **'月数'**
  String get scenarioMonthsCount;

  /// No description provided for @scenarioOneOffAmount.
  ///
  /// In zh, this message translates to:
  /// **'一次性支出（元）'**
  String get scenarioOneOffAmount;

  /// No description provided for @scenarioOccursOn.
  ///
  /// In zh, this message translates to:
  /// **'发生在'**
  String get scenarioOccursOn;

  /// No description provided for @scenarioResultTitle.
  ///
  /// In zh, this message translates to:
  /// **'结果 · {name}'**
  String scenarioResultTitle(String name);

  /// No description provided for @scenarioMinCashBaseline.
  ///
  /// In zh, this message translates to:
  /// **'最低现金 · 基线'**
  String get scenarioMinCashBaseline;

  /// No description provided for @scenarioMinCashScenario.
  ///
  /// In zh, this message translates to:
  /// **'最低现金 · 情景'**
  String get scenarioMinCashScenario;

  /// No description provided for @scenarioTroughDelta.
  ///
  /// In zh, this message translates to:
  /// **'低谷变化'**
  String get scenarioTroughDelta;

  /// No description provided for @scenarioWorstDay.
  ///
  /// In zh, this message translates to:
  /// **'最难受的一天（相对基线）'**
  String get scenarioWorstDay;

  /// No description provided for @scenarioCashOutDate.
  ///
  /// In zh, this message translates to:
  /// **'现金耗尽日'**
  String get scenarioCashOutDate;

  /// No description provided for @scenarioCashOutValue.
  ///
  /// In zh, this message translates to:
  /// **'{date}（还剩 {days} 天）'**
  String scenarioCashOutValue(String date, num days);

  /// No description provided for @scenarioNoCashOut.
  ///
  /// In zh, this message translates to:
  /// **'预测期内未耗尽'**
  String get scenarioNoCashOut;

  /// No description provided for @scenarioNewShortfalls.
  ///
  /// In zh, this message translates to:
  /// **'新增缺口（基线没有、情景触发的）'**
  String get scenarioNewShortfalls;

  /// No description provided for @scenarioBelowReserve.
  ///
  /// In zh, this message translates to:
  /// **'低于准备金与底线'**
  String get scenarioBelowReserve;

  /// No description provided for @scenarioShortfallCount.
  ///
  /// In zh, this message translates to:
  /// **'…共 {n} 条'**
  String scenarioShortfallCount(num n);

  /// No description provided for @scenarioSurvives.
  ///
  /// In zh, this message translates to:
  /// **'情景可承受：无新增缺口、现金未耗尽。底线之外仍有余量 {amount}。'**
  String scenarioSurvives(String amount);

  /// No description provided for @scenarioHurts.
  ///
  /// In zh, this message translates to:
  /// **'该情景会造成伤害：考虑提高准备金、推迟可选支出或安排信用额度备用。'**
  String get scenarioHurts;

  /// No description provided for @scenarioMethodNote.
  ///
  /// In zh, this message translates to:
  /// **'口径：与现金预测同引擎重放（docs/05 §12）；准备金、债务还款与底线不变。'**
  String get scenarioMethodNote;

  /// No description provided for @saveChanges.
  ///
  /// In zh, this message translates to:
  /// **'保存修改'**
  String get saveChanges;

  /// No description provided for @allReady.
  ///
  /// In zh, this message translates to:
  /// **'全部就绪'**
  String get allReady;

  /// No description provided for @assetsTitle.
  ///
  /// In zh, this message translates to:
  /// **'资产'**
  String get assetsTitle;

  /// No description provided for @assetsTitleHint.
  ///
  /// In zh, this message translates to:
  /// **'全部账户的台账与净值：点任一账户看价值、编辑资料、记估值与买卖'**
  String get assetsTitleHint;

  /// No description provided for @assetAdd.
  ///
  /// In zh, this message translates to:
  /// **'添加资产'**
  String get assetAdd;

  /// No description provided for @assetNew.
  ///
  /// In zh, this message translates to:
  /// **'新建资产'**
  String get assetNew;

  /// No description provided for @assetCreate.
  ///
  /// In zh, this message translates to:
  /// **'创建资产'**
  String get assetCreate;

  /// No description provided for @assetsEmptyTitle.
  ///
  /// In zh, this message translates to:
  /// **'还没有资产或负债'**
  String get assetsEmptyTitle;

  /// No description provided for @assetsEmptyMessage.
  ///
  /// In zh, this message translates to:
  /// **'添加第一笔资产：现金、银行卡、房产、股票持仓……保存后地球首页会点亮它的坐标。'**
  String get assetsEmptyMessage;

  /// No description provided for @assetNameLabel.
  ///
  /// In zh, this message translates to:
  /// **'名称'**
  String get assetNameLabel;

  /// No description provided for @assetNameRequired.
  ///
  /// In zh, this message translates to:
  /// **'请填写资产名称'**
  String get assetNameRequired;

  /// No description provided for @assetValuePositiveRequired.
  ///
  /// In zh, this message translates to:
  /// **'价值需为正数（如 1280000）'**
  String get assetValuePositiveRequired;

  /// No description provided for @assetLocationRequired.
  ///
  /// In zh, this message translates to:
  /// **'请选择资产位置——保存后将在地球首页点亮对应坐标'**
  String get assetLocationRequired;

  /// No description provided for @assetLocationTooltip.
  ///
  /// In zh, this message translates to:
  /// **'资产需选位置——保存后弹窗将碎成光束，飞往地球点亮该坐标'**
  String get assetLocationTooltip;

  /// No description provided for @assetCurrentValue.
  ///
  /// In zh, this message translates to:
  /// **'当前价值'**
  String get assetCurrentValue;

  /// No description provided for @assetOpeningDebtNote.
  ///
  /// In zh, this message translates to:
  /// **'期初欠款'**
  String get assetOpeningDebtNote;

  /// No description provided for @accountEditProfile.
  ///
  /// In zh, this message translates to:
  /// **'编辑资料'**
  String get accountEditProfile;

  /// No description provided for @accountUpdateValuation.
  ///
  /// In zh, this message translates to:
  /// **'更新估值'**
  String get accountUpdateValuation;

  /// No description provided for @accountOpeningBalance.
  ///
  /// In zh, this message translates to:
  /// **'期初余额'**
  String get accountOpeningBalance;

  /// No description provided for @accountOpeningBalanceTitle.
  ///
  /// In zh, this message translates to:
  /// **'记期初余额（历史补录，不算当月收入）'**
  String get accountOpeningBalanceTitle;

  /// No description provided for @accountReconcileAdjust.
  ///
  /// In zh, this message translates to:
  /// **'对账调整'**
  String get accountReconcileAdjust;

  /// No description provided for @accountReconcileAdjustTitle.
  ///
  /// In zh, this message translates to:
  /// **'对账调整（填差额，可负）'**
  String get accountReconcileAdjustTitle;

  /// No description provided for @accountQuoteCode.
  ///
  /// In zh, this message translates to:
  /// **'行情代码'**
  String get accountQuoteCode;

  /// No description provided for @accountQuoteCodeTitle.
  ///
  /// In zh, this message translates to:
  /// **'行情代码（直连行情源用）'**
  String get accountQuoteCodeTitle;

  /// No description provided for @accountQuoteCodeHint.
  ///
  /// In zh, this message translates to:
  /// **'A股 600519 / 港股 00700 / 美股 AAPL'**
  String get accountQuoteCodeHint;

  /// No description provided for @accountQuoteCodeHelp.
  ///
  /// In zh, this message translates to:
  /// **'A股 6 位数字自动判交易所；港股填数字；美股填字母代码。修改只影响行情查询，不影响任何账目。'**
  String get accountQuoteCodeHelp;

  /// No description provided for @accountArchive.
  ///
  /// In zh, this message translates to:
  /// **'归档'**
  String get accountArchive;

  /// No description provided for @accountUnarchive.
  ///
  /// In zh, this message translates to:
  /// **'取消归档'**
  String get accountUnarchive;

  /// No description provided for @accountArchived.
  ///
  /// In zh, this message translates to:
  /// **'已归档'**
  String get accountArchived;

  /// No description provided for @accountArchivedHint.
  ///
  /// In zh, this message translates to:
  /// **'不计入净资产统计'**
  String get accountArchivedHint;

  /// No description provided for @accountValuationMissing.
  ///
  /// In zh, this message translates to:
  /// **'缺估值'**
  String get accountValuationMissing;

  /// No description provided for @accountMissingValuationHint.
  ///
  /// In zh, this message translates to:
  /// **'尚无估值记录，未计入净资产——点「更新估值」补录'**
  String get accountMissingValuationHint;

  /// No description provided for @accountMissingValuationTip.
  ///
  /// In zh, this message translates to:
  /// **'缺估值：未计入净资产'**
  String get accountMissingValuationTip;

  /// No description provided for @accountValuationStale.
  ///
  /// In zh, this message translates to:
  /// **'估值过期'**
  String get accountValuationStale;

  /// No description provided for @accountStaleValuationHint.
  ///
  /// In zh, this message translates to:
  /// **'超过 30 天未更新'**
  String get accountStaleValuationHint;

  /// No description provided for @accountStaleValuationTip.
  ///
  /// In zh, this message translates to:
  /// **'估值已过期（>30 天）'**
  String get accountStaleValuationTip;

  /// No description provided for @accountDebtBaseLabel.
  ///
  /// In zh, this message translates to:
  /// **'当前欠款（本位币）'**
  String get accountDebtBaseLabel;

  /// No description provided for @accountValueBaseLabel.
  ///
  /// In zh, this message translates to:
  /// **'当前价值（本位币）'**
  String get accountValueBaseLabel;

  /// No description provided for @accountOriginalBalance.
  ///
  /// In zh, this message translates to:
  /// **'原币余额 {amount}'**
  String accountOriginalBalance(String amount);

  /// No description provided for @accountMyShareDetail.
  ///
  /// In zh, this message translates to:
  /// **'本人份额 {value}（{share}%）'**
  String accountMyShareDetail(String value, String share);

  /// No description provided for @accountMineShare.
  ///
  /// In zh, this message translates to:
  /// **'我 {share}%'**
  String accountMineShare(String share);

  /// No description provided for @accountRecentTransactions.
  ///
  /// In zh, this message translates to:
  /// **'近期交易'**
  String get accountRecentTransactions;

  /// No description provided for @accountUnitPriceLabel.
  ///
  /// In zh, this message translates to:
  /// **'单价（每单位）'**
  String get accountUnitPriceLabel;

  /// No description provided for @accountTotalValueLabel.
  ///
  /// In zh, this message translates to:
  /// **'当前总价值'**
  String get accountTotalValueLabel;

  /// No description provided for @accountCurrentBalance.
  ///
  /// In zh, this message translates to:
  /// **'当前余额'**
  String get accountCurrentBalance;

  /// No description provided for @accountLocated.
  ///
  /// In zh, this message translates to:
  /// **'已定位'**
  String get accountLocated;

  /// No description provided for @accountGroupCash.
  ///
  /// In zh, this message translates to:
  /// **'现金与活期'**
  String get accountGroupCash;

  /// No description provided for @accountGroupSteady.
  ///
  /// In zh, this message translates to:
  /// **'稳健理财'**
  String get accountGroupSteady;

  /// No description provided for @accountGroupHoldings.
  ///
  /// In zh, this message translates to:
  /// **'持仓'**
  String get accountGroupHoldings;

  /// No description provided for @accountGroupReal.
  ///
  /// In zh, this message translates to:
  /// **'实物与权益'**
  String get accountGroupReal;

  /// No description provided for @accountGroupLiabilities.
  ///
  /// In zh, this message translates to:
  /// **'负债'**
  String get accountGroupLiabilities;

  /// No description provided for @liabilityCurrentDebt.
  ///
  /// In zh, this message translates to:
  /// **'当前欠款'**
  String get liabilityCurrentDebt;

  /// No description provided for @netWorth.
  ///
  /// In zh, this message translates to:
  /// **'净资产'**
  String get netWorth;

  /// No description provided for @netWorthMyShare.
  ///
  /// In zh, this message translates to:
  /// **'净资产（本人份额）'**
  String get netWorthMyShare;

  /// No description provided for @netWorthMyShareHint.
  ///
  /// In zh, this message translates to:
  /// **'存在归属份额 <100% 的账户，此处为本人份额口径；全户口径见右侧合计'**
  String get netWorthMyShareHint;

  /// No description provided for @totalAssets.
  ///
  /// In zh, this message translates to:
  /// **'资产合计'**
  String get totalAssets;

  /// No description provided for @totalLiabilities.
  ///
  /// In zh, this message translates to:
  /// **'负债合计'**
  String get totalLiabilities;

  /// No description provided for @valuationStatusLabel.
  ///
  /// In zh, this message translates to:
  /// **'估值状态'**
  String get valuationStatusLabel;

  /// No description provided for @itemsMissingValuation.
  ///
  /// In zh, this message translates to:
  /// **'{count} 项缺估值'**
  String itemsMissingValuation(num count);

  /// No description provided for @itemsStaleValuation.
  ///
  /// In zh, this message translates to:
  /// **'{count} 项已过期'**
  String itemsStaleValuation(num count);

  /// No description provided for @selectAccountHint.
  ///
  /// In zh, this message translates to:
  /// **'选择左侧账户查看详情'**
  String get selectAccountHint;

  /// No description provided for @subtypeLabel.
  ///
  /// In zh, this message translates to:
  /// **'类型'**
  String get subtypeLabel;

  /// No description provided for @currencyLabel.
  ///
  /// In zh, this message translates to:
  /// **'币种'**
  String get currencyLabel;

  /// No description provided for @locationLabel.
  ///
  /// In zh, this message translates to:
  /// **'位置'**
  String get locationLabel;

  /// No description provided for @institutionLabel.
  ///
  /// In zh, this message translates to:
  /// **'机构'**
  String get institutionLabel;

  /// No description provided for @securityCodeLabel.
  ///
  /// In zh, this message translates to:
  /// **'证券代码'**
  String get securityCodeLabel;

  /// No description provided for @ownershipTitle.
  ///
  /// In zh, this message translates to:
  /// **'归属份额'**
  String get ownershipTitle;

  /// No description provided for @ownershipMyShareLabel.
  ///
  /// In zh, this message translates to:
  /// **'本人份额（%）'**
  String get ownershipMyShareLabel;

  /// No description provided for @ownershipShareLabel.
  ///
  /// In zh, this message translates to:
  /// **'份额'**
  String get ownershipShareLabel;

  /// No description provided for @ownershipHelper.
  ///
  /// In zh, this message translates to:
  /// **'100 = 全额本人；夫妻共同账户各填 50。只影响净资产/我的份额统计，不改流水。'**
  String get ownershipHelper;

  /// No description provided for @ownershipRangeError.
  ///
  /// In zh, this message translates to:
  /// **'份额需在 0–100 之间（例如 50 或 33.3）'**
  String get ownershipRangeError;

  /// No description provided for @tradeBuy.
  ///
  /// In zh, this message translates to:
  /// **'买入'**
  String get tradeBuy;

  /// No description provided for @tradeSell.
  ///
  /// In zh, this message translates to:
  /// **'卖出'**
  String get tradeSell;

  /// No description provided for @tradeDividendInterest.
  ///
  /// In zh, this message translates to:
  /// **'分红/利息'**
  String get tradeDividendInterest;

  /// No description provided for @tradeBuyTitle.
  ///
  /// In zh, this message translates to:
  /// **'买入 · {name}'**
  String tradeBuyTitle(String name);

  /// No description provided for @tradeSellTitle.
  ///
  /// In zh, this message translates to:
  /// **'卖出 · {name}'**
  String tradeSellTitle(String name);

  /// No description provided for @tradeDividendTitle.
  ///
  /// In zh, this message translates to:
  /// **'分红/利息入账'**
  String get tradeDividendTitle;

  /// No description provided for @tradeHoldingSummary.
  ///
  /// In zh, this message translates to:
  /// **'持有 {qty} 份 · 成本 {cost}'**
  String tradeHoldingSummary(String qty, String cost);

  /// No description provided for @tradeCashAccount.
  ///
  /// In zh, this message translates to:
  /// **'现金账户'**
  String get tradeCashAccount;

  /// No description provided for @tradeCashAccountCredited.
  ///
  /// In zh, this message translates to:
  /// **'入账现金账户'**
  String get tradeCashAccountCredited;

  /// No description provided for @tradeQuantityLabel.
  ///
  /// In zh, this message translates to:
  /// **'数量（份）'**
  String get tradeQuantityLabel;

  /// No description provided for @tradeTotalCostLabel.
  ///
  /// In zh, this message translates to:
  /// **'总花费（含费用）'**
  String get tradeTotalCostLabel;

  /// No description provided for @tradeNetProceedsLabel.
  ///
  /// In zh, this message translates to:
  /// **'净到账金额'**
  String get tradeNetProceedsLabel;

  /// No description provided for @tradeDividendAmountLabel.
  ///
  /// In zh, this message translates to:
  /// **'分红/利息金额'**
  String get tradeDividendAmountLabel;

  /// No description provided for @tradeNoteLabel.
  ///
  /// In zh, this message translates to:
  /// **'备注（可选）'**
  String get tradeNoteLabel;

  /// No description provided for @lotSectionTitle.
  ///
  /// In zh, this message translates to:
  /// **'成本批次（FIFO）'**
  String get lotSectionTitle;

  /// No description provided for @lotRealizedTotal.
  ///
  /// In zh, this message translates to:
  /// **'累计已实现 {amount}'**
  String lotRealizedTotal(String amount);

  /// No description provided for @lotRealizedYear.
  ///
  /// In zh, this message translates to:
  /// **'{year} 年已实现 {amount}'**
  String lotRealizedYear(num year, String amount);

  /// No description provided for @lotLineItem.
  ///
  /// In zh, this message translates to:
  /// **'{qty} 份 × 单价 {price}'**
  String lotLineItem(String qty, String price);

  /// No description provided for @lotShortfall.
  ///
  /// In zh, this message translates to:
  /// **'⚠ {qty} 份卖出早于首笔买入（历史缺口，以零成本配对）'**
  String lotShortfall(String qty);

  /// No description provided for @lotMethodologyNote.
  ///
  /// In zh, this message translates to:
  /// **'口径：先买先卖逐批配对，与账面平均成本法并行披露（docs/05 §11）'**
  String get lotMethodologyNote;

  /// No description provided for @aiRecognize.
  ///
  /// In zh, this message translates to:
  /// **'AI 识别'**
  String get aiRecognize;

  /// No description provided for @aiFillNameFirst.
  ///
  /// In zh, this message translates to:
  /// **'先填写资产名称，AI 才能识别'**
  String get aiFillNameFirst;

  /// No description provided for @aiNotBound.
  ///
  /// In zh, this message translates to:
  /// **'尚未绑定 AI：设置 → AI 服务'**
  String get aiNotBound;

  /// No description provided for @aiRecognizing.
  ///
  /// In zh, this message translates to:
  /// **'AI 识别中…'**
  String get aiRecognizing;

  /// No description provided for @aiFilledConfirmValue.
  ///
  /// In zh, this message translates to:
  /// **'AI 已填充，请确认价值'**
  String get aiFilledConfirmValue;

  /// No description provided for @aiValTitle.
  ///
  /// In zh, this message translates to:
  /// **'AI 估值'**
  String get aiValTitle;

  /// No description provided for @aiValDaily.
  ///
  /// In zh, this message translates to:
  /// **'每日 AI 估值'**
  String get aiValDaily;

  /// No description provided for @aiValDailyTooltip.
  ///
  /// In zh, this message translates to:
  /// **'开启后每天联网检索该资产真实市价并自动更新价值（房产看成交行情、车辆看二手估值，多源交叉剔除营销噪音）；你随时可在账户详情纠正，当日人工值优先'**
  String get aiValDailyTooltip;

  /// No description provided for @aiValSectionTooltip.
  ///
  /// In zh, this message translates to:
  /// **'每天解锁后自动联网检索真实市价并更新价值；你手动改过的估值当日优先，AI 不覆盖'**
  String get aiValSectionTooltip;

  /// No description provided for @aiValQueryLabel.
  ///
  /// In zh, this message translates to:
  /// **'检索线索（小区/栋/室 · 年款型号）'**
  String get aiValQueryLabel;

  /// No description provided for @aiValSaveQuery.
  ///
  /// In zh, this message translates to:
  /// **'保存线索'**
  String get aiValSaveQuery;

  /// No description provided for @aiValSearching.
  ///
  /// In zh, this message translates to:
  /// **'检索中…'**
  String get aiValSearching;

  /// No description provided for @aiValEstimateNow.
  ///
  /// In zh, this message translates to:
  /// **'立即估值'**
  String get aiValEstimateNow;

  /// No description provided for @aiValQueryFallback.
  ///
  /// In zh, this message translates to:
  /// **'检索词空 = 「{query}」'**
  String aiValQueryFallback(String query);

  /// No description provided for @aiValQuerySaved.
  ///
  /// In zh, this message translates to:
  /// **'AI 估值线索已保存'**
  String get aiValQuerySaved;

  /// No description provided for @aiValBindKeyFirst.
  ///
  /// In zh, this message translates to:
  /// **'先在 设置 → AI 服务 绑定你的 AI Key'**
  String get aiValBindKeyFirst;

  /// No description provided for @aiValUpdated.
  ///
  /// In zh, this message translates to:
  /// **'已更新估值：{value}'**
  String aiValUpdated(String value);

  /// No description provided for @aiValError.
  ///
  /// In zh, this message translates to:
  /// **'AI 估值：{error}'**
  String aiValError(Object error);

  /// No description provided for @aiValResultTitle.
  ///
  /// In zh, this message translates to:
  /// **'AI 估值结果'**
  String get aiValResultTitle;

  /// No description provided for @aiValRange.
  ///
  /// In zh, this message translates to:
  /// **'区间'**
  String get aiValRange;

  /// No description provided for @aiValConfidence.
  ///
  /// In zh, this message translates to:
  /// **'置信度'**
  String get aiValConfidence;

  /// No description provided for @aiValRationale.
  ///
  /// In zh, this message translates to:
  /// **'依据'**
  String get aiValRationale;

  /// No description provided for @aiValSource.
  ///
  /// In zh, this message translates to:
  /// **'来源'**
  String get aiValSource;

  /// No description provided for @aiValDismiss.
  ///
  /// In zh, this message translates to:
  /// **'不用'**
  String get aiValDismiss;

  /// No description provided for @aiValAdopt.
  ///
  /// In zh, this message translates to:
  /// **'采用'**
  String get aiValAdopt;

  /// No description provided for @aiValNoRecords.
  ///
  /// In zh, this message translates to:
  /// **'暂无估值记录'**
  String get aiValNoRecords;

  /// No description provided for @locSet.
  ///
  /// In zh, this message translates to:
  /// **'设置位置'**
  String get locSet;

  /// No description provided for @locChange.
  ///
  /// In zh, this message translates to:
  /// **'修改位置'**
  String get locChange;

  /// No description provided for @locClear.
  ///
  /// In zh, this message translates to:
  /// **'清除位置'**
  String get locClear;

  /// No description provided for @locLocatedBuiltin.
  ///
  /// In zh, this message translates to:
  /// **'已定位：{name}（内置城市坐标）'**
  String locLocatedBuiltin(String name);

  /// No description provided for @locLocatedAiPrecise.
  ///
  /// In zh, this message translates to:
  /// **'AI 已定位：{name}（精确位置）'**
  String locLocatedAiPrecise(String name);

  /// No description provided for @locLocatedAiCity.
  ///
  /// In zh, this message translates to:
  /// **'AI 已定位：{name}（城市中心）'**
  String locLocatedAiCity(String name);

  /// No description provided for @locLocatedFallback.
  ///
  /// In zh, this message translates to:
  /// **'已定位：{name}'**
  String locLocatedFallback(String name);

  /// No description provided for @locDialogTitle.
  ///
  /// In zh, this message translates to:
  /// **'「{name}」的位置'**
  String locDialogTitle(String name);

  /// No description provided for @locDialogSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'设置后该资产将以呼吸标记出现在 3D 资产地球上'**
  String get locDialogSubtitle;

  /// No description provided for @locNameLabel.
  ///
  /// In zh, this message translates to:
  /// **'位置名（如 上海·前滩）'**
  String get locNameLabel;

  /// No description provided for @locLatitudeLabel.
  ///
  /// In zh, this message translates to:
  /// **'纬度 (-90 ~ 90)'**
  String get locLatitudeLabel;

  /// No description provided for @locLongitudeLabel.
  ///
  /// In zh, this message translates to:
  /// **'经度 (-180 ~ 180)'**
  String get locLongitudeLabel;

  /// No description provided for @locCoordNote.
  ///
  /// In zh, this message translates to:
  /// **'坐标为 WGS84；国内资产可用城市快选后在地图 App 里查小区坐标微调'**
  String get locCoordNote;

  /// No description provided for @loadFailedReports.
  ///
  /// In zh, this message translates to:
  /// **'加载失败：{e}'**
  String loadFailedReports(String e);

  /// No description provided for @reportCancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get reportCancel;

  /// No description provided for @reportSave.
  ///
  /// In zh, this message translates to:
  /// **'保存'**
  String get reportSave;

  /// No description provided for @assetAllocation.
  ///
  /// In zh, this message translates to:
  /// **'资产配置'**
  String get assetAllocation;

  /// No description provided for @setTargetAllocation.
  ///
  /// In zh, this message translates to:
  /// **'设置目标配置'**
  String get setTargetAllocation;

  /// No description provided for @allocNoAssetsHint.
  ///
  /// In zh, this message translates to:
  /// **'还没有资产。记账后这里会展示你的资产结构。'**
  String get allocNoAssetsHint;

  /// No description provided for @allocMissingValuations.
  ///
  /// In zh, this message translates to:
  /// **'⚠ {n} 个账户估值缺失（按 0 计入占比）'**
  String allocMissingValuations(num n);

  /// No description provided for @rebalanceAdviceTitle.
  ///
  /// In zh, this message translates to:
  /// **'再平衡建议（5/25 带宽法）'**
  String get rebalanceAdviceTitle;

  /// No description provided for @rebalanceAdviceNote.
  ///
  /// In zh, this message translates to:
  /// **'偏离超过 max(5 个百分点, 目标的 25%) 时提醒，交易回带边（非回到目标，降低换手）。'**
  String get rebalanceAdviceNote;

  /// No description provided for @allocWithinBand.
  ///
  /// In zh, this message translates to:
  /// **'配置均在目标带宽内 ✓'**
  String get allocWithinBand;

  /// No description provided for @allocTargetPct.
  ///
  /// In zh, this message translates to:
  /// **'目标 {n}%'**
  String allocTargetPct(num n);

  /// No description provided for @rebalanceBuy.
  ///
  /// In zh, this message translates to:
  /// **'买入'**
  String get rebalanceBuy;

  /// No description provided for @rebalanceSell.
  ///
  /// In zh, this message translates to:
  /// **'卖出'**
  String get rebalanceSell;

  /// No description provided for @rebalanceAdviceDetail.
  ///
  /// In zh, this message translates to:
  /// **'当前 {current}% → 回到带宽边 {target}%±带'**
  String rebalanceAdviceDetail(String current, String target);

  /// No description provided for @targetAllocationTitle.
  ///
  /// In zh, this message translates to:
  /// **'目标配置'**
  String get targetAllocationTitle;

  /// No description provided for @targetAllocationHint.
  ///
  /// In zh, this message translates to:
  /// **'各类占全部资产的百分比，合计 ≤ 100%。留空 = 不设目标（不参与再平衡提醒）。'**
  String get targetAllocationHint;

  /// No description provided for @targetSumExceeded.
  ///
  /// In zh, this message translates to:
  /// **'合计 {n}%（超过 100%）'**
  String targetSumExceeded(num n);

  /// No description provided for @targetSumRemaining.
  ///
  /// In zh, this message translates to:
  /// **'合计 {sum}% · 未设目标/未分配 {rest}%'**
  String targetSumRemaining(num sum, num rest);

  /// No description provided for @fireTitle.
  ///
  /// In zh, this message translates to:
  /// **'财务独立（FIRE）'**
  String get fireTitle;

  /// No description provided for @fireTuneTooltip.
  ///
  /// In zh, this message translates to:
  /// **'调整参数与模拟'**
  String get fireTuneTooltip;

  /// No description provided for @fireEmptyHint.
  ///
  /// In zh, this message translates to:
  /// **'记录一段时间的收支后，这里会给出“多少钱可以财务自由”的测算。\n口径：FI 门槛 = 年支出 ÷ 提取率（4% 法则），可投资净资产 = 净资产 − 固定资产 − 长期权益。'**
  String get fireEmptyHint;

  /// No description provided for @fiNumberToday.
  ///
  /// In zh, this message translates to:
  /// **'FI 门槛（今天的钱）'**
  String get fiNumberToday;

  /// No description provided for @investableCoverage.
  ///
  /// In zh, this message translates to:
  /// **'可投资净资产覆盖'**
  String get investableCoverage;

  /// No description provided for @coverageHistoryMonths.
  ///
  /// In zh, this message translates to:
  /// **'（历史 {n} 个月）'**
  String coverageHistoryMonths(num n);

  /// No description provided for @fiTimeToReach.
  ///
  /// In zh, this message translates to:
  /// **'默认假设下达标'**
  String get fiTimeToReach;

  /// No description provided for @fiUnreachable.
  ///
  /// In zh, this message translates to:
  /// **'不可达（提高储蓄或收益假设）'**
  String get fiUnreachable;

  /// No description provided for @fiReached.
  ///
  /// In zh, this message translates to:
  /// **'已达标 🎉'**
  String get fiReached;

  /// No description provided for @fiYearsAway.
  ///
  /// In zh, this message translates to:
  /// **'≈ {n} 年'**
  String fiYearsAway(num n);

  /// No description provided for @fireDefaultsNote.
  ///
  /// In zh, this message translates to:
  /// **'默认：名义收益 5% · 通胀 2.5% · 提取率 4% · 储蓄取近 12 个月实绩。点右上角调整并跑蒙特卡洛。'**
  String get fireDefaultsNote;

  /// No description provided for @firePlannerTitle.
  ///
  /// In zh, this message translates to:
  /// **'财务独立（FIRE）规划器'**
  String get firePlannerTitle;

  /// No description provided for @firePlannerNote.
  ///
  /// In zh, this message translates to:
  /// **'FI 门槛 = 年支出 ÷ 提取率；累积期逐月精确复利（名义收益、目标随通胀增长）。蒙特卡洛为实际口径（已扣通胀），固定种子可复现。'**
  String get firePlannerNote;

  /// No description provided for @recalculate.
  ///
  /// In zh, this message translates to:
  /// **'重新测算'**
  String get recalculate;

  /// No description provided for @investableNetWorthField.
  ///
  /// In zh, this message translates to:
  /// **'可投资净资产（元）'**
  String get investableNetWorthField;

  /// No description provided for @annualSavingsField.
  ///
  /// In zh, this message translates to:
  /// **'年储蓄（元，可负）'**
  String get annualSavingsField;

  /// No description provided for @targetAnnualSpendField.
  ///
  /// In zh, this message translates to:
  /// **'目标年支出（元）'**
  String get targetAnnualSpendField;

  /// No description provided for @nominalReturnField.
  ///
  /// In zh, this message translates to:
  /// **'名义收益 %/年'**
  String get nominalReturnField;

  /// No description provided for @inflationField.
  ///
  /// In zh, this message translates to:
  /// **'通胀 %/年'**
  String get inflationField;

  /// No description provided for @withdrawalRateField.
  ///
  /// In zh, this message translates to:
  /// **'提取率 %（4=4% 法则）'**
  String get withdrawalRateField;

  /// No description provided for @withdrawalVolPct.
  ///
  /// In zh, this message translates to:
  /// **'提取期波动率 {v}%'**
  String withdrawalVolPct(String v);

  /// No description provided for @calcResults.
  ///
  /// In zh, this message translates to:
  /// **'测算结果'**
  String get calcResults;

  /// No description provided for @currentCoverage.
  ///
  /// In zh, this message translates to:
  /// **'当前覆盖率'**
  String get currentCoverage;

  /// No description provided for @timeToFi.
  ///
  /// In zh, this message translates to:
  /// **'达标时间'**
  String get timeToFi;

  /// No description provided for @fiUnreachableWithin.
  ///
  /// In zh, this message translates to:
  /// **'不可达（{n} 年内）'**
  String fiUnreachableWithin(num n);

  /// No description provided for @fiYearsMonths.
  ///
  /// In zh, this message translates to:
  /// **'≈ {years} 年（{months} 个月）'**
  String fiYearsMonths(num years, num months);

  /// No description provided for @requiredSavingsTitle.
  ///
  /// In zh, this message translates to:
  /// **'反解：想 N 年达标每年要存多少'**
  String get requiredSavingsTitle;

  /// No description provided for @fiWithinYears.
  ///
  /// In zh, this message translates to:
  /// **'{n} 年内达标'**
  String fiWithinYears(num n);

  /// No description provided for @mcTitle.
  ///
  /// In zh, this message translates to:
  /// **'蒙特卡洛 · 达标后提取 30 年'**
  String get mcTitle;

  /// No description provided for @mcSurvivalLabel.
  ///
  /// In zh, this message translates to:
  /// **'生存率（1000 条路径）'**
  String get mcSurvivalLabel;

  /// No description provided for @mcPercentileLabel.
  ///
  /// In zh, this message translates to:
  /// **'期末余额分位（年支出倍数）'**
  String get mcPercentileLabel;

  /// No description provided for @mcNote.
  ///
  /// In zh, this message translates to:
  /// **'期初 = FI 门槛（提取率倒数倍年支出），每年提取 1 倍并按随机实际收益增长；波动率 {vol}%。模拟为启发式参考，不构成投资建议。'**
  String mcNote(String vol);

  /// No description provided for @fiUnreachableShort.
  ///
  /// In zh, this message translates to:
  /// **'不可达'**
  String get fiUnreachableShort;

  /// No description provided for @fiReachedShort.
  ///
  /// In zh, this message translates to:
  /// **'已达标'**
  String get fiReachedShort;

  /// No description provided for @yearsShort.
  ///
  /// In zh, this message translates to:
  /// **'{n} 年'**
  String yearsShort(num n);

  /// No description provided for @sensitivityTitle.
  ///
  /// In zh, this message translates to:
  /// **'敏感性：收益 ±1pp × 支出 ±10%'**
  String get sensitivityTitle;

  /// No description provided for @baseline.
  ///
  /// In zh, this message translates to:
  /// **'基准'**
  String get baseline;

  /// No description provided for @sensReturnRow.
  ///
  /// In zh, this message translates to:
  /// **'收益{sign}{n} pp'**
  String sensReturnRow(String sign, num n);

  /// No description provided for @sensitivityColsNote.
  ///
  /// In zh, this message translates to:
  /// **'列：支出 ×0.9 / ×1.0 / ×1.1（能省 10% 比多赚 1 个点更有力）'**
  String get sensitivityColsNote;

  /// No description provided for @portfolioTitle.
  ///
  /// In zh, this message translates to:
  /// **'投资组合'**
  String get portfolioTitle;

  /// No description provided for @noHoldingsHint.
  ///
  /// In zh, this message translates to:
  /// **'还没有持仓。在总览「添加资产」新建持仓账户后，用「买入」记录第一笔投资。'**
  String get noHoldingsHint;

  /// No description provided for @holdingQtyShares.
  ///
  /// In zh, this message translates to:
  /// **'{q} 份'**
  String holdingQtyShares(String q);

  /// No description provided for @holdingCostHint.
  ///
  /// In zh, this message translates to:
  /// **' · 成本 {cost}'**
  String holdingCostHint(String cost);

  /// No description provided for @missingPrice.
  ///
  /// In zh, this message translates to:
  /// **'缺价'**
  String get missingPrice;

  /// No description provided for @skippedFxFlows.
  ///
  /// In zh, this message translates to:
  /// **'⚠ {n} 笔含外币流水因缺历史汇率未计入 XIRR'**
  String skippedFxFlows(num n);

  /// No description provided for @xirrTwrTooltip.
  ///
  /// In zh, this message translates to:
  /// **'XIRR 资金加权（含你的加减仓时点影响）；TWR 时间加权（剔除资金进出，衡量标的表现）'**
  String get xirrTwrTooltip;

  /// No description provided for @annualizedXirr.
  ///
  /// In zh, this message translates to:
  /// **'年化 XIRR {v}%'**
  String annualizedXirr(String v);

  /// No description provided for @annualizedTwr.
  ///
  /// In zh, this message translates to:
  /// **'年化 TWR {v}%'**
  String annualizedTwr(String v);

  /// No description provided for @myCpiTitle.
  ///
  /// In zh, this message translates to:
  /// **'我的通胀 · 近 12 个月'**
  String get myCpiTitle;

  /// No description provided for @myCpiEmptyHint.
  ///
  /// In zh, this message translates to:
  /// **'记账满 6 个月后，这里会用你自己的消费篮子计算“你的生活成本通胀”（固定篮子口径：维持基期消费结构不变，现在要多花多少）。'**
  String get myCpiEmptyHint;

  /// No description provided for @aboveAssumedInflation.
  ///
  /// In zh, this message translates to:
  /// **'高于假设通胀 {v}%'**
  String aboveAssumedInflation(String v);

  /// No description provided for @notAboveAssumedInflation.
  ///
  /// In zh, this message translates to:
  /// **'不高于假设通胀 {v}%'**
  String notAboveAssumedInflation(String v);

  /// No description provided for @basketCoverageWarning.
  ///
  /// In zh, this message translates to:
  /// **'⚠ 篮子覆盖率 {v}%（消费结构变化较大，解读需谨慎）'**
  String basketCoverageWarning(String v);

  /// No description provided for @cpiMethodNote.
  ///
  /// In zh, this message translates to:
  /// **'基期 {base} 个月 vs 近期 {recent} 个月的月均支出；口径：维持基期消费结构不变的价格指数近似（固定篮子 Laspeyres）。'**
  String cpiMethodNote(num base, num recent);

  /// No description provided for @basketShareHint.
  ///
  /// In zh, this message translates to:
  /// **'占篮子 {share}% · 近期/基期 ×{ratio}'**
  String basketShareHint(String share, String ratio);

  /// No description provided for @reportYearTitle.
  ///
  /// In zh, this message translates to:
  /// **'年度 · {year} 年'**
  String reportYearTitle(num year);

  /// No description provided for @reportMonthTitle.
  ///
  /// In zh, this message translates to:
  /// **'月报 · {year} 年 {month} 月'**
  String reportMonthTitle(num year, num month);

  /// No description provided for @prevPeriod.
  ///
  /// In zh, this message translates to:
  /// **'上一期'**
  String get prevPeriod;

  /// No description provided for @nextPeriod.
  ///
  /// In zh, this message translates to:
  /// **'下一期'**
  String get nextPeriod;

  /// No description provided for @nwChangeBreakdown.
  ///
  /// In zh, this message translates to:
  /// **'净资产变化分解'**
  String get nwChangeBreakdown;

  /// No description provided for @residualTooltip.
  ///
  /// In zh, this message translates to:
  /// **'差额非 0 通常意味着缺估值、漏记或导入重复'**
  String get residualTooltip;

  /// No description provided for @pendingReviewChip.
  ///
  /// In zh, this message translates to:
  /// **'待核对 {v}'**
  String pendingReviewChip(String v);

  /// No description provided for @netWorthOpening.
  ///
  /// In zh, this message translates to:
  /// **'期初净资产'**
  String get netWorthOpening;

  /// No description provided for @attributionIncomeExpense.
  ///
  /// In zh, this message translates to:
  /// **'收支贡献'**
  String get attributionIncomeExpense;

  /// No description provided for @attributionRealized.
  ///
  /// In zh, this message translates to:
  /// **'投资损益·已实现'**
  String get attributionRealized;

  /// No description provided for @attributionDividend.
  ///
  /// In zh, this message translates to:
  /// **'投资损益·分红'**
  String get attributionDividend;

  /// No description provided for @attributionUnrealizedDelta.
  ///
  /// In zh, this message translates to:
  /// **'投资损益·未实现变化'**
  String get attributionUnrealizedDelta;

  /// No description provided for @attributionFx.
  ///
  /// In zh, this message translates to:
  /// **'汇兑影响'**
  String get attributionFx;

  /// No description provided for @attributionOtherValuation.
  ///
  /// In zh, this message translates to:
  /// **'其他估值变化'**
  String get attributionOtherValuation;

  /// No description provided for @attributionCorrection.
  ///
  /// In zh, this message translates to:
  /// **'范围/历史修正'**
  String get attributionCorrection;

  /// No description provided for @attributionResidual.
  ///
  /// In zh, this message translates to:
  /// **'待核对差额'**
  String get attributionResidual;

  /// No description provided for @netWorthClosing.
  ///
  /// In zh, this message translates to:
  /// **'期末净资产'**
  String get netWorthClosing;

  /// No description provided for @incomeMix.
  ///
  /// In zh, this message translates to:
  /// **'收入构成'**
  String get incomeMix;

  /// No description provided for @expenseMix.
  ///
  /// In zh, this message translates to:
  /// **'消费构成'**
  String get expenseMix;

  /// No description provided for @closingBalanceSheetMix.
  ///
  /// In zh, this message translates to:
  /// **'期末资产负债构成'**
  String get closingBalanceSheetMix;

  /// No description provided for @valuationMissingSuffix.
  ///
  /// In zh, this message translates to:
  /// **'（缺估值）'**
  String get valuationMissingSuffix;

  /// No description provided for @valuationStaleSuffix.
  ///
  /// In zh, this message translates to:
  /// **'（估值过期）'**
  String get valuationStaleSuffix;

  /// No description provided for @monthlyReport.
  ///
  /// In zh, this message translates to:
  /// **'月报'**
  String get monthlyReport;

  /// No description provided for @yearlyReport.
  ///
  /// In zh, this message translates to:
  /// **'年度'**
  String get yearlyReport;

  /// No description provided for @riskTitle.
  ///
  /// In zh, this message translates to:
  /// **'风险与风险调整后收益'**
  String get riskTitle;

  /// No description provided for @riskFreeRateTooltip.
  ///
  /// In zh, this message translates to:
  /// **'无风险利率（Sharpe/Sortino 参数）'**
  String get riskFreeRateTooltip;

  /// No description provided for @riskNeedMorePoints.
  ///
  /// In zh, this message translates to:
  /// **'需要至少 2 个有效月末估值点（当前 {n} 个）。\n每月给持仓更新一次价格，即可得到回撤、波动率等风险画像。'**
  String riskNeedMorePoints(num n);

  /// No description provided for @riskSmallSample.
  ///
  /// In zh, this message translates to:
  /// **'⚠ 有效样本 {n} 个月（< 6），指标波动大，仅供参考'**
  String riskSmallSample(num n);

  /// No description provided for @annualizedReturnTwr.
  ///
  /// In zh, this message translates to:
  /// **'年化收益（TWR）'**
  String get annualizedReturnTwr;

  /// No description provided for @annualizedVolatility.
  ///
  /// In zh, this message translates to:
  /// **'年化波动率'**
  String get annualizedVolatility;

  /// No description provided for @sharpeRatio.
  ///
  /// In zh, this message translates to:
  /// **'Sharpe 比率'**
  String get sharpeRatio;

  /// No description provided for @sharpeFormulaHint.
  ///
  /// In zh, this message translates to:
  /// **'(年化收益 − 无风险) / 波动率'**
  String get sharpeFormulaHint;

  /// No description provided for @sortinoRatio.
  ///
  /// In zh, this message translates to:
  /// **'Sortino 比率'**
  String get sortinoRatio;

  /// No description provided for @sortinoHint.
  ///
  /// In zh, this message translates to:
  /// **'下行偏差版 Sharpe'**
  String get sortinoHint;

  /// No description provided for @bestWorstMonth.
  ///
  /// In zh, this message translates to:
  /// **'最佳 / 最差月'**
  String get bestWorstMonth;

  /// No description provided for @monthWinRate.
  ///
  /// In zh, this message translates to:
  /// **'月胜率'**
  String get monthWinRate;

  /// No description provided for @riskBasisNote.
  ///
  /// In zh, this message translates to:
  /// **'基于 {periods} 个月度子期间（近 36 个月中 {points} 个有效月末估值点）· 无风险利率 {rf}%'**
  String riskBasisNote(num periods, num points, String rf);

  /// No description provided for @drawdownSpan.
  ///
  /// In zh, this message translates to:
  /// **'{peak} 峰 → {trough} 谷'**
  String drawdownSpan(String peak, String trough);

  /// No description provided for @maxDrawdown.
  ///
  /// In zh, this message translates to:
  /// **'最大回撤'**
  String get maxDrawdown;

  /// No description provided for @riskFreeRateDialogTitle.
  ///
  /// In zh, this message translates to:
  /// **'无风险利率（年化 %）'**
  String get riskFreeRateDialogTitle;

  /// No description provided for @riskFreeRateHint.
  ///
  /// In zh, this message translates to:
  /// **'如 2.0（十年期国债收益率附近）'**
  String get riskFreeRateHint;

  /// No description provided for @yearSummaryTitle.
  ///
  /// In zh, this message translates to:
  /// **'{year} 年总览'**
  String yearSummaryTitle(num year);

  /// No description provided for @yearTotalIncome.
  ///
  /// In zh, this message translates to:
  /// **'全年收入'**
  String get yearTotalIncome;

  /// No description provided for @yearTotalExpense.
  ///
  /// In zh, this message translates to:
  /// **'全年消费'**
  String get yearTotalExpense;

  /// No description provided for @surplus.
  ///
  /// In zh, this message translates to:
  /// **'结余'**
  String get surplus;

  /// No description provided for @savingsRate.
  ///
  /// In zh, this message translates to:
  /// **'储蓄率'**
  String get savingsRate;

  /// No description provided for @savingsRateTooltip.
  ///
  /// In zh, this message translates to:
  /// **'结余 / 收入'**
  String get savingsRateTooltip;

  /// No description provided for @positiveSurplusMonths.
  ///
  /// In zh, this message translates to:
  /// **'结余为正的月份'**
  String get positiveSurplusMonths;

  /// No description provided for @interestPaid.
  ///
  /// In zh, this message translates to:
  /// **'支付利息'**
  String get interestPaid;

  /// No description provided for @interestPaidTooltip.
  ///
  /// In zh, this message translates to:
  /// **'全年债务成本'**
  String get interestPaidTooltip;

  /// No description provided for @realizedPnl.
  ///
  /// In zh, this message translates to:
  /// **'已实现投资损益'**
  String get realizedPnl;

  /// No description provided for @realizedPnlTooltip.
  ///
  /// In zh, this message translates to:
  /// **'卖出落袋（账面口径）'**
  String get realizedPnlTooltip;

  /// No description provided for @dividends.
  ///
  /// In zh, this message translates to:
  /// **'分红派息'**
  String get dividends;

  /// No description provided for @netInvestmentGain.
  ///
  /// In zh, this message translates to:
  /// **'投资净收益'**
  String get netInvestmentGain;

  /// No description provided for @netInvestmentGainTooltip.
  ///
  /// In zh, this message translates to:
  /// **'已实现 + 分红'**
  String get netInvestmentGainTooltip;

  /// No description provided for @monthlyCashflow.
  ///
  /// In zh, this message translates to:
  /// **'月度收支'**
  String get monthlyCashflow;

  /// No description provided for @incomeLabel.
  ///
  /// In zh, this message translates to:
  /// **'收入'**
  String get incomeLabel;

  /// No description provided for @expenseLabel.
  ///
  /// In zh, this message translates to:
  /// **'支出'**
  String get expenseLabel;

  /// No description provided for @barTooltipMonth.
  ///
  /// In zh, this message translates to:
  /// **'{n} 月\n{amount}'**
  String barTooltipMonth(num n, String amount);

  /// No description provided for @yearExpenseRanking.
  ///
  /// In zh, this message translates to:
  /// **'全年消费排行'**
  String get yearExpenseRanking;

  /// No description provided for @yearHighlights.
  ///
  /// In zh, this message translates to:
  /// **'年度亮点'**
  String get yearHighlights;

  /// No description provided for @biggestExpense.
  ///
  /// In zh, this message translates to:
  /// **'最大单笔：{label}'**
  String biggestExpense(String label);

  /// No description provided for @expenseFallback.
  ///
  /// In zh, this message translates to:
  /// **'消费'**
  String get expenseFallback;

  /// No description provided for @loanPrincipalRepaid.
  ///
  /// In zh, this message translates to:
  /// **'全年还贷本金'**
  String get loanPrincipalRepaid;

  /// No description provided for @incomeCategoryEntry.
  ///
  /// In zh, this message translates to:
  /// **'收入 · {name}'**
  String incomeCategoryEntry(String name);

  /// No description provided for @globeTitle.
  ///
  /// In zh, this message translates to:
  /// **'资产地球'**
  String get globeTitle;

  /// No description provided for @globeBackToOverview.
  ///
  /// In zh, this message translates to:
  /// **'返回总览'**
  String get globeBackToOverview;

  /// No description provided for @globeResetView.
  ///
  /// In zh, this message translates to:
  /// **'复位视角'**
  String get globeResetView;

  /// No description provided for @globeFullscreen.
  ///
  /// In zh, this message translates to:
  /// **'全屏地球'**
  String get globeFullscreen;

  /// No description provided for @globeAssetCategory.
  ///
  /// In zh, this message translates to:
  /// **'资产类别'**
  String get globeAssetCategory;

  /// No description provided for @globeInstitution.
  ///
  /// In zh, this message translates to:
  /// **'机构'**
  String get globeInstitution;

  /// No description provided for @globeCurrentValue.
  ///
  /// In zh, this message translates to:
  /// **'当前价值'**
  String get globeCurrentValue;

  /// No description provided for @globeValuationMissingExcluded.
  ///
  /// In zh, this message translates to:
  /// **'缺估值（不计净资产）'**
  String get globeValuationMissingExcluded;

  /// No description provided for @globeValuationStale.
  ///
  /// In zh, this message translates to:
  /// **'已过期（>30 天未更新）'**
  String get globeValuationStale;

  /// No description provided for @globeDenominationCurrency.
  ///
  /// In zh, this message translates to:
  /// **'计价币种'**
  String get globeDenominationCurrency;

  /// No description provided for @globeViewAndEdit.
  ///
  /// In zh, this message translates to:
  /// **'查看与编辑'**
  String get globeViewAndEdit;

  /// No description provided for @globeMoreSameLocation.
  ///
  /// In zh, this message translates to:
  /// **'同址还有 {n} 处资产'**
  String globeMoreSameLocation(num n);

  /// No description provided for @globeValuationMissing.
  ///
  /// In zh, this message translates to:
  /// **'缺估值'**
  String get globeValuationMissing;

  /// No description provided for @homeLoadFailed.
  ///
  /// In zh, this message translates to:
  /// **'加载失败：{error}'**
  String homeLoadFailed(Object error);

  /// No description provided for @homeTodoTooltip.
  ///
  /// In zh, this message translates to:
  /// **'待办事项'**
  String get homeTodoTooltip;

  /// No description provided for @homeTodoPending.
  ///
  /// In zh, this message translates to:
  /// **'待办 · {n} 项待处理，点击查看'**
  String homeTodoPending(num n);

  /// No description provided for @homeAiTooltip.
  ///
  /// In zh, this message translates to:
  /// **'AI 助手'**
  String get homeAiTooltip;

  /// No description provided for @homeSettingsTooltip.
  ///
  /// In zh, this message translates to:
  /// **'设置'**
  String get homeSettingsTooltip;

  /// No description provided for @homeLocateCurrentTooltip.
  ///
  /// In zh, this message translates to:
  /// **'定位当前位置'**
  String get homeLocateCurrentTooltip;

  /// No description provided for @homeLocating.
  ///
  /// In zh, this message translates to:
  /// **'定位中…'**
  String get homeLocating;

  /// No description provided for @homeLocatedExact.
  ///
  /// In zh, this message translates to:
  /// **'已定位当前位置：{city}'**
  String homeLocatedExact(String city);

  /// No description provided for @homeLocatedEstimate.
  ///
  /// In zh, this message translates to:
  /// **'定位服务不可用，已按本地时区估计：{city}'**
  String homeLocatedEstimate(String city);

  /// No description provided for @homeAddAsset.
  ///
  /// In zh, this message translates to:
  /// **'添加资产'**
  String get homeAddAsset;

  /// No description provided for @homeAddAssetTooltip.
  ///
  /// In zh, this message translates to:
  /// **'新建资产/负债账户，为资产选位置即点亮地球'**
  String get homeAddAssetTooltip;

  /// No description provided for @homeLogTransaction.
  ///
  /// In zh, this message translates to:
  /// **'记一笔'**
  String get homeLogTransaction;

  /// No description provided for @homeLogTransactionTooltip.
  ///
  /// In zh, this message translates to:
  /// **'上报消费 / 收入 / 转账等日常流水'**
  String get homeLogTransactionTooltip;

  /// No description provided for @homeCollapse.
  ///
  /// In zh, this message translates to:
  /// **'收起'**
  String get homeCollapse;

  /// No description provided for @homeQuickAdd.
  ///
  /// In zh, this message translates to:
  /// **'记一笔 / 添加资产'**
  String get homeQuickAdd;

  /// No description provided for @homeCollapseQuickMenu.
  ///
  /// In zh, this message translates to:
  /// **'收起快捷菜单'**
  String get homeCollapseQuickMenu;

  /// No description provided for @homeAddSemantic.
  ///
  /// In zh, this message translates to:
  /// **'添加：记一笔或添加资产'**
  String get homeAddSemantic;

  /// No description provided for @homeRefreshing.
  ///
  /// In zh, this message translates to:
  /// **'刷新中…'**
  String get homeRefreshing;

  /// No description provided for @homeRefreshData.
  ///
  /// In zh, this message translates to:
  /// **'刷新数据'**
  String get homeRefreshData;

  /// No description provided for @homeNwCardHint.
  ///
  /// In zh, this message translates to:
  /// **'月报 · 净资产变化分解'**
  String get homeNwCardHint;

  /// No description provided for @homeFlowCardHint.
  ///
  /// In zh, this message translates to:
  /// **'流水 · 本月全部收支'**
  String get homeFlowCardHint;

  /// No description provided for @homeHealthCardHint.
  ///
  /// In zh, this message translates to:
  /// **'月报 · 体检与构成明细'**
  String get homeHealthCardHint;

  /// No description provided for @homeAssetsCardHint.
  ///
  /// In zh, this message translates to:
  /// **'资产 · 全部账户台账与编辑'**
  String get homeAssetsCardHint;

  /// No description provided for @homeBudgetCardHint.
  ///
  /// In zh, this message translates to:
  /// **'预算 · 额度与配速'**
  String get homeBudgetCardHint;

  /// No description provided for @homeTrendCardHint.
  ///
  /// In zh, this message translates to:
  /// **'月报 · 历史走势与归因'**
  String get homeTrendCardHint;

  /// No description provided for @homePlansCardHint.
  ///
  /// In zh, this message translates to:
  /// **'计划 · 固定开销与预定支出'**
  String get homePlansCardHint;

  /// No description provided for @homeAutoPosted.
  ///
  /// In zh, this message translates to:
  /// **'已按计划自动记入 {n} 笔交易，可在流水中查看（来源：计划）'**
  String homeAutoPosted(num n);

  /// No description provided for @dashNetWorth.
  ///
  /// In zh, this message translates to:
  /// **'净资产'**
  String get dashNetWorth;

  /// No description provided for @dashAsOf.
  ///
  /// In zh, this message translates to:
  /// **'截至 {date}'**
  String dashAsOf(String date);

  /// No description provided for @dashMyShare.
  ///
  /// In zh, this message translates to:
  /// **'我的份额 {amount}'**
  String dashMyShare(String amount);

  /// No description provided for @dashAssetsAmount.
  ///
  /// In zh, this message translates to:
  /// **'资产 {amount}'**
  String dashAssetsAmount(String amount);

  /// No description provided for @dashLiabAmount.
  ///
  /// In zh, this message translates to:
  /// **'负债 {amount}'**
  String dashLiabAmount(String amount);

  /// No description provided for @dashResidualTooltip.
  ///
  /// In zh, this message translates to:
  /// **'差额非 0 通常意味着缺估值、漏记或导入重复（月报页有明细）'**
  String get dashResidualTooltip;

  /// No description provided for @dashPendingReview.
  ///
  /// In zh, this message translates to:
  /// **'待核对 {amount}'**
  String dashPendingReview(String amount);

  /// No description provided for @dashTotalAssets.
  ///
  /// In zh, this message translates to:
  /// **'总资产'**
  String get dashTotalAssets;

  /// No description provided for @dashTotalLiabilities.
  ///
  /// In zh, this message translates to:
  /// **'总负债'**
  String get dashTotalLiabilities;

  /// No description provided for @dashMonthFlow.
  ///
  /// In zh, this message translates to:
  /// **'本月收支（{m} 月）'**
  String dashMonthFlow(num m);

  /// No description provided for @dashIncome.
  ///
  /// In zh, this message translates to:
  /// **'收入'**
  String get dashIncome;

  /// No description provided for @dashSpendFees.
  ///
  /// In zh, this message translates to:
  /// **'消费与费用'**
  String get dashSpendFees;

  /// No description provided for @dashSurplus.
  ///
  /// In zh, this message translates to:
  /// **'结余'**
  String get dashSurplus;

  /// No description provided for @dashInvestPnl.
  ///
  /// In zh, this message translates to:
  /// **'投资损益'**
  String get dashInvestPnl;

  /// No description provided for @dashPrincipalRepaid.
  ///
  /// In zh, this message translates to:
  /// **'还贷本金'**
  String get dashPrincipalRepaid;

  /// No description provided for @dashInterestPaid.
  ///
  /// In zh, this message translates to:
  /// **'支付利息'**
  String get dashInterestPaid;

  /// No description provided for @dashSpendable.
  ///
  /// In zh, this message translates to:
  /// **'还能花多少（未来 {n} 天）'**
  String dashSpendable(num n);

  /// No description provided for @dashForecastThrough.
  ///
  /// In zh, this message translates to:
  /// **'现金流预测截至 {date}'**
  String dashForecastThrough(String date);

  /// No description provided for @dashDiscretionaryCap.
  ///
  /// In zh, this message translates to:
  /// **'计划外可支配上限'**
  String get dashDiscretionaryCap;

  /// No description provided for @dashDiscretionaryCapHint.
  ///
  /// In zh, this message translates to:
  /// **'已扣除固定计划、还款、准备金与现金底线'**
  String get dashDiscretionaryCapHint;

  /// No description provided for @dashMonthSpendForecast.
  ///
  /// In zh, this message translates to:
  /// **'本月消费预测'**
  String get dashMonthSpendForecast;

  /// No description provided for @dashMonthSpendForecastHint.
  ///
  /// In zh, this message translates to:
  /// **'按当前速度外推到月末'**
  String get dashMonthSpendForecastHint;

  /// No description provided for @dashDailyAllowance.
  ///
  /// In zh, this message translates to:
  /// **'剩余日均可花'**
  String get dashDailyAllowance;

  /// No description provided for @dashDaysElapsed.
  ///
  /// In zh, this message translates to:
  /// **'本月已过 {n} 天'**
  String dashDaysElapsed(num n);

  /// No description provided for @dashCashLowPoint.
  ///
  /// In zh, this message translates to:
  /// **'现金最低点'**
  String get dashCashLowPoint;

  /// No description provided for @dashShortfall.
  ///
  /// In zh, this message translates to:
  /// **'{label}（{date}）短缺'**
  String dashShortfall(String label, String date);

  /// No description provided for @dashHealthTitle.
  ///
  /// In zh, this message translates to:
  /// **'财务体检'**
  String get dashHealthTitle;

  /// No description provided for @dashSavingsRate.
  ///
  /// In zh, this message translates to:
  /// **'储蓄率'**
  String get dashSavingsRate;

  /// No description provided for @dashSavingsRateHint.
  ///
  /// In zh, this message translates to:
  /// **'本月（收入−消费）/收入'**
  String get dashSavingsRateHint;

  /// No description provided for @dashEmergencyMonths.
  ///
  /// In zh, this message translates to:
  /// **'应急月数'**
  String get dashEmergencyMonths;

  /// No description provided for @dashEmergencyMonthsHint.
  ///
  /// In zh, this message translates to:
  /// **'流动资产/月均消费'**
  String get dashEmergencyMonthsHint;

  /// No description provided for @dashDebtToAsset.
  ///
  /// In zh, this message translates to:
  /// **'资产负债率'**
  String get dashDebtToAsset;

  /// No description provided for @dashDebtToAssetHint.
  ///
  /// In zh, this message translates to:
  /// **'总负债/总资产'**
  String get dashDebtToAssetHint;

  /// No description provided for @dashInsights.
  ///
  /// In zh, this message translates to:
  /// **'智慧洞察'**
  String get dashInsights;

  /// No description provided for @dashNwTrend.
  ///
  /// In zh, this message translates to:
  /// **'净资产走势'**
  String get dashNwTrend;

  /// No description provided for @dashNwTrendMonths.
  ///
  /// In zh, this message translates to:
  /// **'净资产走势（近 {n} 个月）'**
  String dashNwTrendMonths(num n);

  /// No description provided for @dashNwTrendHint.
  ///
  /// In zh, this message translates to:
  /// **'按住底部滚筒左右拖动：从 1 个月拉长到 {n} 个月'**
  String dashNwTrendHint(num n);

  /// No description provided for @dashRollerHint.
  ///
  /// In zh, this message translates to:
  /// **'按住滚筒左右拖动：1 ~ {n} 个月'**
  String dashRollerHint(num n);

  /// No description provided for @dashUpcomingTitle.
  ///
  /// In zh, this message translates to:
  /// **'未来 30 天要花的钱'**
  String get dashUpcomingTitle;

  /// No description provided for @dashNoUpcoming.
  ///
  /// In zh, this message translates to:
  /// **'暂无计划支出'**
  String get dashNoUpcoming;

  /// No description provided for @dashPendingDue.
  ///
  /// In zh, this message translates to:
  /// **'{n} 笔到期计划待入账（计划页可一键记入）'**
  String dashPendingDue(num n);

  /// No description provided for @dashMissingValuations.
  ///
  /// In zh, this message translates to:
  /// **'{n} 个账户缺估值（不计为 0，请编辑账户补录）'**
  String dashMissingValuations(num n);

  /// No description provided for @dashStaleValuations.
  ///
  /// In zh, this message translates to:
  /// **'{n} 个账户估值已过期（>30 天）'**
  String dashStaleValuations(num n);

  /// No description provided for @dashResidualIssue.
  ///
  /// In zh, this message translates to:
  /// **'本月归因存在待核对差额：{amount}'**
  String dashResidualIssue(String amount);

  /// No description provided for @dashIssuesTitle.
  ///
  /// In zh, this message translates to:
  /// **'待处理'**
  String get dashIssuesTitle;

  /// No description provided for @dashBalanceSheet.
  ///
  /// In zh, this message translates to:
  /// **'资产负债表'**
  String get dashBalanceSheet;

  /// No description provided for @dashAssetsTotal.
  ///
  /// In zh, this message translates to:
  /// **'资产合计'**
  String get dashAssetsTotal;

  /// No description provided for @dashLiabilitiesTotal.
  ///
  /// In zh, this message translates to:
  /// **'负债合计'**
  String get dashLiabilitiesTotal;

  /// No description provided for @dashIncludedAccounts.
  ///
  /// In zh, this message translates to:
  /// **'计入账户'**
  String get dashIncludedAccounts;

  /// No description provided for @dashAccountCount.
  ///
  /// In zh, this message translates to:
  /// **'{n} 项'**
  String dashAccountCount(num n);

  /// No description provided for @dashValuationStatus.
  ///
  /// In zh, this message translates to:
  /// **'估值状态'**
  String get dashValuationStatus;

  /// No description provided for @dashMissingCount.
  ///
  /// In zh, this message translates to:
  /// **'{n} 项缺估值'**
  String dashMissingCount(num n);

  /// No description provided for @dashStaleCount.
  ///
  /// In zh, this message translates to:
  /// **'{n} 项已过期'**
  String dashStaleCount(num n);

  /// No description provided for @aiAssistant.
  ///
  /// In zh, this message translates to:
  /// **'AI 助手'**
  String get aiAssistant;

  /// No description provided for @aiHistorySessions.
  ///
  /// In zh, this message translates to:
  /// **'历史会话'**
  String get aiHistorySessions;

  /// No description provided for @aiBindKeyFirst.
  ///
  /// In zh, this message translates to:
  /// **'先在 设置 → AI 服务 绑定你自己的 AI Key'**
  String get aiBindKeyFirst;

  /// No description provided for @aiAssistantError.
  ///
  /// In zh, this message translates to:
  /// **'AI 助手：{error}'**
  String aiAssistantError(String error);

  /// No description provided for @aiSessions.
  ///
  /// In zh, this message translates to:
  /// **'会话'**
  String get aiSessions;

  /// No description provided for @aiNewChat.
  ///
  /// In zh, this message translates to:
  /// **'新对话'**
  String get aiNewChat;

  /// No description provided for @aiNoSessionsHint.
  ///
  /// In zh, this message translates to:
  /// **'还没有会话，点右上「+」开始第一段对话。'**
  String get aiNoSessionsHint;

  /// No description provided for @aiDeleteChat.
  ///
  /// In zh, this message translates to:
  /// **'删除会话'**
  String get aiDeleteChat;

  /// No description provided for @aiLedgerContextOn.
  ///
  /// In zh, this message translates to:
  /// **'已附带账本概况：净资产、本月收支等汇总数字会发给 AI（不含逐笔明细）'**
  String get aiLedgerContextOn;

  /// No description provided for @aiLedgerContextOff.
  ///
  /// In zh, this message translates to:
  /// **'未附带账本数据：AI 只作通用回答'**
  String get aiLedgerContextOff;

  /// No description provided for @aiAskSomething.
  ///
  /// In zh, this message translates to:
  /// **'问点什么，或从下面开始'**
  String get aiAskSomething;

  /// No description provided for @aiInputHint.
  ///
  /// In zh, this message translates to:
  /// **'问你的账房先生…（Enter 发送）'**
  String get aiInputHint;

  /// No description provided for @aiSend.
  ///
  /// In zh, this message translates to:
  /// **'发送'**
  String get aiSend;

  /// No description provided for @aiPromptSpendWhere.
  ///
  /// In zh, this message translates to:
  /// **'我的钱都花哪儿了？'**
  String get aiPromptSpendWhere;

  /// No description provided for @aiPromptNwTrend.
  ///
  /// In zh, this message translates to:
  /// **'净资产最近走势如何？'**
  String get aiPromptNwTrend;

  /// No description provided for @aiPromptSaveMonth.
  ///
  /// In zh, this message translates to:
  /// **'这个月怎么省下一笔？'**
  String get aiPromptSaveMonth;

  /// No description provided for @aiPromptPrepay.
  ///
  /// In zh, this message translates to:
  /// **'现在适合提前还贷吗？'**
  String get aiPromptPrepay;

  /// No description provided for @aiValuationsUpdated.
  ///
  /// In zh, this message translates to:
  /// **'AI 已更新 {n} 项资产估值（来源可审计，可在账户详情纠正）'**
  String aiValuationsUpdated(num n);

  /// No description provided for @aiValuationsUpdatedFailed.
  ///
  /// In zh, this message translates to:
  /// **'AI 已更新 {n} 项资产估值（部分失败，可在账户详情查看）'**
  String aiValuationsUpdatedFailed(num n);

  /// No description provided for @commonCancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get commonCancel;

  /// No description provided for @commonSave.
  ///
  /// In zh, this message translates to:
  /// **'保存'**
  String get commonSave;

  /// No description provided for @commonEdit.
  ///
  /// In zh, this message translates to:
  /// **'编辑'**
  String get commonEdit;

  /// No description provided for @commonVoid.
  ///
  /// In zh, this message translates to:
  /// **'作废'**
  String get commonVoid;

  /// No description provided for @commonGotIt.
  ///
  /// In zh, this message translates to:
  /// **'知道了'**
  String get commonGotIt;

  /// No description provided for @fieldType.
  ///
  /// In zh, this message translates to:
  /// **'类型'**
  String get fieldType;

  /// No description provided for @dirIncome.
  ///
  /// In zh, this message translates to:
  /// **'收入'**
  String get dirIncome;

  /// No description provided for @dirExpense.
  ///
  /// In zh, this message translates to:
  /// **'支出'**
  String get dirExpense;

  /// No description provided for @txAddTitle.
  ///
  /// In zh, this message translates to:
  /// **'记一笔'**
  String get txAddTitle;

  /// No description provided for @txEditTitle.
  ///
  /// In zh, this message translates to:
  /// **'编辑交易'**
  String get txEditTitle;

  /// No description provided for @txPageTitle.
  ///
  /// In zh, this message translates to:
  /// **'流水'**
  String get txPageTitle;

  /// No description provided for @txExportCsvTooltip.
  ///
  /// In zh, this message translates to:
  /// **'导出 CSV（明文，自选位置）'**
  String get txExportCsvTooltip;

  /// No description provided for @txImportCsvTooltip.
  ///
  /// In zh, this message translates to:
  /// **'导入账单 CSV'**
  String get txImportCsvTooltip;

  /// No description provided for @txSearchHint.
  ///
  /// In zh, this message translates to:
  /// **'搜索全账本：备注、对方、标签'**
  String get txSearchHint;

  /// No description provided for @txEmptyTitle.
  ///
  /// In zh, this message translates to:
  /// **'还没有流水'**
  String get txEmptyTitle;

  /// No description provided for @txNoMatchTitle.
  ///
  /// In zh, this message translates to:
  /// **'没有匹配的交易'**
  String get txNoMatchTitle;

  /// No description provided for @txEmptyHint.
  ///
  /// In zh, this message translates to:
  /// **'右下角「记一笔」，或从设置导入账单 CSV。'**
  String get txEmptyHint;

  /// No description provided for @txNoMatchHint.
  ///
  /// In zh, this message translates to:
  /// **'换个关键词，或清除类型筛选再试。'**
  String get txNoMatchHint;

  /// No description provided for @txNoMatchHintWide.
  ///
  /// In zh, this message translates to:
  /// **'换个关键词，或清除右侧类型筛选再试。'**
  String get txNoMatchHintWide;

  /// No description provided for @txExportedToast.
  ///
  /// In zh, this message translates to:
  /// **'已导出流水 CSV（含 BOM，Excel 可直接打开）'**
  String get txExportedToast;

  /// No description provided for @txAccountLabel.
  ///
  /// In zh, this message translates to:
  /// **'账户'**
  String get txAccountLabel;

  /// No description provided for @txAccountPayFrom.
  ///
  /// In zh, this message translates to:
  /// **'支付账户'**
  String get txAccountPayFrom;

  /// No description provided for @txAccountDeposit.
  ///
  /// In zh, this message translates to:
  /// **'入账账户'**
  String get txAccountDeposit;

  /// No description provided for @txAccountTransferFrom.
  ///
  /// In zh, this message translates to:
  /// **'转出账户'**
  String get txAccountTransferFrom;

  /// No description provided for @txAccountTransferTo.
  ///
  /// In zh, this message translates to:
  /// **'转入账户'**
  String get txAccountTransferTo;

  /// No description provided for @txAccountRepayCard.
  ///
  /// In zh, this message translates to:
  /// **'偿还卡片'**
  String get txAccountRepayCard;

  /// No description provided for @txAccountRepayFrom.
  ///
  /// In zh, this message translates to:
  /// **'还款来源'**
  String get txAccountRepayFrom;

  /// No description provided for @txAccountLoan.
  ///
  /// In zh, this message translates to:
  /// **'贷款账户'**
  String get txAccountLoan;

  /// No description provided for @txAccountBorrowTo.
  ///
  /// In zh, this message translates to:
  /// **'借入到'**
  String get txAccountBorrowTo;

  /// No description provided for @txAccountBorrowToAsset.
  ///
  /// In zh, this message translates to:
  /// **'借入到账账户（资产）'**
  String get txAccountBorrowToAsset;

  /// No description provided for @txAccountLendReceivable.
  ///
  /// In zh, this message translates to:
  /// **'借出（挂应收）'**
  String get txAccountLendReceivable;

  /// No description provided for @txAccountReceiveBackTo.
  ///
  /// In zh, this message translates to:
  /// **'收回至'**
  String get txAccountReceiveBackTo;

  /// No description provided for @txAccountCounterpartyCash.
  ///
  /// In zh, this message translates to:
  /// **'对方现金账户'**
  String get txAccountCounterpartyCash;

  /// No description provided for @txAccountB.
  ///
  /// In zh, this message translates to:
  /// **'账户 B'**
  String get txAccountB;

  /// No description provided for @txInterestCategory.
  ///
  /// In zh, this message translates to:
  /// **'利息分类'**
  String get txInterestCategory;

  /// No description provided for @txCategory.
  ///
  /// In zh, this message translates to:
  /// **'分类'**
  String get txCategory;

  /// No description provided for @txNoteOptional.
  ///
  /// In zh, this message translates to:
  /// **'备注（可选）'**
  String get txNoteOptional;

  /// No description provided for @txVoidedBadge.
  ///
  /// In zh, this message translates to:
  /// **'已作废'**
  String get txVoidedBadge;

  /// No description provided for @txPostingsTitle.
  ///
  /// In zh, this message translates to:
  /// **'分录（借贷平衡）'**
  String get txPostingsTitle;

  /// No description provided for @txShares.
  ///
  /// In zh, this message translates to:
  /// **'{q} 份'**
  String txShares(String q);

  /// No description provided for @txExternalId.
  ///
  /// In zh, this message translates to:
  /// **'外部 ID：{id}'**
  String txExternalId(String id);

  /// No description provided for @txVoidConfirmTitle.
  ///
  /// In zh, this message translates to:
  /// **'作废此交易？'**
  String get txVoidConfirmTitle;

  /// No description provided for @txVoidConfirmMessage.
  ///
  /// In zh, this message translates to:
  /// **'作废后分录不再计入余额与统计，但保留审计痕迹。'**
  String get txVoidConfirmMessage;

  /// No description provided for @monthExpense.
  ///
  /// In zh, this message translates to:
  /// **'本月支出'**
  String get monthExpense;

  /// No description provided for @monthIncome.
  ///
  /// In zh, this message translates to:
  /// **'本月收入'**
  String get monthIncome;

  /// No description provided for @monthSurplus.
  ///
  /// In zh, this message translates to:
  /// **'本月结余'**
  String get monthSurplus;

  /// No description provided for @monthThis.
  ///
  /// In zh, this message translates to:
  /// **'本月'**
  String get monthThis;

  /// No description provided for @monthSpent.
  ///
  /// In zh, this message translates to:
  /// **'已支出'**
  String get monthSpent;

  /// No description provided for @monthCnyOnlyTooltip.
  ///
  /// In zh, this message translates to:
  /// **'仅统计人民币流水，避免混币求和失真'**
  String get monthCnyOnlyTooltip;

  /// No description provided for @filterPanelHint.
  ///
  /// In zh, this message translates to:
  /// **'按交易种类过滤台账；搜索不受此筛选限制'**
  String get filterPanelHint;

  /// No description provided for @importTitle.
  ///
  /// In zh, this message translates to:
  /// **'导入账单'**
  String get importTitle;

  /// No description provided for @importFileTypeBills.
  ///
  /// In zh, this message translates to:
  /// **'账单'**
  String get importFileTypeBills;

  /// No description provided for @importStepHeader.
  ///
  /// In zh, this message translates to:
  /// **'第 {n}/4 步 · {title}'**
  String importStepHeader(num n, String title);

  /// No description provided for @importStepPickFile.
  ///
  /// In zh, this message translates to:
  /// **'选择文件'**
  String get importStepPickFile;

  /// No description provided for @importStepChooseAccount.
  ///
  /// In zh, this message translates to:
  /// **'选择账户'**
  String get importStepChooseAccount;

  /// No description provided for @importStepPreview.
  ///
  /// In zh, this message translates to:
  /// **'预览与分类'**
  String get importStepPreview;

  /// No description provided for @importStepDone.
  ///
  /// In zh, this message translates to:
  /// **'完成'**
  String get importStepDone;

  /// No description provided for @importParsePreview.
  ///
  /// In zh, this message translates to:
  /// **'解析预览'**
  String get importParsePreview;

  /// No description provided for @importConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确认入账'**
  String get importConfirm;

  /// No description provided for @importPickFileHint.
  ///
  /// In zh, this message translates to:
  /// **'微信 / 支付宝导出的原生账单（CSV，GBK 或 UTF-8）自动识别列名与交易单号，无需改表头；其他 CSV 需表头含 date、type、amount 三列。'**
  String get importPickFileHint;

  /// No description provided for @importChooseCsvFile.
  ///
  /// In zh, this message translates to:
  /// **'选择 CSV 文件'**
  String get importChooseCsvFile;

  /// No description provided for @importParseFailed.
  ///
  /// In zh, this message translates to:
  /// **'解析失败：{error}'**
  String importParseFailed(String error);

  /// No description provided for @importTargetAccount.
  ///
  /// In zh, this message translates to:
  /// **'入到哪个账户'**
  String get importTargetAccount;

  /// No description provided for @importFileName.
  ///
  /// In zh, this message translates to:
  /// **'文件：{file}'**
  String importFileName(String file);

  /// No description provided for @importRowsDetected.
  ///
  /// In zh, this message translates to:
  /// **'已识别 {n} 行'**
  String importRowsDetected(num n);

  /// No description provided for @importDefaultExpenseCategory.
  ///
  /// In zh, this message translates to:
  /// **'支出默认分类'**
  String get importDefaultExpenseCategory;

  /// No description provided for @importDefaultIncomeCategory.
  ///
  /// In zh, this message translates to:
  /// **'收入默认分类'**
  String get importDefaultIncomeCategory;

  /// No description provided for @importReadyToPost.
  ///
  /// In zh, this message translates to:
  /// **'可入账'**
  String get importReadyToPost;

  /// No description provided for @importLineCount.
  ///
  /// In zh, this message translates to:
  /// **'{n} 行'**
  String importLineCount(num n);

  /// No description provided for @importExactDuplicates.
  ///
  /// In zh, this message translates to:
  /// **'精确重复跳过'**
  String get importExactDuplicates;

  /// No description provided for @importCategoryHits.
  ///
  /// In zh, this message translates to:
  /// **'智慧分类命中'**
  String get importCategoryHits;

  /// No description provided for @importCategoryHitsDetail.
  ///
  /// In zh, this message translates to:
  /// **'{n} 行（规则+历史学习）'**
  String importCategoryHitsDetail(num n);

  /// No description provided for @importParserSkipped.
  ///
  /// In zh, this message translates to:
  /// **'原生解析跳过'**
  String get importParserSkipped;

  /// No description provided for @importTransferSuggestions.
  ///
  /// In zh, this message translates to:
  /// **'转账配对建议'**
  String get importTransferSuggestions;

  /// No description provided for @importTransferSuggestionDetail.
  ///
  /// In zh, this message translates to:
  /// **'{n} 条（导入后可在流水页人工合并）'**
  String importTransferSuggestionDetail(num n);

  /// No description provided for @importNoCounterparty.
  ///
  /// In zh, this message translates to:
  /// **'(无对方)'**
  String get importNoCounterparty;

  /// No description provided for @importPostedCount.
  ///
  /// In zh, this message translates to:
  /// **'已入账 {n} 笔'**
  String importPostedCount(num n);

  /// No description provided for @importDoneHint.
  ///
  /// In zh, this message translates to:
  /// **'重复导入同一文件会自动跳过（外部 ID 幂等）。对手方分类已被学习，下次导入会自动建议。'**
  String get importDoneHint;

  /// No description provided for @strategyCompareTitle.
  ///
  /// In zh, this message translates to:
  /// **'还款策略对比'**
  String get strategyCompareTitle;

  /// No description provided for @strategySubtitle.
  ///
  /// In zh, this message translates to:
  /// **'在最低还款之外，每月额外拿出一笔钱优先还某一笔债'**
  String get strategySubtitle;

  /// No description provided for @strategyExtraMonthly.
  ///
  /// In zh, this message translates to:
  /// **'每月额外还款额'**
  String get strategyExtraMonthly;

  /// No description provided for @strategyResimulate.
  ///
  /// In zh, this message translates to:
  /// **'重新模拟'**
  String get strategyResimulate;

  /// No description provided for @strategyNoDebt.
  ///
  /// In zh, this message translates to:
  /// **'没有待还负债'**
  String get strategyNoDebt;

  /// No description provided for @strategyAvalancheTitle.
  ///
  /// In zh, this message translates to:
  /// **'雪崩法 · 高利率优先'**
  String get strategyAvalancheTitle;

  /// No description provided for @strategySnowballTitle.
  ///
  /// In zh, this message translates to:
  /// **'雪球法 · 小额优先'**
  String get strategySnowballTitle;

  /// No description provided for @strategyAvalancheSaves.
  ///
  /// In zh, this message translates to:
  /// **'雪崩法比雪球法少付利息 {amount}；若你需要\"先清掉一笔\"的成就感，选雪球也完全合理。'**
  String strategyAvalancheSaves(String amount);

  /// No description provided for @strategyPayoffTime.
  ///
  /// In zh, this message translates to:
  /// **'还清时间'**
  String get strategyPayoffTime;

  /// No description provided for @strategyDuration.
  ///
  /// In zh, this message translates to:
  /// **'{years} 年 {months} 个月'**
  String strategyDuration(num years, num months);

  /// No description provided for @strategyTotalInterest.
  ///
  /// In zh, this message translates to:
  /// **'总利息'**
  String get strategyTotalInterest;

  /// No description provided for @strategyPayoffOrder.
  ///
  /// In zh, this message translates to:
  /// **'还清顺序'**
  String get strategyPayoffOrder;

  /// No description provided for @debtPageTitle.
  ///
  /// In zh, this message translates to:
  /// **'负债'**
  String get debtPageTitle;

  /// No description provided for @debtStrategyTooltip.
  ///
  /// In zh, this message translates to:
  /// **'雪崩 vs 雪球策略对比'**
  String get debtStrategyTooltip;

  /// No description provided for @debtNew.
  ///
  /// In zh, this message translates to:
  /// **'新建负债'**
  String get debtNew;

  /// No description provided for @debtEmptyTitle.
  ///
  /// In zh, this message translates to:
  /// **'还没有负债'**
  String get debtEmptyTitle;

  /// No description provided for @debtEmptyHint.
  ///
  /// In zh, this message translates to:
  /// **'登记信用卡、房贷、花呗等负债后，这里给出还款计划与压力模拟。'**
  String get debtEmptyHint;

  /// No description provided for @debtOverviewTitle.
  ///
  /// In zh, this message translates to:
  /// **'负债总览'**
  String get debtOverviewTitle;

  /// No description provided for @debtTotalBase.
  ///
  /// In zh, this message translates to:
  /// **'总负债（折本位币）'**
  String get debtTotalBase;

  /// No description provided for @debtTotalBaseTooltip.
  ///
  /// In zh, this message translates to:
  /// **'按账本内最近汇率折算本位币汇总；无汇率的外币计 0'**
  String get debtTotalBaseTooltip;

  /// No description provided for @debtCountLabel.
  ///
  /// In zh, this message translates to:
  /// **'笔数'**
  String get debtCountLabel;

  /// No description provided for @debtCountValue.
  ///
  /// In zh, this message translates to:
  /// **'{n} 笔'**
  String debtCountValue(num n);

  /// No description provided for @debtWorstApr.
  ///
  /// In zh, this message translates to:
  /// **'最高实际年化'**
  String get debtWorstApr;

  /// No description provided for @debtWorstAprTooltip.
  ///
  /// In zh, this message translates to:
  /// **'IRR 口径；费用率类负债明显高于名义利率'**
  String get debtWorstAprTooltip;

  /// No description provided for @debtRepayMethod.
  ///
  /// In zh, this message translates to:
  /// **'还款方式'**
  String get debtRepayMethod;

  /// No description provided for @debtNominalApr.
  ///
  /// In zh, this message translates to:
  /// **'名义年利率'**
  String get debtNominalApr;

  /// No description provided for @debtNominalAprField.
  ///
  /// In zh, this message translates to:
  /// **'名义年利率 %（如 3.85）'**
  String get debtNominalAprField;

  /// No description provided for @debtTermLabel.
  ///
  /// In zh, this message translates to:
  /// **'期数'**
  String get debtTermLabel;

  /// No description provided for @debtTermCount.
  ///
  /// In zh, this message translates to:
  /// **'{n} 期'**
  String debtTermCount(num n);

  /// No description provided for @debtTermMonthsField.
  ///
  /// In zh, this message translates to:
  /// **'期数（月）'**
  String get debtTermMonthsField;

  /// No description provided for @debtEffectiveApr.
  ///
  /// In zh, this message translates to:
  /// **'实际年化'**
  String get debtEffectiveApr;

  /// No description provided for @debtEffectiveAprTooltip.
  ///
  /// In zh, this message translates to:
  /// **'IRR 口径，费用率类负债明显更高'**
  String get debtEffectiveAprTooltip;

  /// No description provided for @debtNextRepay.
  ///
  /// In zh, this message translates to:
  /// **'下期 {month}/{day} 还 {total}（本金 {principal} + 利息 {interest}）'**
  String debtNextRepay(
    num month,
    num day,
    String total,
    String principal,
    String interest,
  );

  /// No description provided for @debtRepayNext.
  ///
  /// In zh, this message translates to:
  /// **'按计划还款'**
  String get debtRepayNext;

  /// No description provided for @debtPrepaySim.
  ///
  /// In zh, this message translates to:
  /// **'提前还款模拟'**
  String get debtPrepaySim;

  /// No description provided for @debtNoScheduleSnackBar.
  ///
  /// In zh, this message translates to:
  /// **'没有待还期数（或为手工计划）'**
  String get debtNoScheduleSnackBar;

  /// No description provided for @debtPrepaySimTitle.
  ///
  /// In zh, this message translates to:
  /// **'提前还款模拟 · {name}'**
  String debtPrepaySimTitle(String name);

  /// No description provided for @debtRemainingPrincipal.
  ///
  /// In zh, this message translates to:
  /// **'当前剩余本金 {amount}'**
  String debtRemainingPrincipal(String amount);

  /// No description provided for @debtExtraPayment.
  ///
  /// In zh, this message translates to:
  /// **'额外偿还金额'**
  String get debtExtraPayment;

  /// No description provided for @debtSimulate.
  ///
  /// In zh, this message translates to:
  /// **'模拟'**
  String get debtSimulate;

  /// No description provided for @debtSimResultTitle.
  ///
  /// In zh, this message translates to:
  /// **'模拟结果'**
  String get debtSimResultTitle;

  /// No description provided for @debtSimFee.
  ///
  /// In zh, this message translates to:
  /// **'手续费：{fee}'**
  String debtSimFee(String fee);

  /// No description provided for @debtSimInterestSaved.
  ///
  /// In zh, this message translates to:
  /// **'利息净节省：{saved}'**
  String debtSimInterestSaved(String saved);

  /// No description provided for @debtSimRemaining.
  ///
  /// In zh, this message translates to:
  /// **'剩余期数：{n} 期'**
  String debtSimRemaining(num n);

  /// No description provided for @debtSimMonthsSaved.
  ///
  /// In zh, this message translates to:
  /// **'（少 {n} 期）'**
  String debtSimMonthsSaved(num n);

  /// No description provided for @debtNameField.
  ///
  /// In zh, this message translates to:
  /// **'名称'**
  String get debtNameField;

  /// No description provided for @debtPrincipal.
  ///
  /// In zh, this message translates to:
  /// **'本金'**
  String get debtPrincipal;

  /// No description provided for @debtStartDate.
  ///
  /// In zh, this message translates to:
  /// **'起始日'**
  String get debtStartDate;

  /// No description provided for @wdgCancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get wdgCancel;

  /// No description provided for @wdgConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确认'**
  String get wdgConfirm;

  /// No description provided for @wdgSave.
  ///
  /// In zh, this message translates to:
  /// **'保存'**
  String get wdgSave;

  /// No description provided for @wdgDelete.
  ///
  /// In zh, this message translates to:
  /// **'删除'**
  String get wdgDelete;

  /// No description provided for @wdgLoadFailed.
  ///
  /// In zh, this message translates to:
  /// **'加载失败：{e}'**
  String wdgLoadFailed(String e);

  /// No description provided for @wdgBack.
  ///
  /// In zh, this message translates to:
  /// **'返回'**
  String get wdgBack;

  /// No description provided for @wdgAmount.
  ///
  /// In zh, this message translates to:
  /// **'金额'**
  String get wdgAmount;

  /// No description provided for @wdgDate.
  ///
  /// In zh, this message translates to:
  /// **'日期'**
  String get wdgDate;

  /// No description provided for @wdgCloseEsc.
  ///
  /// In zh, this message translates to:
  /// **'关闭 (Esc)'**
  String get wdgCloseEsc;

  /// No description provided for @wdgDialogBarrier.
  ///
  /// In zh, this message translates to:
  /// **'关闭弹窗'**
  String get wdgDialogBarrier;

  /// No description provided for @wdgSheetBarrier.
  ///
  /// In zh, this message translates to:
  /// **'关闭面板'**
  String get wdgSheetBarrier;

  /// No description provided for @wdgMinimize.
  ///
  /// In zh, this message translates to:
  /// **'最小化'**
  String get wdgMinimize;

  /// No description provided for @wdgRestoreDown.
  ///
  /// In zh, this message translates to:
  /// **'向下还原'**
  String get wdgRestoreDown;

  /// No description provided for @wdgMaximize.
  ///
  /// In zh, this message translates to:
  /// **'最大化'**
  String get wdgMaximize;

  /// No description provided for @wdgClose.
  ///
  /// In zh, this message translates to:
  /// **'关闭'**
  String get wdgClose;

  /// No description provided for @wdgDeltaWithPercent.
  ///
  /// In zh, this message translates to:
  /// **'{amount}（{arrow} {pct}%）'**
  String wdgDeltaWithPercent(String amount, String arrow, String pct);

  /// No description provided for @budgetPageTitle.
  ///
  /// In zh, this message translates to:
  /// **'预算'**
  String get budgetPageTitle;

  /// No description provided for @budgetCreate.
  ///
  /// In zh, this message translates to:
  /// **'新建预算'**
  String get budgetCreate;

  /// No description provided for @budgetEmptyTitle.
  ///
  /// In zh, this message translates to:
  /// **'还没有预算'**
  String get budgetEmptyTitle;

  /// No description provided for @budgetEmptyMessage.
  ///
  /// In zh, this message translates to:
  /// **'从月度总预算开始，或给餐饮、购物等分类单独设额度，首页会按当前消费速度预测月末是否超支。'**
  String get budgetEmptyMessage;

  /// No description provided for @budgetMonthTitle.
  ///
  /// In zh, this message translates to:
  /// **'本月预算'**
  String get budgetMonthTitle;

  /// No description provided for @budgetOverspentHero.
  ///
  /// In zh, this message translates to:
  /// **'已超支'**
  String get budgetOverspentHero;

  /// No description provided for @budgetRemainingHero.
  ///
  /// In zh, this message translates to:
  /// **'剩余可花'**
  String get budgetRemainingHero;

  /// No description provided for @budgetTotalLimit.
  ///
  /// In zh, this message translates to:
  /// **'总额度'**
  String get budgetTotalLimit;

  /// No description provided for @budgetSpent.
  ///
  /// In zh, this message translates to:
  /// **'已花'**
  String get budgetSpent;

  /// No description provided for @budgetOverEnvelopes.
  ///
  /// In zh, this message translates to:
  /// **'超支信封'**
  String get budgetOverEnvelopes;

  /// No description provided for @budgetEnvelopeCount.
  ///
  /// In zh, this message translates to:
  /// **'{n} 只'**
  String budgetEnvelopeCount(num n);

  /// No description provided for @budgetTotalUsagePct.
  ///
  /// In zh, this message translates to:
  /// **'总用量 {v}%'**
  String budgetTotalUsagePct(String v);

  /// No description provided for @budgetMonthTotalLimit.
  ///
  /// In zh, this message translates to:
  /// **'本月总额度'**
  String get budgetMonthTotalLimit;

  /// No description provided for @budgetRemaining.
  ///
  /// In zh, this message translates to:
  /// **'剩余'**
  String get budgetRemaining;

  /// No description provided for @budgetOverAmount.
  ///
  /// In zh, this message translates to:
  /// **'超支 {amount}'**
  String budgetOverAmount(String amount);

  /// No description provided for @budgetRemainingAmount.
  ///
  /// In zh, this message translates to:
  /// **'剩余 {amount}'**
  String budgetRemainingAmount(String amount);

  /// No description provided for @budgetEnvelopeActions.
  ///
  /// In zh, this message translates to:
  /// **'信封操作'**
  String get budgetEnvelopeActions;

  /// No description provided for @budgetDelete.
  ///
  /// In zh, this message translates to:
  /// **'删除预算'**
  String get budgetDelete;

  /// No description provided for @budgetLimit.
  ///
  /// In zh, this message translates to:
  /// **'额度'**
  String get budgetLimit;

  /// No description provided for @budgetPlanned.
  ///
  /// In zh, this message translates to:
  /// **'计划占用'**
  String get budgetPlanned;

  /// No description provided for @budgetPlannedTooltip.
  ///
  /// In zh, this message translates to:
  /// **'未来计划将落在这只信封里的金额'**
  String get budgetPlannedTooltip;

  /// No description provided for @budgetDeleteConfirmTitle.
  ///
  /// In zh, this message translates to:
  /// **'删除预算？'**
  String get budgetDeleteConfirmTitle;

  /// No description provided for @budgetDeleteConfirmMessage.
  ///
  /// In zh, this message translates to:
  /// **'「{name}」的额度记录将被删除，已发生的消费不受影响。'**
  String budgetDeleteConfirmMessage(String name);

  /// No description provided for @budgetForecastExceed.
  ///
  /// In zh, this message translates to:
  /// **'按当前配速月底将花 {projected}（超 {over}）'**
  String budgetForecastExceed(String projected, String over);

  /// No description provided for @budgetForecastOk.
  ///
  /// In zh, this message translates to:
  /// **'按当前配速月底约花 {projected}，剩余日均可花 {daily}'**
  String budgetForecastOk(String projected, String daily);

  /// No description provided for @budgetMonthlyTotalName.
  ///
  /// In zh, this message translates to:
  /// **'月度总预算'**
  String get budgetMonthlyTotalName;

  /// No description provided for @budgetCategoryBudget.
  ///
  /// In zh, this message translates to:
  /// **'分类预算'**
  String get budgetCategoryBudget;

  /// No description provided for @budgetScopeTotal.
  ///
  /// In zh, this message translates to:
  /// **'总预算'**
  String get budgetScopeTotal;

  /// No description provided for @budgetCategoryField.
  ///
  /// In zh, this message translates to:
  /// **'分类'**
  String get budgetCategoryField;

  /// No description provided for @budgetMonthlyLimitField.
  ///
  /// In zh, this message translates to:
  /// **'每月额度（元）'**
  String get budgetMonthlyLimitField;

  /// No description provided for @budgetNameOptionalField.
  ///
  /// In zh, this message translates to:
  /// **'名称（可选）'**
  String get budgetNameOptionalField;

  /// No description provided for @goalsPageTitle.
  ///
  /// In zh, this message translates to:
  /// **'目标与准备金'**
  String get goalsPageTitle;

  /// No description provided for @goalNew.
  ///
  /// In zh, this message translates to:
  /// **'新建目标'**
  String get goalNew;

  /// No description provided for @goalEmptyTitle.
  ///
  /// In zh, this message translates to:
  /// **'还没有目标'**
  String get goalEmptyTitle;

  /// No description provided for @goalEmptyMessage.
  ///
  /// In zh, this message translates to:
  /// **'用目标为大额支出提前留钱：旅行、保费、学费、设备……'**
  String get goalEmptyMessage;

  /// No description provided for @goalSummaryTitle.
  ///
  /// In zh, this message translates to:
  /// **'目标合计'**
  String get goalSummaryTitle;

  /// No description provided for @goalSummaryHint.
  ///
  /// In zh, this message translates to:
  /// **'为大额支出提前留钱的准备金总览'**
  String get goalSummaryHint;

  /// No description provided for @goalReserved.
  ///
  /// In zh, this message translates to:
  /// **'已留'**
  String get goalReserved;

  /// No description provided for @goalTotalTarget.
  ///
  /// In zh, this message translates to:
  /// **'目标总额'**
  String get goalTotalTarget;

  /// No description provided for @goalTotalGap.
  ///
  /// In zh, this message translates to:
  /// **'总缺口'**
  String get goalTotalGap;

  /// No description provided for @goalCount.
  ///
  /// In zh, this message translates to:
  /// **'目标数'**
  String get goalCount;

  /// No description provided for @goalItems.
  ///
  /// In zh, this message translates to:
  /// **'{n} 个'**
  String goalItems(num n);

  /// No description provided for @goalActions.
  ///
  /// In zh, this message translates to:
  /// **'目标操作'**
  String get goalActions;

  /// No description provided for @goalAddReserve.
  ///
  /// In zh, this message translates to:
  /// **'增加预留'**
  String get goalAddReserve;

  /// No description provided for @goalDelete.
  ///
  /// In zh, this message translates to:
  /// **'删除目标'**
  String get goalDelete;

  /// No description provided for @goalTarget.
  ///
  /// In zh, this message translates to:
  /// **'目标'**
  String get goalTarget;

  /// No description provided for @goalGap.
  ///
  /// In zh, this message translates to:
  /// **'缺口'**
  String get goalGap;

  /// No description provided for @goalMonthlyNeed.
  ///
  /// In zh, this message translates to:
  /// **'每月需留'**
  String get goalMonthlyNeed;

  /// No description provided for @goalMonthlyNeedTooltip.
  ///
  /// In zh, this message translates to:
  /// **'目标日已过或已留满，无需再留'**
  String get goalMonthlyNeedTooltip;

  /// No description provided for @goalDaysLeft.
  ///
  /// In zh, this message translates to:
  /// **'还有 {n} 天'**
  String goalDaysLeft(num n);

  /// No description provided for @goalOverdueBy.
  ///
  /// In zh, this message translates to:
  /// **'已过期 {n} 天'**
  String goalOverdueBy(num n);

  /// No description provided for @goalDeleteConfirmTitle.
  ///
  /// In zh, this message translates to:
  /// **'删除目标？'**
  String get goalDeleteConfirmTitle;

  /// No description provided for @goalDeleteConfirmMessage.
  ///
  /// In zh, this message translates to:
  /// **'「{name}」的预留记录将删除，已发生的转账不受影响。'**
  String goalDeleteConfirmMessage(String name);

  /// No description provided for @goalReserveTitle.
  ///
  /// In zh, this message translates to:
  /// **'为「{name}」增加预留'**
  String goalReserveTitle(String name);

  /// No description provided for @goalNameField.
  ///
  /// In zh, this message translates to:
  /// **'名称'**
  String get goalNameField;

  /// No description provided for @goalAmountField.
  ///
  /// In zh, this message translates to:
  /// **'目标金额'**
  String get goalAmountField;

  /// No description provided for @goalDateField.
  ///
  /// In zh, this message translates to:
  /// **'目标日期'**
  String get goalDateField;

  /// No description provided for @lockOpeningLedger.
  ///
  /// In zh, this message translates to:
  /// **'正在打开加密账本…'**
  String get lockOpeningLedger;

  /// No description provided for @lockWelcome.
  ///
  /// In zh, this message translates to:
  /// **'欢迎来到资观'**
  String get lockWelcome;

  /// No description provided for @lockOpenFailed.
  ///
  /// In zh, this message translates to:
  /// **'打开失败：{e}'**
  String lockOpenFailed(String e);

  /// No description provided for @lockCreateFailed.
  ///
  /// In zh, this message translates to:
  /// **'创建失败：{e}'**
  String lockCreateFailed(String e);

  /// No description provided for @lockPassphraseRule.
  ///
  /// In zh, this message translates to:
  /// **'主口令至少 8 位；建议 12 位以上 passphrase'**
  String get lockPassphraseRule;

  /// No description provided for @lockPassMismatch.
  ///
  /// In zh, this message translates to:
  /// **'两次输入不一致'**
  String get lockPassMismatch;

  /// No description provided for @lockWeakPassphrase.
  ///
  /// In zh, this message translates to:
  /// **'口令强度不足：请更长或混合字符类型'**
  String get lockWeakPassphrase;

  /// No description provided for @lockEnterPrompt.
  ///
  /// In zh, this message translates to:
  /// **'请输入主口令或恢复码'**
  String get lockEnterPrompt;

  /// No description provided for @lockWrongCredential.
  ///
  /// In zh, this message translates to:
  /// **'主口令或恢复码不正确'**
  String get lockWrongCredential;

  /// No description provided for @lockUnlockFailed.
  ///
  /// In zh, this message translates to:
  /// **'解锁失败：{e}'**
  String lockUnlockFailed(String e);

  /// No description provided for @lockUnlocking.
  ///
  /// In zh, this message translates to:
  /// **'正在解锁加密账本…'**
  String get lockUnlocking;

  /// No description provided for @lockUnlocked.
  ///
  /// In zh, this message translates to:
  /// **'已解锁'**
  String get lockUnlocked;

  /// No description provided for @lockSaveRecoveryTitle.
  ///
  /// In zh, this message translates to:
  /// **'请离线保存恢复码'**
  String get lockSaveRecoveryTitle;

  /// No description provided for @lockRecoveryIntro.
  ///
  /// In zh, this message translates to:
  /// **'恢复码是丢失主口令后唯一的自救方式。请抄写在安全的地方（不要拍照存云端）。'**
  String get lockRecoveryIntro;

  /// No description provided for @lockRecoverySaved.
  ///
  /// In zh, this message translates to:
  /// **'我已保存，进入账本'**
  String get lockRecoverySaved;

  /// No description provided for @lockCreateHint.
  ///
  /// In zh, this message translates to:
  /// **'创建加密账本：设定主口令（8 位以上）'**
  String get lockCreateHint;

  /// No description provided for @lockPassphraseTooltip.
  ///
  /// In zh, this message translates to:
  /// **'主口令派生密钥加密全部数据，无法找回，只能用恢复码自救'**
  String get lockPassphraseTooltip;

  /// No description provided for @lockRepeatPassphrase.
  ///
  /// In zh, this message translates to:
  /// **'再输入一遍主口令'**
  String get lockRepeatPassphrase;

  /// No description provided for @lockUnlockHint.
  ///
  /// In zh, this message translates to:
  /// **'输入主口令或恢复码'**
  String get lockUnlockHint;

  /// No description provided for @lockRecoveryNotice.
  ///
  /// In zh, this message translates to:
  /// **'也可直接输入恢复码解锁'**
  String get lockRecoveryNotice;

  /// No description provided for @lockForgotPassphrase.
  ///
  /// In zh, this message translates to:
  /// **'忘记主口令？使用恢复码'**
  String get lockForgotPassphrase;

  /// No description provided for @shellCollapseMenu.
  ///
  /// In zh, this message translates to:
  /// **'收起分类菜单'**
  String get shellCollapseMenu;

  /// No description provided for @shellExpandMenu.
  ///
  /// In zh, this message translates to:
  /// **'展开分类菜单'**
  String get shellExpandMenu;

  /// No description provided for @shellMenuLabel.
  ///
  /// In zh, this message translates to:
  /// **'分类菜单'**
  String get shellMenuLabel;

  /// No description provided for @shellNavTitle.
  ///
  /// In zh, this message translates to:
  /// **'分类导航'**
  String get shellNavTitle;

  /// No description provided for @shellPinnedTip.
  ///
  /// In zh, this message translates to:
  /// **'已固定：菜单保持展开'**
  String get shellPinnedTip;

  /// No description provided for @shellUnpinnedTip.
  ///
  /// In zh, this message translates to:
  /// **'未固定：跳转后自动收起'**
  String get shellUnpinnedTip;

  /// No description provided for @globeRestorePage.
  ///
  /// In zh, this message translates to:
  /// **'恢复页面'**
  String get globeRestorePage;

  /// No description provided for @globeClearScreen.
  ///
  /// In zh, this message translates to:
  /// **'清屏地球：只留中央地球'**
  String get globeClearScreen;

  /// No description provided for @ovMonths.
  ///
  /// In zh, this message translates to:
  /// **'近 {n} 个月'**
  String ovMonths(num n);

  /// No description provided for @ovTrGoReport.
  ///
  /// In zh, this message translates to:
  /// **'查看月报归因'**
  String get ovTrGoReport;

  /// No description provided for @ovNwTitle.
  ///
  /// In zh, this message translates to:
  /// **'净资产'**
  String get ovNwTitle;

  /// No description provided for @ovNwHint.
  ///
  /// In zh, this message translates to:
  /// **'全面了解资产总额、结构分布与账户变化。'**
  String get ovNwHint;

  /// No description provided for @ovNwMonthDelta.
  ///
  /// In zh, this message translates to:
  /// **'较上月'**
  String get ovNwMonthDelta;

  /// No description provided for @ovNwCoverage.
  ///
  /// In zh, this message translates to:
  /// **'估值覆盖 {n}/{m}'**
  String ovNwCoverage(num n, num m);

  /// No description provided for @ovNwCoverageHint.
  ///
  /// In zh, this message translates to:
  /// **'纳入净资产的账户中，已有当期估值的数量。缺失估值的账户按 0 计入并单独提示。'**
  String get ovNwCoverageHint;

  /// No description provided for @ovNwGlobe.
  ///
  /// In zh, this message translates to:
  /// **'全球资产分布'**
  String get ovNwGlobe;

  /// No description provided for @ovNwGlobeHint.
  ///
  /// In zh, this message translates to:
  /// **'已设置地理位置的资产在地球上发光；拖动旋转、滚轮缩放，点击光点查看账户。'**
  String get ovNwGlobeHint;

  /// No description provided for @ovNwLocatedNote.
  ///
  /// In zh, this message translates to:
  /// **'已定位 {n} · 未定位 {m}'**
  String ovNwLocatedNote(num n, num m);

  /// No description provided for @ovNwAssetTypes.
  ///
  /// In zh, this message translates to:
  /// **'资产类型分布'**
  String get ovNwAssetTypes;

  /// No description provided for @ovNwAssetTypesHint.
  ///
  /// In zh, this message translates to:
  /// **'按业务分组：现金活期、投资持仓、稳健理财、长期资产。'**
  String get ovNwAssetTypesHint;

  /// No description provided for @ovNwGroupCash.
  ///
  /// In zh, this message translates to:
  /// **'现金活期'**
  String get ovNwGroupCash;

  /// No description provided for @ovNwGroupHold.
  ///
  /// In zh, this message translates to:
  /// **'投资持仓'**
  String get ovNwGroupHold;

  /// No description provided for @ovNwGroupSteady.
  ///
  /// In zh, this message translates to:
  /// **'稳健理财'**
  String get ovNwGroupSteady;

  /// No description provided for @ovNwGroupLong.
  ///
  /// In zh, this message translates to:
  /// **'长期资产'**
  String get ovNwGroupLong;

  /// No description provided for @ovNwNoAssets.
  ///
  /// In zh, this message translates to:
  /// **'暂无资产'**
  String get ovNwNoAssets;

  /// No description provided for @ovNwNoAssetsMsg.
  ///
  /// In zh, this message translates to:
  /// **'在首页右上角添加第一笔资产，点亮你的地球。'**
  String get ovNwNoAssetsMsg;

  /// No description provided for @ovNwGroupTitle.
  ///
  /// In zh, this message translates to:
  /// **'账户分布'**
  String get ovNwGroupTitle;

  /// No description provided for @ovNwGroupHint.
  ///
  /// In zh, this message translates to:
  /// **'按业务分组的资产占比。'**
  String get ovNwGroupHint;

  /// No description provided for @ovNwTopAccounts.
  ///
  /// In zh, this message translates to:
  /// **'主要资产账户'**
  String get ovNwTopAccounts;

  /// No description provided for @ovNwViewAll.
  ///
  /// In zh, this message translates to:
  /// **'全部资产'**
  String get ovNwViewAll;

  /// No description provided for @ovNwMissingHint.
  ///
  /// In zh, this message translates to:
  /// **'该账户缺当期估值，暂按 0 计入。'**
  String get ovNwMissingHint;

  /// No description provided for @ovNwTrendEmpty.
  ///
  /// In zh, this message translates to:
  /// **'走势待积累'**
  String get ovNwTrendEmpty;

  /// No description provided for @ovNwTrendEmptyMsg.
  ///
  /// In zh, this message translates to:
  /// **'账本满一个月后这里会长出第一条曲线。'**
  String get ovNwTrendEmptyMsg;

  /// No description provided for @ovNwAttribution.
  ///
  /// In zh, this message translates to:
  /// **'本月变动归因'**
  String get ovNwAttribution;

  /// No description provided for @ovNwAttributionHint.
  ///
  /// In zh, this message translates to:
  /// **'净资产变动拆解为收支、投资、汇率与其他估值变动；对不上的部分计入「待核对」。'**
  String get ovNwAttributionHint;

  /// No description provided for @ovNwNetChange.
  ///
  /// In zh, this message translates to:
  /// **'净变动'**
  String get ovNwNetChange;

  /// No description provided for @ovNwAttrIncomeExpense.
  ///
  /// In zh, this message translates to:
  /// **'收支结余'**
  String get ovNwAttrIncomeExpense;

  /// No description provided for @ovNwAttrIncomeHint.
  ///
  /// In zh, this message translates to:
  /// **'常规收入减常规消费（不含转账与投资买卖）。'**
  String get ovNwAttrIncomeHint;

  /// No description provided for @ovNwAttrInvest.
  ///
  /// In zh, this message translates to:
  /// **'投资损益'**
  String get ovNwAttrInvest;

  /// No description provided for @ovNwAttrInvestHint.
  ///
  /// In zh, this message translates to:
  /// **'已实现损益 + 分红 + 未实现损益变动。'**
  String get ovNwAttrInvestHint;

  /// No description provided for @ovNwAttrFx.
  ///
  /// In zh, this message translates to:
  /// **'汇率影响'**
  String get ovNwAttrFx;

  /// No description provided for @ovNwAttrFxHint.
  ///
  /// In zh, this message translates to:
  /// **'外币头寸的重估影响与换汇损益。'**
  String get ovNwAttrFxHint;

  /// No description provided for @ovNwAttrOther.
  ///
  /// In zh, this message translates to:
  /// **'其他估值变动'**
  String get ovNwAttrOther;

  /// No description provided for @ovNwAttrOtherHint.
  ///
  /// In zh, this message translates to:
  /// **'房产等手工估值的期初期末变动。'**
  String get ovNwAttrOtherHint;

  /// No description provided for @ovNwAttrCorrection.
  ///
  /// In zh, this message translates to:
  /// **'数据修正'**
  String get ovNwAttrCorrection;

  /// No description provided for @ovNwAttrCorrectionHint.
  ///
  /// In zh, this message translates to:
  /// **'权益类科目的调整（历史修正等）。'**
  String get ovNwAttrCorrectionHint;

  /// No description provided for @ovNwAttrResidual.
  ///
  /// In zh, this message translates to:
  /// **'待核对'**
  String get ovNwAttrResidual;

  /// No description provided for @ovCfTitle.
  ///
  /// In zh, this message translates to:
  /// **'本月收支'**
  String get ovCfTitle;

  /// No description provided for @ovCfHint.
  ///
  /// In zh, this message translates to:
  /// **'了解每一笔现金流，掌握消费结构与月度预算。'**
  String get ovCfHint;

  /// No description provided for @ovCfIncomeHint.
  ///
  /// In zh, this message translates to:
  /// **'按收入科目账户汇总；投资收益在归因页单独披露。'**
  String get ovCfIncomeHint;

  /// No description provided for @ovCfExpenseHint.
  ///
  /// In zh, this message translates to:
  /// **'实际消费与费用；信用卡消费计入当月。'**
  String get ovCfExpenseHint;

  /// No description provided for @ovCfSurplusHint.
  ///
  /// In zh, this message translates to:
  /// **'收入减消费。内部转账不算收支，买入资产不算消费。'**
  String get ovCfSurplusHint;

  /// No description provided for @ovCfDailyTitle.
  ///
  /// In zh, this message translates to:
  /// **'每日收支趋势'**
  String get ovCfDailyTitle;

  /// No description provided for @ovCfDailyHint.
  ///
  /// In zh, this message translates to:
  /// **'双柱为当日收入/消费，亮线为累计净额；悬停查看当天明细。'**
  String get ovCfDailyHint;

  /// No description provided for @ovCfNetLine.
  ///
  /// In zh, this message translates to:
  /// **'累计净额'**
  String get ovCfNetLine;

  /// No description provided for @ovCfExpenseCatTitle.
  ///
  /// In zh, this message translates to:
  /// **'消费分类'**
  String get ovCfExpenseCatTitle;

  /// No description provided for @ovCfExpenseCatHint.
  ///
  /// In zh, this message translates to:
  /// **'按支出科目账户汇总。'**
  String get ovCfExpenseCatHint;

  /// No description provided for @ovCfOthers.
  ///
  /// In zh, this message translates to:
  /// **'其他'**
  String get ovCfOthers;

  /// No description provided for @ovCfNoExpense.
  ///
  /// In zh, this message translates to:
  /// **'本月还没有消费记录'**
  String get ovCfNoExpense;

  /// No description provided for @ovCfMonthExpense.
  ///
  /// In zh, this message translates to:
  /// **'本月消费'**
  String get ovCfMonthExpense;

  /// No description provided for @ovCfIncomeTitle.
  ///
  /// In zh, this message translates to:
  /// **'收入来源'**
  String get ovCfIncomeTitle;

  /// No description provided for @ovCfNoIncome.
  ///
  /// In zh, this message translates to:
  /// **'本月还没有收入记录'**
  String get ovCfNoIncome;

  /// No description provided for @ovCfBudgetTitle.
  ///
  /// In zh, this message translates to:
  /// **'预算执行'**
  String get ovCfBudgetTitle;

  /// No description provided for @ovCfBudgetHint.
  ///
  /// In zh, this message translates to:
  /// **'本月总预算额度 vs 实际消费。'**
  String get ovCfBudgetHint;

  /// No description provided for @ovCfNoBudget.
  ///
  /// In zh, this message translates to:
  /// **'未设置预算'**
  String get ovCfNoBudget;

  /// No description provided for @ovCfNoBudgetMsg.
  ///
  /// In zh, this message translates to:
  /// **'在预算页设置月度总预算后，这里会出现执行进度。'**
  String get ovCfNoBudgetMsg;

  /// No description provided for @ovCfBudgetOf.
  ///
  /// In zh, this message translates to:
  /// **'额度 {x}'**
  String ovCfBudgetOf(String x);

  /// No description provided for @ovCfBudgetUsed.
  ///
  /// In zh, this message translates to:
  /// **'已用'**
  String get ovCfBudgetUsed;

  /// No description provided for @ovCfOverBy.
  ///
  /// In zh, this message translates to:
  /// **'已超支'**
  String get ovCfOverBy;

  /// No description provided for @ovCfBudgetLeft.
  ///
  /// In zh, this message translates to:
  /// **'剩余'**
  String get ovCfBudgetLeft;

  /// No description provided for @ovCfHeatTitle.
  ///
  /// In zh, this message translates to:
  /// **'收支热力'**
  String get ovCfHeatTitle;

  /// No description provided for @ovCfHeatHint.
  ///
  /// In zh, this message translates to:
  /// **'颜色越深金额越大：蓝=净流入日，红=净流出日。'**
  String get ovCfHeatHint;

  /// No description provided for @ovCfRecentTitle.
  ///
  /// In zh, this message translates to:
  /// **'近期交易'**
  String get ovCfRecentTitle;

  /// No description provided for @ovCfRecentHint.
  ///
  /// In zh, this message translates to:
  /// **'本月最近的收支交易，点击查看详情。'**
  String get ovCfRecentHint;

  /// No description provided for @ovCfNoTx.
  ///
  /// In zh, this message translates to:
  /// **'暂无交易'**
  String get ovCfNoTx;

  /// No description provided for @ovCfUntitled.
  ///
  /// In zh, this message translates to:
  /// **'未命名交易'**
  String get ovCfUntitled;

  /// No description provided for @ovHlTitle.
  ///
  /// In zh, this message translates to:
  /// **'财务体检'**
  String get ovHlTitle;

  /// No description provided for @ovHlHint.
  ///
  /// In zh, this message translates to:
  /// **'储蓄、应急、杠杆与固定覆盖四个维度的健康评估。'**
  String get ovHlHint;

  /// No description provided for @ovHlTargetSave.
  ///
  /// In zh, this message translates to:
  /// **'建议 ≥ 30%'**
  String get ovHlTargetSave;

  /// No description provided for @ovHlTargetEmergency.
  ///
  /// In zh, this message translates to:
  /// **'建议 ≥ 6 个月'**
  String get ovHlTargetEmergency;

  /// No description provided for @ovHlTargetLeverage.
  ///
  /// In zh, this message translates to:
  /// **'建议 ≤ 50%'**
  String get ovHlTargetLeverage;

  /// No description provided for @ovHlTargetCushion.
  ///
  /// In zh, this message translates to:
  /// **'建议 ≥ 100%'**
  String get ovHlTargetCushion;

  /// No description provided for @ovHlCushion.
  ///
  /// In zh, this message translates to:
  /// **'固定覆盖'**
  String get ovHlCushion;

  /// No description provided for @ovHlCushionHint.
  ///
  /// In zh, this message translates to:
  /// **'月末固定收入可覆盖固定支出的比例。'**
  String get ovHlCushionHint;

  /// No description provided for @ovHlScoreTitle.
  ///
  /// In zh, this message translates to:
  /// **'健康评分'**
  String get ovHlScoreTitle;

  /// No description provided for @ovHlScoreHint.
  ///
  /// In zh, this message translates to:
  /// **'可得指标归一化到建议带后的平均分；数据不足时如实显示「暂无法评分」。'**
  String get ovHlScoreHint;

  /// No description provided for @ovHlNoScore.
  ///
  /// In zh, this message translates to:
  /// **'暂无法评分'**
  String get ovHlNoScore;

  /// No description provided for @ovHlExcellent.
  ///
  /// In zh, this message translates to:
  /// **'优秀'**
  String get ovHlExcellent;

  /// No description provided for @ovHlGood.
  ///
  /// In zh, this message translates to:
  /// **'良好'**
  String get ovHlGood;

  /// No description provided for @ovHlAttention.
  ///
  /// In zh, this message translates to:
  /// **'关注'**
  String get ovHlAttention;

  /// No description provided for @ovHlRisk.
  ///
  /// In zh, this message translates to:
  /// **'风险'**
  String get ovHlRisk;

  /// No description provided for @ovHlMissing.
  ///
  /// In zh, this message translates to:
  /// **'还差这些数据：{x}'**
  String ovHlMissing(String x);

  /// No description provided for @ovHlScoreNote.
  ///
  /// In zh, this message translates to:
  /// **'基于 {n} 项真实指标'**
  String ovHlScoreNote(num n);

  /// No description provided for @ovHlOrbitTitle.
  ///
  /// In zh, this message translates to:
  /// **'维度巡游'**
  String get ovHlOrbitTitle;

  /// No description provided for @ovHlOrbitHint.
  ///
  /// In zh, this message translates to:
  /// **'四颗维度星沿轨道巡游；颜色即状态：蓝=达标，金=关注，红=风险。'**
  String get ovHlOrbitHint;

  /// No description provided for @ovHlRadarTitle.
  ///
  /// In zh, this message translates to:
  /// **'目标雷达'**
  String get ovHlRadarTitle;

  /// No description provided for @ovHlRadarHint.
  ///
  /// In zh, this message translates to:
  /// **'当前值（蓝）对照建议带（金）。'**
  String get ovHlRadarHint;

  /// No description provided for @ovHlCurrent.
  ///
  /// In zh, this message translates to:
  /// **'当前'**
  String get ovHlCurrent;

  /// No description provided for @ovHlTarget.
  ///
  /// In zh, this message translates to:
  /// **'目标'**
  String get ovHlTarget;

  /// No description provided for @ovHlPace.
  ///
  /// In zh, this message translates to:
  /// **'消费配速'**
  String get ovHlPace;

  /// No description provided for @ovHlPaceDays.
  ///
  /// In zh, this message translates to:
  /// **'已过 {n} 天'**
  String ovHlPaceDays(num n);

  /// No description provided for @ovHlCoverage.
  ///
  /// In zh, this message translates to:
  /// **'估值覆盖'**
  String get ovHlCoverage;

  /// No description provided for @ovHlCoverageSub.
  ///
  /// In zh, this message translates to:
  /// **'已覆盖账户'**
  String get ovHlCoverageSub;

  /// No description provided for @ovHlDiagTitle.
  ///
  /// In zh, this message translates to:
  /// **'诊断'**
  String get ovHlDiagTitle;

  /// No description provided for @ovHlDiagHint.
  ///
  /// In zh, this message translates to:
  /// **'按各维度得分自动分桶：≥75% 优势、40–75% 优化空间、<40% 风险。'**
  String get ovHlDiagHint;

  /// No description provided for @ovHlDiagValuation.
  ///
  /// In zh, this message translates to:
  /// **'估值缺口'**
  String get ovHlDiagValuation;

  /// No description provided for @ovHlDiagGood.
  ///
  /// In zh, this message translates to:
  /// **'优势亮点'**
  String get ovHlDiagGood;

  /// No description provided for @ovHlDiagRisk.
  ///
  /// In zh, this message translates to:
  /// **'潜在风险'**
  String get ovHlDiagRisk;

  /// No description provided for @ovHlDiagImprove.
  ///
  /// In zh, this message translates to:
  /// **'优化空间'**
  String get ovHlDiagImprove;

  /// No description provided for @ovHlDiagEmpty.
  ///
  /// In zh, this message translates to:
  /// **'指标数据不足，先记账一段时间再看诊断。'**
  String get ovHlDiagEmpty;

  /// No description provided for @ovHlDiagNone.
  ///
  /// In zh, this message translates to:
  /// **'—'**
  String get ovHlDiagNone;

  /// No description provided for @ovHlActTitle.
  ///
  /// In zh, this message translates to:
  /// **'行动建议'**
  String get ovHlActTitle;

  /// No description provided for @ovHlActHint.
  ///
  /// In zh, this message translates to:
  /// **'按最弱维度排序，每条直达对应业务页。'**
  String get ovHlActHint;

  /// No description provided for @ovHlActValuation.
  ///
  /// In zh, this message translates to:
  /// **'补齐 {n} 项估值'**
  String ovHlActValuation(num n);

  /// No description provided for @ovHlActValuationSub.
  ///
  /// In zh, this message translates to:
  /// **'缺估值会拉低净资产的准确性'**
  String get ovHlActValuationSub;

  /// No description provided for @ovHlActSave.
  ///
  /// In zh, this message translates to:
  /// **'提高储蓄率'**
  String get ovHlActSave;

  /// No description provided for @ovHlActSaveSub.
  ///
  /// In zh, this message translates to:
  /// **'设置预算，先存后花'**
  String get ovHlActSaveSub;

  /// No description provided for @ovHlActEmergency.
  ///
  /// In zh, this message translates to:
  /// **'充实应急金'**
  String get ovHlActEmergency;

  /// No description provided for @ovHlActEmergencySub.
  ///
  /// In zh, this message translates to:
  /// **'目标：6 个月必要支出'**
  String get ovHlActEmergencySub;

  /// No description provided for @ovHlActLeverage.
  ///
  /// In zh, this message translates to:
  /// **'压降负债率'**
  String get ovHlActLeverage;

  /// No description provided for @ovHlActLeverageSub.
  ///
  /// In zh, this message translates to:
  /// **'优先偿还高息负债'**
  String get ovHlActLeverageSub;

  /// No description provided for @ovHlActCushion.
  ///
  /// In zh, this message translates to:
  /// **'平衡固定收支'**
  String get ovHlActCushion;

  /// No description provided for @ovHlActCushionSub.
  ///
  /// In zh, this message translates to:
  /// **'检视周期计划与还款日程'**
  String get ovHlActCushionSub;

  /// No description provided for @ovHlActEmpty.
  ///
  /// In zh, this message translates to:
  /// **'各维度都在轨道上，保持。'**
  String get ovHlActEmpty;

  /// No description provided for @ovHlActGo.
  ///
  /// In zh, this message translates to:
  /// **'去处理'**
  String get ovHlActGo;

  /// No description provided for @ovBsTitle.
  ///
  /// In zh, this message translates to:
  /// **'资产负债表'**
  String get ovBsTitle;

  /// No description provided for @ovBsHint.
  ///
  /// In zh, this message translates to:
  /// **'资产、负债与净资产结构的专业分析。'**
  String get ovBsHint;

  /// No description provided for @ovBsAssetsHint.
  ///
  /// In zh, this message translates to:
  /// **'全部资产账户的本位币估值合计。'**
  String get ovBsAssetsHint;

  /// No description provided for @ovBsLiabHint.
  ///
  /// In zh, this message translates to:
  /// **'全部负债账户的本位币估值合计。'**
  String get ovBsLiabHint;

  /// No description provided for @ovBsScaleTitle.
  ///
  /// In zh, this message translates to:
  /// **'资产负债天平'**
  String get ovBsScaleTitle;

  /// No description provided for @ovBsScaleHint.
  ///
  /// In zh, this message translates to:
  /// **'横梁倾角示意负债率：50% 时水平。仅作视觉表达，不代表财务计算。'**
  String get ovBsScaleHint;

  /// No description provided for @ovBsTreemapTitle.
  ///
  /// In zh, this message translates to:
  /// **'资产结构树图'**
  String get ovBsTreemapTitle;

  /// No description provided for @ovBsTreemapHint.
  ///
  /// In zh, this message translates to:
  /// **'面积 = 金额占比；点击色块查看类别。'**
  String get ovBsTreemapHint;

  /// No description provided for @ovBsAssetTableTitle.
  ///
  /// In zh, this message translates to:
  /// **'资产分类'**
  String get ovBsAssetTableTitle;

  /// No description provided for @ovBsAssetTableHint.
  ///
  /// In zh, this message translates to:
  /// **'按资产子类型；环比为期初至今。'**
  String get ovBsAssetTableHint;

  /// No description provided for @ovBsColClass.
  ///
  /// In zh, this message translates to:
  /// **'类别'**
  String get ovBsColClass;

  /// No description provided for @ovBsColAmount.
  ///
  /// In zh, this message translates to:
  /// **'金额'**
  String get ovBsColAmount;

  /// No description provided for @ovBsColShare.
  ///
  /// In zh, this message translates to:
  /// **'占比'**
  String get ovBsColShare;

  /// No description provided for @ovBsColDelta.
  ///
  /// In zh, this message translates to:
  /// **'环比'**
  String get ovBsColDelta;

  /// No description provided for @ovBsLiabTableTitle.
  ///
  /// In zh, this message translates to:
  /// **'负债分类'**
  String get ovBsLiabTableTitle;

  /// No description provided for @ovBsLiabTableHint.
  ///
  /// In zh, this message translates to:
  /// **'按负债子类型。'**
  String get ovBsLiabTableHint;

  /// No description provided for @ovBsNoDebt.
  ///
  /// In zh, this message translates to:
  /// **'没有负债'**
  String get ovBsNoDebt;

  /// No description provided for @ovBsNoDebtMsg.
  ///
  /// In zh, this message translates to:
  /// **'当前没有任何负债账户。'**
  String get ovBsNoDebtMsg;

  /// No description provided for @ovBsLiquidityTitle.
  ///
  /// In zh, this message translates to:
  /// **'流动性结构'**
  String get ovBsLiquidityTitle;

  /// No description provided for @ovBsLiquidityHint.
  ///
  /// In zh, this message translates to:
  /// **'按变现天数分桶：≤1 天、≤90 天、>90 天。'**
  String get ovBsLiquidityHint;

  /// No description provided for @ovBsLiquidNow.
  ///
  /// In zh, this message translates to:
  /// **'随时可用'**
  String get ovBsLiquidNow;

  /// No description provided for @ovBsLiquidMid.
  ///
  /// In zh, this message translates to:
  /// **'短期可变现'**
  String get ovBsLiquidMid;

  /// No description provided for @ovBsLiquidLong.
  ///
  /// In zh, this message translates to:
  /// **'长期资产'**
  String get ovBsLiquidLong;

  /// No description provided for @ovBsLiabMixTitle.
  ///
  /// In zh, this message translates to:
  /// **'负债构成'**
  String get ovBsLiabMixTitle;

  /// No description provided for @ovBsLiabMixHint.
  ///
  /// In zh, this message translates to:
  /// **'按负债子类型的占比。'**
  String get ovBsLiabMixHint;

  /// No description provided for @ovBsDualTitle.
  ///
  /// In zh, this message translates to:
  /// **'资产 vs 负债'**
  String get ovBsDualTitle;

  /// No description provided for @ovBsDualHint.
  ///
  /// In zh, this message translates to:
  /// **'近 12 个月双线对比。'**
  String get ovBsDualHint;

  /// No description provided for @ovSpTitle.
  ///
  /// In zh, this message translates to:
  /// **'还能花多少（{n} 天）'**
  String ovSpTitle(num n);

  /// No description provided for @ovSpHint.
  ///
  /// In zh, this message translates to:
  /// **'在保留准备金与已知支出的前提下，未来还能安全花多少钱。'**
  String get ovSpHint;

  /// No description provided for @ovSpHeroTitle.
  ///
  /// In zh, this message translates to:
  /// **'安全可支配 · {n} 天'**
  String ovSpHeroTitle(num n);

  /// No description provided for @ovSpHeroHint.
  ///
  /// In zh, this message translates to:
  /// **'可支配 = 每日现金 − 准备金 − 现金底线的最小值；不是全部净资产。'**
  String get ovSpHeroHint;

  /// No description provided for @ovSpHeroOk.
  ///
  /// In zh, this message translates to:
  /// **'计划外可自由安排的上限'**
  String get ovSpHeroOk;

  /// No description provided for @ovSpHeroZero.
  ///
  /// In zh, this message translates to:
  /// **'现有计划已触及安全边界，暂无计划外空间'**
  String get ovSpHeroZero;

  /// No description provided for @ovSpCashNow.
  ///
  /// In zh, this message translates to:
  /// **'可用流动资金'**
  String get ovSpCashNow;

  /// No description provided for @ovSpPlannedOut.
  ///
  /// In zh, this message translates to:
  /// **'未来必要流出'**
  String get ovSpPlannedOut;

  /// No description provided for @ovSpReserved.
  ///
  /// In zh, this message translates to:
  /// **'已预留（目标+底线）'**
  String get ovSpReserved;

  /// No description provided for @ovSpRemain.
  ///
  /// In zh, this message translates to:
  /// **'计划外可支配'**
  String get ovSpRemain;

  /// No description provided for @ovSpScenTitle.
  ///
  /// In zh, this message translates to:
  /// **'情景模拟'**
  String get ovSpScenTitle;

  /// No description provided for @ovSpScenHint.
  ///
  /// In zh, this message translates to:
  /// **'同一份期初余额与准备金，只换事件流重放。'**
  String get ovSpScenHint;

  /// No description provided for @ovSpScenConservative.
  ///
  /// In zh, this message translates to:
  /// **'保守'**
  String get ovSpScenConservative;

  /// No description provided for @ovSpScenConsSub.
  ///
  /// In zh, this message translates to:
  /// **'只信已确认收入'**
  String get ovSpScenConsSub;

  /// No description provided for @ovSpScenStandard.
  ///
  /// In zh, this message translates to:
  /// **'标准'**
  String get ovSpScenStandard;

  /// No description provided for @ovSpScenStdSub.
  ///
  /// In zh, this message translates to:
  /// **'与首页预测同口径'**
  String get ovSpScenStdSub;

  /// No description provided for @ovSpScenOptimistic.
  ///
  /// In zh, this message translates to:
  /// **'乐观'**
  String get ovSpScenOptimistic;

  /// No description provided for @ovSpScenOptSub.
  ///
  /// In zh, this message translates to:
  /// **'可压缩的估算支出不计'**
  String get ovSpScenOptSub;

  /// No description provided for @ovSpKpiSafe.
  ///
  /// In zh, this message translates to:
  /// **'安全可支配（{n} 天）'**
  String ovSpKpiSafe(num n);

  /// No description provided for @ovSpKpiMonthCap.
  ///
  /// In zh, this message translates to:
  /// **'建议月度消费上限'**
  String get ovSpKpiMonthCap;

  /// No description provided for @ovSpKpiMonthCapHint.
  ///
  /// In zh, this message translates to:
  /// **'安全可支配按 {n} 天折算到月。'**
  String ovSpKpiMonthCapHint(num n);

  /// No description provided for @ovSpKpiDaily.
  ///
  /// In zh, this message translates to:
  /// **'剩余日均可花'**
  String get ovSpKpiDaily;

  /// No description provided for @ovSpKpiDailyHint.
  ///
  /// In zh, this message translates to:
  /// **'安全可支配 ÷ {n} 天。'**
  String ovSpKpiDailyHint(num n);

  /// No description provided for @ovSpKpiLow.
  ///
  /// In zh, this message translates to:
  /// **'现金最低点'**
  String get ovSpKpiLow;

  /// No description provided for @ovSpKpiLowHint.
  ///
  /// In zh, this message translates to:
  /// **'预测期内无流出事件。'**
  String get ovSpKpiLowHint;

  /// No description provided for @ovSpKpiLowAt.
  ///
  /// In zh, this message translates to:
  /// **'出现在 {x}'**
  String ovSpKpiLowAt(String x);

  /// No description provided for @ovSpFcTitle.
  ///
  /// In zh, this message translates to:
  /// **'{n} 天现金预测'**
  String ovSpFcTitle(num n);

  /// No description provided for @ovSpFcHint.
  ///
  /// In zh, this message translates to:
  /// **'实线为逐日现金；虚线为安全底线（准备金+现金底线）；红点为缺口日。'**
  String get ovSpFcHint;

  /// No description provided for @ovSpFloorLabel.
  ///
  /// In zh, this message translates to:
  /// **'安全底线'**
  String get ovSpFloorLabel;

  /// No description provided for @ovSpFlowTitle.
  ///
  /// In zh, this message translates to:
  /// **'预计流入与流出'**
  String get ovSpFlowTitle;

  /// No description provided for @ovSpFlowHint.
  ///
  /// In zh, this message translates to:
  /// **'期内全部现金事件（本位币）。'**
  String get ovSpFlowHint;

  /// No description provided for @ovSpFlowIn.
  ///
  /// In zh, this message translates to:
  /// **'预计流入'**
  String get ovSpFlowIn;

  /// No description provided for @ovSpFlowOut.
  ///
  /// In zh, this message translates to:
  /// **'预计流出'**
  String get ovSpFlowOut;

  /// No description provided for @ovSpFlowNet.
  ///
  /// In zh, this message translates to:
  /// **'净现金流'**
  String get ovSpFlowNet;

  /// No description provided for @ovSpFlowPlanned.
  ///
  /// In zh, this message translates to:
  /// **'计划支出'**
  String get ovSpFlowPlanned;

  /// No description provided for @ovSpFlowDebt.
  ///
  /// In zh, this message translates to:
  /// **'负债还款'**
  String get ovSpFlowDebt;

  /// No description provided for @ovSpFlowBudget.
  ///
  /// In zh, this message translates to:
  /// **'预算基线'**
  String get ovSpFlowBudget;

  /// No description provided for @ovSpFlowIncome.
  ///
  /// In zh, this message translates to:
  /// **'预期收入'**
  String get ovSpFlowIncome;

  /// No description provided for @ovSpFlowOther.
  ///
  /// In zh, this message translates to:
  /// **'其他'**
  String get ovSpFlowOther;

  /// No description provided for @ovSpMonthTitle.
  ///
  /// In zh, this message translates to:
  /// **'月度消费分配'**
  String get ovSpMonthTitle;

  /// No description provided for @ovSpMonthHint.
  ///
  /// In zh, this message translates to:
  /// **'蓝柱=当月计划流出；金柱=建议上限（计划+可支配摊月）。'**
  String get ovSpMonthHint;

  /// No description provided for @ovSpMonthPlanned.
  ///
  /// In zh, this message translates to:
  /// **'计划'**
  String get ovSpMonthPlanned;

  /// No description provided for @ovSpMonthCap.
  ///
  /// In zh, this message translates to:
  /// **'建议上限'**
  String get ovSpMonthCap;

  /// No description provided for @ovSpCalTitle.
  ///
  /// In zh, this message translates to:
  /// **'消费日历'**
  String get ovSpCalTitle;

  /// No description provided for @ovSpCalHint.
  ///
  /// In zh, this message translates to:
  /// **'流出强度着色；红点标记预测缺口日。'**
  String get ovSpCalHint;

  /// No description provided for @ovSpCalDay.
  ///
  /// In zh, this message translates to:
  /// **'流出 {x}'**
  String ovSpCalDay(String x);

  /// No description provided for @ovSpCalShortfall.
  ///
  /// In zh, this message translates to:
  /// **'缺口'**
  String get ovSpCalShortfall;

  /// No description provided for @ovSpRiskTitle.
  ///
  /// In zh, this message translates to:
  /// **'风险与建议'**
  String get ovSpRiskTitle;

  /// No description provided for @ovSpRiskHint.
  ///
  /// In zh, this message translates to:
  /// **'缺口来自预测重放；建议基于规则生成。'**
  String get ovSpRiskHint;

  /// No description provided for @ovSpRiskNone.
  ///
  /// In zh, this message translates to:
  /// **'未来 {n} 天没有预测到资金缺口。'**
  String ovSpRiskNone(num n);

  /// No description provided for @ovSpAdviceTitle.
  ///
  /// In zh, this message translates to:
  /// **'建议'**
  String get ovSpAdviceTitle;

  /// No description provided for @ovSpAdviceScenario.
  ///
  /// In zh, this message translates to:
  /// **'以保守情景规划：只按已确认收入，可支配为 {x}。'**
  String ovSpAdviceScenario(String x);

  /// No description provided for @ovSpAdviceZero.
  ///
  /// In zh, this message translates to:
  /// **'可支配为 0：先调整计划支出或补充流动资金。'**
  String get ovSpAdviceZero;

  /// No description provided for @ovSpAdviceReconcile.
  ///
  /// In zh, this message translates to:
  /// **'保持账本与估值新鲜，预测才可信。'**
  String get ovSpAdviceReconcile;

  /// No description provided for @ovTrTitle.
  ///
  /// In zh, this message translates to:
  /// **'净资产走势'**
  String get ovTrTitle;

  /// No description provided for @ovTrHint.
  ///
  /// In zh, this message translates to:
  /// **'以时间序列为中心的历史分析。'**
  String get ovTrHint;

  /// No description provided for @ovTrCurrent.
  ///
  /// In zh, this message translates to:
  /// **'当前净资产'**
  String get ovTrCurrent;

  /// No description provided for @ovTrChange.
  ///
  /// In zh, this message translates to:
  /// **'期间变化'**
  String get ovTrChange;

  /// No description provided for @ovTrChangeHint.
  ///
  /// In zh, this message translates to:
  /// **'{a} → {b} 的变化。'**
  String ovTrChangeHint(String a, String b);

  /// No description provided for @ovTrGrowth.
  ///
  /// In zh, this message translates to:
  /// **'期间增长率'**
  String get ovTrGrowth;

  /// No description provided for @ovTrGrowthHint.
  ///
  /// In zh, this message translates to:
  /// **'期间变化 ÷ 期初绝对值。'**
  String get ovTrGrowthHint;

  /// No description provided for @ovTrMax.
  ///
  /// In zh, this message translates to:
  /// **'期间最高'**
  String get ovTrMax;

  /// No description provided for @ovTrMin.
  ///
  /// In zh, this message translates to:
  /// **'期间最低'**
  String get ovTrMin;

  /// No description provided for @ovTrChartTitle.
  ///
  /// In zh, this message translates to:
  /// **'趋势大图'**
  String get ovTrChartTitle;

  /// No description provided for @ovTrAll.
  ///
  /// In zh, this message translates to:
  /// **'全部'**
  String get ovTrAll;

  /// No description provided for @ovTrInsightTitle.
  ///
  /// In zh, this message translates to:
  /// **'关键洞察'**
  String get ovTrInsightTitle;

  /// No description provided for @ovTrInsightHint.
  ///
  /// In zh, this message translates to:
  /// **'由真实序列推导；不预设增长。'**
  String get ovTrInsightHint;

  /// No description provided for @ovTrStreak.
  ///
  /// In zh, this message translates to:
  /// **'连涨 {n} 个月'**
  String ovTrStreak(num n);

  /// No description provided for @ovTrStreakSub.
  ///
  /// In zh, this message translates to:
  /// **'环比逐月抬升'**
  String get ovTrStreakSub;

  /// No description provided for @ovTrBigMove.
  ///
  /// In zh, this message translates to:
  /// **'最大单月变动：{m}（{x}）'**
  String ovTrBigMove(String m, String x);

  /// No description provided for @ovTrMilestone.
  ///
  /// In zh, this message translates to:
  /// **'预计 {n} 个月后（{m}）触及下一整数关口'**
  String ovTrMilestone(num n, String m);

  /// No description provided for @ovTrMilestoneSub.
  ///
  /// In zh, this message translates to:
  /// **'Theil–Sen 稳健趋势：每月 {x}'**
  String ovTrMilestoneSub(String x);

  /// No description provided for @ovTrAttributionGo.
  ///
  /// In zh, this message translates to:
  /// **'当月拆解见归因瀑布与月报。'**
  String get ovTrAttributionGo;

  /// No description provided for @ovTrWfStart.
  ///
  /// In zh, this message translates to:
  /// **'期初'**
  String get ovTrWfStart;

  /// No description provided for @ovTrWfEnd.
  ///
  /// In zh, this message translates to:
  /// **'期末'**
  String get ovTrWfEnd;

  /// No description provided for @ovTrWfTitle.
  ///
  /// In zh, this message translates to:
  /// **'本月归因瀑布'**
  String get ovTrWfTitle;

  /// No description provided for @ovUpTitle.
  ///
  /// In zh, this message translates to:
  /// **'未来 30 天要花的钱'**
  String get ovUpTitle;

  /// No description provided for @ovUpHint.
  ///
  /// In zh, this message translates to:
  /// **'未来账单与支出计划中心。'**
  String get ovUpHint;

  /// No description provided for @ovUpPlanned30.
  ///
  /// In zh, this message translates to:
  /// **'30 天计划支出'**
  String get ovUpPlanned30;

  /// No description provided for @ovUpPlannedHint.
  ///
  /// In zh, this message translates to:
  /// **'已计划且未落地的流出合计。'**
  String get ovUpPlannedHint;

  /// No description provided for @ovUpDue7.
  ///
  /// In zh, this message translates to:
  /// **'7 天内到期'**
  String get ovUpDue7;

  /// No description provided for @ovUpDue7Hint.
  ///
  /// In zh, this message translates to:
  /// **'今天起 7 天内到期的计划流出。'**
  String get ovUpDue7Hint;

  /// No description provided for @ovUpOverdue.
  ///
  /// In zh, this message translates to:
  /// **'已逾期'**
  String get ovUpOverdue;

  /// No description provided for @ovUpOverdueHint.
  ///
  /// In zh, this message translates to:
  /// **'到期未落地的计划发生。'**
  String get ovUpOverdueHint;

  /// No description provided for @ovUpNone.
  ///
  /// In zh, this message translates to:
  /// **'无'**
  String get ovUpNone;

  /// No description provided for @ovUpRecurring.
  ///
  /// In zh, this message translates to:
  /// **'周期计划'**
  String get ovUpRecurring;

  /// No description provided for @ovUpRecurringHint.
  ///
  /// In zh, this message translates to:
  /// **'处于激活状态的周期性事件数。'**
  String get ovUpRecurringHint;

  /// No description provided for @ovUpCalTitle.
  ///
  /// In zh, this message translates to:
  /// **'支出日历'**
  String get ovUpCalTitle;

  /// No description provided for @ovUpCalHint.
  ///
  /// In zh, this message translates to:
  /// **'今天钢蓝描边；3 日内琥珀；逾期红框；已付绿点。点日期看当日明细。'**
  String get ovUpCalHint;

  /// No description provided for @ovUpModeCal.
  ///
  /// In zh, this message translates to:
  /// **'日历'**
  String get ovUpModeCal;

  /// No description provided for @ovUpModeTimeline.
  ///
  /// In zh, this message translates to:
  /// **'时间线'**
  String get ovUpModeTimeline;

  /// No description provided for @ovUpItemCount.
  ///
  /// In zh, this message translates to:
  /// **'{n} 项'**
  String ovUpItemCount(num n);

  /// No description provided for @ovUpDueTitle.
  ///
  /// In zh, this message translates to:
  /// **'即将到期'**
  String get ovUpDueTitle;

  /// No description provided for @ovUpDueHint.
  ///
  /// In zh, this message translates to:
  /// **'按日期紧迫排序；状态：待落地/已逾期/已付。'**
  String get ovUpDueHint;

  /// No description provided for @ovUpAllSettled.
  ///
  /// In zh, this message translates to:
  /// **'未来 30 天没有待处理的支出'**
  String get ovUpAllSettled;

  /// No description provided for @ovUpGoPost.
  ///
  /// In zh, this message translates to:
  /// **'去计划页落地账单'**
  String get ovUpGoPost;

  /// No description provided for @ovUpFixedTitle.
  ///
  /// In zh, this message translates to:
  /// **'定期固定收支'**
  String get ovUpFixedTitle;

  /// No description provided for @ovUpFixedHint.
  ///
  /// In zh, this message translates to:
  /// **'周期事件及其下次执行日。'**
  String get ovUpFixedHint;

  /// No description provided for @ovUpNoFixed.
  ///
  /// In zh, this message translates to:
  /// **'暂无周期计划'**
  String get ovUpNoFixed;

  /// No description provided for @ovUpNextAt.
  ///
  /// In zh, this message translates to:
  /// **'下次 {x}'**
  String ovUpNextAt(String x);

  /// No description provided for @ovUpWeekTitle.
  ///
  /// In zh, this message translates to:
  /// **'周流出分布'**
  String get ovUpWeekTitle;

  /// No description provided for @ovUpWeekHint.
  ///
  /// In zh, this message translates to:
  /// **'未来五周每周计划流出（首周琥珀）。'**
  String get ovUpWeekHint;

  /// No description provided for @ovUpWeekLabel.
  ///
  /// In zh, this message translates to:
  /// **'第 {n} 周'**
  String ovUpWeekLabel(num n);

  /// No description provided for @ovIxTitle.
  ///
  /// In zh, this message translates to:
  /// **'待处理'**
  String get ovIxTitle;

  /// No description provided for @ovIxHint.
  ///
  /// In zh, this message translates to:
  /// **'估值缺失、到期计划、对账差额与资金预警的统一处理中心。'**
  String get ovIxHint;

  /// No description provided for @ovIxStatHigh.
  ///
  /// In zh, this message translates to:
  /// **'高优先级'**
  String get ovIxStatHigh;

  /// No description provided for @ovIxStatMissing.
  ///
  /// In zh, this message translates to:
  /// **'估值缺失'**
  String get ovIxStatMissing;

  /// No description provided for @ovIxStatStale.
  ///
  /// In zh, this message translates to:
  /// **'估值过期'**
  String get ovIxStatStale;

  /// No description provided for @ovIxStatReconcile.
  ///
  /// In zh, this message translates to:
  /// **'对账与预警'**
  String get ovIxStatReconcile;

  /// No description provided for @ovIxTableTitle.
  ///
  /// In zh, this message translates to:
  /// **'任务清单'**
  String get ovIxTableTitle;

  /// No description provided for @ovIxTableHint.
  ///
  /// In zh, this message translates to:
  /// **'全部来自真实业务记录；处理完成即自动消失。'**
  String get ovIxTableHint;

  /// No description provided for @ovIxFilterAll.
  ///
  /// In zh, this message translates to:
  /// **'全部'**
  String get ovIxFilterAll;

  /// No description provided for @ovIxFilterUrgent.
  ///
  /// In zh, this message translates to:
  /// **'紧急'**
  String get ovIxFilterUrgent;

  /// No description provided for @ovIxFilterToday.
  ///
  /// In zh, this message translates to:
  /// **'今天'**
  String get ovIxFilterToday;

  /// No description provided for @ovIxFilterWeek.
  ///
  /// In zh, this message translates to:
  /// **'本周'**
  String get ovIxFilterWeek;

  /// No description provided for @ovIxColTask.
  ///
  /// In zh, this message translates to:
  /// **'事项'**
  String get ovIxColTask;

  /// No description provided for @ovIxColType.
  ///
  /// In zh, this message translates to:
  /// **'类型'**
  String get ovIxColType;

  /// No description provided for @ovIxColPriority.
  ///
  /// In zh, this message translates to:
  /// **'优先级'**
  String get ovIxColPriority;

  /// No description provided for @ovIxColDue.
  ///
  /// In zh, this message translates to:
  /// **'截止'**
  String get ovIxColDue;

  /// No description provided for @ovIxNoMatch.
  ///
  /// In zh, this message translates to:
  /// **'该筛选下没有任务'**
  String get ovIxNoMatch;

  /// No description provided for @ovIxTypeDue.
  ///
  /// In zh, this message translates to:
  /// **'计划到期'**
  String get ovIxTypeDue;

  /// No description provided for @ovIxTypeMissing.
  ///
  /// In zh, this message translates to:
  /// **'缺估值'**
  String get ovIxTypeMissing;

  /// No description provided for @ovIxTypeStale.
  ///
  /// In zh, this message translates to:
  /// **'估值过期'**
  String get ovIxTypeStale;

  /// No description provided for @ovIxTypeResidual.
  ///
  /// In zh, this message translates to:
  /// **'待核对'**
  String get ovIxTypeResidual;

  /// No description provided for @ovIxTypeShortfall.
  ///
  /// In zh, this message translates to:
  /// **'资金预警'**
  String get ovIxTypeShortfall;

  /// No description provided for @ovIxPriorityHigh.
  ///
  /// In zh, this message translates to:
  /// **'高'**
  String get ovIxPriorityHigh;

  /// No description provided for @ovIxPriorityMedium.
  ///
  /// In zh, this message translates to:
  /// **'中'**
  String get ovIxPriorityMedium;

  /// No description provided for @ovIxPriorityLow.
  ///
  /// In zh, this message translates to:
  /// **'低'**
  String get ovIxPriorityLow;

  /// No description provided for @ovIxResidualTask.
  ///
  /// In zh, this message translates to:
  /// **'本月归因差额 {x} 待核对'**
  String ovIxResidualTask(String x);

  /// No description provided for @ovIxAction.
  ///
  /// In zh, this message translates to:
  /// **'前往对应业务页处理'**
  String get ovIxAction;

  /// No description provided for @ovIxGo.
  ///
  /// In zh, this message translates to:
  /// **'去处理'**
  String get ovIxGo;

  /// No description provided for @ovIxQuickTitle.
  ///
  /// In zh, this message translates to:
  /// **'快捷操作'**
  String get ovIxQuickTitle;

  /// No description provided for @ovIxQuickHint.
  ///
  /// In zh, this message translates to:
  /// **'高频处理入口。'**
  String get ovIxQuickHint;

  /// No description provided for @ovIxAValuation.
  ///
  /// In zh, this message translates to:
  /// **'补估值'**
  String get ovIxAValuation;

  /// No description provided for @ovIxAValuationSub.
  ///
  /// In zh, this message translates to:
  /// **'为缺估值的资产补当期值'**
  String get ovIxAValuationSub;

  /// No description provided for @ovIxAPost.
  ///
  /// In zh, this message translates to:
  /// **'落地计划'**
  String get ovIxAPost;

  /// No description provided for @ovIxAPostSub.
  ///
  /// In zh, this message translates to:
  /// **'把到期的计划变成真实交易'**
  String get ovIxAPostSub;

  /// No description provided for @ovIxALedger.
  ///
  /// In zh, this message translates to:
  /// **'对账'**
  String get ovIxALedger;

  /// No description provided for @ovIxALedgerSub.
  ///
  /// In zh, this message translates to:
  /// **'核对流水与归因差额'**
  String get ovIxALedgerSub;

  /// No description provided for @ovIxASpendable.
  ///
  /// In zh, this message translates to:
  /// **'看资金预测'**
  String get ovIxASpendable;

  /// No description provided for @ovIxASpendableSub.
  ///
  /// In zh, this message translates to:
  /// **'未来还能安全花多少'**
  String get ovIxASpendableSub;

  /// No description provided for @ovIxTimelineTitle.
  ///
  /// In zh, this message translates to:
  /// **'提醒时间线'**
  String get ovIxTimelineTitle;

  /// No description provided for @ovIxTimelineHint.
  ///
  /// In zh, this message translates to:
  /// **'按日期与优先级排列。'**
  String get ovIxTimelineHint;

  /// No description provided for @ovIxNoDue.
  ///
  /// In zh, this message translates to:
  /// **'无截止'**
  String get ovIxNoDue;

  /// No description provided for @ovIxEmptyTitle.
  ///
  /// In zh, this message translates to:
  /// **'目前没有待处理事项。'**
  String get ovIxEmptyTitle;

  /// No description provided for @ovIxEmptyMsg.
  ///
  /// In zh, this message translates to:
  /// **'估值齐全、计划落地、账目对得上——保持。'**
  String get ovIxEmptyMsg;

  /// No description provided for @settingsRelNow.
  ///
  /// In zh, this message translates to:
  /// **'刚刚'**
  String get settingsRelNow;

  /// No description provided for @settingsRelMin.
  ///
  /// In zh, this message translates to:
  /// **'{n} 分钟前'**
  String settingsRelMin(num n);

  /// No description provided for @settingsRelHour.
  ///
  /// In zh, this message translates to:
  /// **'{n} 小时前'**
  String settingsRelHour(num n);

  /// No description provided for @settingsRelDay.
  ///
  /// In zh, this message translates to:
  /// **'{n} 天前'**
  String settingsRelDay(num n);

  /// No description provided for @settingsSecHeroHint.
  ///
  /// In zh, this message translates to:
  /// **'保护您的资产与隐私，确保所有数据只属于您自己。'**
  String get settingsSecHeroHint;

  /// No description provided for @settingsStatLocalEncrypt.
  ///
  /// In zh, this message translates to:
  /// **'本地加密'**
  String get settingsStatLocalEncrypt;

  /// No description provided for @settingsStatEnabled.
  ///
  /// In zh, this message translates to:
  /// **'已启用'**
  String get settingsStatEnabled;

  /// No description provided for @settingsStatLocalEncryptTip.
  ///
  /// In zh, this message translates to:
  /// **'数据库在本机加密存储，密钥不出设备。'**
  String get settingsStatLocalEncryptTip;

  /// No description provided for @settingsStatPassphrase.
  ///
  /// In zh, this message translates to:
  /// **'主口令'**
  String get settingsStatPassphrase;

  /// No description provided for @settingsStatSet.
  ///
  /// In zh, this message translates to:
  /// **'已设置'**
  String get settingsStatSet;

  /// No description provided for @settingsStatPassphraseTip.
  ///
  /// In zh, this message translates to:
  /// **'解锁与备份加密使用的主口令。'**
  String get settingsStatPassphraseTip;

  /// No description provided for @settingsStatRecovery.
  ///
  /// In zh, this message translates to:
  /// **'恢复码'**
  String get settingsStatRecovery;

  /// No description provided for @settingsStatConfigured.
  ///
  /// In zh, this message translates to:
  /// **'已配置'**
  String get settingsStatConfigured;

  /// No description provided for @settingsStatNotConfigured.
  ///
  /// In zh, this message translates to:
  /// **'未配置'**
  String get settingsStatNotConfigured;

  /// No description provided for @settingsStatRecoveryTip.
  ///
  /// In zh, this message translates to:
  /// **'忘记口令时的找回途径。'**
  String get settingsStatRecoveryTip;

  /// No description provided for @settingsSessionTitle.
  ///
  /// In zh, this message translates to:
  /// **'会话与保护'**
  String get settingsSessionTitle;

  /// No description provided for @settingsSessionHint.
  ///
  /// In zh, this message translates to:
  /// **'管理应用的自动锁定与身份验证行为。'**
  String get settingsSessionHint;

  /// No description provided for @settingsAutoLockRowHint.
  ///
  /// In zh, this message translates to:
  /// **'空闲一段时间后自动锁定。'**
  String get settingsAutoLockRowHint;

  /// No description provided for @settingsStartupVerify.
  ///
  /// In zh, this message translates to:
  /// **'启动验证'**
  String get settingsStartupVerify;

  /// No description provided for @settingsStartupVerifyHint.
  ///
  /// In zh, this message translates to:
  /// **'启动应用时要求验证。'**
  String get settingsStartupVerifyHint;

  /// No description provided for @settingsStartupVerifyValue.
  ///
  /// In zh, this message translates to:
  /// **'已开启'**
  String get settingsStartupVerifyValue;

  /// No description provided for @settingsRecentTitle.
  ///
  /// In zh, this message translates to:
  /// **'最近安全操作'**
  String get settingsRecentTitle;

  /// No description provided for @settingsRecentHint.
  ///
  /// In zh, this message translates to:
  /// **'解锁、锁定、口令与恢复码变更记录，与账本同库加密保存。'**
  String get settingsRecentHint;

  /// No description provided for @settingsEvEmpty.
  ///
  /// In zh, this message translates to:
  /// **'暂无安全事件记录'**
  String get settingsEvEmpty;

  /// No description provided for @settingsEvLock.
  ///
  /// In zh, this message translates to:
  /// **'应用锁定'**
  String get settingsEvLock;

  /// No description provided for @settingsEvUnlock.
  ///
  /// In zh, this message translates to:
  /// **'应用解锁'**
  String get settingsEvUnlock;

  /// No description provided for @settingsEvPass.
  ///
  /// In zh, this message translates to:
  /// **'主口令修改'**
  String get settingsEvPass;

  /// No description provided for @settingsEvRecovery.
  ///
  /// In zh, this message translates to:
  /// **'恢复码重新生成'**
  String get settingsEvRecovery;

  /// No description provided for @settingsEvConfig.
  ///
  /// In zh, this message translates to:
  /// **'安全配置变更'**
  String get settingsEvConfig;

  /// No description provided for @settingsAiStatusTitle.
  ///
  /// In zh, this message translates to:
  /// **'AI 服务状态'**
  String get settingsAiStatusTitle;

  /// No description provided for @settingsAiStatusHint.
  ///
  /// In zh, this message translates to:
  /// **'模型与联网搜索配置。'**
  String get settingsAiStatusHint;

  /// No description provided for @settingsAiOn.
  ///
  /// In zh, this message translates to:
  /// **'已开启'**
  String get settingsAiOn;

  /// No description provided for @settingsAiOff.
  ///
  /// In zh, this message translates to:
  /// **'已关闭'**
  String get settingsAiOff;

  /// No description provided for @settingsAiUnconfigured.
  ///
  /// In zh, this message translates to:
  /// **'未配置'**
  String get settingsAiUnconfigured;

  /// No description provided for @settingsAiProvider.
  ///
  /// In zh, this message translates to:
  /// **'服务商'**
  String get settingsAiProvider;

  /// No description provided for @settingsAiModel.
  ///
  /// In zh, this message translates to:
  /// **'模型'**
  String get settingsAiModel;

  /// No description provided for @settingsAiCustom.
  ///
  /// In zh, this message translates to:
  /// **'自定义'**
  String get settingsAiCustom;

  /// No description provided for @settingsAiWebSearch.
  ///
  /// In zh, this message translates to:
  /// **'联网搜索'**
  String get settingsAiWebSearch;

  /// No description provided for @settingsBkOverviewTitle.
  ///
  /// In zh, this message translates to:
  /// **'备份概览'**
  String get settingsBkOverviewTitle;

  /// No description provided for @settingsBkOverviewHint.
  ///
  /// In zh, this message translates to:
  /// **'最近备份与备份容器。'**
  String get settingsBkOverviewHint;

  /// No description provided for @settingsBkLastBackup.
  ///
  /// In zh, this message translates to:
  /// **'最近备份'**
  String get settingsBkLastBackup;

  /// No description provided for @settingsBkLastBackupTip.
  ///
  /// In zh, this message translates to:
  /// **'上次成功备份的时间。'**
  String get settingsBkLastBackupTip;

  /// No description provided for @settingsBkNever.
  ///
  /// In zh, this message translates to:
  /// **'从未'**
  String get settingsBkNever;

  /// No description provided for @settingsBkContainer.
  ///
  /// In zh, this message translates to:
  /// **'备份容器'**
  String get settingsBkContainer;

  /// No description provided for @settingsBkContainerTip.
  ///
  /// In zh, this message translates to:
  /// **'.asbk 加密容器：由独立备份口令加密，与主口令互不相关。'**
  String get settingsBkContainerTip;

  /// No description provided for @settingsDataOverviewTitle.
  ///
  /// In zh, this message translates to:
  /// **'数据概览'**
  String get settingsDataOverviewTitle;

  /// No description provided for @settingsDataOverviewHint.
  ///
  /// In zh, this message translates to:
  /// **'账本规模一览。'**
  String get settingsDataOverviewHint;

  /// No description provided for @settingsDataAccounts.
  ///
  /// In zh, this message translates to:
  /// **'账户'**
  String get settingsDataAccounts;

  /// No description provided for @settingsDataTxns.
  ///
  /// In zh, this message translates to:
  /// **'交易'**
  String get settingsDataTxns;

  /// No description provided for @settingsDataCurrencies.
  ///
  /// In zh, this message translates to:
  /// **'币种'**
  String get settingsDataCurrencies;

  /// No description provided for @settingsPrefAppearanceTitle.
  ///
  /// In zh, this message translates to:
  /// **'外观'**
  String get settingsPrefAppearanceTitle;

  /// No description provided for @settingsPrefAppearanceHint.
  ///
  /// In zh, this message translates to:
  /// **'主题模式立即生效并持久化。'**
  String get settingsPrefAppearanceHint;

  /// No description provided for @settingsPrefMoneyTitle.
  ///
  /// In zh, this message translates to:
  /// **'货币'**
  String get settingsPrefMoneyTitle;

  /// No description provided for @settingsPrefMoneyHint.
  ///
  /// In zh, this message translates to:
  /// **'本位币与汇率。'**
  String get settingsPrefMoneyHint;

  /// No description provided for @settingsPrefForecastTitle.
  ///
  /// In zh, this message translates to:
  /// **'预测'**
  String get settingsPrefForecastTitle;

  /// No description provided for @settingsPrefForecastHint.
  ///
  /// In zh, this message translates to:
  /// **'现金预测口径。'**
  String get settingsPrefForecastHint;

  /// No description provided for @settingsAboutVersion.
  ///
  /// In zh, this message translates to:
  /// **'应用版本'**
  String get settingsAboutVersion;

  /// No description provided for @settingsAboutVersionHint.
  ///
  /// In zh, this message translates to:
  /// **'当前应用版本。'**
  String get settingsAboutVersionHint;

  /// No description provided for @settingsPageHint.
  ///
  /// In zh, this message translates to:
  /// **'管理账户安全、数据、系统偏好与智能服务。'**
  String get settingsPageHint;

  /// No description provided for @settingsHeaderShield.
  ///
  /// In zh, this message translates to:
  /// **'加密保护中'**
  String get settingsHeaderShield;

  /// No description provided for @settingsHeaderShieldTip.
  ///
  /// In zh, this message translates to:
  /// **'账本整库加密，密钥由主口令在本地派生，绝不离开这台设备。'**
  String get settingsHeaderShieldTip;

  /// No description provided for @settingsThemeModeLabel.
  ///
  /// In zh, this message translates to:
  /// **'主题模式'**
  String get settingsThemeModeLabel;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
