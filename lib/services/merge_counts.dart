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
