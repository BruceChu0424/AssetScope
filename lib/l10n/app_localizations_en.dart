// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'AssetScope';

  @override
  String get aiCfgTestMissingInput => 'Enter the Base URL and API key first';

  @override
  String aiCfgTestConnected(String reply) {
    return 'Connected: $reply';
  }

  @override
  String get aiCfgGlmCodingPlanKeyHint =>
      'If this is a Coding Plan key, switch to the \"Zhipu GLM Coding Plan\" preset';

  @override
  String get aiCfgGlmRegularKeyHint =>
      'The Coding Plan endpoint only accepts Coding Plan keys; for a regular API key switch to the \"Zhipu GLM\" preset';

  @override
  String get aiCfgKeyPrivacyTip =>
      'The API key is stored encrypted in the local ledger and used only for quote/FX fetching and the AI assistant; fetching sends only the queried names and currency pairs, never balances or amounts.';

  @override
  String get aiCfgOpenAiCompatibleNote => 'OpenAI-compatible endpoint';

  @override
  String get aiCfgWebSearchOnTip =>
      'Web search on: quote fetching carries web tools, prices come from live pages';

  @override
  String get aiCfgWebSearchOffTip =>
      'Web search off: quotes may come from model memory';

  @override
  String get aiCfgNoWebSearchSupportTip =>
      'This provider\'s chat API does not support web tools; quotes may come from model memory';

  @override
  String get aiCfgDialogTitle => 'AI service setup';

  @override
  String get aiCfgProvider => 'Provider';

  @override
  String get aiCfgBaseUrlLabel =>
      'Base URL (https://…, without /chat/completions)';

  @override
  String get aiCfgModelLabel => 'Model (must support web search)';

  @override
  String get aiCfgWebSearch => 'Web search';

  @override
  String get aiCfgTestConnection => 'Test connection';

  @override
  String get aiCfgUsageTitle => 'Usage & quota';

  @override
  String get aiCfgUsageTooltip =>
      'Call counts are tallied locally by the app (reopen the settings page to refresh); quota comes from the provider API — free models are not charged';

  @override
  String get aiCfgStatToday => 'Today';

  @override
  String get aiCfgStatLast7Days => 'Last 7 days';

  @override
  String get aiCfgStatTotal => 'Total';

  @override
  String aiCfgCalls(num n) {
    return '$n calls';
  }

  @override
  String get aiCfgNoBalanceApi =>
      'No balance API for this provider; check its console';

  @override
  String get aiCfgBalanceGlm => 'Provider balance (Zhipu)';

  @override
  String aiCfgBalanceTotal(String v) {
    return 'Total quota ¥$v';
  }

  @override
  String aiCfgBalanceVoucher(String v) {
    return 'Free quota ¥$v';
  }

  @override
  String aiCfgBalanceCash(String v) {
    return 'Cash ¥$v';
  }

  @override
  String get aiCfgBalanceNoFields => 'The API returned no quota fields';

  @override
  String aiCfgBalanceQueryFailed(String e) {
    return 'Query failed: $e';
  }

  @override
  String get aiCfgBalanceQuery => 'Query';

  @override
  String get aiCfgBalanceRefresh => 'Refresh';

  @override
  String get aiCfgServiceHint =>
      'Zhipu/Kimi/Qwen/OpenAI/Claude/custom; the key is stored encrypted locally';

  @override
  String get categoryManagerTitle => 'Categories & rules';

  @override
  String get categoryRulePriorityHint =>
      'Keyword rules take priority over learned history on import.';

  @override
  String get categoryExpenseGroup => 'Expense categories';

  @override
  String get categoryIncomeGroup => 'Income categories';

  @override
  String get categoryKeywordRules => 'Keyword rules';

  @override
  String get categoryNoRulesHint =>
      'No explicit rules yet. Imports and everyday bookkeeping learn counterparty-to-category mappings automatically.';

  @override
  String categoryRuleKeyword(String kw) {
    return '\"$kw\"';
  }

  @override
  String get categoryAddExpense => 'New expense category';

  @override
  String get categoryAddIncome => 'New income category';

  @override
  String get categoryRename => 'Rename category';

  @override
  String get categoryAddRule => 'New keyword rule';

  @override
  String get categoryRuleKeywordLabel => 'Keyword (e.g. Meituan, NETFLIX)';

  @override
  String get categoryRuleTargetLabel => 'Categorize matches as';

  @override
  String get categoryManagerHint =>
      'Manage income/expense categories and merchant→category keyword rules';

  @override
  String get fxManagerTitle => 'FX rates';

  @override
  String get fxManagerHint =>
      'NAV conversion uses the latest rate on or before each date; save back-dated entries to override history.';

  @override
  String get fxAddRate => 'Add rate';

  @override
  String get fxAiFetch => 'AI fetch';

  @override
  String get fxNoRatesHint =>
      'No FX rates yet. Converting multi-currency accounts needs at least one rate per currency.';

  @override
  String get fxEditRateTitle => 'Enter FX rate';

  @override
  String get fxFromCurrency => 'From currency';

  @override
  String get fxToCurrency => 'To currency';

  @override
  String get fxRateLabel => '1 from-currency = ? to-currency (e.g. 7.25)';

  @override
  String get fxRateSaved => 'FX rate saved';

  @override
  String get fxRateInvalid => 'Invalid FX rate format';

  @override
  String get fxManualHint =>
      'Enter per-currency rates against the base currency by hand';

  @override
  String mergeDecryptFailed(Object e) {
    return 'Could not decrypt the backup (wrong passphrase or corrupted file): $e';
  }

  @override
  String mergeSchemaTooNew(num v) {
    return 'This backup is from a newer app version (schema $v); upgrade before merging';
  }

  @override
  String get mergeLineageMismatch =>
      'This backup belongs to a different ledger (lineage fingerprint mismatch) and cannot be merged. Use \"Restore from backup\" instead.';

  @override
  String mergeVerifyFailed(Object e) {
    return 'Backup integrity check failed: $e';
  }

  @override
  String get mergeNothingToMerge =>
      'The two ledgers are already identical; nothing to merge';

  @override
  String get mergeDone => 'Merge complete';

  @override
  String mergeSafetyBackupNote(String path) {
    return 'Pre-merge safety backup:\n$path\nPages refresh automatically when they return to the foreground.';
  }

  @override
  String mergeFailed(Object e) {
    return 'Merge failed (ledger unchanged, fully rolled back): $e';
  }

  @override
  String get mergePassphraseLabel => 'Passphrase this .asbk was exported with';

  @override
  String get mergeConfirmTitle => 'Confirm merge';

  @override
  String mergeWillImport(String summary) {
    return 'Will merge in: $summary.';
  }

  @override
  String get mergeConfirmNote =>
      'Transactions merge with \"newest update wins\"; other tables follow per-table policy. A safety backup is created first, so you can revert anytime with \"Restore from backup\".';

  @override
  String get mergeLegacyWarning =>
      'Note: this backup was exported by an older version and carries no ledger identity. Make sure it really comes from the same ledger.';

  @override
  String get mergeBackupAndMerge => 'Back up and merge';

  @override
  String quoteAppliedCount(num n) {
    return 'Wrote $n quotes/rates';
  }

  @override
  String quoteWriteFailed(Object e) {
    return 'Write failed: $e';
  }

  @override
  String get quoteFetchTitle => 'Quotes / FX fetch';

  @override
  String get quoteFetchIntro =>
      'Direct official quote sources (free, no key, instant); fall back to AI web search for anything missing. Nothing is written until you approve the preview, and sources stay auditable. Either way, only ticker symbols and currency pairs are sent.';

  @override
  String get quoteQueryingDirect => 'Querying official quote sources…';

  @override
  String get quoteQueryingAi =>
      'AI is searching the web for quotes — this takes about 10–60 seconds…';

  @override
  String get quoteNoWebSearchWarning =>
      'Web search is off in the current AI config; the model may return stale prices from memory — review carefully.';

  @override
  String get quoteWillQuery => 'Will query:';

  @override
  String get quoteNoTargets =>
      'No security holdings and no foreign-currency accounts to convert.';

  @override
  String quoteHoldingPrices(num n, String names) {
    return '· Holding prices ($n): $names';
  }

  @override
  String quoteFxPairs(num n, String pairs, String base) {
    return '· FX rates ($n): $pairs → $base';
  }

  @override
  String get quoteRoutingHint =>
      'Direct routing: A-shares / listed funds → Tencent Quotes; HK / US stocks → stooq; FX → ECB. Tickers are set in each holding account\'s details (e.g. 600519 / 00700 / AAPL).';

  @override
  String get quoteDirectFetchButton =>
      'Direct official sources (recommended · free · instant)';

  @override
  String get quoteAiFetchFallback => 'AI web search (fallback)';

  @override
  String get quoteAiFetchNeedsConfig => 'AI web search (configure AI first)';

  @override
  String get quoteAssetPrices => 'Asset prices';

  @override
  String get quoteFxRates => 'FX rates';

  @override
  String get quoteNotes => 'Warnings';

  @override
  String quoteSelectedCount(num p, num r) {
    return '$p prices + $r rates selected';
  }

  @override
  String get quoteBack => 'Back';

  @override
  String get quoteApplyButton => 'Apply';

  @override
  String get quoteUnmatchedTooltip =>
      'Not matched to a holding account; will not be posted';

  @override
  String quoteCurrencyMismatchTooltip(String ccy) {
    return 'Currency mismatch ($ccy vs account currency); unchecked by default';
  }

  @override
  String get quoteFetchHint =>
      'AI web search for the latest prices and FX rates; posted only after preview confirmation';

  @override
  String settingsFailed(Object e) {
    return 'Failed: $e';
  }

  @override
  String get settingsFailedPrefix => 'Failed';

  @override
  String get settingsCancel => 'Cancel';

  @override
  String get settingsSave => 'Save';

  @override
  String get settingsGotIt => 'Got it';

  @override
  String get settingsBackupFileType => 'Backup';

  @override
  String get settingsBackupPassphraseTitle => 'Enter backup passphrase';

  @override
  String get settingsVerify => 'Verify';

  @override
  String get settingsChangePassphrase => 'Change master passphrase';

  @override
  String get settingsCurrentPassphrase => 'Current passphrase';

  @override
  String get settingsNewPassphraseLabel =>
      'New passphrase (≥12 chars is safer)';

  @override
  String get settingsConfirm => 'Confirm';

  @override
  String get settingsPassphraseUpdated => 'Master passphrase updated';

  @override
  String get settingsNewRecoveryCode => 'New recovery code (store offline)';

  @override
  String get settingsBackupPassphrase => 'Backup passphrase';

  @override
  String get settingsBackupPassphraseLabel =>
      'Backup file passphrase (≥8 chars; 12+ recommended)';

  @override
  String get settingsExport => 'Export';

  @override
  String settingsExportedTo(String path) {
    return 'Exported to: $path';
  }

  @override
  String settingsExportFailed(Object e) {
    return 'Export failed: $e';
  }

  @override
  String get settingsVerifyAndRestore => 'Verify and restore';

  @override
  String get settingsRestoreDone =>
      'Restore complete; locked with the new data — unlock with your master passphrase (the original database is kept as .bak)';

  @override
  String settingsRestoreFailed(Object e) {
    return 'Restore failed (original ledger untouched): $e';
  }

  @override
  String get settingsBaseCurrency => 'Base currency';

  @override
  String settingsBaseCurrencySet(String code) {
    return 'Base currency set to $code';
  }

  @override
  String get settingsNotUnlocked => 'Locked';

  @override
  String get settingsGroupSecurity => 'Security';

  @override
  String get settingsGroupBackup => 'Backup & restore';

  @override
  String get settingsGroupPreferences => 'Preferences';

  @override
  String get settingsGroupData => 'Data management';

  @override
  String get settingsGroupAiQuotes => 'AI & quotes';

  @override
  String get settingsGroupAbout => 'About';

  @override
  String get settingsLockNow => 'Lock now';

  @override
  String get settingsLockNowHint =>
      'Closes the database and clears in-memory keys; also auto-locks when idle';

  @override
  String get settingsChangePassphraseHint =>
      'Only re-wraps the keys; data is not re-encrypted';

  @override
  String get settingsRegenRecoveryCode => 'Regenerate recovery code';

  @override
  String get settingsRegenRecoveryCodeHint =>
      'The old recovery code stops working immediately';

  @override
  String get settingsExportBackup => 'Export encrypted backup';

  @override
  String get settingsExportBackupHint =>
      'Creates an encrypted .asbk container; use a separate passphrase and store it offline';

  @override
  String get settingsRestoreBackup => 'Restore from backup';

  @override
  String get settingsRestoreBackupHint =>
      'Verifies in isolation first; replaces the current ledger only after it passes (original kept as .bak)';

  @override
  String get settingsMergeBackup => 'Merge from backup (multi-device)';

  @override
  String get settingsMergeBackupHint =>
      'Merges another device\'s .asbk into this ledger: newest transaction wins, safety backup created first';

  @override
  String get settingsBaseCurrencyHint =>
      'The reporting currency for stats, net worth and projections';

  @override
  String get settingsImportCsv => 'Import bill CSV';

  @override
  String get settingsImportCsvHint =>
      'UTF-8/GBK auto-detection, idempotent de-duplication, smart category suggestions';

  @override
  String get settingsExportJson => 'Export full JSON';

  @override
  String get settingsExportJsonHint =>
      'A plaintext snapshot of accounts/valuations/transactions/plans/budgets (no keys); auditable and portable';

  @override
  String get settingsPageTitle => 'Settings';

  @override
  String get settingsFullJsonExported =>
      'Full JSON exported (plaintext, no keys)';

  @override
  String get settingsAboutTagline =>
      'A local-first system for personal assets, liabilities and financial planning. Data is encrypted at rest, and every online feature is off by default.';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsAppearanceHint =>
      'Light mist white / dark wealth terminal; follows the system automatically';

  @override
  String get settingsThemeSystem => 'Follow system';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsAutoLock => 'Auto-lock';

  @override
  String get settingsAutoLockHint =>
      'Locks the ledger after this much idle time';

  @override
  String settingsMinutes(num n) {
    return '$n min';
  }

  @override
  String get settingsAutoLockDialogTitle => 'Idle auto-lock';

  @override
  String settingsAutoLockSet(num n) {
    return 'Auto-lock set to $n min';
  }

  @override
  String get settingsCashHorizon => 'Cash projection horizon';

  @override
  String get settingsCashHorizonHint =>
      'Days projected behind the home \"how much can I spend\" figure';

  @override
  String settingsDays(num n) {
    return '$n days';
  }

  @override
  String settingsCashHorizonSet(num n) {
    return 'Cash projection horizon set to $n days';
  }

  @override
  String get settingsCashFloor => 'Cash floor';

  @override
  String get settingsCashFloorHint =>
      'Falling below this counts as a cash shortage (deducted from projections and the spendable ceiling)';

  @override
  String get settingsCashFloorSaved => 'Cash floor saved';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get save => 'Save';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get remove => 'Remove';

  @override
  String loadFailed(Object error) {
    return 'Failed to load: $error';
  }

  @override
  String yearsN(String n) {
    return '$n yrs';
  }

  @override
  String monthsN(num n) {
    return '$n mo';
  }

  @override
  String daysLaterN(num n) {
    return 'In $n days';
  }

  @override
  String get lifeEventAddTitle => 'Add a life event';

  @override
  String get lifeEventBuyHome => 'Buy a home (with mortgage)';

  @override
  String get lifeEventChildRearing => 'Having a child / raising';

  @override
  String get lifeEventIncomeChangeOption =>
      'Income jump (promotion / job loss)';

  @override
  String get lifeEventRetirement => 'Retirement';

  @override
  String get lifeEventBigPurchaseOption => 'Major purchase (e.g. a car)';

  @override
  String get lifeEventLumpSum => 'One-off large inflow or outflow';

  @override
  String get lifeEventIncomeChange => 'Income jump';

  @override
  String get lifeEventBigPurchase => 'Major purchase';

  @override
  String get lifeEventYearsLater => 'Years from now';

  @override
  String get lifeEventTotalPrice => 'Total price (¥)';

  @override
  String get lifeEventDownPayment => 'Down payment (¥)';

  @override
  String get lifeEventAnnualRateHint => 'Annual rate % (e.g. 3.6)';

  @override
  String get lifeEventLoanTerm => 'Loan term';

  @override
  String get lifeEventYearsUntilBirth => 'Years until birth';

  @override
  String get lifeEventMonthlyRearingCost => 'Monthly child-rearing cost (¥)';

  @override
  String get lifeEventCollegeExtra =>
      'Extra monthly in college years (¥, optional)';

  @override
  String get lifeEventChangePctHint =>
      'Change % (+30 = up 30% / −100 = to zero)';

  @override
  String get lifeEventYearsUntilRetire => 'Years until retirement';

  @override
  String get lifeEventRetirementNote =>
      'After retirement: income ×0.4 (pension replacement rate), spending ×0.75';

  @override
  String get lifeEventPurchaseCost => 'Purchase cost (¥)';

  @override
  String get lifeEventResidualValue =>
      'Residual value counted as fixed assets (¥, optional)';

  @override
  String get lifeEventAmountInOut => 'Amount (¥; negative = outflow)';

  @override
  String get lifePlanTitle => 'Life planning · Multi-year projection';

  @override
  String lifePlanIntro(num years) {
    return 'Put the big moves — home, children, car, retirement — on one timeline and project the next $years years of cash flow and net worth month by month (nominal; income and spending grow with inflation). Read-only simulation; nothing is written to the ledger.';
  }

  @override
  String get lifePlanRerun => 'Re-run projection';

  @override
  String get lifePlanInvestableAssets => 'Investable net worth (¥)';

  @override
  String get lifePlanFixedAssets => 'Fixed assets etc. (¥)';

  @override
  String get lifePlanMonthlyIncome => 'Monthly income (¥)';

  @override
  String get lifePlanMonthlyExpense => 'Monthly spending (¥)';

  @override
  String get lifePlanNominalReturn => 'Nominal return %/yr';

  @override
  String get lifePlanInflation => 'Inflation %/yr';

  @override
  String get lifePlanHorizonYears => 'Projection horizon';

  @override
  String get lifePlanEvents => 'Life events';

  @override
  String get lifePlanAddEvent => 'Add event';

  @override
  String get lifePlanNoEvents =>
      'No events yet. Try one: buy a home in three years, a baby next year…';

  @override
  String get lifePlanResults => 'Projection results';

  @override
  String lifePlanNetWorthInYears(num years) {
    return 'Net worth in $years yrs';
  }

  @override
  String get lifePlanPeakNetWorth => 'Peak net worth';

  @override
  String get lifePlanNewLoanInterest => 'Total interest on new loans';

  @override
  String get lifePlanCashExhaustionRisk => 'Cash exhaustion risk';

  @override
  String get lifePlanNoGap => 'No gap within the horizon ✓';

  @override
  String lifePlanExhaustedAt(num year, String date) {
    return 'Year $year (around $date)';
  }

  @override
  String get lifePlanNetWorthCurve => 'Net worth curve (¥ ×10k)';

  @override
  String lifePlanCurveTooltip(String year, String value) {
    return 'Year $year  $value';
  }

  @override
  String get planNew => 'New plan';

  @override
  String get planEdit => 'Edit plan';

  @override
  String get planNameLabel => 'Name (e.g. rent / salary)';

  @override
  String get planOutflow => 'Expense';

  @override
  String get planInflow => 'Income';

  @override
  String get planCadence => 'Cadence';

  @override
  String get planAnchorMonthly => 'Start date (same day each month)';

  @override
  String get planAnchorDate => 'Start date';

  @override
  String get planEndDate => 'End date (optional)';

  @override
  String get planAutoPostTitle => 'Auto-post to the ledger when due';

  @override
  String get planAutoPostSubtitle =>
      'Posts automatically when the app is unlocked; posted or voided items are never duplicated';

  @override
  String get planPayAccount => 'Payment account';

  @override
  String get planIncomeAccount => 'Receiving account';

  @override
  String planNoAccountForCurrency(String currency) {
    return 'No $currency account to choose from — create one first';
  }

  @override
  String get planCategory => 'Category';

  @override
  String planPostTitle(String name) {
    return 'Post to ledger · $name';
  }

  @override
  String planPostDateNote(String date) {
    return 'Posting date $date (occurrence date)';
  }

  @override
  String get planPostEstimateNote =>
      ' · Estimated amount uses the median; you can edit it';

  @override
  String planAccountsLoadFailed(String error) {
    return 'Failed to load accounts: $error';
  }

  @override
  String planPostFailed(String error) {
    return 'Failed to post: $error';
  }

  @override
  String get planSkipOnce => 'Skip this one';

  @override
  String get planPostNow => 'Post to ledger';

  @override
  String get planPosting => 'Posting…';

  @override
  String get plansPageTitle => 'Plans';

  @override
  String get planMonthlyRhythm => 'This month at a glance';

  @override
  String get planDueUnposted => 'Due, unposted';

  @override
  String planCount(num n) {
    return '$n items';
  }

  @override
  String get planDueTooltip =>
      'Scheduled events past due and unposted — post them one by one or all at once';

  @override
  String get planNext30Days => 'Next 30 days';

  @override
  String get planNext30Tooltip => 'All occurrences, posted and unposted';

  @override
  String get planNext30Net => 'Next 30-day net flow';

  @override
  String get planNetSignTooltip =>
      'Positive is net inflow, negative is net outflow';

  @override
  String planDueTitle(num n) {
    return 'To post · $n due';
  }

  @override
  String get planPostAll => 'Post all';

  @override
  String get planEstimateTooltip =>
      'Estimated amount; you can edit it when confirming';

  @override
  String get planEstimateBadge => 'Est.';

  @override
  String planMoreDue(num n) {
    return '…$n more — \"Post all\" handles them in one go';
  }

  @override
  String planNetEffect(String amount) {
    return 'Net effect $amount';
  }

  @override
  String planBlockedCount(num n) {
    return ' · $n need an account picked on the confirm step';
  }

  @override
  String planPostedCount(num n) {
    return 'Posted $n scheduled items';
  }

  @override
  String get planNothingToPost =>
      'Nothing ready to post (pick an account on the confirm step first)';

  @override
  String get planNoUpcoming => 'No scheduled expenses yet';

  @override
  String get planAllPlans => 'All plans';

  @override
  String get planEmptyHint =>
      'Tap \"New plan\" at the bottom right, or generate plans from detected recurring flows.';

  @override
  String get planEstimateAmount => ' · Estimated amount';

  @override
  String get planActions => 'Plan actions';

  @override
  String get planPause => 'Pause';

  @override
  String get planResume => 'Resume';

  @override
  String get planMarkFinished => 'Mark finished';

  @override
  String get planDeleteTitle => 'Delete plan';

  @override
  String planDeleteMessage(String name) {
    return 'Deleting \"$name\" does not affect posted transactions.';
  }

  @override
  String get recurringTitle => 'Detected recurring flows';

  @override
  String get recurringIntro =>
      'Detected from the last 18 months of transactions (same counterparty, regular intervals, ≥3 times). Once converted, the plan counts as \"planned\" in cash projection and budgets.';

  @override
  String get recurringOpenTooltip => 'Detect recurring flows from transactions';

  @override
  String get recurringEmpty =>
      'No recurring flows detected yet. Record a few months of regular flows — rent, subscriptions, salary —\nthen come back and try again.';

  @override
  String recurringStatLine1(String cadence, num n, String pct) {
    return '$cadence · $n times · $pct% confidence';
  }

  @override
  String recurringStatLine2(String amount, num m, num d) {
    return 'Median $amount · next expected $m/$d';
  }

  @override
  String get recurringAlreadyPlanned => 'Already planned';

  @override
  String get recurringConvertToPlan => 'Convert to plan';

  @override
  String get scenarioTitle => 'Scenario simulation · Cash stress test';

  @override
  String get scenarioIntro =>
      'Put \"what if\" into a 180-day cash projection: plans, debt payments and reserves stay fixed while only income and spending take the hit — see how deep the trough gets and whether cash holds. Nothing is written to the ledger.';

  @override
  String get scenarioExtraMonthlyLabel => 'Scenario: extra monthly spending';

  @override
  String get scenarioOneOffLabel => 'Scenario: one-off expense';

  @override
  String scenarioRunFailed(String error) {
    return 'Simulation failed: $error';
  }

  @override
  String get scenarioRun => 'Run simulation';

  @override
  String get scenarioRunning => 'Simulating…';

  @override
  String get scenarioExtrasTitle => 'Add custom shocks (optional)';

  @override
  String get scenarioExtraMonthlyAmount => 'Extra monthly spending (¥/mo)';

  @override
  String get scenarioMonthsCount => 'Months';

  @override
  String get scenarioOneOffAmount => 'One-off expense (¥)';

  @override
  String get scenarioOccursOn => 'Occurs';

  @override
  String scenarioResultTitle(String name) {
    return 'Result · $name';
  }

  @override
  String get scenarioMinCashBaseline => 'Minimum cash · Baseline';

  @override
  String get scenarioMinCashScenario => 'Minimum cash · Scenario';

  @override
  String get scenarioTroughDelta => 'Trough change';

  @override
  String get scenarioWorstDay => 'Worst day (vs baseline)';

  @override
  String get scenarioCashOutDate => 'Cash-out date';

  @override
  String scenarioCashOutValue(String date, num days) {
    return '$date ($days days left)';
  }

  @override
  String get scenarioNoCashOut => 'Not exhausted within the horizon';

  @override
  String get scenarioNewShortfalls =>
      'New shortfalls (absent in baseline, triggered by the scenario)';

  @override
  String get scenarioBelowReserve => 'Below reserves and floor';

  @override
  String scenarioShortfallCount(num n) {
    return '…$n in total';
  }

  @override
  String scenarioSurvives(String amount) {
    return 'The scenario is survivable: no new shortfalls and cash never runs out. Headroom above the floor: $amount.';
  }

  @override
  String get scenarioHurts =>
      'This scenario would hurt: consider raising reserves, deferring optional spending, or arranging a backup credit line.';

  @override
  String get scenarioMethodNote =>
      'Method: replayed on the same engine as the cash projection (docs/05 §12); reserves, debt payments and the floor unchanged.';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get allReady => 'All up to date';

  @override
  String get assetsTitle => 'Assets';

  @override
  String get assetsTitleHint =>
      'Ledger and net value of all accounts: tap any account to view its value, edit details, record valuations and trades';

  @override
  String get assetAdd => 'Add asset';

  @override
  String get assetNew => 'New asset';

  @override
  String get assetCreate => 'Create asset';

  @override
  String get assetsEmptyTitle => 'No assets or liabilities yet';

  @override
  String get assetsEmptyMessage =>
      'Add your first asset: cash, bank account, property, stock holdings… once saved, its coordinates light up on the globe home.';

  @override
  String get assetNameLabel => 'Name';

  @override
  String get assetNameRequired => 'Please enter an asset name';

  @override
  String get assetValuePositiveRequired =>
      'Value must be positive (e.g. 1280000)';

  @override
  String get assetLocationRequired =>
      'Please pick a location — it lights up on the globe home after saving';

  @override
  String get assetLocationTooltip =>
      'Assets need a location — on save the dialog dissolves into a beam that flies to the globe';

  @override
  String get assetCurrentValue => 'Current value';

  @override
  String get assetOpeningDebtNote => 'Opening debt';

  @override
  String get accountEditProfile => 'Edit details';

  @override
  String get accountUpdateValuation => 'Update valuation';

  @override
  String get accountOpeningBalance => 'Opening balance';

  @override
  String get accountOpeningBalanceTitle =>
      'Record opening balance (backdated; not counted as income)';

  @override
  String get accountReconcileAdjust => 'Reconcile';

  @override
  String get accountReconcileAdjustTitle =>
      'Reconcile adjustment (enter the difference; negatives allowed)';

  @override
  String get accountQuoteCode => 'Ticker symbol';

  @override
  String get accountQuoteCodeTitle =>
      'Ticker symbol (for direct quote sources)';

  @override
  String get accountQuoteCodeHint => 'A-shares 600519 / HK 00700 / US AAPL';

  @override
  String get accountQuoteCodeHelp =>
      'A-share tickers (6 digits) resolve the exchange automatically; HK stocks use digits; US stocks use letters. Changes only affect quote lookups, never your ledger.';

  @override
  String get accountArchive => 'Archive';

  @override
  String get accountUnarchive => 'Unarchive';

  @override
  String get accountArchived => 'Archived';

  @override
  String get accountArchivedHint => 'Excluded from net worth';

  @override
  String get accountValuationMissing => 'Missing valuation';

  @override
  String get accountMissingValuationHint =>
      'No valuation on record; excluded from net worth — tap \"Update valuation\" to add one';

  @override
  String get accountMissingValuationTip =>
      'Missing valuation: excluded from net worth';

  @override
  String get accountValuationStale => 'Stale valuation';

  @override
  String get accountStaleValuationHint => 'Not updated in over 30 days';

  @override
  String get accountStaleValuationTip => 'Stale (>30 days)';

  @override
  String get accountDebtBaseLabel => 'Current debt (base currency)';

  @override
  String get accountValueBaseLabel => 'Current value (base currency)';

  @override
  String accountOriginalBalance(String amount) {
    return 'Original balance $amount';
  }

  @override
  String accountMyShareDetail(String value, String share) {
    return 'My share $value ($share%)';
  }

  @override
  String accountMineShare(String share) {
    return 'Mine $share%';
  }

  @override
  String get accountRecentTransactions => 'Recent transactions';

  @override
  String get accountUnitPriceLabel => 'Unit price (per unit)';

  @override
  String get accountTotalValueLabel => 'Current total value';

  @override
  String get accountCurrentBalance => 'Current balance';

  @override
  String get accountLocated => 'Located';

  @override
  String get accountGroupCash => 'Cash & checking';

  @override
  String get accountGroupSteady => 'Steady investments';

  @override
  String get accountGroupHoldings => 'Holdings';

  @override
  String get accountGroupReal => 'Real assets & equity';

  @override
  String get accountGroupLiabilities => 'Liabilities';

  @override
  String get liabilityCurrentDebt => 'Current debt';

  @override
  String get netWorth => 'Net worth';

  @override
  String get netWorthMyShare => 'Net worth (my share)';

  @override
  String get netWorthMyShareHint =>
      'Some accounts are held below 100%, so this shows your share; household-wide totals are on the right';

  @override
  String get totalAssets => 'Total assets';

  @override
  String get totalLiabilities => 'Total liabilities';

  @override
  String get valuationStatusLabel => 'Valuation status';

  @override
  String itemsMissingValuation(num count) {
    return '$count missing valuation';
  }

  @override
  String itemsStaleValuation(num count) {
    return '$count outdated';
  }

  @override
  String get selectAccountHint =>
      'Select an account on the left to see details';

  @override
  String get subtypeLabel => 'Type';

  @override
  String get currencyLabel => 'Currency';

  @override
  String get locationLabel => 'Location';

  @override
  String get institutionLabel => 'Institution';

  @override
  String get securityCodeLabel => 'Ticker symbol';

  @override
  String get ownershipTitle => 'Ownership share';

  @override
  String get ownershipMyShareLabel => 'My share (%)';

  @override
  String get ownershipShareLabel => 'Share';

  @override
  String get ownershipHelper =>
      '100 = fully yours; joint spousal accounts 50 each. Affects net worth and share statistics only, never transactions.';

  @override
  String get ownershipRangeError =>
      'Share must be between 0 and 100 (e.g. 50 or 33.3)';

  @override
  String get tradeBuy => 'Buy';

  @override
  String get tradeSell => 'Sell';

  @override
  String get tradeDividendInterest => 'Dividend/interest';

  @override
  String tradeBuyTitle(String name) {
    return 'Buy · $name';
  }

  @override
  String tradeSellTitle(String name) {
    return 'Sell · $name';
  }

  @override
  String get tradeDividendTitle => 'Dividend/interest entry';

  @override
  String tradeHoldingSummary(String qty, String cost) {
    return 'Holding $qty units · cost $cost';
  }

  @override
  String get tradeCashAccount => 'Cash account';

  @override
  String get tradeCashAccountCredited => 'Cash account to credit';

  @override
  String get tradeQuantityLabel => 'Quantity (units)';

  @override
  String get tradeTotalCostLabel => 'Total cost (fees included)';

  @override
  String get tradeNetProceedsLabel => 'Net proceeds';

  @override
  String get tradeDividendAmountLabel => 'Dividend/interest amount';

  @override
  String get tradeNoteLabel => 'Note (optional)';

  @override
  String get lotSectionTitle => 'Cost lots (FIFO)';

  @override
  String lotRealizedTotal(String amount) {
    return 'Realized total $amount';
  }

  @override
  String lotRealizedYear(num year, String amount) {
    return 'Realized in $year: $amount';
  }

  @override
  String lotLineItem(String qty, String price) {
    return '$qty units × unit cost $price';
  }

  @override
  String lotShortfall(String qty) {
    return '⚠ $qty units sold before the first purchase (historical gap, matched at zero cost)';
  }

  @override
  String get lotMethodologyNote =>
      'Method: first-in-first-out lot matching, disclosed alongside the book average-cost method (docs/05 §11)';

  @override
  String get aiRecognize => 'Recognize with AI';

  @override
  String get aiFillNameFirst =>
      'Enter an asset name first so AI can recognize it';

  @override
  String get aiNotBound => 'No AI connected: Settings → AI services';

  @override
  String get aiRecognizing => 'Recognizing with AI…';

  @override
  String get aiFilledConfirmValue => 'AI filled in — please confirm the value';

  @override
  String get aiValTitle => 'AI valuation';

  @override
  String get aiValDaily => 'Daily AI valuation';

  @override
  String get aiValDailyTooltip =>
      'When enabled, live market prices for this asset are fetched daily and the value updated automatically (homes from transaction listings, cars from resale estimates, cross-checked across sources to strip marketing noise). You can correct it anytime in account details — manual values win for the day.';

  @override
  String get aiValSectionTooltip =>
      'After each unlock, live market prices are fetched and the value updated; valuations you set manually take priority for the day and are never overwritten by AI.';

  @override
  String get aiValQueryLabel =>
      'Search clues (estate/building/unit · year, model)';

  @override
  String get aiValSaveQuery => 'Save query';

  @override
  String get aiValSearching => 'Searching…';

  @override
  String get aiValEstimateNow => 'Estimate now';

  @override
  String aiValQueryFallback(String query) {
    return 'Empty query = \"$query\"';
  }

  @override
  String get aiValQuerySaved => 'AI valuation query saved';

  @override
  String get aiValBindKeyFirst =>
      'Bind your AI key first: Settings → AI services';

  @override
  String aiValUpdated(String value) {
    return 'Valuation updated: $value';
  }

  @override
  String aiValError(Object error) {
    return 'AI valuation: $error';
  }

  @override
  String get aiValResultTitle => 'AI valuation result';

  @override
  String get aiValRange => 'Range';

  @override
  String get aiValConfidence => 'Confidence';

  @override
  String get aiValRationale => 'Rationale';

  @override
  String get aiValSource => 'Source';

  @override
  String get aiValDismiss => 'No thanks';

  @override
  String get aiValAdopt => 'Adopt';

  @override
  String get aiValNoRecords => 'No valuation records yet';

  @override
  String get locSet => 'Set location';

  @override
  String get locChange => 'Change location';

  @override
  String get locClear => 'Clear location';

  @override
  String locLocatedBuiltin(String name) {
    return 'Located: $name (built-in city coordinates)';
  }

  @override
  String locLocatedAiPrecise(String name) {
    return 'AI located: $name (precise location)';
  }

  @override
  String locLocatedAiCity(String name) {
    return 'AI located: $name (city center)';
  }

  @override
  String locLocatedFallback(String name) {
    return 'Located: $name';
  }

  @override
  String locDialogTitle(String name) {
    return 'Location of \"$name\"';
  }

  @override
  String get locDialogSubtitle =>
      'Once set, this asset appears as a breathing marker on the 3D asset globe';

  @override
  String get locNameLabel => 'Location name (e.g. Shanghai · Qiantan)';

  @override
  String get locLatitudeLabel => 'Latitude (-90 ~ 90)';

  @override
  String get locLongitudeLabel => 'Longitude (-180 ~ 180)';

  @override
  String get locCoordNote =>
      'Coordinates are WGS84; for domestic assets, quick-pick a city, then fine-tune with estate coordinates from a maps app';

  @override
  String loadFailedReports(String e) {
    return 'Failed to load: $e';
  }

  @override
  String get reportCancel => 'Cancel';

  @override
  String get reportSave => 'Save';

  @override
  String get assetAllocation => 'Asset allocation';

  @override
  String get setTargetAllocation => 'Set target allocation';

  @override
  String get allocNoAssetsHint =>
      'No assets yet. Record transactions and your asset mix will appear here.';

  @override
  String allocMissingValuations(num n) {
    return '⚠ $n accounts missing valuations (counted as 0)';
  }

  @override
  String get rebalanceAdviceTitle => 'Rebalancing advice (5/25 band method)';

  @override
  String get rebalanceAdviceNote =>
      'Alerts when drift exceeds max(5 percentage points, 25% of target); trades return to the band edge rather than the target to reduce turnover.';

  @override
  String get allocWithinBand => 'All allocations within target bands ✓';

  @override
  String allocTargetPct(num n) {
    return 'Target $n%';
  }

  @override
  String get rebalanceBuy => 'Buy';

  @override
  String get rebalanceSell => 'Sell';

  @override
  String rebalanceAdviceDetail(String current, String target) {
    return 'Current $current% → back to band edge $target%±band';
  }

  @override
  String get targetAllocationTitle => 'Target allocation';

  @override
  String get targetAllocationHint =>
      'Percentage of total assets per class, summing to ≤ 100%. Leave blank = no target (excluded from rebalancing alerts).';

  @override
  String targetSumExceeded(num n) {
    return 'Total $n% (over 100%)';
  }

  @override
  String targetSumRemaining(num sum, num rest) {
    return 'Total $sum% · no target/unallocated $rest%';
  }

  @override
  String get fireTitle => 'Financial independence (FIRE)';

  @override
  String get fireTuneTooltip => 'Adjust assumptions & simulate';

  @override
  String get fireEmptyHint =>
      'Once you have tracked income and spending for a while, this estimates \"how much it takes to be financially free\".\nDefinitions: FI number = annual spend ÷ withdrawal rate (4% rule); investable net worth = net worth − fixed assets − long-term equity.';

  @override
  String get fiNumberToday => 'FI number (today’s money)';

  @override
  String get investableCoverage => 'Investable net worth coverage';

  @override
  String coverageHistoryMonths(num n) {
    return ' ($n months of history)';
  }

  @override
  String get fiTimeToReach => 'Time to FI (defaults)';

  @override
  String get fiUnreachable =>
      'Unreachable (raise savings or return assumptions)';

  @override
  String get fiReached => 'FI reached 🎉';

  @override
  String fiYearsAway(num n) {
    return '≈ $n yr';
  }

  @override
  String get fireDefaultsNote =>
      'Defaults: 5% nominal return · 2.5% inflation · 4% withdrawal rate · savings from the trailing 12 months. Use the top-right button to adjust and run Monte Carlo.';

  @override
  String get firePlannerTitle => 'Financial independence (FIRE) planner';

  @override
  String get firePlannerNote =>
      'FI number = annual spend ÷ withdrawal rate; the accumulation phase compounds month by month (nominal returns, target grows with inflation). Monte Carlo is in real terms (net of inflation) with a fixed seed for reproducibility.';

  @override
  String get recalculate => 'Recalculate';

  @override
  String get investableNetWorthField => 'Investable net worth (¥)';

  @override
  String get annualSavingsField => 'Annual savings (¥, can be negative)';

  @override
  String get targetAnnualSpendField => 'Target annual spend (¥)';

  @override
  String get nominalReturnField => 'Nominal return %/yr';

  @override
  String get inflationField => 'Inflation %/yr';

  @override
  String get withdrawalRateField => 'Withdrawal rate % (4 = 4% rule)';

  @override
  String withdrawalVolPct(String v) {
    return 'Withdrawal-phase volatility $v%';
  }

  @override
  String get calcResults => 'Results';

  @override
  String get currentCoverage => 'Current coverage';

  @override
  String get timeToFi => 'Time to FI';

  @override
  String fiUnreachableWithin(num n) {
    return 'Not reachable (within $n years)';
  }

  @override
  String fiYearsMonths(num years, num months) {
    return '≈ $years yr ($months mo)';
  }

  @override
  String get requiredSavingsTitle =>
      'Work backwards: annual savings needed to reach FI in N years';

  @override
  String fiWithinYears(num n) {
    return 'FI within $n years';
  }

  @override
  String get mcTitle => 'Monte Carlo · 30 years of withdrawal after FI';

  @override
  String get mcSurvivalLabel => 'Survival rate (1,000 paths)';

  @override
  String get mcPercentileLabel => 'Ending-balance percentiles (× annual spend)';

  @override
  String mcNote(String vol) {
    return 'Starting point = FI number (annual spend × the inverse of the withdrawal rate); withdraw 1× each year and grow at random real returns; volatility $vol%. A heuristic reference, not investment advice.';
  }

  @override
  String get fiUnreachableShort => 'Unreachable';

  @override
  String get fiReachedShort => 'Reached';

  @override
  String yearsShort(num n) {
    return '$n yr';
  }

  @override
  String get sensitivityTitle => 'Sensitivity: returns ±1pp × spend ±10%';

  @override
  String get baseline => 'Baseline';

  @override
  String sensReturnRow(String sign, num n) {
    return 'Return $sign$n pp';
  }

  @override
  String get sensitivityColsNote =>
      'Columns: spend ×0.9 / ×1.0 / ×1.1 (saving 10% beats earning 1pp more)';

  @override
  String get portfolioTitle => 'Portfolio';

  @override
  String get noHoldingsHint =>
      'No holdings yet. Create a holding account via “Add asset” on the dashboard, then log your first investment with “Buy”.';

  @override
  String holdingQtyShares(String q) {
    return '$q shares';
  }

  @override
  String holdingCostHint(String cost) {
    return ' · cost $cost';
  }

  @override
  String get missingPrice => 'No price';

  @override
  String skippedFxFlows(num n) {
    return '⚠ $n foreign-currency flows excluded from XIRR (missing historical FX rates)';
  }

  @override
  String get xirrTwrTooltip =>
      'XIRR is money-weighted (includes the timing of your trades); TWR is time-weighted (strips out cash flows to measure the asset’s performance)';

  @override
  String annualizedXirr(String v) {
    return 'Annualized XIRR $v%';
  }

  @override
  String annualizedTwr(String v) {
    return 'Annualized TWR $v%';
  }

  @override
  String get myCpiTitle => 'My inflation · trailing 12 months';

  @override
  String get myCpiEmptyHint =>
      'After 6 months of records, this measures your personal cost-of-living inflation from your own consumption basket (fixed-basket basis: how much more the base-period basket costs today).';

  @override
  String aboveAssumedInflation(String v) {
    return 'Above assumed inflation $v%';
  }

  @override
  String notAboveAssumedInflation(String v) {
    return 'Not above assumed inflation $v%';
  }

  @override
  String basketCoverageWarning(String v) {
    return '⚠ Basket coverage $v% (spending mix has shifted; interpret with care)';
  }

  @override
  String cpiMethodNote(num base, num recent) {
    return 'Monthly average spend over a $base-month base period vs the recent $recent months; a price-index approximation holding the base-period consumption mix fixed (fixed-basket Laspeyres).';
  }

  @override
  String basketShareHint(String share, String ratio) {
    return '$share% of basket · recent/base ×$ratio';
  }

  @override
  String reportYearTitle(num year) {
    return 'Yearly · $year';
  }

  @override
  String reportMonthTitle(num year, num month) {
    return 'Monthly · $year.$month';
  }

  @override
  String get prevPeriod => 'Previous period';

  @override
  String get nextPeriod => 'Next period';

  @override
  String get nwChangeBreakdown => 'Net worth change breakdown';

  @override
  String get residualTooltip =>
      'A non-zero residual usually means missing valuations, omissions, or duplicate imports';

  @override
  String pendingReviewChip(String v) {
    return 'Unreconciled $v';
  }

  @override
  String get netWorthOpening => 'Opening net worth';

  @override
  String get attributionIncomeExpense => 'Income & expense contribution';

  @override
  String get attributionRealized => 'Investment P&L · realized';

  @override
  String get attributionDividend => 'Investment P&L · dividends';

  @override
  String get attributionUnrealizedDelta => 'Investment P&L · unrealized change';

  @override
  String get attributionFx => 'FX effect';

  @override
  String get attributionOtherValuation => 'Other valuation changes';

  @override
  String get attributionCorrection => 'Scope/history corrections';

  @override
  String get attributionResidual => 'Unreconciled difference';

  @override
  String get netWorthClosing => 'Closing net worth';

  @override
  String get incomeMix => 'Income mix';

  @override
  String get expenseMix => 'Spending mix';

  @override
  String get closingBalanceSheetMix => 'Closing assets & liabilities';

  @override
  String get valuationMissingSuffix => ' (no valuation)';

  @override
  String get valuationStaleSuffix => ' (stale valuation)';

  @override
  String get monthlyReport => 'Monthly';

  @override
  String get yearlyReport => 'Yearly';

  @override
  String get riskTitle => 'Risk & risk-adjusted returns';

  @override
  String get riskFreeRateTooltip => 'Risk-free rate (Sharpe/Sortino parameter)';

  @override
  String riskNeedMorePoints(num n) {
    return 'Needs at least 2 valid month-end valuation points ($n available).\nUpdate holding prices monthly to unlock drawdown, volatility and other risk metrics.';
  }

  @override
  String riskSmallSample(num n) {
    return '⚠ Only $n months of valid samples (< 6); metrics are volatile, treat as reference only';
  }

  @override
  String get annualizedReturnTwr => 'Annualized return (TWR)';

  @override
  String get annualizedVolatility => 'Annualized volatility';

  @override
  String get sharpeRatio => 'Sharpe ratio';

  @override
  String get sharpeFormulaHint =>
      '(annualized return − risk-free) / volatility';

  @override
  String get sortinoRatio => 'Sortino ratio';

  @override
  String get sortinoHint => 'Downside-deviation Sharpe';

  @override
  String get bestWorstMonth => 'Best / worst month';

  @override
  String get monthWinRate => 'Monthly win rate';

  @override
  String riskBasisNote(num periods, num points, String rf) {
    return 'Based on $periods monthly sub-periods ($points valid month-end valuations over the last 36 months) · risk-free rate $rf%';
  }

  @override
  String drawdownSpan(String peak, String trough) {
    return '$peak peak → $trough trough';
  }

  @override
  String get maxDrawdown => 'Max drawdown';

  @override
  String get riskFreeRateDialogTitle => 'Risk-free rate (annualized %)';

  @override
  String get riskFreeRateHint =>
      'e.g. 2.0 (near the 10-year government bond yield)';

  @override
  String yearSummaryTitle(num year) {
    return '$year in review';
  }

  @override
  String get yearTotalIncome => 'Annual income';

  @override
  String get yearTotalExpense => 'Annual spending';

  @override
  String get surplus => 'Surplus';

  @override
  String get savingsRate => 'Savings rate';

  @override
  String get savingsRateTooltip => 'Surplus / income';

  @override
  String get positiveSurplusMonths => 'Months with positive surplus';

  @override
  String get interestPaid => 'Interest paid';

  @override
  String get interestPaidTooltip => 'Annual debt cost';

  @override
  String get realizedPnl => 'Realized investment P&L';

  @override
  String get realizedPnlTooltip => 'Locked in on sale (book basis)';

  @override
  String get dividends => 'Dividends';

  @override
  String get netInvestmentGain => 'Net investment gain';

  @override
  String get netInvestmentGainTooltip => 'Realized + dividends';

  @override
  String get monthlyCashflow => 'Monthly income & spending';

  @override
  String get incomeLabel => 'Income';

  @override
  String get expenseLabel => 'Spending';

  @override
  String barTooltipMonth(num n, String amount) {
    return 'Month $n\n$amount';
  }

  @override
  String get yearExpenseRanking => 'Top spending of the year';

  @override
  String get yearHighlights => 'Year highlights';

  @override
  String biggestExpense(String label) {
    return 'Largest expense: $label';
  }

  @override
  String get expenseFallback => 'Expense';

  @override
  String get loanPrincipalRepaid => 'Loan principal repaid';

  @override
  String incomeCategoryEntry(String name) {
    return 'Income · $name';
  }

  @override
  String get globeTitle => 'Asset globe';

  @override
  String get globeBackToOverview => 'Back to overview';

  @override
  String get globeResetView => 'Reset view';

  @override
  String get globeFullscreen => 'Fullscreen globe';

  @override
  String get globeAssetCategory => 'Asset category';

  @override
  String get globeInstitution => 'Institution';

  @override
  String get globeCurrentValue => 'Current value';

  @override
  String get globeValuationMissingExcluded =>
      'No valuation (excluded from net worth)';

  @override
  String get globeValuationStale => 'Stale (not updated in >30 days)';

  @override
  String get globeDenominationCurrency => 'Valuation currency';

  @override
  String get globeViewAndEdit => 'View & edit';

  @override
  String globeMoreSameLocation(num n) {
    return '$n more assets here';
  }

  @override
  String get globeValuationMissing => 'No valuation';

  @override
  String homeLoadFailed(Object error) {
    return 'Failed to load: $error';
  }

  @override
  String get homeTodoTooltip => 'To-dos';

  @override
  String homeTodoPending(num n) {
    return 'To-dos · $n pending — click to review';
  }

  @override
  String get homeAiTooltip => 'AI assistant';

  @override
  String get homeSettingsTooltip => 'Settings';

  @override
  String get homeLocateCurrentTooltip => 'Locate current position';

  @override
  String get homeLocating => 'Locating…';

  @override
  String homeLocatedExact(String city) {
    return 'Current position located: $city';
  }

  @override
  String homeLocatedEstimate(String city) {
    return 'Location service unavailable — estimated from time zone: $city';
  }

  @override
  String get homeAddAsset => 'Add asset';

  @override
  String get homeAddAssetTooltip =>
      'Create an asset or liability account; set a location to light it up on the globe';

  @override
  String get homeLogTransaction => 'Log a transaction';

  @override
  String get homeLogTransactionTooltip =>
      'Record spending, income and transfers';

  @override
  String get homeCollapse => 'Collapse';

  @override
  String get homeQuickAdd => 'Log a transaction / add asset';

  @override
  String get homeCollapseQuickMenu => 'Collapse quick menu';

  @override
  String get homeAddSemantic => 'Add: log a transaction or add an asset';

  @override
  String get homeRefreshing => 'Refreshing…';

  @override
  String get homeRefreshData => 'Refresh data';

  @override
  String get homeNwCardHint => 'Reports · net worth change breakdown';

  @override
  String get homeFlowCardHint =>
      'Transactions · all income and spending this month';

  @override
  String get homeHealthCardHint => 'Reports · health checks and composition';

  @override
  String get homeAssetsCardHint => 'Assets · full account ledger and editing';

  @override
  String get homeBudgetCardHint => 'Budgets · limits and pacing';

  @override
  String get homeTrendCardHint => 'Reports · trends and attribution';

  @override
  String get homePlansCardHint => 'Plans · recurring and upcoming spending';

  @override
  String homeAutoPosted(num n) {
    return '$n planned transactions posted automatically — see Transactions (source: Plans)';
  }

  @override
  String get dashNetWorth => 'Net worth';

  @override
  String dashAsOf(String date) {
    return 'As of $date';
  }

  @override
  String dashMyShare(String amount) {
    return 'My share $amount';
  }

  @override
  String dashAssetsAmount(String amount) {
    return 'Assets $amount';
  }

  @override
  String dashLiabAmount(String amount) {
    return 'Liabilities $amount';
  }

  @override
  String get dashResidualTooltip =>
      'A non-zero residual usually means missing valuations, missed entries or duplicate imports (details in the monthly report)';

  @override
  String dashPendingReview(String amount) {
    return 'Review $amount';
  }

  @override
  String get dashTotalAssets => 'Total assets';

  @override
  String get dashTotalLiabilities => 'Total liabilities';

  @override
  String dashMonthFlow(num m) {
    return 'Cash flow (month $m)';
  }

  @override
  String get dashIncome => 'Income';

  @override
  String get dashSpendFees => 'Spend & fees';

  @override
  String get dashSurplus => 'Surplus';

  @override
  String get dashInvestPnl => 'Investment P&L';

  @override
  String get dashPrincipalRepaid => 'Principal repaid';

  @override
  String get dashInterestPaid => 'Interest paid';

  @override
  String dashSpendable(num n) {
    return 'Spendable (next $n days)';
  }

  @override
  String dashForecastThrough(String date) {
    return 'Cash flow forecast through $date';
  }

  @override
  String get dashDiscretionaryCap => 'Discretionary cap';

  @override
  String get dashDiscretionaryCapHint =>
      'Net of fixed plans, repayments, reserves and your cash floor';

  @override
  String get dashMonthSpendForecast => 'Projected month spend';

  @override
  String get dashMonthSpendForecastHint =>
      'Extrapolated to month end at the current pace';

  @override
  String get dashDailyAllowance => 'Daily allowance left';

  @override
  String dashDaysElapsed(num n) {
    return '$n days into the month';
  }

  @override
  String get dashCashLowPoint => 'Cash low point';

  @override
  String dashShortfall(String label, String date) {
    return '$label shortfall ($date)';
  }

  @override
  String get dashHealthTitle => 'Financial health';

  @override
  String get dashSavingsRate => 'Savings rate';

  @override
  String get dashSavingsRateHint => 'This month: (income − spend) / income';

  @override
  String get dashEmergencyMonths => 'Emergency months';

  @override
  String get dashEmergencyMonthsHint => 'Liquid assets / average monthly spend';

  @override
  String get dashDebtToAsset => 'Debt-to-asset ratio';

  @override
  String get dashDebtToAssetHint => 'Total liabilities / total assets';

  @override
  String get dashInsights => 'Insights';

  @override
  String get dashNwTrend => 'Net worth trend';

  @override
  String dashNwTrendMonths(num n) {
    return 'Net worth trend (last $n months)';
  }

  @override
  String dashNwTrendHint(num n) {
    return 'Hold and drag the bottom roller to range from 1 to $n months';
  }

  @override
  String dashRollerHint(num n) {
    return 'Hold and drag the roller: 1 ~ $n months';
  }

  @override
  String get dashUpcomingTitle => 'Spending due in the next 30 days';

  @override
  String get dashNoUpcoming => 'No planned spending yet';

  @override
  String dashPendingDue(num n) {
    return '$n matured plans to post (one tap from Plans)';
  }

  @override
  String dashMissingValuations(num n) {
    return '$n accounts without valuations (not counted as zero — edit to add)';
  }

  @override
  String dashStaleValuations(num n) {
    return '$n accounts with stale valuations (>30 days)';
  }

  @override
  String dashResidualIssue(String amount) {
    return 'This month\'s attribution has an unreconciled residual: $amount';
  }

  @override
  String get dashIssuesTitle => 'Needs attention';

  @override
  String get dashBalanceSheet => 'Balance sheet';

  @override
  String get dashAssetsTotal => 'Total assets';

  @override
  String get dashLiabilitiesTotal => 'Total liabilities';

  @override
  String get dashIncludedAccounts => 'Accounts included';

  @override
  String dashAccountCount(num n) {
    return '$n';
  }

  @override
  String get dashValuationStatus => 'Valuation status';

  @override
  String dashMissingCount(num n) {
    return '$n unvalued';
  }

  @override
  String dashStaleCount(num n) {
    return '$n stale';
  }

  @override
  String get aiAssistant => 'AI assistant';

  @override
  String get aiHistorySessions => 'Chat history';

  @override
  String get aiBindKeyFirst =>
      'First bind your own AI key in Settings → AI services';

  @override
  String aiAssistantError(String error) {
    return 'AI assistant: $error';
  }

  @override
  String get aiSessions => 'Chats';

  @override
  String get aiNewChat => 'New chat';

  @override
  String get aiNoSessionsHint =>
      'No chats yet — tap “+” at the top right to start.';

  @override
  String get aiDeleteChat => 'Delete chat';

  @override
  String get aiLedgerContextOn =>
      'Ledger overview attached: net worth and month totals are sent to the AI (no individual transactions)';

  @override
  String get aiLedgerContextOff =>
      'No ledger data attached: the AI answers generically';

  @override
  String get aiAskSomething => 'Ask anything, or start below';

  @override
  String get aiInputHint => 'Ask your private banker… (Enter to send)';

  @override
  String get aiSend => 'Send';

  @override
  String get aiPromptSpendWhere => 'Where is my money going?';

  @override
  String get aiPromptNwTrend => 'How has my net worth been trending?';

  @override
  String get aiPromptSaveMonth => 'How can I save more this month?';

  @override
  String get aiPromptPrepay => 'Is now a good time to prepay my loans?';

  @override
  String aiValuationsUpdated(num n) {
    return 'AI updated valuations for $n assets (auditable sources; correct in account details)';
  }

  @override
  String aiValuationsUpdatedFailed(num n) {
    return 'AI updated valuations for $n assets (some failed — see account details)';
  }

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonSave => 'Save';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonVoid => 'Void';

  @override
  String get commonGotIt => 'Got it';

  @override
  String get fieldType => 'Type';

  @override
  String get dirIncome => 'Income';

  @override
  String get dirExpense => 'Expense';

  @override
  String get txAddTitle => 'Add transaction';

  @override
  String get txEditTitle => 'Edit transaction';

  @override
  String get txPageTitle => 'Transactions';

  @override
  String get txExportCsvTooltip => 'Export CSV (plain text, choose location)';

  @override
  String get txImportCsvTooltip => 'Import statement CSV';

  @override
  String get txSearchHint =>
      'Search the whole ledger: notes, counterparties, tags';

  @override
  String get txEmptyTitle => 'No transactions yet';

  @override
  String get txNoMatchTitle => 'No matching transactions';

  @override
  String get txEmptyHint =>
      'Tap \"Add transaction\" at the bottom corner, or import a statement CSV from settings.';

  @override
  String get txNoMatchHint => 'Try another keyword, or clear the type filter.';

  @override
  String get txNoMatchHintWide =>
      'Try another keyword, or clear the type filter on the right.';

  @override
  String get txExportedToast =>
      'Ledger CSV exported (with BOM, opens directly in Excel)';

  @override
  String get txAccountLabel => 'Account';

  @override
  String get txAccountPayFrom => 'Paying account';

  @override
  String get txAccountDeposit => 'Deposit account';

  @override
  String get txAccountTransferFrom => 'Transfer from';

  @override
  String get txAccountTransferTo => 'Transfer to';

  @override
  String get txAccountRepayCard => 'Card to repay';

  @override
  String get txAccountRepayFrom => 'Repay from';

  @override
  String get txAccountLoan => 'Loan account';

  @override
  String get txAccountBorrowTo => 'Borrow into';

  @override
  String get txAccountBorrowToAsset => 'Borrow into (asset account)';

  @override
  String get txAccountLendReceivable => 'Lend (as receivable)';

  @override
  String get txAccountReceiveBackTo => 'Receive back into';

  @override
  String get txAccountCounterpartyCash => 'Counterparty cash account';

  @override
  String get txAccountB => 'Account B';

  @override
  String get txInterestCategory => 'Interest category';

  @override
  String get txCategory => 'Category';

  @override
  String get txNoteOptional => 'Note (optional)';

  @override
  String get txVoidedBadge => 'Voided';

  @override
  String get txPostingsTitle => 'Entries (debits = credits)';

  @override
  String txShares(String q) {
    return '$q shares';
  }

  @override
  String txExternalId(String id) {
    return 'External ID: $id';
  }

  @override
  String get txVoidConfirmTitle => 'Void this transaction?';

  @override
  String get txVoidConfirmMessage =>
      'Voided entries no longer count toward balances or statistics, but the audit trail is kept.';

  @override
  String get monthExpense => 'Expenses this month';

  @override
  String get monthIncome => 'Income this month';

  @override
  String get monthSurplus => 'Surplus this month';

  @override
  String get monthThis => 'This month';

  @override
  String get monthSpent => 'Spent';

  @override
  String get monthCnyOnlyTooltip =>
      'CNY transactions only, to avoid distorted mixed-currency totals';

  @override
  String get filterPanelHint =>
      'Filter the ledger by transaction type; search is unaffected';

  @override
  String get importTitle => 'Import statements';

  @override
  String get importFileTypeBills => 'Statements';

  @override
  String importStepHeader(num n, String title) {
    return 'Step $n/4 · $title';
  }

  @override
  String get importStepPickFile => 'Choose file';

  @override
  String get importStepChooseAccount => 'Choose account';

  @override
  String get importStepPreview => 'Preview & categories';

  @override
  String get importStepDone => 'Done';

  @override
  String get importParsePreview => 'Parse & preview';

  @override
  String get importConfirm => 'Post to ledger';

  @override
  String get importPickFileHint =>
      'WeChat / Alipay native exports (CSV, GBK or UTF-8) are recognized automatically by column names and transaction IDs, so no header edits are needed. Other CSV files must include date, type and amount columns.';

  @override
  String get importChooseCsvFile => 'Choose CSV file';

  @override
  String importParseFailed(String error) {
    return 'Parse failed: $error';
  }

  @override
  String get importTargetAccount => 'Which account to import into';

  @override
  String importFileName(String file) {
    return 'File: $file';
  }

  @override
  String importRowsDetected(num n) {
    return '$n rows detected';
  }

  @override
  String get importDefaultExpenseCategory => 'Default expense category';

  @override
  String get importDefaultIncomeCategory => 'Default income category';

  @override
  String get importReadyToPost => 'Ready to post';

  @override
  String importLineCount(num n) {
    return '$n rows';
  }

  @override
  String get importExactDuplicates => 'Exact duplicates skipped';

  @override
  String get importCategoryHits => 'Smart categorization hits';

  @override
  String importCategoryHitsDetail(num n) {
    return '$n rows (rules + learned history)';
  }

  @override
  String get importParserSkipped => 'Skipped by native parser';

  @override
  String get importTransferSuggestions => 'Transfer pair suggestions';

  @override
  String importTransferSuggestionDetail(num n) {
    return '$n items (merge manually on the ledger page after import)';
  }

  @override
  String get importNoCounterparty => '(no counterparty)';

  @override
  String importPostedCount(num n) {
    return '$n entries posted';
  }

  @override
  String get importDoneHint =>
      'Re-importing the same file is skipped automatically (external ID idempotency). Counterparty categories have been learned and will be suggested on the next import.';

  @override
  String get strategyCompareTitle => 'Repayment strategy comparison';

  @override
  String get strategySubtitle =>
      'Beyond the minimum payment, commit extra money each month to one debt first';

  @override
  String get strategyExtraMonthly => 'Extra monthly payment';

  @override
  String get strategyResimulate => 'Re-run simulation';

  @override
  String get strategyNoDebt => 'No outstanding debt';

  @override
  String get strategyAvalancheTitle => 'Avalanche · highest rate first';

  @override
  String get strategySnowballTitle => 'Snowball · smallest balance first';

  @override
  String strategyAvalancheSaves(String amount) {
    return 'Avalanche saves $amount in interest versus snowball. If the quick win of clearing one debt first matters to you, snowball is a perfectly sound choice.';
  }

  @override
  String get strategyPayoffTime => 'Debt-free in';

  @override
  String strategyDuration(num years, num months) {
    return '$years yr $months mo';
  }

  @override
  String get strategyTotalInterest => 'Total interest';

  @override
  String get strategyPayoffOrder => 'Payoff order';

  @override
  String get debtPageTitle => 'Debts';

  @override
  String get debtStrategyTooltip => 'Avalanche vs snowball';

  @override
  String get debtNew => 'New debt';

  @override
  String get debtEmptyTitle => 'No debts yet';

  @override
  String get debtEmptyHint =>
      'Register credit cards, mortgages, Huabei and other debts to see repayment plans and stress simulations.';

  @override
  String get debtOverviewTitle => 'Debt overview';

  @override
  String get debtTotalBase => 'Total debt (base currency)';

  @override
  String get debtTotalBaseTooltip =>
      'Summed in base currency at the latest ledger FX rate; foreign currencies without a rate count as zero';

  @override
  String get debtCountLabel => 'Items';

  @override
  String debtCountValue(num n) {
    return '$n items';
  }

  @override
  String get debtWorstApr => 'Highest effective APR';

  @override
  String get debtWorstAprTooltip =>
      'IRR-based; fee-driven debts run well above the nominal rate';

  @override
  String get debtRepayMethod => 'Repayment method';

  @override
  String get debtNominalApr => 'Nominal APR';

  @override
  String get debtNominalAprField => 'Nominal APR % (e.g. 3.85)';

  @override
  String get debtTermLabel => 'Installments';

  @override
  String debtTermCount(num n) {
    return '$n installments';
  }

  @override
  String get debtTermMonthsField => 'Term (months)';

  @override
  String get debtEffectiveApr => 'Effective APR';

  @override
  String get debtEffectiveAprTooltip =>
      'IRR-based; fee-driven debts run notably higher';

  @override
  String debtNextRepay(
    num month,
    num day,
    String total,
    String principal,
    String interest,
  ) {
    return 'Next $month/$day: pay $total (principal $principal + interest $interest)';
  }

  @override
  String get debtRepayNext => 'Pay next installment';

  @override
  String get debtPrepaySim => 'Prepayment simulator';

  @override
  String get debtNoScheduleSnackBar => 'No installment due (or a manual plan)';

  @override
  String debtPrepaySimTitle(String name) {
    return 'Prepayment simulator · $name';
  }

  @override
  String debtRemainingPrincipal(String amount) {
    return 'Current remaining principal $amount';
  }

  @override
  String get debtExtraPayment => 'Extra payment';

  @override
  String get debtSimulate => 'Simulate';

  @override
  String get debtSimResultTitle => 'Simulation result';

  @override
  String debtSimFee(String fee) {
    return 'Fee: $fee';
  }

  @override
  String debtSimInterestSaved(String saved) {
    return 'Interest saved: $saved';
  }

  @override
  String debtSimRemaining(num n) {
    return 'Installments remaining: $n';
  }

  @override
  String debtSimMonthsSaved(num n) {
    return ' ($n fewer)';
  }

  @override
  String get debtNameField => 'Name';

  @override
  String get debtPrincipal => 'Principal';

  @override
  String get debtStartDate => 'Start date';

  @override
  String get wdgCancel => 'Cancel';

  @override
  String get wdgConfirm => 'Confirm';

  @override
  String get wdgSave => 'Save';

  @override
  String get wdgDelete => 'Delete';

  @override
  String wdgLoadFailed(String e) {
    return 'Failed to load: $e';
  }

  @override
  String get wdgBack => 'Back';

  @override
  String get wdgAmount => 'Amount';

  @override
  String get wdgDate => 'Date';

  @override
  String get wdgCloseEsc => 'Close (Esc)';

  @override
  String get wdgDialogBarrier => 'Close dialog';

  @override
  String get wdgSheetBarrier => 'Close panel';

  @override
  String get wdgMinimize => 'Minimize';

  @override
  String get wdgRestoreDown => 'Restore down';

  @override
  String get wdgMaximize => 'Maximize';

  @override
  String get wdgClose => 'Close';

  @override
  String wdgDeltaWithPercent(String amount, String arrow, String pct) {
    return '$amount ($arrow $pct%)';
  }

  @override
  String get budgetPageTitle => 'Budgets';

  @override
  String get budgetCreate => 'New budget';

  @override
  String get budgetEmptyTitle => 'No budgets yet';

  @override
  String get budgetEmptyMessage =>
      'Start with a monthly total budget, or set separate limits for categories like dining and shopping — Home will project whether the month ends over budget at your current pace.';

  @override
  String get budgetMonthTitle => 'Budget this month';

  @override
  String get budgetOverspentHero => 'Over budget';

  @override
  String get budgetRemainingHero => 'Left to spend';

  @override
  String get budgetTotalLimit => 'Total limit';

  @override
  String get budgetSpent => 'Spent';

  @override
  String get budgetOverEnvelopes => 'Over-budget envelopes';

  @override
  String budgetEnvelopeCount(num n) {
    return '$n';
  }

  @override
  String budgetTotalUsagePct(String v) {
    return 'Total used $v%';
  }

  @override
  String get budgetMonthTotalLimit => 'Month total limit';

  @override
  String get budgetRemaining => 'Remaining';

  @override
  String budgetOverAmount(String amount) {
    return 'Over $amount';
  }

  @override
  String budgetRemainingAmount(String amount) {
    return 'Left $amount';
  }

  @override
  String get budgetEnvelopeActions => 'Envelope actions';

  @override
  String get budgetDelete => 'Delete budget';

  @override
  String get budgetLimit => 'Limit';

  @override
  String get budgetPlanned => 'Planned';

  @override
  String get budgetPlannedTooltip =>
      'Amount from upcoming plans that will land in this envelope';

  @override
  String get budgetDeleteConfirmTitle => 'Delete budget?';

  @override
  String budgetDeleteConfirmMessage(String name) {
    return 'The limit record for \"$name\" will be deleted; spending that already happened is unaffected.';
  }

  @override
  String budgetForecastExceed(String projected, String over) {
    return 'At this pace you\'ll spend $projected by month end ($over over)';
  }

  @override
  String budgetForecastOk(String projected, String daily) {
    return 'At this pace you\'ll spend about $projected by month end; $daily per day left';
  }

  @override
  String get budgetMonthlyTotalName => 'Monthly total budget';

  @override
  String get budgetCategoryBudget => 'Category budget';

  @override
  String get budgetScopeTotal => 'Total budget';

  @override
  String get budgetCategoryField => 'Category';

  @override
  String get budgetMonthlyLimitField => 'Monthly limit (¥)';

  @override
  String get budgetNameOptionalField => 'Name (optional)';

  @override
  String get goalsPageTitle => 'Goals & reserves';

  @override
  String get goalNew => 'New goal';

  @override
  String get goalEmptyTitle => 'No goals yet';

  @override
  String get goalEmptyMessage =>
      'Set money aside ahead of big expenses with goals: travel, insurance premiums, tuition, gear…';

  @override
  String get goalSummaryTitle => 'All goals';

  @override
  String get goalSummaryHint =>
      'An overview of reserves set aside for large upcoming expenses';

  @override
  String get goalReserved => 'Reserved';

  @override
  String get goalTotalTarget => 'Total target';

  @override
  String get goalTotalGap => 'Total gap';

  @override
  String get goalCount => 'Goals';

  @override
  String goalItems(num n) {
    return '$n';
  }

  @override
  String get goalActions => 'Goal actions';

  @override
  String get goalAddReserve => 'Add reserve';

  @override
  String get goalDelete => 'Delete goal';

  @override
  String get goalTarget => 'Target';

  @override
  String get goalGap => 'Gap';

  @override
  String get goalMonthlyNeed => 'Monthly need';

  @override
  String get goalMonthlyNeedTooltip =>
      'Target date passed or goal fully funded — nothing more to set aside';

  @override
  String goalDaysLeft(num n) {
    return '$n days left';
  }

  @override
  String goalOverdueBy(num n) {
    return 'Overdue by $n days';
  }

  @override
  String get goalDeleteConfirmTitle => 'Delete goal?';

  @override
  String goalDeleteConfirmMessage(String name) {
    return 'Reserve records for \"$name\" will be deleted; transfers already made are unaffected.';
  }

  @override
  String goalReserveTitle(String name) {
    return 'Add reserve for \"$name\"';
  }

  @override
  String get goalNameField => 'Name';

  @override
  String get goalAmountField => 'Target amount';

  @override
  String get goalDateField => 'Target date';

  @override
  String get lockOpeningLedger => 'Opening encrypted ledger…';

  @override
  String get lockWelcome => 'Welcome to AssetScope';

  @override
  String lockOpenFailed(String e) {
    return 'Failed to open: $e';
  }

  @override
  String lockCreateFailed(String e) {
    return 'Failed to create: $e';
  }

  @override
  String get lockPassphraseRule =>
      'Master passphrase must be at least 8 characters; 12 or more as a passphrase is recommended';

  @override
  String get lockPassMismatch => 'The two entries do not match';

  @override
  String get lockWeakPassphrase =>
      'Passphrase too weak: make it longer or mix character types';

  @override
  String get lockEnterPrompt => 'Enter your master passphrase or recovery code';

  @override
  String get lockWrongCredential =>
      'Incorrect master passphrase or recovery code';

  @override
  String lockUnlockFailed(String e) {
    return 'Failed to unlock: $e';
  }

  @override
  String get lockUnlocking => 'Unlocking encrypted ledger…';

  @override
  String get lockUnlocked => 'Unlocked';

  @override
  String get lockSaveRecoveryTitle => 'Save your recovery code offline';

  @override
  String get lockRecoveryIntro =>
      'The recovery code is your only way back in if you lose the master passphrase. Write it down somewhere safe (do not photograph it or store it in the cloud).';

  @override
  String get lockRecoverySaved => 'I\'ve saved it — open my ledger';

  @override
  String get lockCreateHint =>
      'Create an encrypted ledger: set a master passphrase (8+ characters)';

  @override
  String get lockPassphraseTooltip =>
      'The master passphrase derives the key that encrypts all your data. It cannot be recovered — only the recovery code can save you';

  @override
  String get lockRepeatPassphrase => 'Re-enter the master passphrase';

  @override
  String get lockUnlockHint => 'Master passphrase or recovery code';

  @override
  String get lockRecoveryNotice =>
      'You can also unlock directly with the recovery code';

  @override
  String get lockForgotPassphrase =>
      'Forgot the passphrase? Use the recovery code';

  @override
  String get shellCollapseMenu => 'Collapse category menu';

  @override
  String get shellExpandMenu => 'Expand category menu';

  @override
  String get shellMenuLabel => 'Category menu';

  @override
  String get shellNavTitle => 'Categories';

  @override
  String get shellPinnedTip => 'Pinned: menu stays open';

  @override
  String get shellUnpinnedTip => 'Unpinned: collapses after navigation';

  @override
  String get globeRestorePage => 'Restore page';

  @override
  String get globeClearScreen => 'Clear the deck: globe only';

  @override
  String ovMonths(num n) {
    return 'Last $n mo';
  }

  @override
  String get ovTrGoReport => 'Open monthly attribution';

  @override
  String get ovNwTitle => 'Net worth';

  @override
  String get ovNwHint => 'Assets, structure and account changes at a glance.';

  @override
  String get ovNwMonthDelta => 'vs last month';

  @override
  String ovNwCoverage(num n, num m) {
    return 'Valuation coverage $n/$m';
  }

  @override
  String get ovNwCoverageHint =>
      'Accounts with a current valuation among those included in net worth. Missing ones count as zero and are flagged.';

  @override
  String get ovNwGlobe => 'Global asset map';

  @override
  String get ovNwGlobeHint =>
      'Geotagged assets glow on the globe; drag to rotate, scroll to zoom, tap a marker for details.';

  @override
  String ovNwLocatedNote(num n, num m) {
    return '$n located · $m unmapped';
  }

  @override
  String get ovNwAssetTypes => 'Asset mix';

  @override
  String get ovNwAssetTypesHint =>
      'Grouped by business class: cash, holdings, steady wealth, long-term assets.';

  @override
  String get ovNwGroupCash => 'Cash & demand';

  @override
  String get ovNwGroupHold => 'Investment holdings';

  @override
  String get ovNwGroupSteady => 'Steady wealth';

  @override
  String get ovNwGroupLong => 'Long-term assets';

  @override
  String get ovNwNoAssets => 'No assets yet';

  @override
  String get ovNwNoAssetsMsg =>
      'Add your first asset from the home page to light up the globe.';

  @override
  String get ovNwGroupTitle => 'Account distribution';

  @override
  String get ovNwGroupHint => 'Asset share by business group.';

  @override
  String get ovNwTopAccounts => 'Top accounts';

  @override
  String get ovNwViewAll => 'All assets';

  @override
  String get ovNwMissingHint =>
      'Missing a current valuation; counted as zero for now.';

  @override
  String get ovNwTrendEmpty => 'Trend pending';

  @override
  String get ovNwTrendEmptyMsg =>
      'The curve appears after one full month of ledger data.';

  @override
  String get ovNwAttribution => 'This month\'s attribution';

  @override
  String get ovNwAttributionHint =>
      'Net-worth change split into cash flow, investment, FX and other valuations; unexplained parts go to residual.';

  @override
  String get ovNwNetChange => 'Net change';

  @override
  String get ovNwAttrIncomeExpense => 'Income − expense';

  @override
  String get ovNwAttrIncomeHint =>
      'Regular income minus regular spending (transfers and trades excluded).';

  @override
  String get ovNwAttrInvest => 'Investment P&L';

  @override
  String get ovNwAttrInvestHint =>
      'Realized P&L + dividends + change in unrealized P&L.';

  @override
  String get ovNwAttrFx => 'FX effect';

  @override
  String get ovNwAttrFxHint =>
      'Revaluation of foreign-currency positions and conversion P&L.';

  @override
  String get ovNwAttrOther => 'Other valuations';

  @override
  String get ovNwAttrOtherHint =>
      'Manual valuations (property etc.) change over the month.';

  @override
  String get ovNwAttrCorrection => 'Corrections';

  @override
  String get ovNwAttrCorrectionHint =>
      'Equity-account adjustments such as historical corrections.';

  @override
  String get ovNwAttrResidual => 'Residual';

  @override
  String get ovCfTitle => 'Monthly cash flow';

  @override
  String get ovCfHint =>
      'Every cash flow, spending structure and budget in one place.';

  @override
  String get ovCfIncomeHint =>
      'Aggregated by income accounts; investment P&L is disclosed in attribution.';

  @override
  String get ovCfExpenseHint =>
      'Actual spending and fees; card purchases count in-month.';

  @override
  String get ovCfSurplusHint =>
      'Income minus spending. Transfers are neither; buying assets is not spending.';

  @override
  String get ovCfDailyTitle => 'Daily cash flow';

  @override
  String get ovCfDailyHint =>
      'Bars are daily income/spending; the bright line is cumulative net. Hover for details.';

  @override
  String get ovCfNetLine => 'Cumulative net';

  @override
  String get ovCfExpenseCatTitle => 'Spending by category';

  @override
  String get ovCfExpenseCatHint => 'Aggregated by expense accounts.';

  @override
  String get ovCfOthers => 'Others';

  @override
  String get ovCfNoExpense => 'No spending this month';

  @override
  String get ovCfMonthExpense => 'Month spend';

  @override
  String get ovCfIncomeTitle => 'Income sources';

  @override
  String get ovCfNoIncome => 'No income this month';

  @override
  String get ovCfBudgetTitle => 'Budget execution';

  @override
  String get ovCfBudgetHint => 'Monthly total budget vs actual spending.';

  @override
  String get ovCfNoBudget => 'No budget set';

  @override
  String get ovCfNoBudgetMsg => 'Set a monthly budget to see execution here.';

  @override
  String ovCfBudgetOf(String x) {
    return 'Limit $x';
  }

  @override
  String get ovCfBudgetUsed => 'Used';

  @override
  String get ovCfOverBy => 'Over by';

  @override
  String get ovCfBudgetLeft => 'Left';

  @override
  String get ovCfHeatTitle => 'Cash-flow heatmap';

  @override
  String get ovCfHeatHint =>
      'Darker means larger: blue = net-in day, red = net-out day.';

  @override
  String get ovCfRecentTitle => 'Recent transactions';

  @override
  String get ovCfRecentHint =>
      'Latest transactions this month; tap for details.';

  @override
  String get ovCfNoTx => 'No transactions';

  @override
  String get ovCfUntitled => 'Untitled';

  @override
  String get ovHlTitle => 'Financial health';

  @override
  String get ovHlHint =>
      'A health check across saving, emergency fund, leverage and fixed-cost coverage.';

  @override
  String get ovHlTargetSave => 'Target ≥ 30%';

  @override
  String get ovHlTargetEmergency => 'Target ≥ 6 months';

  @override
  String get ovHlTargetLeverage => 'Target ≤ 50%';

  @override
  String get ovHlTargetCushion => 'Target ≥ 100%';

  @override
  String get ovHlCushion => 'Fixed-cost cover';

  @override
  String get ovHlCushionHint =>
      'How much of fixed costs are covered by fixed income at month end.';

  @override
  String get ovHlScoreTitle => 'Health score';

  @override
  String get ovHlScoreHint =>
      'Average of available metrics normalized to their target bands; shows honestly when data is insufficient.';

  @override
  String get ovHlNoScore => 'Not scoreable';

  @override
  String get ovHlExcellent => 'Excellent';

  @override
  String get ovHlGood => 'Good';

  @override
  String get ovHlAttention => 'Watch';

  @override
  String get ovHlRisk => 'At risk';

  @override
  String ovHlMissing(String x) {
    return 'Missing data: $x';
  }

  @override
  String ovHlScoreNote(num n) {
    return 'From $n real metrics';
  }

  @override
  String get ovHlOrbitTitle => 'Dimension orbit';

  @override
  String get ovHlOrbitHint =>
      'Four dimension stars orbit the score; color encodes status: blue=ok, amber=watch, red=risk.';

  @override
  String get ovHlRadarTitle => 'Target radar';

  @override
  String get ovHlRadarHint => 'Current values (blue) vs target band (amber).';

  @override
  String get ovHlCurrent => 'Current';

  @override
  String get ovHlTarget => 'Target';

  @override
  String get ovHlPace => 'Spending pace';

  @override
  String ovHlPaceDays(num n) {
    return '$n days in';
  }

  @override
  String get ovHlCoverage => 'Valuation coverage';

  @override
  String get ovHlCoverageSub => 'covered accounts';

  @override
  String get ovHlDiagTitle => 'Diagnosis';

  @override
  String get ovHlDiagHint =>
      'Auto-bucketed by score: ≥75% strength, 40–75% to improve, <40% risk.';

  @override
  String get ovHlDiagValuation => 'valuation gaps';

  @override
  String get ovHlDiagGood => 'Strengths';

  @override
  String get ovHlDiagRisk => 'Risks';

  @override
  String get ovHlDiagImprove => 'To improve';

  @override
  String get ovHlDiagEmpty => 'Not enough data yet — keep the ledger going.';

  @override
  String get ovHlDiagNone => '—';

  @override
  String get ovHlActTitle => 'Actions';

  @override
  String get ovHlActHint =>
      'Sorted by weakest dimension; each links to the right page.';

  @override
  String ovHlActValuation(num n) {
    return 'Fix $n valuations';
  }

  @override
  String get ovHlActValuationSub => 'Missing valuations distort net worth';

  @override
  String get ovHlActSave => 'Raise your savings rate';

  @override
  String get ovHlActSaveSub => 'Set a budget and pay yourself first';

  @override
  String get ovHlActEmergency => 'Build the emergency fund';

  @override
  String get ovHlActEmergencySub => 'Target: 6 months of essentials';

  @override
  String get ovHlActLeverage => 'Reduce leverage';

  @override
  String get ovHlActLeverageSub => 'Pay high-interest debts first';

  @override
  String get ovHlActCushion => 'Balance fixed flows';

  @override
  String get ovHlActCushionSub => 'Review recurring plans and repayments';

  @override
  String get ovHlActEmpty => 'All dimensions on track. Keep it up.';

  @override
  String get ovHlActGo => 'Take action';

  @override
  String get ovBsTitle => 'Balance sheet';

  @override
  String get ovBsHint =>
      'A professional view of assets, liabilities and structure.';

  @override
  String get ovBsAssetsHint => 'Base-currency total of all asset accounts.';

  @override
  String get ovBsLiabHint => 'Base-currency total of all liability accounts.';

  @override
  String get ovBsScaleTitle => 'The balance';

  @override
  String get ovBsScaleHint =>
      'Beam tilt mirrors the debt ratio; level at 50%. Visual only, not a calculation.';

  @override
  String get ovBsTreemapTitle => 'Asset treemap';

  @override
  String get ovBsTreemapHint =>
      'Area = share of total; tap a block to inspect.';

  @override
  String get ovBsAssetTableTitle => 'Asset classes';

  @override
  String get ovBsAssetTableHint => 'By asset subtype; delta vs month start.';

  @override
  String get ovBsColClass => 'Class';

  @override
  String get ovBsColAmount => 'Amount';

  @override
  String get ovBsColShare => 'Share';

  @override
  String get ovBsColDelta => 'Δ';

  @override
  String get ovBsLiabTableTitle => 'Liabilities';

  @override
  String get ovBsLiabTableHint => 'By liability subtype.';

  @override
  String get ovBsNoDebt => 'Debt free';

  @override
  String get ovBsNoDebtMsg => 'No liability accounts right now.';

  @override
  String get ovBsLiquidityTitle => 'Liquidity';

  @override
  String get ovBsLiquidityHint => 'By days to liquidate: ≤1d, ≤90d, >90d.';

  @override
  String get ovBsLiquidNow => 'On demand';

  @override
  String get ovBsLiquidMid => 'Within 90 days';

  @override
  String get ovBsLiquidLong => 'Long term';

  @override
  String get ovBsLiabMixTitle => 'Liability mix';

  @override
  String get ovBsLiabMixHint => 'Share by liability subtype.';

  @override
  String get ovBsDualTitle => 'Assets vs liabilities';

  @override
  String get ovBsDualHint => 'Twelve months side by side.';

  @override
  String ovSpTitle(num n) {
    return 'Safe to spend (${n}d)';
  }

  @override
  String get ovSpHint =>
      'How much you can safely spend after reserves and known obligations.';

  @override
  String ovSpHeroTitle(num n) {
    return 'Discretionary · ${n}d';
  }

  @override
  String get ovSpHeroHint =>
      'Discretionary = min over days of (cash − reserve − floor); not your whole net worth.';

  @override
  String get ovSpHeroOk => 'Ceiling for unplanned spending';

  @override
  String get ovSpHeroZero =>
      'Plans already touch the safety line — no slack left';

  @override
  String get ovSpCashNow => 'Liquid cash now';

  @override
  String get ovSpPlannedOut => 'Known outflows';

  @override
  String get ovSpReserved => 'Reserved (goals+floor)';

  @override
  String get ovSpRemain => 'Discretionary';

  @override
  String get ovSpScenTitle => 'Scenarios';

  @override
  String get ovSpScenHint =>
      'Same starting cash and reserves; only the event stream changes.';

  @override
  String get ovSpScenConservative => 'Conservative';

  @override
  String get ovSpScenConsSub => 'Confirmed income only';

  @override
  String get ovSpScenStandard => 'Standard';

  @override
  String get ovSpScenStdSub => 'Same as home forecast';

  @override
  String get ovSpScenOptimistic => 'Optimistic';

  @override
  String get ovSpScenOptSub => 'Flexible estimates excluded';

  @override
  String ovSpKpiSafe(num n) {
    return 'Safe to spend (${n}d)';
  }

  @override
  String get ovSpKpiMonthCap => 'Suggested monthly cap';

  @override
  String ovSpKpiMonthCapHint(num n) {
    return 'Discretionary prorated over $n days.';
  }

  @override
  String get ovSpKpiDaily => 'Daily allowance';

  @override
  String ovSpKpiDailyHint(num n) {
    return 'Discretionary ÷ $n days.';
  }

  @override
  String get ovSpKpiLow => 'Cash low point';

  @override
  String get ovSpKpiLowHint => 'No outflow events in the horizon.';

  @override
  String ovSpKpiLowAt(String x) {
    return 'Bottoms on $x';
  }

  @override
  String ovSpFcTitle(num n) {
    return '$n-day cash forecast';
  }

  @override
  String get ovSpFcHint =>
      'Line = daily cash; dashes = safety floor (reserve+baseline); red dots = shortfall days.';

  @override
  String get ovSpFloorLabel => 'Safety floor';

  @override
  String get ovSpFlowTitle => 'In & out';

  @override
  String get ovSpFlowHint => 'All cash events in the horizon (base currency).';

  @override
  String get ovSpFlowIn => 'Expected in';

  @override
  String get ovSpFlowOut => 'Expected out';

  @override
  String get ovSpFlowNet => 'Net flow';

  @override
  String get ovSpFlowPlanned => 'Planned spending';

  @override
  String get ovSpFlowDebt => 'Debt repayment';

  @override
  String get ovSpFlowBudget => 'Budget baseline';

  @override
  String get ovSpFlowIncome => 'Expected income';

  @override
  String get ovSpFlowOther => 'Other';

  @override
  String get ovSpMonthTitle => 'Monthly allocation';

  @override
  String get ovSpMonthHint =>
      'Blue = planned outflow; gold = suggested cap (planned + prorated discretionary).';

  @override
  String get ovSpMonthPlanned => 'Planned';

  @override
  String get ovSpMonthCap => 'Cap';

  @override
  String get ovSpCalTitle => 'Spending calendar';

  @override
  String get ovSpCalHint =>
      'Outflow intensity; red dots mark forecast shortfalls.';

  @override
  String ovSpCalDay(String x) {
    return 'out $x';
  }

  @override
  String get ovSpCalShortfall => 'shortfall';

  @override
  String get ovSpRiskTitle => 'Risks & advice';

  @override
  String get ovSpRiskHint =>
      'Shortfalls come from the replay; advice is rule-based.';

  @override
  String ovSpRiskNone(num n) {
    return 'No shortfall forecast in the next $n days.';
  }

  @override
  String get ovSpAdviceTitle => 'Advice';

  @override
  String ovSpAdviceScenario(String x) {
    return 'Plan on the conservative scenario: confirmed income only, discretionary $x.';
  }

  @override
  String get ovSpAdviceZero =>
      'Zero discretionary: trim planned spending or top up cash first.';

  @override
  String get ovSpAdviceReconcile =>
      'Keep the ledger and valuations fresh for a trustworthy forecast.';

  @override
  String get ovTrTitle => 'Net-worth trend';

  @override
  String get ovTrHint => 'History, one series at the center.';

  @override
  String get ovTrCurrent => 'Current';

  @override
  String get ovTrChange => 'Period change';

  @override
  String ovTrChangeHint(String a, String b) {
    return 'Change from $a to $b.';
  }

  @override
  String get ovTrGrowth => 'Growth rate';

  @override
  String get ovTrGrowthHint => 'Change over the absolute starting value.';

  @override
  String get ovTrMax => 'Peak';

  @override
  String get ovTrMin => 'Trough';

  @override
  String get ovTrChartTitle => 'The big chart';

  @override
  String get ovTrAll => 'All';

  @override
  String get ovTrInsightTitle => 'Key insights';

  @override
  String get ovTrInsightHint =>
      'Derived from the real series; growth is never assumed.';

  @override
  String ovTrStreak(num n) {
    return '$n-month streak';
  }

  @override
  String get ovTrStreakSub => 'rising month over month';

  @override
  String ovTrBigMove(String m, String x) {
    return 'Biggest monthly move: $m ($x)';
  }

  @override
  String ovTrMilestone(num n, String m) {
    return 'Next round milestone in $n months ($m)';
  }

  @override
  String ovTrMilestoneSub(String x) {
    return 'Theil–Sen trend: $x per month';
  }

  @override
  String get ovTrAttributionGo =>
      'For this month, see the waterfall and the report.';

  @override
  String get ovTrWfStart => 'Start';

  @override
  String get ovTrWfEnd => 'End';

  @override
  String get ovTrWfTitle => 'Attribution waterfall';

  @override
  String get ovUpTitle => 'Next 30 days';

  @override
  String get ovUpHint => 'Bills and planned spending ahead.';

  @override
  String get ovUpPlanned30 => 'Planned in 30d';

  @override
  String get ovUpPlannedHint => 'Planned outflows not yet posted.';

  @override
  String get ovUpDue7 => 'Due in 7d';

  @override
  String get ovUpDue7Hint => 'Outflows due within seven days.';

  @override
  String get ovUpOverdue => 'Overdue';

  @override
  String get ovUpOverdueHint => 'Due occurrences not yet posted.';

  @override
  String get ovUpNone => 'None';

  @override
  String get ovUpRecurring => 'Recurring';

  @override
  String get ovUpRecurringHint => 'Active recurring events.';

  @override
  String get ovUpCalTitle => 'Bill calendar';

  @override
  String get ovUpCalHint =>
      'Today in steel; within 3 days amber; overdue red; posted green. Tap a day for details.';

  @override
  String get ovUpModeCal => 'Calendar';

  @override
  String get ovUpModeTimeline => 'Timeline';

  @override
  String ovUpItemCount(num n) {
    return '$n items';
  }

  @override
  String get ovUpDueTitle => 'Due soon';

  @override
  String get ovUpDueHint => 'Sorted by date; status: pending/overdue/posted.';

  @override
  String get ovUpAllSettled => 'Nothing pending in the next 30 days';

  @override
  String get ovUpGoPost => 'Post bills in Plans';

  @override
  String get ovUpFixedTitle => 'Recurring items';

  @override
  String get ovUpFixedHint => 'Recurring events and their next date.';

  @override
  String get ovUpNoFixed => 'No recurring plans';

  @override
  String ovUpNextAt(String x) {
    return 'next $x';
  }

  @override
  String get ovUpWeekTitle => 'Weekly outflows';

  @override
  String get ovUpWeekHint => 'Planned outflow per week; current week in amber.';

  @override
  String ovUpWeekLabel(num n) {
    return 'W$n';
  }

  @override
  String get ovIxTitle => 'Task center';

  @override
  String get ovIxHint =>
      'One place for valuation gaps, due plans, reconciliation and cash alerts.';

  @override
  String get ovIxStatHigh => 'High priority';

  @override
  String get ovIxStatMissing => 'Missing values';

  @override
  String get ovIxStatStale => 'Stale values';

  @override
  String get ovIxStatReconcile => 'Reconcile & alerts';

  @override
  String get ovIxTableTitle => 'Tasks';

  @override
  String get ovIxTableHint =>
      'All from real records; done items disappear by themselves.';

  @override
  String get ovIxFilterAll => 'All';

  @override
  String get ovIxFilterUrgent => 'Urgent';

  @override
  String get ovIxFilterToday => 'Today';

  @override
  String get ovIxFilterWeek => 'This week';

  @override
  String get ovIxColTask => 'Task';

  @override
  String get ovIxColType => 'Type';

  @override
  String get ovIxColPriority => 'Priority';

  @override
  String get ovIxColDue => 'Due';

  @override
  String get ovIxNoMatch => 'No tasks under this filter';

  @override
  String get ovIxTypeDue => 'Due plan';

  @override
  String get ovIxTypeMissing => 'Missing value';

  @override
  String get ovIxTypeStale => 'Stale value';

  @override
  String get ovIxTypeResidual => 'Residual';

  @override
  String get ovIxTypeShortfall => 'Cash alert';

  @override
  String get ovIxPriorityHigh => 'High';

  @override
  String get ovIxPriorityMedium => 'Med';

  @override
  String get ovIxPriorityLow => 'Low';

  @override
  String ovIxResidualTask(String x) {
    return 'Attribution residual $x to reconcile';
  }

  @override
  String get ovIxAction => 'Open the related page to resolve';

  @override
  String get ovIxGo => 'Go';

  @override
  String get ovIxQuickTitle => 'Quick actions';

  @override
  String get ovIxQuickHint => 'Frequent fixes.';

  @override
  String get ovIxAValuation => 'Fix valuations';

  @override
  String get ovIxAValuationSub => 'Add current values where missing';

  @override
  String get ovIxAPost => 'Post plans';

  @override
  String get ovIxAPostSub => 'Turn due plans into real transactions';

  @override
  String get ovIxALedger => 'Reconcile';

  @override
  String get ovIxALedgerSub => 'Check the ledger and residuals';

  @override
  String get ovIxASpendable => 'Cash forecast';

  @override
  String get ovIxASpendableSub => 'How much is safe to spend';

  @override
  String get ovIxTimelineTitle => 'Alert timeline';

  @override
  String get ovIxTimelineHint => 'By date and priority.';

  @override
  String get ovIxNoDue => 'No due date';

  @override
  String get ovIxEmptyTitle => 'All clear.';

  @override
  String get ovIxEmptyMsg =>
      'Values fresh, plans posted, books reconciled. Keep it up.';

  @override
  String get settingsRelNow => 'Just now';

  @override
  String settingsRelMin(num n) {
    return '$n min ago';
  }

  @override
  String settingsRelHour(num n) {
    return '$n h ago';
  }

  @override
  String settingsRelDay(num n) {
    return '$n d ago';
  }

  @override
  String get settingsSecHeroHint =>
      'A security overview of encryption, passphrase and recovery.';

  @override
  String get settingsStatLocalEncrypt => 'Local encryption';

  @override
  String get settingsStatEnabled => 'Enabled';

  @override
  String get settingsStatLocalEncryptTip =>
      'The database is encrypted on-device; keys never leave this machine.';

  @override
  String get settingsStatPassphrase => 'Master passphrase';

  @override
  String get settingsStatSet => 'Set';

  @override
  String get settingsStatPassphraseTip =>
      'Used for unlock and backup encryption.';

  @override
  String get settingsStatRecovery => 'Recovery code';

  @override
  String get settingsStatConfigured => 'Configured';

  @override
  String get settingsStatNotConfigured => 'Not configured';

  @override
  String get settingsStatRecoveryTip =>
      'How to regain access if the passphrase is lost.';

  @override
  String get settingsSessionTitle => 'Session & protection';

  @override
  String get settingsSessionHint => 'Auto-lock and startup verification.';

  @override
  String get settingsAutoLockRowHint => 'Lock automatically after being idle.';

  @override
  String get settingsStartupVerify => 'Startup verification';

  @override
  String get settingsStartupVerifyHint =>
      'Require verification when the app launches.';

  @override
  String get settingsStartupVerifyValue => 'On';

  @override
  String get settingsRecentTitle => 'Recent security activity';

  @override
  String get settingsRecentHint => 'Unlock, lock and configuration changes.';

  @override
  String get settingsEvEmpty => 'No security activity yet';

  @override
  String get settingsEvLock => 'App locked';

  @override
  String get settingsEvUnlock => 'App unlocked';

  @override
  String get settingsEvPass => 'Passphrase changed';

  @override
  String get settingsEvRecovery => 'Recovery code regenerated';

  @override
  String get settingsEvConfig => 'Security setting changed';

  @override
  String get settingsAiStatusTitle => 'AI service status';

  @override
  String get settingsAiStatusHint => 'Model and web-search setup.';

  @override
  String get settingsAiOn => 'On';

  @override
  String get settingsAiOff => 'Off';

  @override
  String get settingsAiUnconfigured => 'Not configured';

  @override
  String get settingsAiProvider => 'Provider';

  @override
  String get settingsAiModel => 'Model';

  @override
  String get settingsAiCustom => 'Custom';

  @override
  String get settingsAiWebSearch => 'Web search';

  @override
  String get settingsBkOverviewTitle => 'Backup';

  @override
  String get settingsBkOverviewHint => 'Last backup and its container.';

  @override
  String get settingsBkLastBackup => 'Last backup';

  @override
  String get settingsBkLastBackupTip => 'When the last backup succeeded.';

  @override
  String get settingsBkNever => 'Never';

  @override
  String get settingsBkContainer => 'Container';

  @override
  String get settingsBkContainerTip =>
      '.asbk encrypted container: sealed by its own backup passphrase, independent of the master passphrase.';

  @override
  String get settingsDataOverviewTitle => 'Data overview';

  @override
  String get settingsDataOverviewHint => 'The size of your ledger.';

  @override
  String get settingsDataAccounts => 'Accounts';

  @override
  String get settingsDataTxns => 'Transactions';

  @override
  String get settingsDataCurrencies => 'Currencies';

  @override
  String get settingsPrefAppearanceTitle => 'Appearance';

  @override
  String get settingsPrefAppearanceHint => 'Theme and motion preferences.';

  @override
  String get settingsPrefMoneyTitle => 'Money';

  @override
  String get settingsPrefMoneyHint => 'Base currency and rates.';

  @override
  String get settingsPrefForecastTitle => 'Forecast';

  @override
  String get settingsPrefForecastHint => 'Cash forecast horizon.';

  @override
  String get settingsAboutVersion => 'App version';

  @override
  String get settingsAboutVersionHint => 'Current app version.';

  @override
  String get settingsPageHint =>
      'Manage account security, data, system preferences and AI services.';

  @override
  String get settingsHeaderShield => 'Encrypted';

  @override
  String get settingsHeaderShieldTip =>
      'The ledger database is fully encrypted; keys are derived locally from your master passphrase and never leave this device.';

  @override
  String get settingsThemeModeLabel => 'Theme mode';
}
