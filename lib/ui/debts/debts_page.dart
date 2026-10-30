import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/debt/debt_contract.dart';
import '../../domain/ledger/account.dart';
import '../../domain/ledger/transaction.dart';
import '../../domain/money/currency.dart';
import '../../domain/money/fx_rate.dart';
import '../../domain/money/money.dart';
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
    final async = ref.watch(_debtsProvider);
    return PageFrame(
      title: '负债',
      maxWidth: 980,
      actions: [
        ActionIcon(
          tooltip: '雪崩 vs 雪球策略对比',
          icon: Icons.compare_arrows,
          onTap: () => showDebtStrategySheet(context, ref),
        ),
      ],
      fab: ParticleEdge(
        band: 12,
        extendBelow: 6,
        child: FloatingActionButton.extended(
          onPressed: () async {
            final ok = await showDialog<bool>(
              context: context,
              builder: (_) => const _DebtEditDialog(),
            );
            if (ok == true) ref.invalidate(_debtsProvider);
          },
          icon: const Icon(Icons.add),
          label: const Text('新建负债'),
        ),
      ),
      child: async.when(
        loading: () => const Center(child: OrbitSpinner(size: 36)),
        error: (e, _) => ErrorPlaceholder('加载失败：$e'),
        data: (data) {
          final (debts, totalBase) = data;
          if (debts.isEmpty) {
            return const EmptyState(
              icon: Icons.credit_card_outlined,
              title: '还没有负债',
              message: '登记信用卡、房贷、花呗等负债后，这里给出还款计划与压力模拟。',
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
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            children: [
              StatBand(
                items: [
                  StatBandItem(
                    '总负债（折本位币）',
                    fmtMinor(totalBase, 'CNY'),
                    color: AppColors.negativeOf(brightness),
                    tooltip: '按账本内最近汇率折算本位币汇总；无汇率的外币计 0',
                  ),
                  StatBandItem('笔数', '${debts.length} 笔'),
                  if (worstApr != null)
                    StatBandItem(
                      '最高实际年化',
                      _pct(worstApr),
                      color: AppColors.warnOf(brightness),
                      tooltip: 'IRR 口径；费用率类负债明显高于名义利率',
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
                  label: '还款方式',
                  amount: contract.method.labelZh,
                ),
                AmountTile(
                  label: '名义年利率',
                  amount: contract.aprPercent.isZero
                      ? '0'
                      : DebtsPage._pct(contract.aprPercent),
                ),
                if (contract.termMonths > 0)
                  AmountTile(label: '期数', amount: '${contract.termMonths} 期'),
                if (eff != null)
                  AmountTile(
                    label: '实际年化',
                    amount: '≈ ${DebtsPage._pct(eff)}',
                    color: AppColors.negativeOf(theme.brightness),
                    tooltip: 'IRR 口径，费用率类负债明显更高',
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
                      '下期 ${next.dueDate.month}/${next.dueDate.day} 还 '
                      '${fmtMinor(next.totalMinor, account.currencyCode)}'
                      '（本金 ${fmtMinor(next.principalMinor, account.currencyCode)}'
                      ' + 利息 ${fmtMinor(next.interestMinor, account.currencyCode)}）',
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
                  label: const Text('按计划还款'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _prepay(context, ref),
                  icon: const Icon(Icons.bolt_outlined, size: 17),
                  label: const Text('提前还款模拟'),
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
    final s = sessionOf(ref.read(vaultProvider));
    if (s == null) return;
    if (entry == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('没有待还期数（或为手工计划）')),
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
            ParticleTextField(
              controller: ctrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: '额外偿还金额（元）'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ParticleFilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('模拟'),
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
            ParticleFilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('知道了'),
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
    return AlertDialog(
      title: const Text('新建负债'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ParticleTextField(
              controller: _name,
              decoration: const InputDecoration(labelText: '名称'),
            ),
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
            ParticleTextField(
              controller: _principal,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: '本金（元）'),
            ),
            const SizedBox(height: 8),
            ParticleTextField(
              controller: _apr,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: '名义年利率 %（如 3.85）'),
            ),
            const SizedBox(height: 8),
            ParticleTextField(
              controller: _term,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: '期数（月）'),
            ),
            const SizedBox(height: 8),
            ParticleTextField(
              controller: _start,
              decoration: const InputDecoration(labelText: '起始日'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('取消'),
        ),
        ParticleFilledButton(onPressed: _save, child: const Text('保存')),
      ],
    );
  }
}
