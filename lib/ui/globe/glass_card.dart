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
///   仍走主题色，保证可读）；
/// - v0.24 毛玻璃强化（2026-10 用户指令）：底色透明度下调 + 模糊加深
///   （16→24），让背后**随机游走的星尘粒子**（space_backdrop）透出
///   移动感——磨砂只有在有东西从后面掠过时才被感知；顶缘一道渐隐
///   高光（斜向 112° 光泽），配合发丝边构成「厚玻璃」读感。
class GlassCard extends StatelessWidget {
  const GlassCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final tint = dark
        ? const Color(0xFF10161D).withValues(alpha: 0.46)
        : Colors.white.withValues(alpha: 0.62);
    final hairline = dark
        ? const Color(0x33E7ECF2)
        : Colors.white.withValues(alpha: 0.90);
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.card),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
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
            child: Stack(
              children: [
                child,
                // 顶缘渐隐高光：一道斜向（112°）掠过玻璃上沿的光泽，与
                // 发丝边一起构成「厚玻璃」读感；纯装饰不参与命中。
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadii.card),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: const Alignment(0.4, 1),
                          colors: [
                            (dark ? Colors.white : Colors.white).withValues(
                              alpha: dark ? 0.085 : 0.35,
                            ),
                            Colors.white.withValues(alpha: 0),
                          ],
                          stops: const [0, 0.22],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
