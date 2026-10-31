import 'package:flutter/material.dart';

import '../../domain/money/currency.dart';
import '../../domain/money/fx_rate.dart';
import '../../domain/money/money.dart';
import '../../domain/planning/life_planner.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/runtime_l10n.dart';
import '../widgets/common.dart';

/// 人生规划事件的新建/编辑对话框 + 摘要文案。

Future<LifeEvent?> showLifeEventDialog(
  BuildContext context, {
  LifeEvent? initial,
}) async {
  if (initial != null) {
    return showAppDialog<LifeEvent>(
      context,
      builder: (_) => _EventFormDialog(event: initial),
    );
  }
  // 类型选择先返回索引，由外层（活跃）context 弹表单——
  // 在对话框 onPressed 里 pop 后立刻用自身 context 会查已失活的 element。
  final kind = await showAppDialog<int>(
    context,
    builder: (_) => const _EventTypeDialog(),
  );
  if (kind == null || !context.mounted) return null;
  return showAppDialog<LifeEvent>(
    context,
    builder: (_) => _EventFormDialog(kind: kind),
  );
}

/// 事件类型选择（返回索引）。
class _EventTypeDialog extends StatelessWidget {
  const _EventTypeDialog();

  static final _types = [
    (Icons.home_work_outlined, rt('买房（含贷款）')),
    (Icons.child_care_outlined, rt('生孩子 / 抚养')),
    (Icons.trending_up, rt('收入跳变（升职/失业）')),
    (Icons.beach_access_outlined, rt('退休')),
    (Icons.directions_car_outlined, rt('大件购置（换车等）')),
    (Icons.payments_outlined, rt('一次性大额收支')),
  ];

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return AppDialog(
      title: t.lifeEventAddTitle,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, t) in _types.indexed)
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => Navigator.pop(context, i),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(t.$1, size: 20),
                    const SizedBox(width: 12),
                    Text(t.$2),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EventFormDialog extends StatefulWidget {
  const _EventFormDialog({this.kind, this.event});

  final int? kind; // _EventTypeDialog 索引
  final LifeEvent? event;

  @override
  State<_EventFormDialog> createState() => _EventFormDialogState();
}

class _EventFormDialogState extends State<_EventFormDialog> {
  late final int _kind = widget.event != null
      ? switch (widget.event!) {
          HomePurchase() => 0,
          ChildRearing() => 1,
          IncomeChange() => 2,
          Retirement() => 3,
          BigPurchase() => 4,
          LumpSum() => 5,
        }
      : widget.kind!;

  final _c = <String, TextEditingController>{};
  String _termYears = '30';

  TextEditingController _f(String key, [String init = '']) =>
      _c.putIfAbsent(key, () => TextEditingController(text: init));

  @override
  void dispose() {
    for (final v in _c.values) {
      v.dispose();
    }
    super.dispose();
  }

  BigInt? _minor(String key) {
    final t = _c[key]?.text.trim() ?? '';
    if (t.isEmpty) return null;
    try {
      return Money.parse(t, CurrencyInfo.cny).amountMinor;
    } on FormatException {
      return null;
    }
  }

  int? _int(String key) => int.tryParse(_c[key]?.text.trim() ?? '');

  Rational? _pct(String key) {
    final v = double.tryParse(_c[key]?.text.trim() ?? '');
    if (v == null || v <= -100 || v > 1000) return null;
    return Rational.parseDecimal(v.toString());
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final fields = switch (_kind) {
      0 => t.lifeEventBuyHome,
      1 => t.lifeEventChildRearing,
      2 => t.lifeEventIncomeChange,
      3 => t.lifeEventRetirement,
      4 => t.lifeEventBigPurchase,
      _ => t.lifeEventLumpSum,
    };
    return AppDialog(
      title: fields,
      scroll: true,
      content: _form(),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(t.cancel),
        ),
        ParticleFilledButton(onPressed: _save, child: Text(t.confirm)),
      ],
    );
  }

  Widget _num(String key, String label, {String init = ''}) =>
      ParticleTextField(
        controller: _f(key, init),
        keyboardType: const TextInputType.numberWithOptions(
          decimal: true,
          signed: true,
        ),
        decoration: InputDecoration(isDense: true, labelText: label),
      );

  Widget _form() {
    final t = AppLocalizations.of(context);
    switch (_kind) {
      case 0:
        final e = widget.event as HomePurchase?;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _num(
              'y',
              t.lifeEventYearsLater,
              init: e == null ? '3' : (e.month / 12).round().toString(),
            ),
            _num(
              'price',
              t.lifeEventTotalPrice,
              init: e?.priceMinor == null ? '' : _yuan(e!.priceMinor),
            ),
            _num(
              'down',
              t.lifeEventDownPayment,
              init: e?.downPaymentMinor == null
                  ? ''
                  : _yuan(e!.downPaymentMinor),
            ),
            _num(
              'rate',
              t.lifeEventAnnualRateHint,
              init: e == null
                  ? '3.6'
                  : (e.annualRate.asDouble() * 100).toString(),
            ),
            ParticleDropdownField<String>(
              initialValue: e == null
                  ? '30'
                  : (e.termYears == 10 ||
                        e.termYears == 20 ||
                        e.termYears == 30)
                  ? e.termYears.toString()
                  : '30',
              decoration: InputDecoration(labelText: t.lifeEventLoanTerm),
              items: [
                DropdownMenuItem(value: '10', child: Text(t.yearsN('10'))),
                DropdownMenuItem(value: '20', child: Text(t.yearsN('20'))),
                DropdownMenuItem(value: '30', child: Text(t.yearsN('30'))),
              ],
              onChanged: (v) => _termYears = v ?? '30',
            ),
          ],
        );
      case 1:
        final e = widget.event as ChildRearing?;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _num(
              'y',
              t.lifeEventYearsUntilBirth,
              init: e == null ? '2' : (e.month / 12).round().toString(),
            ),
            _num(
              'm',
              t.lifeEventMonthlyRearingCost,
              init: e?.monthlyCostMinor == null
                  ? '3000'
                  : _yuan(e!.monthlyCostMinor),
            ),
            _num(
              'c',
              t.lifeEventCollegeExtra,
              init: e?.collegeExtraMinor == null
                  ? ''
                  : _yuan(e!.collegeExtraMinor!),
            ),
          ],
        );
      case 2:
        final e = widget.event as IncomeChange?;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _num(
              'y',
              t.lifeEventYearsLater,
              init: e == null ? '1' : (e.month / 12).round().toString(),
            ),
            _num(
              'p',
              t.lifeEventChangePctHint,
              init: e == null
                  ? '+30'
                  : ((e.factor - Rational.one) *
                            Rational.fromInt(BigInt.from(100)))
                        .asDouble()
                        .toString(),
            ),
          ],
        );
      case 3:
        final e = widget.event as Retirement?;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _num(
              'y',
              t.lifeEventYearsUntilRetire,
              init: e == null ? '30' : (e.month / 12).round().toString(),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                t.lifeEventRetirementNote,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        );
      case 4:
        final e = widget.event as BigPurchase?;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _num(
              'y',
              t.lifeEventYearsLater,
              init: e == null ? '5' : (e.month / 12).round().toString(),
            ),
            _num(
              'cost',
              t.lifeEventPurchaseCost,
              init: e?.costMinor == null ? '' : _yuan(e!.costMinor),
            ),
            _num(
              'r',
              t.lifeEventResidualValue,
              init: e?.residualMinor == null ? '' : _yuan(e!.residualMinor!),
            ),
          ],
        );
      default:
        final e = widget.event as LumpSum?;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _num(
              'y',
              t.lifeEventYearsLater,
              init: e == null ? '1' : (e.month / 12).round().toString(),
            ),
            _num(
              'a',
              t.lifeEventAmountInOut,
              init: e?.amountMinor == null ? '' : _yuan(e!.amountMinor),
            ),
          ],
        );
    }
  }

  String _yuan(BigInt minor) => (minor ~/ BigInt.from(100)).toString();

  void _save() {
    final y = _int('y');
    if (y == null || y < 0) return;
    final month = y * 12;
    LifeEvent? ev;
    switch (_kind) {
      case 0:
        final price = _minor('price');
        final down = _minor('down');
        final rate = _pct('rate');
        if (price != null && down != null && rate != null && down < price) {
          ev = HomePurchase(
            month: month,
            priceMinor: price,
            downPaymentMinor: down,
            annualRate: rate / Rational.fromInt(BigInt.from(100)),
            termYears: int.parse(_termYears),
          );
        }
      case 1:
        final m = _minor('m');
        if (m != null) {
          ev = ChildRearing(
            month: month,
            monthlyCostMinor: m,
            collegeExtraMinor: _minor('c'),
          );
        }
      case 2:
        final p = _pct('p');
        if (p != null) {
          ev = IncomeChange(
            month: month,
            factor: Rational.one + p / Rational.fromInt(BigInt.from(100)),
          );
        }
      case 3:
        ev = Retirement(month: month);
      case 4:
        final cost = _minor('cost');
        if (cost != null) {
          ev = BigPurchase(
            month: month,
            costMinor: cost,
            residualMinor: _minor('r'),
          );
        }
      default:
        final a = _minor('a');
        if (a != null) ev = LumpSum(month: month, amountMinor: a);
    }
    if (ev != null) Navigator.pop(context, ev);
  }
}

/// 事件列表摘要（弹层展示用）。
String lifeEventSummary(LifeEvent e) {
  String yuan(BigInt minor) =>
      '${minor ~/ BigInt.from(1000000)} ${rt('万')}'; // 万 = 10^6 分
  String inYears(int month) =>
      month == 0 ? rt('现在') : '${(month / 12).round()} ${rt('年后')}';
  return switch (e) {
    HomePurchase h =>
      '${inYears(h.month)}${rt('买房')} ${yuan(h.priceMinor)}${rt('（首付')} ${yuan(h.downPaymentMinor)} · ${(h.annualRate.asDouble() * 100).toStringAsFixed(2)}% × ${h.termYears}${rt(' 年）')}',
    ChildRearing c =>
      '${inYears(c.month)}${rt('生孩子（月成本')} ${yuan(c.monthlyCostMinor)}${c.collegeExtraMinor != null && c.collegeExtraMinor != BigInt.zero ? ' · ${rt('大学加')} ${yuan(c.collegeExtraMinor!)}' : ''}${rt('）')}',
    IncomeChange ic =>
      '${inYears(ic.month)}${rt('收入')}${ic.factor >= Rational.one ? rt('涨') : rt('降')}${rt('到')} ${((ic.factor - Rational.one) * Rational.fromInt(BigInt.from(100))).asDouble().toStringAsFixed(0)}%',
    Retirement r => '${inYears(r.month)}${rt('退休')}',
    BigPurchase b =>
      '${inYears(b.month)}${rt('购置')} ${yuan(b.costMinor)}${b.residualMinor != null && b.residualMinor != BigInt.zero ? '${rt('（残值')} ${yuan(b.residualMinor!)}${rt('）')}' : ''}',
    LumpSum l =>
      '${inYears(l.month)}${rt('一次性')}${l.amountMinor.isNegative ? rt('流出') : rt('流入')} ${yuan(l.amountMinor.abs())}',
  };
}
