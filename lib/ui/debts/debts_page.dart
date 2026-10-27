import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/debt/debt_contract.dart';
import '../../domain/ledger/account.dart';
import '../../domain/ledger/transaction.dart';
import '../../domain/money/currency.dart';
import '../../domain/money/fx_rate.dart';
import '../../domain/money/money.dart';
import '../widgets/common.dart';
import 'debt_strategy_sheet.dart';

/// 负债页：合同管理、还款计划、按计划还款（本金/利息拆分入账）、提前还款模拟。
class DebtsPage extends ConsumerWidget {
  const DebtsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_debtsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('负债'),
        actions: [
          IconButton(
            tooltip: '雪崩 vs 雪球策略对比',
            icon: const Icon(Icons.compare_arrows),
            onPressed: () => showDebtStrategySheet(context, ref),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final ok = await showDialog<bool>(
              context: context, builder: (_) => const _DebtEditDialog());
          if (ok == true) ref.invalidate(_debtsProvider);
        },
        icon: const Icon(Icons.add),
        label: const Text('新建负债'),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorPlaceholder('加载失败：$e'),
        data: (debts) => debts.isEmpty
            ? const ErrorPlaceholder('登记信用卡、房贷、花呗等负债后，这里给出还款计划与压力模拟。')
            : ListView(
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
    );
  }
}

final _debtsProvider = FutureProvider.autoDispose<
    List<(Account, DebtContract, BigInt)>>((ref) async {
  final s = sessionOf(ref.watch(vaultProvider));
  if (s == null) return const [];
  final accounts = await s.accounts.all();
  final contracts = await s.planning.debtContracts();
  final balances = await s.ledger
      .moneyBalancesAt(DateTime.now().add(const Duration(days: 1)));
  final out = <(Account, DebtContract, BigInt)>[];
  for (final a in accounts) {
    if (a.type != AccountType.liability || a.isSystem) continue;
    final c = contracts[a.id];
    final owed = -(balances[a.id] ?? BigInt.zero); // 贷方净额取正
    out.add((a, c ?? _manualContract(a.id, owed), owed));
  }
  return out;
});

DebtContract _manualContract(String accountId, BigInt owed) => DebtContract(
      liabilityAccountId: accountId,
      principalOriginalMinor: owed,
      aprPercent: Rational.zero(),
      method: RepaymentMethod.manual,
      termMonths: 0,
      startDate: DateTime.now(),
    );

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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.credit_card, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(account.name,
                        style: theme.textTheme.titleMedium)),
                Text(
                  fmtMinor(remainingMinor, account.currencyCode),
                  style: theme.textTheme.titleMedium?.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()]),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${contract.method.labelZh} · 名义年利率 ${_aprLabel(contract)}'
              '${contract.termMonths > 0 ? ' · ${contract.termMonths} 期' : ''}',
              style: theme.textTheme.bodySmall,
            ),
            if (contract.effectiveAprPercent() != null)
              Text(
                '实际年化 ≈ ${_pct(contract.effectiveAprPercent()!)}'
                '（IRR 口径，费用率类负债明显更高）',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
              ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: [
                ActionChip(
                  label: const Text('按计划还款'),
                  onPressed: () => _repayNext(context, ref, next),
                ),
                ActionChip(
                  label: const Text('提前还款模拟'),
                  onPressed: () => _prepay(context, ref),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _aprLabel(DebtContract c) =>
      c.aprPercent.isZero ? '0' : _pct(c.aprPercent);

  String _pct(Rational r) {
    final pct = (r * Rational.fromInt(BigInt.from(100))).asDouble();
    return '${pct.toStringAsFixed(2)}%';
  }

  Future<void> _repayNext(BuildContext context, WidgetRef ref,
      DebtScheduleEntry? entry) async {
    final s = sessionOf(ref.read(vaultProvider));
    if (s == null) return;
    if (entry == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('没有待还期数（或为手工计划）')));
      }
      return;
    }
    final accounts = await s.accounts.all();
    final assets = accounts
        .where((a) => a.type == AccountType.asset && !a.isSystem && !a.isHolding)
        .toList();
    if (assets.isEmpty) return;
    final asset = assets.first;
    final interestCat = accounts.firstWhere((a) => a.id == 'cat:e:interest',
        orElse: () => accounts.firstWhere((a) => a.type == AccountType.expense));
    await s.ledger.post(TxBuilders.loanRepay(
      loan: account,
      payFrom: asset,
      principalMinor: entry.principalMinor,
      interestMinor: entry.interestMinor,
      feeMinor: entry.feeMinor,
      interestCategory: interestCat,
      date: DateTime.now(),
    ));
    ref.invalidate(_debtsProvider);
  }

  Future<void> _prepay(BuildContext context, WidgetRef ref) async {
    final s = sessionOf(ref.read(vaultProvider));
    if (s == null) return;
    final ctrl = TextEditingController(text: '10000');
    final shorten = true;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('提前还款模拟 · ${account.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('当前剩余本金 ${fmtMinor(remainingMinor, account.currencyCode)}'),
            const SizedBox(height: 8),
            TextField(
              controller: ctrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: '额外偿还金额（元）'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('模拟')),
        ],
      ),
    );
    if (ok != true) return;
    final amount = Money.parse(ctrl.text, CurrencyInfo.parse(account.currencyCode)).amountMinor;
    final schedule = contract.generateSchedule();
    final result = contract.simulatePrepayment(
      afterEntrySeq: _paidCount(schedule, remainingMinor),
      extraMinor: amount,
      remainingPrincipalMinor: remainingMinor,
      shortenTerm: shorten,
    );
    if (context.mounted) {
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('模拟结果'),
          content: Text(
            '手续费：${fmtMinor(result.prepayFeeMinor, account.currencyCode)}\n'
            '利息净节省：${fmtMinor(result.interestSavedMinor, account.currencyCode)}\n'
            '剩余期数：${result.remainingEntries.length} 期'
            '${result.monthsSaved > 0 ? '（少 ${result.monthsSaved} 期）' : ''}',
          ),
          actions: [
            FilledButton(
                onPressed: () => Navigator.pop(context), child: const Text('知道了')),
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
    final id = 'acc:liab:${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}';
    await s.accounts.upsert(Account(
      id: id,
      name: _name.text.trim(),
      type: AccountType.liability,
      liabilitySubtype: _subtype,
      currencyCode: 'CNY',
    ));
    await s.planning.saveDebtContract(DebtContract(
      liabilityAccountId: id,
      principalOriginalMinor:
          Money.parse(_principal.text, CurrencyInfo.cny).amountMinor,
      aprPercent: Rational.parseDecimal(_apr.text.trim().isEmpty ? '0' : _apr.text.trim()),
      method: _method,
      termMonths: int.tryParse(_term.text) ?? 0,
      startDate: start,
      repaymentDay: start.day,
    ));
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('新建负债'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _name, decoration: const InputDecoration(labelText: '名称')),
            const SizedBox(height: 8),
            DropdownButtonFormField<LiabilitySubtype>(
              initialValue: _subtype,
              decoration: const InputDecoration(labelText: '类型'),
              items: [
                for (final st in LiabilitySubtype.values)
                  DropdownMenuItem(value: st, child: Text(st.labelZh)),
              ],
              onChanged: (v) => setState(() => _subtype = v!),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<RepaymentMethod>(
              initialValue: _method,
              decoration: const InputDecoration(labelText: '还款方式'),
              items: [
                for (final m in RepaymentMethod.values)
                  DropdownMenuItem(value: m, child: Text(m.labelZh)),
              ],
              onChanged: (v) => setState(() => _method = v!),
            ),
            const SizedBox(height: 8),
            TextField(
                controller: _principal,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: '本金（元）')),
            const SizedBox(height: 8),
            TextField(
                controller: _apr,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: '名义年利率 %（如 3.85）')),
            const SizedBox(height: 8),
            TextField(
                controller: _term,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: '期数（月）')),
            const SizedBox(height: 8),
            TextField(controller: _start, decoration: const InputDecoration(labelText: '起始日')),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
        FilledButton(onPressed: _save, child: const Text('保存')),
      ],
    );
  }
}
