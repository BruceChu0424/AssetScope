import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 悬浮玻璃卡片：把现有财务卡（内部仍是 Card/SectionCard）包进一层
/// 「局部背景模糊 + 半透明深色 + 发丝细边 + 柔和悬浮阴影」的信息面板
/// 质感，像浮在星空之上。
///
/// - 每卡独立 ClipRRect + BackdropFilter：模糊只发生在卡片自身圆角内，
///   卡片之间的星空保持清晰（不做整列一体模糊）；
/// - 内层用 Theme 覆写 cardTheme 为全透明：Card/SectionCard 的内容与
///   排版原样保留，只剥掉它们自带的不透明底色；
/// - 明暗两套玻璃：深色=蓝碳玻璃，浅色=雾白玻璃（页面底是深空时文字
///   仍走主题色，保证可读）。
class GlassCard extends StatelessWidget {
  const GlassCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final tint = dark
        ? const Color(0xFF10161D).withValues(alpha: 0.74)
        : Colors.white.withValues(alpha: 0.80);
    final hairline = dark
        ? const Color(0x2EE7ECF2)
        : Colors.white.withValues(alpha: 0.85);
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.card),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.card),
            color: tint,
            border: Border.all(color: hairline),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: dark ? 0.32 : 0.10),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Theme(
            data: Theme.of(context).copyWith(
              cardTheme: const CardThemeData(
                elevation: 0,
                color: Colors.transparent,
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
