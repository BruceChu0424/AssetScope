import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/money/currency.dart';
import '../../domain/money/fx_rate.dart';
import '../../domain/money/money.dart';
import '../../domain/planning/fire.dart';
import '../../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'fire_card.dart';

/// FIRE 参数弹层：全部假设可调 + 反解储蓄 + 敏感性 + 蒙特卡洛生存率。
Future<void> showFireSheet(BuildContext context, WidgetRef ref) {
  return showAppSheet<void>(
    context,
    scrollControlled: true,
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
    ref
        .read(fireDefaultsProvider.future)
        .then((d) {
          if (!mounted) return;
          setState(() {
            _portfolio.text = _major(d.investableMinor);
            _spend.text = _major(d.ttmSpendMinor);
            _savings.text = _major(d.ttmSavingsMinor);
          });
          _recompute();
        })
        .catchError((_) {});
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
    final t = AppLocalizations.of(context);
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.88,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Text(
              t.firePlannerTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              t.firePlannerNote,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.hintColor,
                height: 1.5,
              ),
            ),
          ),
          const Divider(height: 16),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: [
                _inputCard(theme),
                const SizedBox(height: 12),
                ParticleFilledButton.icon(
                  onPressed: _recompute,
                  icon: const Icon(Icons.calculate),
                  label: Text(t.recalculate),
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
    final t = AppLocalizations.of(context);
    Widget field(
      TextEditingController c,
      String label, {
      bool decimal = false,
      bool signed = false,
    }) {
      return Expanded(
        child: ParticleTextField(
          controller: c,
          keyboardType: TextInputType.numberWithOptions(
            decimal: decimal,
            signed: signed,
          ),
          decoration: InputDecoration(isDense: true, labelText: label),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          children: [
            Row(
              children: [
                field(_portfolio, t.investableNetWorthField),
                const SizedBox(width: 12),
                field(_savings, t.annualSavingsField, signed: true),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                field(_spend, t.targetAnnualSpendField),
                const SizedBox(width: 12),
                field(_nominal, t.nominalReturnField, decimal: true),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                field(_inflation, t.inflationField, decimal: true),
                const SizedBox(width: 12),
                field(_wr, t.withdrawalRateField, decimal: true),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  t.withdrawalVolPct((_vol * 100).toStringAsFixed(0)),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.hintColor,
                  ),
                ),
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
    final t = AppLocalizations.of(context);
    return SectionCard(
      title: t.calcResults,
      child: Column(
        children: [
          StatRow(
            label: t.fiNumberToday,
            value: fmtMinor(plan.fiNumberMinor, _base),
            emphasized: true,
          ),
          StatRow(
            label: t.currentCoverage,
            value: '${(plan.coverage * 100).toStringAsFixed(0)}%',
          ),
          StatRow(
            label: t.timeToFi,
            value: plan.alreadyFi
                ? t.fiReached
                : plan.yearsToFi == null
                ? t.fiUnreachableWithin(plan.curve.length - 1)
                : t.fiYearsMonths(plan.yearsToFi!, plan.monthsToFi),
            valueColor: plan.yearsToFi != null || plan.alreadyFi
                ? null
                : AppColors.negativeOf(theme.brightness),
          ),
        ],
      ),
    );
  }

  Widget _requiredCard(ThemeData theme) {
    final t = AppLocalizations.of(context);
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
      title: t.requiredSavingsTitle,
      child: Column(
        children: [
          for (final y in const [10, 15, 20, 25])
            StatRow(
              label: t.fiWithinYears(y),
              value: fmtMinor(
                FirePlanner.requiredAnnualSavingsMinor(input, y),
                _base,
              ),
            ),
        ],
      ),
    );
  }

  Widget _mcCard(ThemeData theme) {
    final mc = _mc!;
    final t = AppLocalizations.of(context);
    final color = mc.successRate >= 0.9
        ? AppColors.positiveOf(theme.brightness)
        : mc.successRate >= 0.75
        ? AppColors.brassOf(theme.brightness)
        : AppColors.negativeOf(theme.brightness);
    return SectionCard(
      title: t.mcTitle,
      child: Column(
        children: [
          StatRow(
            label: t.mcSurvivalLabel,
            value: '${(mc.successRate * 100).toStringAsFixed(0)}%',
            emphasized: true,
            valueColor: color,
          ),
          StatRow(
            label: t.mcPercentileLabel,
            value:
                'P10 ${mc.p10.toStringAsFixed(1)}× · '
                'P50 ${mc.p50.toStringAsFixed(1)}× · P90 ${mc.p90.toStringAsFixed(1)}×',
          ),
          const SizedBox(height: 6),
          Text(
            t.mcNote((_vol * 100).toStringAsFixed(0)),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.hintColor,
              fontSize: 11,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sensitivityCard(ThemeData theme) {
    final cells = _sensitivity!;
    final t = AppLocalizations.of(context);
    String label(int months) => months < 0
        ? t.fiUnreachableShort
        : months == 0
        ? t.fiReachedShort
        : t.yearsShort((months / 12).ceil());
    return SectionCard(
      title: t.sensitivityTitle,
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
                      row == 0 ? t.baseline : t.sensReturnRow(row > 0 ? '+' : '', row),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                  ),
                  for (final f in const [0.9, 1.0, 1.1])
                    Expanded(
                      child: Center(
                        child: Text(
                          label(
                            cells
                                .firstWhere(
                                  (c) =>
                                      c.returnShiftPercentPoint == row &&
                                      c.spendFactor == f,
                                )
                                .monthsToFi,
                          ),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          Text(
            t.sensitivityColsNote,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.hintColor,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
