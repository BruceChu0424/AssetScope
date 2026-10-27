import 'package:flutter/material.dart';

/// 资观设计令牌（Design Tokens）。
///
/// 视觉方向：金融仪器面板——深祖母绿主色、暖铜金强调、暖纸底色、
/// 全等宽数字、发丝线分隔。克制、精确、数字优先。
/// 所有 UI 必须引用这里的令牌，禁止散落硬编码颜色。
abstract final class AppColors {
  // 品牌基色
  static const evergreen = Color(0xFF1E5C45); // 主色·深祖母绿
  static const evergreenDeep = Color(0xFF143D2F);
  static const brass = Color(0xFFB08A2E); // 强调·暖铜金（荣誉/里程碑）
  static const ink = Color(0xFF1A2C24); // 墨色（绿黑）
  static const paper = Color(0xFFF6F5F1); // 暖纸底

  // 语义色
  static const positive = Color(0xFF2E7D5B);
  static const negative = Color(0xFFB3402E); // 砖红（非默认红）
  static const warn = Color(0xFF9A6B1F);

  // 深色模式
  static const darkBg = Color(0xFF0E1512);
  static const darkSurface = Color(0xFF14201A);
  static const darkInk = Color(0xFFE8EDE9);
  static const darkPositive = Color(0xFF5FBB98);
  static const darkNegative = Color(0xFFE07862);
  static const darkBrass = Color(0xFFD4B25E);

  static Color positiveOf(Brightness b) =>
      b == Brightness.light ? positive : darkPositive;
  static Color negativeOf(Brightness b) =>
      b == Brightness.light ? negative : darkNegative;
  static Color brassOf(Brightness b) =>
      b == Brightness.light ? brass : darkBrass;
}

abstract final class AppRadii {
  static const card = 14.0;
  static const chip = 10.0;
  static const sheet = 20.0;
}

abstract final class AppSpace {
  static const screenH = 16.0; // 屏幕水平边距
  static const cardH = 16.0; // 卡片内边距
  static const gap = 10.0;
}

/// 正负金额颜色（全 UI 唯一入口）。
Color signColor(BigInt minor, Brightness b) => minor.isNegative
    ? AppColors.negativeOf(b)
    : (minor == BigInt.zero ? AppColors.brassOf(b) : AppColors.positiveOf(b));

ThemeData buildAppTheme(Brightness brightness) {
  final isLight = brightness == Brightness.light;
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.evergreen,
    brightness: brightness,
  ).copyWith(
    primary: isLight ? AppColors.evergreen : const Color(0xFF4CA98A),
    secondary: AppColors.brassOf(brightness),
    surface: isLight ? Colors.white : AppColors.darkSurface,
    surfaceContainerLowest: isLight ? Colors.white : const Color(0xFF0B110E),
    surfaceContainerLow:
        isLight ? AppColors.paper : const Color(0xFF101814),
    surfaceContainer:
        isLight ? const Color(0xFFEFEDE7) : const Color(0xFF182420),
  );

  final baseText = (isLight ? AppColors.ink : AppColors.darkInk);
  final hairline = isLight
      ? const Color(0x141A2C24)
      : const Color(0x24E8EDE9); // 发丝线 8%~14% 透明度

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: isLight ? AppColors.paper : AppColors.darkBg,
    splashFactory: InkSparkle.splashFactory,
    appBarTheme: AppBarTheme(
      centerTitle: false,
      backgroundColor: isLight ? AppColors.paper : AppColors.darkBg,
      scrolledUnderElevation: 0.5,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: baseText,
        fontSize: 17,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
      iconTheme: IconThemeData(color: baseText),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: scheme.surface,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
        side: BorderSide(color: hairline),
      ),
    ),
    dividerTheme: DividerThemeData(color: hairline, thickness: 1, space: 1),
    listTileTheme: ListTileThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isLight ? Colors.white : const Color(0xFF101814),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: hairline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: hairline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.evergreen, width: 1.4),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: scheme.primary,
        foregroundColor: isLight ? Colors.white : AppColors.darkBg,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        shape: WidgetStatePropertyAll(RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12))),
        side: const WidgetStatePropertyAll(
            BorderSide(color: AppColors.evergreen)),
      ),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.chip)),
      side: BorderSide(color: hairline),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: isLight ? AppColors.paper : AppColors.darkBg,
      indicatorColor: scheme.primary.withValues(alpha: 0.14),
      height: 64,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: isLight ? AppColors.paper : AppColors.darkBg,
      indicatorColor: scheme.primary.withValues(alpha: 0.14),
    ),
    textTheme: Typography.material2021().black.apply(
          bodyColor: baseText,
          displayColor: baseText,
        ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: isLight ? AppColors.ink : AppColors.darkInk,
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: TextStyle(
          color: isLight ? Colors.white : AppColors.darkBg, fontSize: 12),
    ),
  );
}
