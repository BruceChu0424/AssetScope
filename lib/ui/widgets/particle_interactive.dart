import 'package:flutter/material.dart';

import 'particle_edge.dart';

export 'particle_edge.dart' show ParticleEdge;

/// 自带底缘粒子的按钮/输入框镜像件：API 与 Material 原件对齐（本项目
/// 用到的参数面），调用点只改类名即得悬停/聚焦光尘（docs/12 §9 默认
/// 动效）。交互、无障碍、主题行为全部由内部的原件承担。

/// [FilledButton] + 悬停底缘粒子（主行动钮的默认形态）。
class ParticleFilledButton extends StatelessWidget {
  const ParticleFilledButton({
    super.key,
    this.onPressed,
    this.onLongPress,
    this.style,
    this.autofocus = false,
    this.clipBehavior,
    required this.child,
  }) : icon = null,
       label = null;

  const ParticleFilledButton.icon({
    super.key,
    this.onPressed,
    this.onLongPress,
    this.style,
    this.autofocus = false,
    this.clipBehavior,
    required this.icon,
    required this.label,
  }) : child = label;

  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final ButtonStyle? style;
  final bool autofocus;
  final Clip? clipBehavior;
  final Widget? child;

  /// `.icon` 变体的图标与文案（child 此时承载 label）。
  final Widget? icon;
  final Widget? label;

  @override
  Widget build(BuildContext context) {
    final button = icon == null
        ? FilledButton(
            onPressed: onPressed,
            onLongPress: onLongPress,
            style: style,
            autofocus: autofocus,
            clipBehavior: clipBehavior,
            child: child,
          )
        : FilledButton.icon(
            onPressed: onPressed,
            onLongPress: onLongPress,
            style: style,
            autofocus: autofocus,
            clipBehavior: clipBehavior,
            icon: icon!,
            label: label!,
          );
    return ParticleEdge(band: 13, extendBelow: 6, child: button);
  }
}

/// [TextField] + 聚焦底缘粒子（controller 变化时迸「正在输入」火花）。
class ParticleTextField extends StatelessWidget {
  const ParticleTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.decoration = const InputDecoration(),
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.autofocus = false,
    this.readOnly = false,
    this.enabled = true,
    this.maxLength,
    this.minLines,
    this.maxLines = 1,
    this.textAlign = TextAlign.start,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final InputDecoration decoration;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final bool autofocus;
  final bool readOnly;
  final bool enabled;
  final int? maxLength;

  /// 多行输入（对齐 TextField：minLines 非 null 时按行数撑高）。
  final int? minLines;
  final int? maxLines;
  final TextAlign textAlign;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final GestureTapCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ParticleEdge.focus(
      controller: controller,
      focusNode: focusNode,
      band: 14,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        decoration: decoration,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        obscureText: obscureText,
        autofocus: autofocus,
        readOnly: readOnly,
        enabled: enabled,
        maxLength: maxLength,
        minLines: minLines,
        maxLines: maxLines,
        textAlign: textAlign,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        onTap: onTap,
      ),
    );
  }
}
