import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/debt/debt_contract.dart';
import '../../domain/ledger/account.dart';
import '../../domain/ledger/transaction.dart';
import '../../domain/money/currency.dart';
import '../../domain/money/fx_rate.dart';
import '../../domain/money/money.dart';
import '../../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'debt_strategy_sheet.dart';

/// 负债页 · 合同墙：页首汇总（总负债/笔数/最高实际年化）+ 合同卡网格
/// （460 定宽）。每张合同卡：余额大字 + 合同要素行 + 下期还款 + 动作
/// 胶囊（按计划还款 / 提前还款模拟）。
class DebtsPage extends ConsumerWidget {
  const DebtsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final async = ref.watch(_debtsProvider);
    final wide = MediaQuery.sizeOf(context).width >= PageMeasure.wide;
    return PageFrame(
      title: t.debtPageTitle,
      maxWidth: wide ? AppMeasure.workbench : 980,
      actions: [
        ActionIcon(
          tooltip: t.debtStrategyTooltip,
          icon: Icons.compare_arrows,
          onTap: () => showDebtStrategySheet(context, ref),
        ),
      ],
      fab: ParticleEdge(
        band: 12,
        extendBelow: 6,
        child: FloatingActionButton.extended(
          onPressed: () async {
            final ok = await showAppDialog<bool>(
              context,
              builder: (_) => const _DebtEditDialog(),
            );
            if (ok == true) ref.invalidate(_debtsProvider);
          },
          icon: const Icon(Icons.add),
          label: Text(t.debtNew),
        ),
      ),
      child: async.when(
        loading: () => const Center(child: OrbitSpinner(size: 36)),
        error: (e, _) => ErrorPlaceholder(t.loadFailed('$e')),
        data: (data) {
          final (debts, totalBase) = data;
          if (debts.isEmpty) {
            return EmptyState(
              icon: Icons.credit_card_outlined,
              title: t.debtEmptyTitle,
              message: t.debtEmptyHint,
            );
          }
          Rational? worstApr;
          for (final d in debts) {
            final eff = d.$2.effectiveAprPercent();
            if (eff != null && (worstApr == null || eff > worstApr)) {
              worstApr = eff;
            }
          }
          final brightness = Theme.of(context).brightness;
          if (wide) {
            // 大屏工作台：左 = 总览栏，右 = 合同网格。
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 300,
                    child: SummaryPanel(
                      title: t.debtOverviewTitle,
                      heroValue: fmtMinor(totalBase, 'CNY'),
                      heroLabel: t.debtTotalBase,
                      heroColor: AppColors.negativeOf(brightness),
                      rows: [
                        SummaryRow(
                          t.debtCountLabel,
                          t.debtCountValue(debts.length),
                        ),
                        if (worstApr != null)
                          SummaryRow(
                            t.debtWorstApr,
                            _pct(worstApr),
                            color: AppColors.warnOf(brightness),
                            tooltip: t.debtWorstAprTooltip,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: PageMeasure.gutter),
                  Expanded(
                    child: CardWrap(
                      tileWidth: 460,
                      children: [
                        for (final d in debts)
                          _DebtCard(
                            account: d.$1,
                            contract: d.$2,
                            remainingMinor: d.$3,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            children: [
              StatBand(
                items: [
                  StatBandItem(
                    t.debtTotalBase,
                    fmtMinor(totalBase, 'CNY'),
                    color: AppColors.negativeOf(brightness),
                    tooltip: t.debtTotalBaseTooltip,
                  ),
                  StatBandItem(
                    t.debtCountLabel,
                    t.debtCountValue(debts.length),
                  ),
                  if (worstApr != null)
                    StatBandItem(
                      t.debtWorstApr,
                      _pct(worstApr),
                      color: AppColors.warnOf(brightness),
                      tooltip: t.debtWorstAprTooltip,
                    ),
                ],
              ),
              const SizedBox(height: 16),
              CardWrap(
                tileWidth: 460,
                children: [
                  for (final d in debts)
                    _DebtCard(
                      account: d.$1,
                      contract: d.$2,
                      remainingMinor: d.$3,
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  static String _pct(Rational r) {
    final pct = (r * Rational.fromInt(BigInt.from(100))).asDouble();
    return '${pct.toStringAsFixed(2)}%';
  }
}

final _debtsProvider =
    FutureProvider.autoDispose<(List<(Account, DebtContract, BigInt)>, BigInt)>(
      (ref) async {
        final s = sessionOf(ref.watch(vaultProvider));
        if (s == null) return (const <(Account, DebtContract, BigInt)>[], BigInt.zero);
        final accounts = await s.accounts.all();
        final contracts = await s.planning.debtContracts();
        final balances = await s.ledger.moneyBalancesAt(
          DateTime.now().add(const Duration(days: 1)),
        );
        final base = await s.statsService.baseCurrency();
        final now = DateTime.now();
        final out = <(Account, DebtContract, BigInt)>[];
        var totalBase = BigInt.zero;
        for (final a in accounts) {
          if (a.type != AccountType.liability || a.isSystem) continue;
          final c = contracts[a.id];
          final owed = -(balances[a.id] ?? BigInt.zero); // 贷方净额取正
          out.add((a, c ?? _manualContract(a.id, owed), owed));
          if (a.currencyCode == base) {
            totalBase += owed;
          } else {
            final rate = await s.meta.toBaseRate(
              ccy: a.currencyCode,
              base: base,
              onOrBefore: now,
            );
            if (rate != null) {
              totalBase += (Rational.fromInt(owed) * rate.rate).rounded();
            }
          }
        }
        return (out, totalBase);
      },
    );

DebtContract _manualContract(String accountId, BigInt owed) => DebtContract(
  liabilityAccountId: accountId,
  principalOriginalMinor: owed,
  aprPercent: Rational.zero(),
  method: RepaymentMethod.manual,
  termMonths: 0,
  startDate: DateTime.now(),
);

/// 单张合同卡。
class _DebtCard extends ConsumerWidget {
  const _DebtCard({
    required this.account,
    required this.contract,
    required this.remainingMinor,
  });

  final Account account;
  final DebtContract contract;
  final BigInt remainingMinor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schedule = contract.generateSchedule();
    final today = DateTime.now();
    DebtScheduleEntry? next;
    for (final e in schedule) {
      if (!e.dueDate.isBefore(DateTime(today.year, today.month, today.day))) {
        next = e;
        break;
      }
    }
    next ??= schedule.isEmpty ? null : schedule.last;
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);
    final eff = contract.effectiveAprPercent();
    // 底缘光尘（docs/12 §9 卡片规范）：合同卡与区块卡同一家族。
    return ParticleEdge(
      band: 22,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: AppColors.negativeOf(
                      theme.brightness,
                    ).withValues(alpha: 0.12),
                  ),
                  child: Icon(
                    Icons.credit_card,
                    size: 18,
                    color: AppColors.negativeOf(theme.brightness),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    account.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  fmtMinor(remainingMinor, account.currencyCode),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 14,
              runSpacing: 6,
              children: [
                AmountTile(
                  label: t.debtRepayMethod,
                  amount: contract.method.labelZh,
                ),
                AmountTile(
                  label: t.debtNominalApr,
                  amount: contract.aprPercent.isZero
                      ? '0'
                      : DebtsPage._pct(contract.aprPercent),
                ),
                if (contract.termMonths > 0)
                  AmountTile(
                    label: t.debtTermLabel,
                    amount: t.debtTermCount(contract.termMonths),
                  ),
                if (eff != null)
                  AmountTile(
                    label: t.debtEffectiveApr,
                    amount: '≈ ${DebtsPage._pct(eff)}',
                    color: AppColors.negativeOf(theme.brightness),
                    tooltip: t.debtEffectiveAprTooltip,
                  ),
              ],
            ),
            if (next != null) ...[
              const Divider(height: 22),
              Row(
                children: [
                  Icon(
                    Icons.event_available_outlined,
                    size: 16,
                    color: theme.hintColor,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      t.debtNextRepay(
                        next.dueDate.month,
                        next.dueDate.day,
                        fmtMinor(next.totalMinor, account.currencyCode),
                        fmtMinor(next.principalMinor, account.currencyCode),
                        fmtMinor(next.interestMinor, account.currencyCode),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () => _repayNext(context, ref, next),
                  icon: const Icon(Icons.payments_outlined, size: 17),
                  label: Text(t.debtRepayNext),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _prepay(context, ref),
                  icon: const Icon(Icons.bolt_outlined, size: 17),
                  label: Text(t.debtPrepaySim),
                ),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }

  Future<void> _repayNext(
    BuildContext context,
    WidgetRef ref,
    DebtScheduleEntry? entry,
  ) async {
    final t = AppLocalizations.of(context);
    final s = sessionOf(ref.read(vaultProvider));
    if (s == null) return;
    if (entry == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.debtNoScheduleSnackBar)),
      );
      return;
    }
    final accounts = await s.accounts.all();
    final assets = accounts
        .where((a) => a.type == AccountType.asset && !a.isSystem && !a.isHolding)
        .toList();
    if (assets.isEmpty) return;
    final asset = assets.first;
    final interestCat = accounts.firstWhere(
      (a) => a.id == 'cat:e:interest',
      orElse: () => accounts.firstWhere((a) => a.type == AccountType.expense),
    );
    await s.ledger.post(
      TxBuilders.loanRepay(
        loan: account,
        payFrom: asset,
        principalMinor: entry.principalMinor,
        interestMinor: entry.interestMinor,
        feeMinor: entry.feeMinor,
        interestCategory: interestCat,
        date: DateTime.now(),
      ),
    );
    ref.invalidate(_debtsProvider);
  }

  Future<void> _prepay(BuildContext context, WidgetRef ref) async {
    final t = AppLocalizations.of(context);
    final s = sessionOf(ref.read(vaultProvider));
    if (s == null) return;
    final ctrl = TextEditingController(text: '10000');
    final shorten = true;
    final ok = await showAppDialog<bool>(
      context,
      builder: (dctx) => AppDialog(
        title: t.debtPrepaySimTitle(account.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.debtRemainingPrincipal(
                fmtMinor(remainingMinor, account.currencyCode),
              ),
              style: Theme.of(dctx).textTheme.bodyMedium?.copyWith(
                color: Theme.of(dctx).hintColor,
              ),
            ),
            const SizedBox(height: 14),
            AppAmountField(
              controller: ctrl,
              currencyCode: account.currencyCode,
              label: t.debtExtraPayment,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dctx, false),
            child: Text(t.commonCancel),
          ),
          ParticleFilledButton(
            onPressed: () => Navigator.pop(dctx, true),
            child: Text(t.debtSimulate),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final amount = Money.parse(
      ctrl.text,
      CurrencyInfo.parse(account.currencyCode),
    ).amountMinor;
    final schedule = contract.generateSchedule();
    final result = contract.simulatePrepayment(
      afterEntrySeq: _paidCount(schedule, remainingMinor),
      extraMinor: amount,
      remainingPrincipalMinor: remainingMinor,
      shortenTerm: shorten,
    );
    if (context.mounted) {
      await showAppDialog<void>(
        context,
        builder: (dctx) => AppDialog(
          title: t.debtSimResultTitle,
          content: Text(
            '${t.debtSimFee(fmtMinor(result.prepayFeeMinor, account.currencyCode))}\n'
            '${t.debtSimInterestSaved(fmtMinor(result.interestSavedMinor, account.currencyCode))}\n'
            '${t.debtSimRemaining(result.remainingEntries.length)}'
            '${result.monthsSaved > 0 ? t.debtSimMonthsSaved(result.monthsSaved) : ''}',
          ),
          actions: [
            ParticleFilledButton(
              onPressed: () => Navigator.pop(dctx),
              child: Text(t.commonGotIt),
            ),
          ],
        ),
      );
    }
  }

  int _paidCount(List<DebtScheduleEntry> schedule, BigInt remaining) {
    // 由剩余本金反推已还期数（对标准计划成立）。
    for (var i = 0; i < schedule.length; i++) {
      if (schedule[i].remainingPrincipalMinor <= remaining) return i;
    }
    return schedule.length;
  }
}

class _DebtEditDialog extends ConsumerStatefulWidget {
  const _DebtEditDialog();

  @override
  ConsumerState<_DebtEditDialog> createState() => _DebtEditDialogState();
}

class _DebtEditDialogState extends ConsumerState<_DebtEditDialog> {
  final _name = TextEditingController();
  final _principal = TextEditingController();
  final _apr = TextEditingController(text: '0');
  final _term = TextEditingController(text: '12');
  final _start = TextEditingController(text: dateToday());
  LiabilitySubtype _subtype = LiabilitySubtype.consumerLoan;
  RepaymentMethod _method = RepaymentMethod.annuity;

  @override
  void dispose() {
    _name.dispose();
    _principal.dispose();
    _apr.dispose();
    _term.dispose();
    _start.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final s = sessionOf(ref.read(vaultProvider));
    if (s == null || _name.text.isEmpty || _principal.text.isEmpty) return;
    final start = DateTime.tryParse(_start.text) ?? DateTime.now();
    final id =
        'acc:liab:${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}';
    await s.accounts.upsert(
      Account(
        id: id,
        name: _name.text.trim(),
        type: AccountType.liability,
        liabilitySubtype: _subtype,
        currencyCode: 'CNY',
      ),
    );
    await s.planning.saveDebtContract(
      DebtContract(
        liabilityAccountId: id,
        principalOriginalMinor: Money.parse(
          _principal.text,
          CurrencyInfo.cny,
        ).amountMinor,
        aprPercent: Rational.parseDecimal(
          _apr.text.trim().isEmpty ? '0' : _apr.text.trim(),
        ),
        method: _method,
        termMonths: int.tryParse(_term.text) ?? 0,
        startDate: start,
        repaymentDay: start.day,
      ),
    );
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return AppDialog(
      title: t.debtNew,
      scroll: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ParticleTextField(
            controller: _name,
            autofocus: true,
            decoration: InputDecoration(labelText: t.debtNameField),
          ),
          const SizedBox(height: 14),
          ParticleDropdownField<LiabilitySubtype>(
            initialValue: _subtype,
            decoration: InputDecoration(labelText: t.fieldType),
            items: [
              for (final st in LiabilitySubtype.values)
                DropdownMenuItem(value: st, child: Text(st.labelZh)),
            ],
            onChanged: (v) => setState(() => _subtype = v!),
          ),
          const SizedBox(height: 14),
          ParticleDropdownField<RepaymentMethod>(
            initialValue: _method,
            decoration: InputDecoration(labelText: t.debtRepayMethod),
            items: [
              for (final m in RepaymentMethod.values)
                DropdownMenuItem(value: m, child: Text(m.labelZh)),
            ],
            onChanged: (v) => setState(() => _method = v!),
          ),
          const SizedBox(height: 14),
          AppAmountField(
            controller: _principal,
            currencyCode: 'CNY',
            label: t.debtPrincipal,
          ),
          const SizedBox(height: 14),
          ParticleTextField(
            controller: _apr,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
            decoration: InputDecoration(
              labelText: t.debtNominalAprField,
            ),
          ),
          const SizedBox(height: 14),
          ParticleTextField(
            controller: _term,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: t.debtTermMonthsField),
          ),
          const SizedBox(height: 14),
          AppDateField(controller: _start, label: t.debtStartDate),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(t.cancel),
        ),
        ParticleFilledButton(onPressed: _save, child: Text(t.commonSave)),
      ],
    );
  }
}
