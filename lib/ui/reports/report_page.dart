import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/reports/year_report.dart';
import '../../services/stats_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'allocation_card.dart';
import 'fire_card.dart';
import 'invest_card.dart';
import 'personal_cpi_card.dart';
import 'risk_card.dart';
import 'year_view.dart';

/// 报表页 · 杂志式双栏：大屏（≥760 内容宽）把卡片交替分流到左右两栏，
/// 小屏单列。月报/年度切换与前后翻页在页头。
class ReportPage extends ConsumerStatefulWidget {
  const ReportPage({super.key});

  @override
  ConsumerState<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends ConsumerState<ReportPage> {
  late DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  int _year = DateTime.now().year;
  bool _yearMode = false;

  late final _monthProvider = FutureProvider.autoDispose<MonthReport>((
    ref,
  ) async {
    final s = sessionOf(ref.watch(vaultProvider));
    if (s == null) throw StateError('locked');
    return s.statsService.monthReport(_month.year, _month.month);
  });

  late final _yearProvider = FutureProvider.autoDispose<YearReport>((
    ref,
  ) async {
    final s = sessionOf(ref.watch(vaultProvider));
    if (s == null) throw StateError('locked');
    return s.yearReportService.yearReport(_year);
  });

  void _shift(int delta) {
    setState(() {
      if (_yearMode) {
        _year += delta;
        ref.invalidate(_yearProvider);
      } else {
        _month = DateTime(_month.year, _month.month + delta);
        ref.invalidate(_monthProvider);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final Widget body;
    if (_yearMode) {
      body = ref
          .watch(_yearProvider)
          .when(
            loading: () => const Center(child: OrbitSpinner(size: 36)),
            error: (e, _) => ErrorPlaceholder('加载失败：$e'),
            data: (r) => _magazine([YearView(report: r)]),
          );
    } else {
      body = ref
          .watch(_monthProvider)
          .when(
            loading: () => const Center(child: OrbitSpinner(size: 36)),
            error: (e, _) => ErrorPlaceholder('加载失败：$e'),
            data: (r) => _magazine([
              _attributionCard(context, r),
              _categoryCard(context, r, income: true),
              _categoryCard(context, r, income: false),
              const PersonalCpiCard(),
              const InvestCard(),
              const RiskCard(),
              const AllocationCard(),
              const FireCard(),
              _compositionCard(context, r),
            ]),
          );
    }
    return PageFrame(
      title: _yearMode ? '年度 · $_year 年' : '月报 · ${_month.year} 年 ${_month.month} 月',
      appBarBottom: _ToggleBar(
        yearMode: _yearMode,
        onMode: (v) => setState(() {
          _yearMode = v;
          if (_yearMode) {
            _year = _month.year;
            ref.invalidate(_yearProvider);
          }
        }),
      ),
      actions: [
        ActionIcon(
          tooltip: '上一期',
          icon: Icons.chevron_left,
          onTap: () => _shift(-1),
        ),
        const SizedBox(width: 6),
        ActionIcon(
          tooltip: '下一期',
          icon: Icons.chevron_right,
          onTap: () => _shift(1),
        ),
      ],
      child: body,
    );
  }

  /// 双栏杂志：交替分流。首卡（归因分解）独占左栏顶位。
  Widget _magazine(List<Widget> cards) {
    return LayoutBuilder(
      builder: (context, c) {
        // Row 的实际可用宽 = c.maxWidth − ListView 水平 padding(32)。
        final avail = c.maxWidth - 32;
        final twoCol = avail >= 728;
        if (!twoCol) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              for (final k in cards)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: k,
                ),
            ],
          );
        }
        final left = <Widget>[];
        final right = <Widget>[];
        for (var i = 0; i < cards.length; i++) {
          (i.isEven ? left : right).add(
            Padding(padding: const EdgeInsets.only(bottom: 16), child: cards[i]),
          );
        }
        final colW = (avail - 16) / 2;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: colW, child: Column(children: left)),
                const SizedBox(width: 16),
                SizedBox(width: colW, child: Column(children: right)),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _attributionCard(BuildContext context, MonthReport r) {
    final a = r.attribution;
    final base = r.baseCurrencyCode;
    Widget row(String label, BigInt v, {bool strong = false}) => ListTile(
      dense: true,
      title: Text(label),
      trailing: Text(
        fmtMinor(v, base, sign: !strong),
        style: TextStyle(
          fontFeatures: const [FontFeature.tabularFigures()],
          fontWeight: strong ? FontWeight.bold : null,
        ),
      ),
    );
    return SectionCard(
      title: '净资产变化分解',
      trailing: a.hasResidual
          ? Tooltip(
              message: '差额非 0 通常意味着缺估值、漏记或导入重复',
              child: Chip(
                label: Text('待核对 ${fmtMinor(a.residual, base)}'),
                visualDensity: VisualDensity.compact,
              ),
            )
          : null,
      child: Column(
        children: [
          row('期初净资产', a.nwStart),
          row('收支贡献', a.incomeExpense),
          row('投资损益·已实现', a.investRealized),
          row('投资损益·分红', a.investDividend),
          row('投资损益·未实现变化', a.investUnrealizedDelta),
          row('汇兑影响', a.fxEffect),
          row('其他估值变化', a.otherValuation),
          row('范围/历史修正', a.correction),
          if (a.hasResidual) row('待核对差额', a.residual),
          const Divider(height: 8),
          row('期末净资产', a.nwEnd, strong: true),
        ],
      ),
    );
  }

  Widget _categoryCard(
    BuildContext context,
    MonthReport r, {
    required bool income,
  }) {
    final base = r.baseCurrencyCode;
    final map = income ? r.incomeByCategory : r.expenseByCategory;
    final entries = map.entries.toList()
      ..sort((x, y) => y.value.compareTo(x.value));
    final total = entries.fold(BigInt.zero, (s, e) => s + e.value);
    if (entries.isEmpty) return const SizedBox.shrink();
    final palette = AppChartPalette.of(Theme.of(context).brightness);
    return SectionCard(
      title: income ? '收入构成' : '消费构成',
      child: Column(
        children: [
          SizedBox(
            height: 120,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                sections: [
                  for (var i = 0; i < entries.length && i < 8; i++)
                    PieChartSectionData(
                      value: entries[i].value.toDouble(),
                      title:
                          '${(entries[i].value.toDouble() / total.toDouble() * 100).toStringAsFixed(0)}%',
                      radius: 44,
                      color: palette[i % palette.length],
                      titleStyle: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          for (final e in entries.take(10))
            rowTile(_catName(r, e.key), fmtMinor(e.value, base)),
        ],
      ),
    );
  }

  String _catName(MonthReport r, String id) =>
      id.replaceAll('cat:e:', '').replaceAll('cat:i:', '');

  Widget rowTile(String label, String value) => ListTile(
    dense: true,
    contentPadding: EdgeInsets.zero,
    title: Text(label),
    trailing: Text(
      value,
      style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()]),
    ),
  );

  Widget _compositionCard(BuildContext context, MonthReport r) {
    final items =
        r.nwEndBreakdown.items
            .where((i) => i.valueBaseMinor != BigInt.zero)
            .toList()
          ..sort((a, b) => b.valueBaseMinor.compareTo(a.valueBaseMinor));
    return SectionCard(
      title: '期末资产负债构成',
      child: Column(
        children: [
          for (final i in items.take(14))
            rowTile(
              '${i.account.name}${i.valuationMissing
                  ? '（缺估值）'
                  : i.valuationStale
                  ? '（估值过期）'
                  : ''}',
              fmtMinor(i.valueBaseMinor, i.account.currencyCode),
            ),
        ],
      ),
    );
  }
}

/// 月/年切换条（AppBar.bottom 兼容件）。
class _ToggleBar extends StatelessWidget implements PreferredSizeWidget {
  const _ToggleBar({required this.yearMode, required this.onMode});

  final bool yearMode;
  final ValueChanged<bool> onMode;

  @override
  Size get preferredSize => const Size.fromHeight(48);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: SegmentedButton<bool>(
        segments: const [
          ButtonSegment(value: false, label: Text('月报')),
          ButtonSegment(value: true, label: Text('年度')),
        ],
        selected: {yearMode},
        onSelectionChanged: (v) => onMode(v.first),
      ),
    );
  }
}
