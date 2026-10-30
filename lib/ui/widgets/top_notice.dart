import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 顶部通知条：错误/提示从屏幕顶部滑入，替代表单内联错误文案。
///
/// `showTopNotice(context, '主口令或恢复码不正确')` —— 挂在根 Overlay
/// 之上，不被路由切换销毁。玻璃拟态（高斯模糊 + 半透明表面），
/// 入场自顶部滑下 320ms easeOutCubic，离场沿原路滑回 240ms（对称
/// 路径）；点按立即关闭，超时自动关闭。系统「减少动画」时仅淡入淡出。
enum TopNoticeTone { info, error }

void showTopNotice(
  BuildContext context,
  String message, {
  TopNoticeTone tone = TopNoticeTone.error,
}) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _TopNoticeView(
      entry: entry,
      message: message,
      tone: tone,
      slot: _TopNoticeState._takeSlot(),
    ),
  );
  overlay.insert(entry);
}

class _TopNoticeView extends StatefulWidget {
  const _TopNoticeView({
    required this.entry,
    required this.message,
    required this.tone,
    required this.slot,
  });

  final OverlayEntry entry;
  final String message;
  final TopNoticeTone tone;
  final int slot;

  @override
  State<_TopNoticeView> createState() => _TopNoticeState();
}

class _TopNoticeState extends State<_TopNoticeView>
    with SingleTickerProviderStateMixin {
  /// 同屏多条时自上而下错开（近似槽位，不做布局协商）。
  static int _active = 0;

  static int _takeSlot() => _active++;

  static void _releaseSlot() => _active--;

  late final AnimationController _slide = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
    reverseDuration: const Duration(milliseconds: 240),
  );
  late final CurvedAnimation _curve = CurvedAnimation(
    parent: _slide,
    curve: Curves.easeOutCubic,
  );
  Timer? _hold;
  bool _reduce = false;
  bool _started = false;
  bool _dismissed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // MediaQuery 不能在 initState 读；首次依赖时启动入场并排自动关闭。
    if (!_started) {
      _started = true;
      _reduce = MediaQuery.disableAnimationsOf(context);
      _slide.forward();
      final ttl = widget.tone == TopNoticeTone.error
          ? const Duration(milliseconds: 3200)
          : const Duration(milliseconds: 2400);
      _hold = Timer(ttl, _dismiss);
    }
  }

  @override
  void dispose() {
    _hold?.cancel();
    _curve.dispose();
    _slide.dispose();
    _releaseSlot();
    super.dispose();
  }

  void _dismiss() {
    if (_dismissed) return;
    _dismissed = true;
    _hold?.cancel();
    _slide.reverse().whenComplete(widget.entry.remove);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final error = widget.tone == TopNoticeTone.error;
    final accent = error
        ? AppColors.negativeOf(theme.brightness)
        : theme.colorScheme.primary;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        minimum: const EdgeInsets.only(top: 10),
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: EdgeInsets.only(top: 64.0 * widget.slot),
            child: SlideTransition(
              // 减少动画：保留淡入淡出，归零滑移。
              position: Tween(
                begin: _reduce ? Offset.zero : const Offset(0, -1),
                end: Offset.zero,
              ).animate(_curve),
              child: FadeTransition(
                opacity: _curve,
                child: GestureDetector(
                  onTap: _dismiss,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHigh
                                .withValues(alpha: 0.78),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: accent.withValues(
                                alpha: error ? 0.5 : 0.35,
                              ),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.22),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                error
                                    ? Icons.error_rounded
                                    : Icons.info_rounded,
                                size: 20,
                                color: accent,
                              ),
                              const SizedBox(width: 10),
                              Flexible(
                                child: Text(
                                  widget.message,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
