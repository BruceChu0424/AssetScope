import 'package:flutter/material.dart';

/// 老虎机式数字滚动：文本中的**数字位**在值变化时逐位上滚——每一位是
/// 一条 0-9 循环的纵向数字条，按连续位置平移（单调向上转，进位像
/// 机械计数器）；非数字字符（币符/千分位/小数点/负号）交叉淡变；
/// 位数或骨架变化时整串淡切。
///
/// 手感来源：单列 300ms easeOutCubic，且**连续重定向平滑续走**
/// （TweenAnimationBuilder 从当前值起步）——配合外层数值插值（如
/// 0→目标 的滚动计数）就是各位波次滚动的老虎机效果：个位滚得最快、
/// 高位次之，落位时依次收束。「减少动画」直接静态显示。
class Odometer extends StatefulWidget {
  const Odometer({super.key, required this.text, required this.style});

  final String text;
  final TextStyle style;

  @override
  State<Odometer> createState() => _OdometerState();
}

class _OdometerState extends State<Odometer> {
  /// 每个字符位的连续滚动位置（数字空间，可 >10 表示滚过整圈）。
  /// 非数字位为 null。
  late List<double?> _positions;

  @override
  void initState() {
    super.initState();
    _positions = [
      for (var i = 0; i < widget.text.length; i++)
        _digitOf(widget.text[i])?.toDouble(),
    ];
  }

  static int? _digitOf(String c) =>
      c.codeUnitAt(0) >= 0x30 && c.codeUnitAt(0) <= 0x39
      ? c.codeUnitAt(0) - 0x30
      : null;

  @override
  void didUpdateWidget(Odometer old) {
    super.didUpdateWidget(old);
    if (old.text == widget.text) return;
    final next = <double?>[
      for (var i = 0; i < widget.text.length; i++)
        _digitOf(widget.text[i])?.toDouble(),
    ];
    // 长度/骨架（哪些位是非数字）不同：整串重建（外层 AnimatedSwitcher
    // 淡切）；否则逐位重定向——单调向上滚到下一个出现的目标数字。
    if (next.length != _positions.length ||
        _skeleton(widget.text) != _skeleton(old.text)) {
      _positions = next;
      return;
    }
    for (var i = 0; i < next.length; i++) {
      final d = next[i];
      final pos = _positions[i];
      if (d == null || pos == null) continue; // 非数字位交给淡变
      final target = d.toInt();
      var end = pos.ceil().toDouble();
      if (end <= pos && end == pos) end = pos; // 整数位保持
      while (((end.toInt() % 10) + 10) % 10 != target || end < pos) {
        end += 1;
      }
      _positions[i] = end == pos ? pos : end;
    }
  }

  /// 骨架：非数字字符序列 + 总长度（决定是否需要整串重建）。
  static String _skeleton(String s) =>
      '${s.length}:${s.replaceAll(RegExp(r'\d'), '#')}';

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    final style = widget.style.copyWith(height: widget.style.height ?? 1.2);
    if (reduce) {
      return Text(widget.text, style: style);
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 240),
      // scaleDown：数字串超宽（极端金额/窄窗/测试方块字形）时整串
      // 等比收缩到可用宽，永不横向溢出；正常情况 1:1 原样呈现。
      child: FittedBox(
        fit: BoxFit.scaleDown,
        key: ValueKey(_skeleton(widget.text)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            for (var i = 0; i < widget.text.length; i++)
              _positions[i] == null
                  ? _FadingChar(char: widget.text[i], style: style)
                  : _DigitColumn(
                      targetPos: _positions[i]!,
                      style: style,
                      cellH: (style.fontSize ?? 14) * (style.height ?? 1.2),
                    ),
          ],
        ),
      ),
    );
  }
}

/// 单个数字列：数字条纵向平移。条上渲染当前位与后续两位（覆盖滚动
/// 中的过渡），按小数部分偏移；tabular figures 保证列宽稳定。
class _DigitColumn extends StatelessWidget {
  const _DigitColumn({
    required this.targetPos,
    required this.style,
    required this.cellH,
  });

  /// 目标连续位置（数字空间；动画从上一目标续走）。
  final double targetPos;
  final TextStyle style;
  final double cellH;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: targetPos),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      builder: (context, pos, _) {
        final base = pos.floor();
        final frac = pos - base;
        return SizedBox(
          height: cellH,
          child: ClipRect(
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                for (var i = -1; i <= 2; i++)
                  Transform.translate(
                    offset: Offset(0, (i - frac) * cellH),
                    child: Text(
                      '${((base + i) % 10 + 10) % 10}',
                      style: style,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 非数字字符：变化时交叉淡变（币符/分隔符等几乎不变，兜底优雅）。
class _FadingChar extends StatelessWidget {
  const _FadingChar({required this.char, required this.style});

  final String char;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: Text(char, key: ValueKey(char), style: style),
    );
  }
}
