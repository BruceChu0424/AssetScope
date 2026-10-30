import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/money/currency.dart';
import '../../domain/money/fx_rate.dart';
import '../../domain/money/money.dart';
import '../../domain/planning/scenario.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

/// 情景模拟弹层：预设压力情景（可叠加自定义冲击）→ 与基线现金预测对比。
Future<void> showScenarioSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const ScenarioSheet(),
  );
}

class _PresetItem {
  const _PresetItem(this.label, this.subtitle, this.build);
  final String label;
  final String subtitle;
  final List<ScenarioComponent> Function() build;
}

final _presets = <_PresetItem>[
  _PresetItem(
    '失业 3 个月',
    '收入完全中断一个季度',
    () => [IncomeShock(drop: Rational.one, months: 3)],
  ),
  _PresetItem(
    '收入降三成 · 6 个月',
    '降薪/绩效缩水的软着陆',
    () => [
      IncomeShock(
        drop: Rational.fromFrac(BigInt.from(3), BigInt.from(10)),
        months: 6,
      ),
    ],
  ),
  _PresetItem(
    '工资延发 30 天 · 2 个月',
    '现金流错位，钱没少但迟到',
    () => [IncomeDelay(delayDays: 30, months: 2)],
  ),
  _PresetItem(
    '支出激增 20% · 3 个月',
    '固定开销全面上涨',
    () => [
      ExpenseSurge(
        surge: Rational.fromFrac(BigInt.one, BigInt.from(5)),
        months: 3,
      ),
    ],
  ),
];

class ScenarioSheet extends ConsumerStatefulWidget {
  const ScenarioSheet({super.key});

  @override
  ConsumerState<ScenarioSheet> createState() => _ScenarioSheetState();
}

class _ScenarioSheetState extends ConsumerState<ScenarioSheet> {
  int _preset = 0;
  final _extraMonthly = TextEditingController();
  int _extraMonths = 6;
  final _oneOffAmount = TextEditingController();
  int _oneOffAfterDays = 15;

  bool _running = false;
  String? _error;
  ScenarioComparison? _result;
  late String _base = 'CNY';

  @override
  void dispose() {
    _extraMonthly.dispose();
    _oneOffAmount.dispose();
    super.dispose();
  }

  BigInt? _parseMinor(String text) {
    if (text.trim().isEmpty) return null;
    try {
      return Money.parse(text.trim(), CurrencyInfo.cny).amountMinor;
    } on FormatException {
      return null;
    }
  }

  Future<void> _run() async {
    final s = sessionOf(ref.read(vaultProvider));
    if (s == null) return;
    final extra = _parseMinor(_extraMonthly.text);
    final oneOff = _parseMinor(_oneOffAmount.text);
    setState(() {
      _running = true;
      _error = null;
    });
    try {
      _base = await s.statsService.baseCurrency();
      final comps = <ScenarioComponent>[..._presets[_preset].build()];
      if (extra != null && extra > BigInt.zero) {
        comps.add(
          ExtraMonthlyOutflow(
            monthlyMinor: extra,
            months: _extraMonths,
            label: '情景：额外月支出',
          ),
        );
      }
      if (oneOff != null && oneOff > BigInt.zero) {
        comps.add(
          OneOffEvent(
            afterDays: _oneOffAfterDays,
            amountBaseMinor: -oneOff,
            label: '情景：一次性支出',
          ),
        );
      }
      final r = await s.scenarios.run(
        ScenarioSpec(name: _presets[_preset].label, components: comps),
        horizonDays: 180,
      );
      setState(() {
        _result = r;
        _running = false;
      });
    } catch (e) {
      setState(() {
        _error = '模拟失败：$e';
        _running = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.85,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Text(
              '情景模拟 · 现金压力测试',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              '把"如果……会怎样"放进 180 天现金预测：计划、债务还款与准备金不变，'
              '只冲击收入/支出，看低谷多深、钱会不会断。不写账本。',
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
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var i = 0; i < _presets.length; i++)
                      ChoiceChip(
                        label: Text(_presets[i].label),
                        selected: _preset == i,
                        onSelected: (_) => setState(() {
                          _preset = i;
                          _result = null;
                        }),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _presets[_preset].subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.hintColor,
                  ),
                ),
                const SizedBox(height: 12),
                _extrasCard(theme),
                const SizedBox(height: 12),
                ParticleFilledButton.icon(
                  onPressed: _running ? null : _run,
                  icon: _running
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.play_arrow),
                  label: Text(_running ? '模拟中…' : '运行模拟'),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: AppColors.negativeOf(theme.brightness),
                      ),
                    ),
                  ),
                if (_result != null) ...[
                  const SizedBox(height: 16),
                  _resultCard(theme, _result!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _extrasCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '叠加自定义冲击（可选）',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 5,
                  child: ParticleTextField(
                    controller: _extraMonthly,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      isDense: true,
                      labelText: '额外月支出（元/月）',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<int>(
                    initialValue: _extraMonths,
                    isDense: true,
                    decoration: const InputDecoration(labelText: '月数'),
                    items: [
                      for (final m in const [3, 6, 12, 24])
                        DropdownMenuItem(value: m, child: Text('$m 月')),
                    ],
                    onChanged: (v) => setState(() => _extraMonths = v ?? 6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  flex: 5,
                  child: ParticleTextField(
                    controller: _oneOffAmount,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      isDense: true,
                      labelText: '一次性支出（元）',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<int>(
                    initialValue: _oneOffAfterDays,
                    isDense: true,
                    decoration: const InputDecoration(labelText: '发生在'),
                    items: [
                      for (final d in const [0, 15, 30, 90])
                        DropdownMenuItem(value: d, child: Text('$d 天后')),
                    ],
                    onChanged: (v) =>
                        setState(() => _oneOffAfterDays = v ?? 15),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _resultCard(ThemeData theme, ScenarioComparison r) {
    final neg = AppColors.negativeOf(theme.brightness);
    final pos = AppColors.positiveOf(theme.brightness);
    final brass = AppColors.brassOf(theme.brightness);
    final delta = r.minBalanceDelta;
    final cashOut = r.firstCashOutDate;
    final newShort = r.newShortfalls;
    return SectionCard(
      title: '结果 · ${_presets[_preset].label}',
      child: Column(
        children: [
          StatRow(
            label: '最低现金 · 基线',
            value: fmtMinor(r.baseline.minBalanceBaseMinor, _base),
          ),
          StatRow(
            label: '最低现金 · 情景',
            value: fmtMinor(r.scenario.minBalanceBaseMinor, _base),
            emphasized: true,
            valueColor: r.scenario.minBalanceBaseMinor < BigInt.zero
                ? neg
                : null,
          ),
          StatRow(
            label: '低谷变化',
            value: '${delta.isNegative ? '' : '+'}${fmtMinor(delta, _base)}',
            valueColor: delta.isNegative ? neg : pos,
          ),
          if (r.worstDailyDelta != delta) ...[
            StatRow(
              label: '最难受的一天（相对基线）',
              value:
                  '${r.worstDailyDelta.isNegative ? '' : '+'}${fmtMinor(r.worstDailyDelta, _base)}',
              valueColor: r.worstDailyDelta.isNegative ? neg : pos,
            ),
          ],
          if (cashOut != null)
            StatRow(
              label: '现金耗尽日',
              value:
                  '${cashOut.year}-${cashOut.month.toString().padLeft(2, '0')}-${cashOut.day.toString().padLeft(2, '0')}（还剩 ${r.daysToCashOut} 天）',
              valueColor: neg,
              emphasized: true,
            )
          else
            StatRow(label: '现金耗尽日', value: '预测期内未耗尽', valueColor: pos),
          if (newShort.isNotEmpty) ...[
            const Divider(height: 16),
            Text(
              '新增缺口（基线没有、情景触发的）',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.hintColor,
              ),
            ),
            for (final s in newShort.take(5))
              StatRow(
                label:
                    '${s.date.month}/${s.date.day} ${s.accountId != null ? s.label : '低于准备金与底线'}',
                value: fmtMinor(s.amountBaseMinor, _base),
                valueColor: neg,
              ),
            if (newShort.length > 5)
              Text(
                '…共 ${newShort.length} 条',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.hintColor,
                ),
              ),
          ],
          const Divider(height: 16),
          Row(
            children: [
              Icon(
                r.survives ? Icons.check_circle : Icons.warning_amber,
                size: 18,
                color: r.survives ? pos : brass,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  r.survives
                      ? '情景可承受：无新增缺口、现金未耗尽。底线之外仍有余量 ${fmtMinor(r.scenario.discretionaryBaseMinor, _base)}。'
                      : '该情景会造成伤害：考虑提高准备金、推迟可选支出或安排信用额度备用。',
                  style: theme.textTheme.bodySmall?.copyWith(height: 1.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '口径：与现金预测同引擎重放（docs/05 §12）；准备金、债务还款与底线不变。',
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
