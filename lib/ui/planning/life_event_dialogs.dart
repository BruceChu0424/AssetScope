import 'package:flutter/material.dart';

import '../../domain/money/currency.dart';
import '../../domain/money/fx_rate.dart';
import '../../domain/money/money.dart';
import '../../domain/planning/life_planner.dart';
import '../widgets/particle_interactive.dart';

/// 人生规划事件的新建/编辑对话框 + 摘要文案。

Future<LifeEvent?> showLifeEventDialog(
  BuildContext context, {
  LifeEvent? initial,
}) async {
  if (initial != null) {
    return showDialog<LifeEvent>(
      context: context,
      builder: (_) => _EventFormDialog(event: initial),
    );
  }
  // 类型选择先返回索引，由外层（活跃）context 弹表单——
  // 在对话框 onPressed 里 pop 后立刻用自身 context 会查已失活的 element。
  final kind = await showDialog<int>(
    context: context,
    builder: (_) => const _EventTypeDialog(),
  );
  if (kind == null || !context.mounted) return null;
  return showDialog<LifeEvent>(
    context: context,
    builder: (_) => _EventFormDialog(kind: kind),
  );
}

/// 事件类型选择（返回索引）。
class _EventTypeDialog extends StatelessWidget {
  const _EventTypeDialog();

  static const _types = [
    (Icons.home_work_outlined, '买房（含贷款）'),
    (Icons.child_care_outlined, '生孩子 / 抚养'),
    (Icons.trending_up, '收入跳变（升职/失业）'),
    (Icons.beach_access_outlined, '退休'),
    (Icons.directions_car_outlined, '大件购置（换车等）'),
    (Icons.payments_outlined, '一次性大额收支'),
  ];

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: const Text('添加人生事件'),
      children: [
        for (final (i, t) in _types.indexed)
          SimpleDialogOption(
            child: Row(
              children: [
                Icon(t.$1, size: 20),
                const SizedBox(width: 12),
                Text(t.$2),
              ],
            ),
            onPressed: () => Navigator.pop(context, i),
          ),
      ],
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
    final fields = switch (_kind) {
      0 => '买房（含贷款）',
      1 => '生孩子 / 抚养',
      2 => '收入跳变',
      3 => '退休',
      4 => '大件购置',
      _ => '一次性大额收支',
    };
    return AlertDialog(
      title: Text(fields),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(child: _form()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ParticleFilledButton(onPressed: _save, child: const Text('确定')),
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
    switch (_kind) {
      case 0:
        final e = widget.event as HomePurchase?;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _num(
              'y',
              '几年后',
              init: e == null ? '3' : (e.month / 12).round().toString(),
            ),
            _num(
              'price',
              '总价（元）',
              init: e?.priceMinor == null ? '' : _yuan(e!.priceMinor),
            ),
            _num(
              'down',
              '首付（元）',
              init: e?.downPaymentMinor == null
                  ? ''
                  : _yuan(e!.downPaymentMinor),
            ),
            _num(
              'rate',
              '年利率 %（如 3.6）',
              init: e == null
                  ? '3.6'
                  : (e.annualRate.asDouble() * 100).toString(),
            ),
            DropdownButtonFormField<String>(
              initialValue: e == null
                  ? '30'
                  : (e.termYears == 10 ||
                        e.termYears == 20 ||
                        e.termYears == 30)
                  ? e.termYears.toString()
                  : '30',
              decoration: const InputDecoration(labelText: '贷款年限'),
              items: const [
                DropdownMenuItem(value: '10', child: Text('10 年')),
                DropdownMenuItem(value: '20', child: Text('20 年')),
                DropdownMenuItem(value: '30', child: Text('30 年')),
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
              '几年后出生',
              init: e == null ? '2' : (e.month / 12).round().toString(),
            ),
            _num(
              'm',
              '每月养育成本（元）',
              init: e?.monthlyCostMinor == null
                  ? '3000'
                  : _yuan(e!.monthlyCostMinor),
            ),
            _num(
              'c',
              '大学阶段每月额外（元，可空）',
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
              '几年后',
              init: e == null ? '1' : (e.month / 12).round().toString(),
            ),
            _num(
              'p',
              '变化 %（+30 涨三成 / −100 归零）',
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
              '几年后退休',
              init: e == null ? '30' : (e.month / 12).round().toString(),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                '退休后：收入 ×0.4（养老金替代率）、支出 ×0.75',
                style: TextStyle(fontSize: 12),
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
              '几年后',
              init: e == null ? '5' : (e.month / 12).round().toString(),
            ),
            _num(
              'cost',
              '购置支出（元）',
              init: e?.costMinor == null ? '' : _yuan(e!.costMinor),
            ),
            _num(
              'r',
              '残值计入固定资产（元，可空）',
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
              '几年后',
              init: e == null ? '1' : (e.month / 12).round().toString(),
            ),
            _num(
              'a',
              '金额（元，负数 = 流出）',
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
      '${minor ~/ BigInt.from(1000000)} 万'; // 万 = 10^6 分
  String inYears(int month) => month == 0 ? '现在' : '${(month / 12).round()} 年后';
  return switch (e) {
    HomePurchase h =>
      '${inYears(h.month)}买房 ${yuan(h.priceMinor)}（首付 ${yuan(h.downPaymentMinor)} · ${(h.annualRate.asDouble() * 100).toStringAsFixed(2)}% × ${h.termYears} 年）',
    ChildRearing c =>
      '${inYears(c.month)}生孩子（月成本 ${yuan(c.monthlyCostMinor)}${c.collegeExtraMinor != null && c.collegeExtraMinor != BigInt.zero ? ' · 大学加 ${yuan(c.collegeExtraMinor!)}' : ''}）',
    IncomeChange ic =>
      '${inYears(ic.month)}收入${ic.factor >= Rational.one ? '涨' : '降'}到 ${((ic.factor - Rational.one) * Rational.fromInt(BigInt.from(100))).asDouble().toStringAsFixed(0)}%',
    Retirement r => '${inYears(r.month)}退休',
    BigPurchase b =>
      '${inYears(b.month)}购置 ${yuan(b.costMinor)}${b.residualMinor != null && b.residualMinor != BigInt.zero ? '（残值 ${yuan(b.residualMinor!)}）' : ''}',
    LumpSum l =>
      '${inYears(l.month)}一次性${l.amountMinor.isNegative ? '流出' : '流入'} ${yuan(l.amountMinor.abs())}',
  };
}
