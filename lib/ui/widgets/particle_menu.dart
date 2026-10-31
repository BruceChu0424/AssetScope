import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderBox, RenderRepaintBoundary;
import 'package:flutter/services.dart' show KeyDownEvent, LogicalKeyboardKey;

import 'particle_dialog.dart' show kParticleDialogTestEnv;
import 'particle_dialog_stage.dart';
import 'soft_sprite.dart';

/// ── 粒子下拉/菜单（v0.25，2026-10 用户指令：下拉弹层动画与显示效果
/// 全量重构——弃用框架默认 _DropdownRoute）────────────────────────────
///
/// - [ParticleDropdownField]：`DropdownButtonFormField` 的镜像件，参数面
///   对齐（initialValue/items/onChanged/decoration/isExpanded/
///   menuMaxHeight/itemHeight/borderRadius），调用点只换类名。
/// - [ParticleMenuButton]：`PopupMenuButton` 的替代（溢出菜单三件套）。
/// - 弹层动画与全站弹窗同一语言：**入场**粒子自四周快速汇拢成菜单
///   形态（320ms，1400 颗 + 尘云），条目 20ms 阶梯自上滑入；**选中**
///   截图粒子化 → 向核心收束 → 迸散闪光环（「拿走了这一项」）；
///   **取消**（点外部/ESC）温和外散。
///
/// 减少动画/FLUTTER_TEST：无粒子（菜单直显/直隐，pumpAndSettle 安全）。

/// 下拉选择域（FormField：表单校验/保存语义完整保留）。
class ParticleDropdownField<T> extends FormField<T> {
  ParticleDropdownField({
    super.key,
    this.items,
    super.initialValue,
    this.onChanged,
    super.validator,
    super.onSaved,
    super.enabled = true,
    this.decoration = const InputDecoration(),
    this.isExpanded = true,
    this.isDense = false,
    this.menuMaxHeight = 380,
    this.itemHeight = 48,
    this.borderRadius,
    this.focusNode,
    super.autovalidateMode,
  }) : super(
         builder: (field) =>
             (field as _ParticleDropdownFieldState<T>)._build(),
       );

  final List<DropdownMenuItem<T>>? items;
  final ValueChanged<T?>? onChanged;
  final InputDecoration decoration;
  final bool isExpanded;

  /// 兼容 DropdownButtonFormField 的密度开关（装饰内边距由
  /// [decoration].contentPadding 决定，这里仅为参数面兼容保留）。
  final bool isDense;
  final double? menuMaxHeight;
  final double itemHeight;
  final BorderRadius? borderRadius;
  final FocusNode? focusNode;

  @override
  FormFieldState<T> createState() => _ParticleDropdownFieldState<T>();
}

class _ParticleDropdownFieldState<T> extends FormFieldState<T> {
  bool _open = false;

  @override
  ParticleDropdownField<T> get widget =>
      super.widget as ParticleDropdownField<T>;

  Widget _build() {
    final theme = Theme.of(context);
    final effective = widget.decoration.applyDefaults(
      theme.inputDecorationTheme,
    );
    DropdownMenuItem<T>? current;
    for (final i in widget.items ?? <DropdownMenuItem<T>>[]) {
      if (i.value == value) {
        current = i;
        break;
      }
    }
    final enabled = widget.enabled;
    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? _openMenu : null,
        child: InputDecorator(
          isEmpty: current == null,
          decoration: effective.copyWith(
            suffixIcon: Padding(
              padding: const EdgeInsets.only(right: 10),
              child: AnimatedRotation(
                turns: _open ? 0.5 : 0,
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                child: Icon(
                  Icons.expand_more,
                  size: 20,
                  color: _open ? theme.colorScheme.primary : theme.hintColor,
                ),
              ),
            ),
            suffixIconConstraints: const BoxConstraints(
              minWidth: 30,
              minHeight: 30,
            ),
          ),
          child: Text(
            current != null
                ? _labelOf(current)
                : (effective.hintText ?? ''),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: enabled
                  ? theme.colorScheme.onSurface
                  : theme.disabledColor,
              fontWeight: current != null ? FontWeight.w500 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }

  /// 取菜单项纯文本（装饰层内统一单行省略；任意 child 场景退化到
  /// value 文本，条目弹层里仍显示原 child）。
  String _labelOf(DropdownMenuItem<T> item) {
    final child = item.child;
    if (child is Text) return child.data ?? '';
    return item.value?.toString() ?? '';
  }

  void _openMenu() {
    final items = widget.items;
    if (items == null || items.isEmpty) return;
    final fieldBox = context.findRenderObject();
    if (fieldBox is! RenderBox || !fieldBox.hasSize) return;
    setState(() => _open = true);
    final fieldRect = fieldBox.localToGlobal(Offset.zero) & fieldBox.size;
    final overlay = Overlay.of(context, rootOverlay: true);
    late final OverlayEntry entry;
    void close(Object? selected) {
      if (entry.mounted) entry.remove();
      if (!mounted) return;
      setState(() => _open = false);
      if (selected != null) {
        didChange(selected as T);
        widget.onChanged?.call(selected as T);
      }
    }

    entry = OverlayEntry(
      builder: (_) => ParticleMenuOverlay(
        anchor: fieldRect,
        items: [
          for (final i in items)
            ParticleMenuEntry(
              value: i.value,
              label: _labelOf(i),
              child: i.child,
            ),
        ],
        selectedValue: value,
        itemHeight: widget.itemHeight,
        maxHeight: widget.menuMaxHeight ?? 380,
        borderRadius: widget.borderRadius,
        onSelect: close,
        onDismiss: () => close(null),
      ),
    );
    overlay.insert(entry);
  }
}

/// 菜单条目（下拉与溢出菜单共用；[child] 优先显示，[label] 用于
/// 字段回显与语义）。
class ParticleMenuEntry<T> {
  const ParticleMenuEntry({
    required this.value,
    required this.label,
    this.child,
    this.icon,
    this.destructive = false,
  });

  final T value;
  final String label;
  final Widget? child;
  final IconData? icon;
  final bool destructive;
}

/// 溢出菜单钮（PopupMenuButton 替代）：点按弹同款粒子菜单。
class ParticleMenuButton<T> extends StatefulWidget {
  const ParticleMenuButton({
    super.key,
    required this.tooltip,
    required this.items,
    this.icon = Icons.more_vert,
    this.onSelected,
    this.child,
  });

  final String tooltip;
  final List<ParticleMenuEntry<T>> items;
  final IconData icon;

  /// 选中回调；取消不回调。
  final ValueChanged<T>? onSelected;

  /// 自定义按钮内容（默认 34px 幽灵圆钮）。
  final Widget? child;

  @override
  State<ParticleMenuButton<T>> createState() => _ParticleMenuButtonState<T>();
}

class _ParticleMenuButtonState<T> extends State<ParticleMenuButton<T>> {
  bool _hover = false;
  bool _pressed = false;

  void _open() {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return;
    final rect = box.localToGlobal(Offset.zero) & box.size;
    final overlay = Overlay.of(context, rootOverlay: true);
    late final OverlayEntry entry;
    void close(Object? selected) {
      if (entry.mounted) entry.remove();
      if (selected != null) widget.onSelected?.call(selected as T);
    }

    entry = OverlayEntry(
      builder: (_) => ParticleMenuOverlay(
        anchor: rect,
        items: [
          for (final e in widget.items)
            ParticleMenuEntry(
              value: e.value,
              label: e.label,
              child: e.child,
              icon: e.icon,
              destructive: e.destructive,
            ),
        ],
        itemHeight: 44,
        maxHeight: 420,
        alignEnd: true,
        onSelect: close,
        onDismiss: () => close(null),
      ),
    );
    overlay.insert(entry);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: Listener(
          onPointerDown: (_) => setState(() => _pressed = true),
          onPointerUp: (_) => setState(() => _pressed = false),
          onPointerCancel: (_) => setState(() => _pressed = false),
          child: AnimatedScale(
            scale: _pressed ? 0.92 : 1,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _open,
              child:
                  widget.child ??
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _hover
                          ? theme.colorScheme.onSurface.withValues(
                              alpha: 0.08,
                            )
                          : Colors.transparent,
                    ),
                    child: Icon(
                      widget.icon,
                      size: 19,
                      color: theme.hintColor,
                    ),
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 粒子菜单弹层：锚定 [anchor]（字段/按钮全局矩形），下方空间不足时
/// 向上弹；全屏透明屏障吸收首击并 ESC 关闭。
class ParticleMenuOverlay extends StatefulWidget {
  const ParticleMenuOverlay({
    super.key,
    required this.anchor,
    required this.items,
    required this.onSelect,
    required this.onDismiss,
    this.selectedValue,
    this.itemHeight = 48,
    this.maxHeight = 380,
    this.borderRadius,
    this.alignEnd = false,
  });

  final Rect anchor;
  final List<ParticleMenuEntry<Object?>> items;

  /// 选中（回传条目 value）与取消。
  final ValueChanged<Object?> onSelect;
  final VoidCallback onDismiss;
  final Object? selectedValue;
  final double itemHeight;
  final double maxHeight;
  final BorderRadius? borderRadius;
  final bool alignEnd;

  @override
  State<ParticleMenuOverlay> createState() => _ParticleMenuOverlayState();
}

class _ParticleMenuOverlayState extends State<ParticleMenuOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entry = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );
  final GlobalKey _panelKey = GlobalKey(debugLabel: 'particle-menu');
  final math.Random _rnd = math.Random();

  /// 屏障焦点（ESC 关闭）：overlay 的 Focus(autofocus) 抢不过模态
  /// scope，须挂帧显式 requestFocus。
  final FocusNode _keyFocus = FocusNode(debugLabel: 'particle-menu-key');

  List<ConvergeParticle>? _specs;
  List<DustLayer> _layers = const [];
  ui.Image? _sprite;
  ui.Image? _cloud;
  Rect? _menuRect;
  bool _closing = false;

  static final bool _noParticles = kParticleDialogTestEnv;

  @override
  void initState() {
    super.initState();
    _layers = bakeDustLayers(_rnd);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _keyFocus.requestFocus();
    });
    if (_noParticles) {
      _entry.value = 1;
      return;
    }
    bakeSoftSprite().then((img) {
      if (mounted) setState(() => _sprite = img);
    });
    dustCloudImage()?.then((img) {
      if (mounted) setState(() => _cloud = img);
    });
    _entry.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) => _armEntry());
  }

  @override
  void dispose() {
    _keyFocus.dispose();
    _entry.dispose();
    super.dispose();
  }

  void _armEntry() {
    if (!mounted || _specs != null) return;
    final ro = _panelKey.currentContext?.findRenderObject();
    if (ro is! RenderBox || !ro.hasSize || ro.size.isEmpty) return;
    setState(() {
      _menuRect = ro.localToGlobal(Offset.zero) & ro.size;
      _specs = sampleConvergence(
        rect: _menuRect!,
        targetCount: 1400,
        maxCount: 1800,
        seed: _rnd.nextInt(1 << 20),
      );
    });
  }

  void _select(Object? value) {
    if (_closing) return;
    _closing = true;
    if (_noParticles) return widget.onSelect(value);
    _playExit(DialogExitKind.burst, () => widget.onSelect(value));
  }

  void _dismiss() {
    if (_closing) return;
    _closing = true;
    if (_noParticles) return widget.onDismiss();
    _playExit(DialogExitKind.scatter, widget.onDismiss);
  }

  /// 菜单粒子化退场（截图采样同弹窗体系；选中为收束迸散，取消温和外散）。
  Future<void> _playExit(DialogExitKind kind, VoidCallback done) async {
    final ro = _panelKey.currentContext?.findRenderObject();
    if (ro is! RenderRepaintBoundary ||
        !ro.hasSize ||
        ro.size.isEmpty ||
        MediaQuery.disableAnimationsOf(context)) {
      done();
      return;
    }
    try {
      final image = await ro.toImage(pixelRatio: 1.0);
      final bytes = await image.toByteData();
      if (bytes == null || !mounted) {
        image.dispose();
        done();
        return;
      }
      final data = sampleDissolve(
        image: image,
        rgba: bytes.buffer.asUint8List(),
        dialogRect: ro.localToGlobal(Offset.zero) & ro.size,
        launchFrom: ro.localToGlobal(ro.size.center(Offset.zero)),
      );
      late final OverlayEntry stage;
      stage = OverlayEntry(
        builder: (_) => DialogExitStage(
          data: data,
          kind: kind,
          onDone: () {
            if (stage.mounted) stage.remove();
            image.dispose();
          },
        ),
      );
      Overlay.of(context, rootOverlay: true).insert(stage);
      // 与舞台同帧：回调立即生效，菜单「化作粒子被拿走」。
      done();
    } catch (_) {
      done();
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final screen = mq.size;
    final width = widget.anchor.width.clamp(180.0, 460.0);
    final menuH = math.min(
      widget.items.length * widget.itemHeight + 12,
      widget.maxHeight,
    );
    final below = widget.anchor.bottom + menuH <= screen.height - 12;
    final top =
        (below
            ? widget.anchor.bottom + 6
            : widget.anchor.top - menuH - 6)
        .clamp(12.0, screen.height)
        .toDouble();
    final maxLeft = math.max(12.0, screen.width - width - 12);
    final left =
        (widget.alignEnd ? widget.anchor.right - width : widget.anchor.left)
            .clamp(12.0, maxLeft)
            .toDouble();
    final radius = widget.borderRadius ?? BorderRadius.circular(14);

    return Stack(
      children: [
        // 透明屏障：吸收首击关闭菜单（不穿透激活下方控件）；ESC 同效。
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _dismiss,
            child: Focus(
              focusNode: _keyFocus,
              onKeyEvent: (node, e) {
                if (e is KeyDownEvent &&
                    e.logicalKey == LogicalKeyboardKey.escape) {
                  _dismiss();
                  return KeyEventResult.handled;
                }
                return KeyEventResult.ignored;
              },
              child: const SizedBox.expand(),
            ),
          ),
        ),
        // 入场粒子（菜单面板之下）。
        if (!_closing && !_noParticles)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: ConvergePainter(
                  progress: _entry.value,
                  particles: _specs ?? const [],
                  sprite: _sprite,
                  cloud: _cloud,
                  layers: _layers,
                  rect: _menuRect ?? widget.anchor,
                ),
              ),
            ),
          ),
        // 菜单面板：显形与条目阶梯由 _entry 驱动；退场立即隐藏
        //（画面交给粒子舞台）。
        Positioned(
          left: left,
          top: top,
          width: width,
          child: AnimatedBuilder(
            animation: _entry,
            builder: (context, child) {
              final surface = _closing
                  ? 0.0
                  : Curves.easeOutCubic.transform(
                      ((_entry.value - 0.45) / 0.55).clamp(0.0, 1.0),
                    );
              return IgnorePointer(
                ignoring: _closing,
                child: Opacity(
                  opacity: surface,
                  child: Transform.scale(
                    scale: 0.97 + 0.03 * surface,
                    alignment: Alignment.topCenter,
                    child: child,
                  ),
                ),
              );
            },
            child: RepaintBoundary(
              key: _panelKey,
              child: _MenuPanel(
                items: widget.items,
                selectedValue: widget.selectedValue,
                itemHeight: widget.itemHeight,
                maxHeight: widget.maxHeight,
                radius: radius,
                entry: _entry,
                onSelect: _select,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 菜单面板本体：玻璃卡家族（surface + 发丝边 + 圆角），条目 hover 洗底
/// /选中高亮/危险语义红，20ms 阶梯自上滑入。
class _MenuPanel extends StatelessWidget {
  const _MenuPanel({
    required this.items,
    required this.selectedValue,
    required this.itemHeight,
    required this.maxHeight,
    required this.radius,
    required this.entry,
    required this.onSelect,
  });

  final List<ParticleMenuEntry<Object?>> items;
  final Object? selectedValue;
  final double itemHeight;
  final double maxHeight;
  final BorderRadius radius;
  final Animation<double> entry;
  final ValueChanged<Object?> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final negative = theme.colorScheme.error;
    return Material(
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: theme.dividerColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < items.length; i++)
                _staggeredItem(i, items[i], theme, negative),
            ],
          ),
        ),
      ),
    );
  }

  Widget _staggeredItem(
    int i,
    ParticleMenuEntry<Object?> item,
    ThemeData theme,
    Color negative,
  ) {
    // 条目阶梯：每项 5% 错峰（≈20ms）淡入 + 自上滑入（easeOutCubic）。
    final begin = (i * 0.05).clamp(0.0, 0.4);
    final curved = CurvedAnimation(
      parent: entry,
      curve: Interval(begin, (begin + 0.5).clamp(0.0, 1.0)),
    );
    final selected = item.value == selectedValue;
    final color = item.destructive
        ? negative
        : selected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurface;
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -0.12),
          end: Offset.zero,
        ).animate(curved),
        child: _MenuItemRow(
          item: item,
          height: itemHeight,
          selected: selected,
          color: color,
          scheme: theme.colorScheme,
          onTap: () => onSelect(item.value),
        ),
      ),
    );
  }
}

class _MenuItemRow extends StatefulWidget {
  const _MenuItemRow({
    required this.item,
    required this.height,
    required this.selected,
    required this.color,
    required this.scheme,
    required this.onTap,
  });

  final ParticleMenuEntry<Object?> item;
  final double height;
  final bool selected;
  final Color color;
  final ColorScheme scheme;
  final VoidCallback onTap;

  @override
  State<_MenuItemRow> createState() => _MenuItemRowState();
}

class _MenuItemRowState extends State<_MenuItemRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final scheme = widget.scheme;
    final item = widget.item;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Container(
          height: widget.height,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: widget.selected
                ? scheme.primary.withValues(alpha: 0.12)
                : _hover
                ? scheme.primary.withValues(alpha: 0.06)
                : Colors.transparent,
          ),
          child: Row(
            children: [
              if (item.icon != null) ...[
                Icon(item.icon, size: 19, color: widget.color),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: DefaultTextStyle(
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: widget.color,
                    fontWeight:
                        widget.selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  child: item.child ?? Text(item.label),
                ),
              ),
              if (widget.selected) ...[
                const SizedBox(width: 8),
                Icon(Icons.check, size: 17, color: scheme.primary),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
