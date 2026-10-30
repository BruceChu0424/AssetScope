import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 品牌图形标：资观 A mark。
///
/// 透明背景单色图形（白色款做源），按主题色重新着色：
/// 浅色模式染墨蓝（AppColors.navy），深色模式保持白色。
/// 品牌色随主题令牌走，换主色时 logo 自动跟随。
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 40});

  /// 图形边长（正方形）。
  final double size;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Image.asset(
      'assets/logo/mark_dark.png',
      width: size,
      height: size,
      color: dark ? null : AppColors.navy,
      colorBlendMode: dark ? null : BlendMode.srcIn,
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
      'assets/logo/lockup_dark.png',
      width: width,
      color: dark ? null : AppColors.navy,
      colorBlendMode: dark ? null : BlendMode.srcIn,
    );
  }
}
