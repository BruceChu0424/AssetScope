import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../services/stats_service.dart';
import '../widgets/common.dart';
import 'invest_card.dart';

/// 月报：净资产归因（互斥分解 + 待核对差额）、分类收支、资产构成。
class ReportPage extends ConsumerStatefulWidget {
  const ReportPage({super.key});

  @override
  ConsumerState<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends ConsumerState<ReportPage> {
  late DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  late final _provider =
      FutureProvider.autoDispose<MonthReport>((ref) async {
    final s = sessionOf(ref.watch(vaultProvider));
    if (s == null) throw StateError('locked');
    return s.statsService.monthReport(_month.year, _month.month);
  });

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(_provider);
    return Scaffold(
      appBar: AppBar(
        title: Text('月报 · ${_month.year} 年 ${_month.month} 月'),
        actions: [
          IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () => setState(() =>
                  _month = DateTime(_month.year, _month.month - 1))),
          IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () => setState(() =>
                  _month = DateTime(_month.year, _month.month + 1))),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorPlaceholder('加载失败：$e'),
        data: (r) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _attributionCard(context, r),
            _categoryCard(context, r, income: true),
            _categoryCard(context, r, income: false),
            const InvestCard(),
            _compositionCard(context, r),
          ],
        ),
      ),
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
                  visualDensity: VisualDensity.compact),
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

  Widget _categoryCard(BuildContext context, MonthReport r,
      {required bool income}) {
    final base = r.baseCurrencyCode;
    final map = income ? r.incomeByCategory : r.expenseByCategory;
    final entries = map.entries.toList()
      ..sort((x, y) => y.value.compareTo(x.value));
    final total = entries.fold(BigInt.zero, (s, e) => s + e.value);
    if (entries.isEmpty) return const SizedBox.shrink();
    const palette = [
      Color(0xFF1E5C45),
      Color(0xFF2E7D5B),
      Color(0xFF4CA98A),
      Color(0xFF7BC5A8),
      Color(0xFFB08A2E),
      Color(0xFFC9A95C),
      Color(0xFF9A6B1F),
      Color(0xFF7C6F5A),
    ];
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
                          fontSize: 10, color: Colors.white),
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
        trailing: Text(value,
            style:
                const TextStyle(fontFeatures: [FontFeature.tabularFigures()])),
      );

  Widget _compositionCard(BuildContext context, MonthReport r) {
    final items = r.nwEndBreakdown.items
        .where((i) => i.valueBaseMinor != BigInt.zero)
        .toList()
      ..sort((a, b) => b.valueBaseMinor.compareTo(a.valueBaseMinor));
    return SectionCard(
      title: '期末资产负债构成',
      child: Column(
        children: [
          for (final i in items.take(14))
            rowTile(
              '${i.account.name}${i.valuationMissing ? '（缺估值）' : i.valuationStale ? '（估值过期）' : ''}',
              fmtMinor(i.valueBaseMinor, i.account.currencyCode),
            ),
        ],
      ),
    );
  }
}
