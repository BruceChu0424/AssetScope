import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../widgets/common.dart';
import 'cash_flow_parts.dart';
import 'overview_anim.dart';
import 'overview_providers.dart';
import 'overview_scaffold.dart';

/// 本月收支详情页：三 KPI + 日现金流双柱图 + 消费分类环形 + 收入来源 +
/// 预算执行 + 月历热力 + 近期交易。月份切换全页联动。
class CashFlowPage extends ConsumerStatefulWidget {
  const CashFlowPage({super.key});

  @override
  ConsumerState<CashFlowPage> createState() => _CashFlowPageState();
}

class _CashFlowPageState extends ConsumerState<CashFlowPage> {
  late DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final async = ref.watch(
      cashFlowDetailProvider((_month.year, _month.month)),
    );
    return OverviewScaffold(
      title: t.ovCfTitle,
      titleHint: t.ovCfHint,
      updatedLabel: t.reportMonthTitle(_month.year, _month.month),
      appBarBottom: MonthNav(
        month: _month,
        onShift: (d) => setState(() {
          _month = DateTime(_month.year, _month.month + d);
        }),
      ),
      child: async.when(
        loading: () => const Center(child: OrbitSpinner(size: 44)),
        error: (e, _) => Center(child: ErrorPlaceholder(t.homeLoadFailed(e))),
        data: (d) => _Body(d: d),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.d});

  final OvCashFlowData d;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final prevInc = d.prevReport?.incomeByCategory.values.fold(
          BigInt.zero,
          (a, b) => a + b,
        );
    final prevExp = d.prevReport?.expenseByCategory.values.fold(
          BigInt.zero,
          (a, b) => a + b,
        );
    final kpis = <Widget>[
      CfKpi(
        icon: Icons.south_west,
        label: t.dashIncome,
        value: fmtMinor(d.income, d.base),
        delta: prevInc == null ? null : d.income - prevInc,
        currency: d.base,
        hint: t.ovCfIncomeHint,
      ),
      CfKpi(
        icon: Icons.north_east,
        label: t.dashSpendFees,
        value: fmtMinor(d.expense, d.base),
        delta: prevExp == null ? null : d.expense - prevExp,
        currency: d.base,
        invertDelta: true,
        hint: t.ovCfExpenseHint,
      ),
      CfKpi(
        icon: Icons.account_balance_wallet_outlined,
        label: t.dashSurplus,
        value: fmtMinor(d.surplus, d.base),
        delta: prevInc == null || prevExp == null
            ? null
            : d.surplus - (prevInc - prevExp),
        currency: d.base,
        hint: t.ovCfSurplusHint,
      ),
    ];
    final width = MediaQuery.sizeOf(context).width;
    if (width < 1120) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      child: SingleChildScrollView(
        child: OvStaggerColumn(
          gap: 12,
          children: [
            ...kpis,
            SizedBox(height: 300, child: DailyPanel(d: d)),
            SizedBox(height: 330, child: ExpenseDonutPanel(d: d)),
            SizedBox(height: 300, child: IncomePanel(d: d)),
            SizedBox(height: 260, child: BudgetPanel(d: d)),
            HeatPanel(d: d),
            SizedBox(height: 340, child: RecentPanel(d: d)),
          ],
        ),
      ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
      child: SingleChildScrollView(
        child: OvStaggerColumn(
          gap: 14,
          children: [
            Row(
              children: [
                for (var i = 0; i < kpis.length; i++) ...[
                  if (i > 0) const SizedBox(width: 14),
                  Expanded(child: kpis[i]),
                ],
              ],
            ),
            SizedBox(
              height: 330,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 5, child: DailyPanel(d: d)),
                  const SizedBox(width: 14),
                  Expanded(flex: 3, child: ExpenseDonutPanel(d: d)),
                ],
              ),
            ),
            SizedBox(
              height: 330,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 3, child: IncomePanel(d: d)),
                  const SizedBox(width: 14),
                  Expanded(flex: 3, child: BudgetPanel(d: d)),
                  const SizedBox(width: 14),
                  Expanded(flex: 3, child: HeatPanel(d: d)),
                ],
              ),
            ),
            SizedBox(height: 300, child: RecentPanel(d: d)),
          ],
        ),
      ),
    );
  }
}
