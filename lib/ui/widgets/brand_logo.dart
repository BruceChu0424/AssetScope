import 'package:flutter/material.dart';

/// 品牌图形标：资观 A mark。
///
/// 透明背景单色图形，按当前主题亮度自动选款：
/// 浅色背景配绿色款（#087F6B），深色背景配白色款。
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 40});

  /// 图形边长（正方形）。
  final double size;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Image.asset(
      dark ? 'assets/logo/mark_dark.png' : 'assets/logo/mark_light.png',
      width: size,
      height: size,
    );
  }
}

/// 品牌 lockup：A mark + AssetScope 字标（横排组合）。
///
/// 用于品牌时刻（首启动、关于页等），同一画面内不要再叠 [BrandMark]
/// 或重复出现 "AssetScope" 文字。
class BrandLockup extends StatelessWidget {
  const BrandLockup({super.key, this.width = 280});

  /// 组合标宽度；高度按 3200:735 原比例自适应。
  final double width;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Image.asset(
      dark ? 'assets/logo/lockup_dark.png' : 'assets/logo/lockup_light.png',
      width: width,
    );
  }
}
