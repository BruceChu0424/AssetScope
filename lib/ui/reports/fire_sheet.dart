import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/money/currency.dart';
import '../../domain/money/fx_rate.dart';
import '../../domain/money/money.dart';
import '../../domain/planning/fire.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'fire_card.dart';

/// FIRE 参数弹层：全部假设可调 + 反解储蓄 + 敏感性 + 蒙特卡洛生存率。
Future<void> showFireSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const FireSheet(),
  );
}

class FireSheet extends ConsumerStatefulWidget {
  const FireSheet({super.key});

  @override
  ConsumerState<FireSheet> createState() => _FireSheetState();
}

class _FireSheetState extends ConsumerState<FireSheet> {
  final _portfolio = TextEditingController();
  final _spend = TextEditingController();
  final _savings = TextEditingController();
  final _nominal = TextEditingController(text: '5.0');
  final _inflation = TextEditingController(text: '2.5');
  final _wr = TextEditingController(text: '4.0');
  double _vol = 0.12;

  FirePlan? _plan;
  FireMcResult? _mc;
  List<FireSensitivityCell>? _sensitivity;
  String _base = 'CNY';

  @override
  void dispose() {
    _portfolio.dispose();
    _spend.dispose();
    _savings.dispose();
    _nominal.dispose();
    _inflation.dispose();
    _wr.dispose();
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
    ref.read(fireDefaultsProvider.future).then((d) {
      if (!mounted) return;
      setState(() {
        _portfolio.text = _major(d.investableMinor);
        _spend.text = _major(d.ttmSpendMinor);
        _savings.text = _major(d.ttmSavingsMinor);
      });
      _recompute();
    }).catchError((_) {});
  }

  String _major(BigInt minor) {
    final yuan = minor ~/ BigInt.from(100);
    return yuan.toString();
  }

  BigInt? _minor(String text) {
    if (text.trim().isEmpty) return null;
    try {
      return Money.parse(text.trim(), CurrencyInfo.cny).amountMinor;
    } on FormatException {
      return null;
    }
  }

  Rational? _pct(String text) {
    final v = double.tryParse(text.trim());
    if (v == null || v <= -100 || v > 100) return null;
    return Rational.parseDecimal(v.toString());
  }

  void _recompute() {
    final p = _minor(_portfolio.text);
    final spend = _minor(_spend.text);
    final savings = _minor(_savings.text);
    final n = _pct(_nominal.text);
    final f = _pct(_inflation.text);
    final w = _pct(_wr.text);
    if (n == null || f == null || w == null || w.isZero || spend == null) {
      setState(() {
        _plan = null;
        _mc = null;
        _sensitivity = null;
      });
      return;
    }
    final input = FireInput(
      portfolioMinor: p ?? BigInt.zero,
      annualSavingsMinor: savings ?? BigInt.zero,
      annualSpendMinor: spend,
      nominalReturnAnnual: n,
      inflationAnnual: f,
      withdrawalRate: w / Rational.fromInt(BigInt.from(100)),
    );
    final plan = FirePlanner.plan(input);
    final mc = FireMonteCarlo.survival(
      initialMultiple: 1 / (w / Rational.fromInt(BigInt.from(100))).asDouble(),
      realReturnMean: input.realReturnAnnual,
      realVol: _vol,
      years: 30,
      paths: 1000,
    );
    setState(() {
      _plan = plan;
      _mc = mc;
      _sensitivity = FirePlanner.sensitivity(input);
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
            child: Text('财务独立（FIRE）规划器',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'FI 门槛 = 年支出 ÷ 提取率；累积期逐月精确复利（名义收益、'
              '目标随通胀增长）。蒙特卡洛为实际口径（已扣通胀），固定种子可复现。',
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
                FilledButton.icon(
                  onPressed: _recompute,
                  icon: const Icon(Icons.calculate),
                  label: const Text('重新测算'),
                ),
                if (_plan != null) ...[
                  const SizedBox(height: 16),
                  _planCard(theme),
                  const SizedBox(height: 12),
                  _requiredCard(theme),
                  const SizedBox(height: 12),
                  _mcCard(theme),
                  const SizedBox(height: 12),
                  _sensitivityCard(theme),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputCard(ThemeData theme) {
    Widget field(TextEditingController c, String label,
        {bool decimal = false, bool signed = false}) {
      return Expanded(
        child: TextField(
          controller: c,
          keyboardType: TextInputType.numberWithOptions(
              decimal: decimal, signed: signed),
          decoration: InputDecoration(isDense: true, labelText: label),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          children: [
            Row(children: [
              field(_portfolio, '可投资净资产（元）'),
              const SizedBox(width: 12),
              field(_savings, '年储蓄（元，可负）', signed: true),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              field(_spend, '目标年支出（元）'),
              const SizedBox(width: 12),
              field(_nominal, '名义收益 %/年', decimal: true),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              field(_inflation, '通胀 %/年', decimal: true),
              const SizedBox(width: 12),
              field(_wr, '提取率 %（4=4% 法则）', decimal: true),
            ]),
            const SizedBox(height: 12),
            Row(
              children: [
                Text('提取期波动率 ${(_vol * 100).toStringAsFixed(0)}%',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.hintColor)),
                Expanded(
                  child: Slider(
                    value: _vol,
                    min: 0.05,
                    max: 0.25,
                    divisions: 20,
                    label: '${(_vol * 100).round()}%',
                    onChanged: (v) => setState(() => _vol = v),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _planCard(ThemeData theme) {
    final plan = _plan!;
    return SectionCard(
      title: '测算结果',
      child: Column(
        children: [
          StatRow(
              label: 'FI 门槛（今天的钱）',
              value: fmtMinor(plan.fiNumberMinor, _base),
              emphasized: true),
          StatRow(
              label: '当前覆盖率',
              value: '${(plan.coverage * 100).toStringAsFixed(0)}%'),
          StatRow(
              label: '达标时间',
              value: plan.alreadyFi
                  ? '已达标 🎉'
                  : plan.yearsToFi == null
                      ? '不可达（${plan.curve.length - 1} 年内）'
                      : '≈ ${plan.yearsToFi} 年（${plan.monthsToFi} 个月）',
              valueColor: plan.yearsToFi != null || plan.alreadyFi
                  ? null
                  : AppColors.negativeOf(theme.brightness)),
        ],
      ),
    );
  }

  Widget _requiredCard(ThemeData theme) {
    final input = FireInput(
      portfolioMinor: _minor(_portfolio.text) ?? BigInt.zero,
      annualSavingsMinor: _minor(_savings.text) ?? BigInt.zero,
      annualSpendMinor: _minor(_spend.text) ?? BigInt.zero,
      nominalReturnAnnual: _pct(_nominal.text) ?? Rational.zero(),
      inflationAnnual: _pct(_inflation.text) ?? Rational.zero(),
      withdrawalRate:
          (_pct(_wr.text) ?? Rational.one) / Rational.fromInt(BigInt.from(100)),
    );
    return SectionCard(
      title: '反解：想 N 年达标每年要存多少',
      child: Column(
        children: [
          for (final y in const [10, 15, 20, 25])
            StatRow(
              label: '$y 年内达标',
              value: fmtMinor(
                  FirePlanner.requiredAnnualSavingsMinor(input, y), _base),
            ),
        ],
      ),
    );
  }

  Widget _mcCard(ThemeData theme) {
    final mc = _mc!;
    final color = mc.successRate >= 0.9
        ? AppColors.positiveOf(theme.brightness)
        : mc.successRate >= 0.75
            ? AppColors.brassOf(theme.brightness)
            : AppColors.negativeOf(theme.brightness);
    return SectionCard(
      title: '蒙特卡洛 · 达标后提取 30 年',
      child: Column(
        children: [
          StatRow(
              label: '生存率（1000 条路径）',
              value: '${(mc.successRate * 100).toStringAsFixed(0)}%',
              emphasized: true,
              valueColor: color),
          StatRow(
              label: '期末余额分位（年支出倍数）',
              value: 'P10 ${mc.p10.toStringAsFixed(1)}× · '
                  'P50 ${mc.p50.toStringAsFixed(1)}× · P90 ${mc.p90.toStringAsFixed(1)}×'),
          const SizedBox(height: 6),
          Text(
            '期初 = FI 门槛（提取率倒数倍年支出），每年提取 1 倍并按随机实际收益增长；'
            '波动率 ${(_vol * 100).toStringAsFixed(0)}%。模拟为启发式参考，不构成投资建议。',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.hintColor, fontSize: 11, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _sensitivityCard(ThemeData theme) {
    final cells = _sensitivity!;
    String label(int months) => months < 0
        ? '不可达'
        : months == 0
            ? '已达标'
            : '${(months / 12).ceil()} 年';
    return SectionCard(
      title: '敏感性：收益 ±1pp × 支出 ±10%',
      child: Column(
        children: [
          for (final row in const [-1, 0, 1])
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 64,
                    child: Text(
                      row == 0 ? '基准' : '收益${row > 0 ? '+' : ''}$row pp',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.hintColor),
                    ),
                  ),
                  for (final f in const [0.9, 1.0, 1.1])
                    Expanded(
                      child: Center(
                        child: Text(
                          label(cells
                              .firstWhere((c) =>
                                  c.returnShiftPercentPoint == row &&
                                  c.spendFactor == f)
                              .monthsToFi),
                          style: theme.textTheme.bodyMedium?.copyWith(
                              fontFeatures: const [
                                FontFeature.tabularFigures()
                              ]),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          Text('列：支出 ×0.9 / ×1.0 / ×1.1（能省 10% 比多赚 1 个点更有力）',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.hintColor, fontSize: 11)),
        ],
      ),
    );
  }
}
