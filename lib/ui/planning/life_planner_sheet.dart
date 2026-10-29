import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/money/currency.dart';
import '../../domain/money/fx_rate.dart';
import '../../domain/money/money.dart';
import '../../domain/planning/life_planner.dart';
import '../../domain/utils/dates.dart';
import '../../services/scenario_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'life_event_dialogs.dart';

/// 人生规划预填值。
final lifeDefaultsProvider =
    FutureProvider.autoDispose<LifeDefaults>((ref) async {
  final s = sessionOf(ref.watch(vaultProvider));
  if (s == null) throw StateError('locked');
  return s.scenarios.lifeDefaults();
});

/// 人生规划弹层：多年度现金流与净资产推演（docs/05 §14）。
/// 只读模拟，不写账本。
Future<void> showLifePlannerSheet(BuildContext context, WidgetRef ref) {
  ref.invalidate(lifeDefaultsProvider);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const LifePlannerSheet(),
  );
}

class LifePlannerSheet extends ConsumerStatefulWidget {
  const LifePlannerSheet({super.key});

  @override
  ConsumerState<LifePlannerSheet> createState() => _LifePlannerSheetState();
}

class _LifePlannerSheetState extends ConsumerState<LifePlannerSheet> {
  final _invest = TextEditingController();
  final _fixed = TextEditingController();
  final _income = TextEditingController();
  final _expense = TextEditingController();
  final _ret = TextEditingController(text: '5.0');
  final _inf = TextEditingController(text: '2.5');
  final _events = <LifeEvent>[];
  int _years = 40;

  LifeResult? _result;
  String _base = 'CNY';

  @override
  void dispose() {
    for (final c in [
      _invest,
      _fixed,
      _income,
      _expense,
      _ret,
      _inf,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final s = sessionOf(ref.read(vaultProvider));
    if (s == null) return;
    s.statsService.baseCurrency().then((b) {
      if (mounted) setState(() => _base = b);
    });
    ref.read(lifeDefaultsProvider.future).then((d) {
      if (!mounted) return;
      setState(() {
        _invest.text = _yuan(d.investMinor);
        _fixed.text = _yuan(d.fixedAssetsMinor);
        _income.text = _yuan(d.monthlyIncomeMinor);
        _expense.text = _yuan(d.monthlyExpenseMinor);
      });
      _run();
    }).catchError((_) {});
  }

  String _yuan(BigInt minor) => (minor ~/ BigInt.from(100)).toString();

  BigInt? _minor(TextEditingController c) {
    final t = c.text.trim();
    if (t.isEmpty) return null;
    try {
      return Money.parse(t, CurrencyInfo.cny).amountMinor;
    } on FormatException {
      return null;
    }
  }

  Rational? _pct(TextEditingController c) {
    final v = double.tryParse(c.text.trim());
    if (v == null || v <= -100 || v > 100) return null;
    return Rational.parseDecimal(v.toString()) /
        Rational.fromInt(BigInt.from(100));
  }

  void _run() {
    final invest = _minor(_invest) ?? BigInt.zero;
    final fixed = _minor(_fixed) ?? BigInt.zero;
    final income = _minor(_income) ?? BigInt.zero;
    final expense = _minor(_expense) ?? BigInt.zero;
    final ret = _pct(_ret);
    final inf = _pct(_inf);
    if (ret == null || inf == null) return;
    setState(() {
      _result = LifePlanner.simulate(LifeInput(
        investMinor: invest,
        fixedAssetsMinor: fixed,
        monthlyIncomeMinor: income,
        monthlyExpenseMinor: expense,
        nominalReturnAnnual: ret,
        inflationAnnual: inf,
        events: List.of(_events),
        years: _years,
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.88,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Text('人生规划 · 多年度推演',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              '把买房、育儿、换车、退休等大事放进同一条时间线，逐月推演未来 $_years 年的'
              '现金流与净资产（名义口径，收入支出按通胀增长）。只读模拟，不写账本。',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.hintColor, height: 1.5),
            ),
          ),
          const Divider(height: 16),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: [
                _inputCard(theme),
                const SizedBox(height: 12),
                _eventsCard(theme),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _run,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('重新推演'),
                ),
                if (_result != null) ...[
                  const SizedBox(height: 16),
                  _resultCard(theme),
                  const SizedBox(height: 12),
                  _curveCard(theme),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputCard(ThemeData theme) {
    Widget field(TextEditingController c, String label) => Expanded(
          child: TextField(
            controller: c,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(isDense: true, labelText: label),
          ),
        );
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Column(
          children: [
            Row(children: [
              field(_invest, '可投资净资产（元）'),
              const SizedBox(width: 12),
              field(_fixed, '固定资产等（元）'),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              field(_income, '月收入（元）'),
              const SizedBox(width: 12),
              field(_expense, '月支出（元）'),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              field(_ret, '名义收益 %/年'),
              const SizedBox(width: 12),
              field(_inf, '通胀 %/年'),
            ]),
            const SizedBox(height: 10),
            DropdownButtonFormField<int>(
              initialValue: _years,
              decoration: const InputDecoration(labelText: '推演年限'),
              items: const [
                DropdownMenuItem(value: 20, child: Text('20 年')),
                DropdownMenuItem(value: 30, child: Text('30 年')),
                DropdownMenuItem(value: 40, child: Text('40 年')),
                DropdownMenuItem(value: 50, child: Text('50 年')),
              ],
              onChanged: (v) {
                if (v != null) {
                  _years = v;
                  _run();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _eventsCard(ThemeData theme) {
    return SectionCard(
      title: '人生事件',
      trailing: IconButton(
        tooltip: '添加事件',
        icon: const Icon(Icons.add, size: 20),
        onPressed: () async {
          final ev = await showLifeEventDialog(context);
          if (ev != null) {
            setState(() => _events.add(ev));
            _run();
          }
        },
      ),
      child: _events.isEmpty
          ? Text('还没有事件。加一个试试：三年后买房、明年生孩子……',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.hintColor))
          : Column(
              children: [
                for (final (i, e) in _events.indexed)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(lifeEventSummary(e)),
                    trailing: IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      tooltip: '移除',
                      onPressed: () {
                        setState(() => _events.removeAt(i));
                        _run();
                      },
                    ),
                    onTap: () async {
                      final ev = await showLifeEventDialog(context,
                          initial: e);
                      if (ev != null) {
                        setState(() => _events[i] = ev);
                        _run();
                      }
                    },
                  ),
              ],
            ),
    );
  }

  Widget _resultCard(ThemeData theme) {
    final r = _result!;
    return SectionCard(
      title: '推演结论',
      child: Column(
        children: [
          StatRow(
            label: '$_years 年后净资产',
            value: fmtMinor(r.curve.last.netWorthMinor, _base),
            emphasized: true,
          ),
          StatRow(label: '峰值净资产', value: fmtMinor(r.peakNetWorthMinor, _base)),
          if (r.newLoanInterestMinor > BigInt.zero)
            StatRow(
              label: '新增贷款总利息',
              value: fmtMinor(r.newLoanInterestMinor, _base),
              valueColor: AppColors.brassOf(theme.brightness),
            ),
          StatRow(
            label: '现金耗尽风险',
            value: r.ok
                ? '推演期内无缺口 ✓'
                : '第 ${(r.exhaustedAtMonth! / 12).ceil()} 年（${dateKey(DateTime.now().add(Duration(days: 30 * r.exhaustedAtMonth!)))} 前后）',
            valueColor: r.ok
                ? AppColors.positiveOf(theme.brightness)
                : AppColors.negativeOf(theme.brightness),
          ),
        ],
      ),
    );
  }

  Widget _curveCard(ThemeData theme) {
    final r = _result!;
    final spots = <FlSpot>[
      for (final p in r.curve) FlSpot(p.month / 12, p.netWorthMinor.toDouble()),
    ];
    var minY = 0.0;
    var maxY = 0.0;
    for (final s in spots) {
      if (s.y < minY) minY = s.y;
      if (s.y > maxY) maxY = s.y;
    }
    final pad = (maxY - minY) * 0.08 + 1;
    return SectionCard(
      title: '净资产曲线（万元）',
      child: SizedBox(
        height: 190,
        child: LineChart(
          LineChartData(
            minY: minY - pad,
            maxY: maxY + pad,
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (touched) => [
                  for (final s in touched)
                    LineTooltipItem(
                        '第 ${s.x.toStringAsFixed(0)} 年  ${fmtMinor(_curveAt(r, s.x), _base)}',
                        const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: false,
                barWidth: 2.2,
                dotData: const FlDotData(show: false),
                color: theme.colorScheme.primary,
                belowBarData: BarAreaData(
                  show: true,
                  color: theme.colorScheme.primary.withValues(alpha: 0.07),
                ),
              ),
            ],
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: (_years / 5).ceilToDouble(),
                  getTitlesWidget: (v, _) => Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('${v.toStringAsFixed(0)} 年',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.hintColor)),
                  ),
                ),
              ),
            ),
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
          ),
        ),
      ),
    );
  }

  /// tooltip 回查：年份 x 对应最近的采样点净资产（BigInt 原值）。
  BigInt _curveAt(LifeResult r, double yearX) {
    final targetMonth = (yearX * 12).round();
    LifePoint best = r.curve.first;
    for (final p in r.curve) {
      if ((p.month - targetMonth).abs() < (best.month - targetMonth).abs()) {
        best = p;
      }
    }
    return best.netWorthMinor;
  }
}
