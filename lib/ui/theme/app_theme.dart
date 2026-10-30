import 'package:flutter/material.dart';

/// 资观设计令牌（Design Tokens）。
///
/// 视觉方向：墨蓝与香槟金——私人银行质感。深墨蓝为主（结构/按钮/导航，
/// 沉稳可信、金融本源），香槟金为唯一暖色对位（荣誉/里程碑/零值），
/// 朱砂只表亏损。浅色模式冷雾白底，深色模式做成"私人财富终端"：
/// 蓝碳底 + 钢蓝主色 + 香槟点缀。克制、精确、数字优先。
/// 所有 UI 必须引用这里的令牌，禁止散落硬编码颜色。
abstract final class AppColors {
  // 品牌基色
  static const navy = Color(0xFF1C3A5C); // 主色·墨蓝（ink navy）
  static const navyDeep = Color(0xFF12283E); // 按压/深墨
  static const brass = Color(0xFFB3924F); // 强调·香槟金（荣誉/里程碑）
  static const ink = Color(0xFF1E2A38); // 蓝墨
  static const paper = Color(0xFFF5F7F9); // 冷雾白底（微蓝灰）

  // 语义色
  static const positive = Color(0xFF2B6CB0); // 收入·靛蓝
  static const negative = Color(0xFFC13A2B); // 朱砂（非默认红）
  static const warn = Color(0xFFB4761B);

  // 深色模式（蓝碳：底更深、卡片更亮，层次拉开）
  static const darkBg = Color(0xFF0B0F14);
  static const darkSurface = Color(0xFF141B24);
  static const darkInk = Color(0xFFE7ECF2);
  static const darkPrimary = Color(0xFF7EA6D9); // 钢蓝（深底上的主色）
  static const darkPositive = Color(0xFF8FBCE8);
  static const darkNegative = Color(0xFFF0907C);
  static const darkBrass = Color(0xFFD8BE85);
  static const darkWarn = Color(0xFFDFAF5E);

  static Color positiveOf(Brightness b) =>
      b == Brightness.light ? positive : darkPositive;
  static Color negativeOf(Brightness b) =>
      b == Brightness.light ? negative : darkNegative;
  static Color brassOf(Brightness b) =>
      b == Brightness.light ? brass : darkBrass;
  static Color warnOf(Brightness b) => b == Brightness.light ? warn : darkWarn;
}

/// 图表调色板：墨蓝三档 + 香槟两档 + 异色标点
/// （青灰蓝/赭石/灰紫/银灰）。深色模式整体提亮一档。
/// 图表/图例取色一律走这里，禁止页面自建 palette。
abstract final class AppChartPalette {
  static const light = [
    Color(0xFF1C3A5C), // 墨蓝·深
    Color(0xFF3A6392), // 墨蓝
    Color(0xFF7C9CC0), // 雾蓝
    Color(0xFFB3924F), // 香槟
    Color(0xFFD3BC85), // 香槟·淡
    Color(0xFF6E7F8D), // 青灰蓝
    Color(0xFFA96F4E), // 赭石（房产/实物）
    Color(0xFF8A7092), // 灰紫
    Color(0xFFA9B2B8), // 银灰
  ];
  static const dark = [
    Color(0xFF4A6E9E),
    Color(0xFF6E90BC),
    Color(0xFFA5C0DD),
    Color(0xFFD2B26A),
    Color(0xFFE5D3A6),
    Color(0xFF9AAAB8),
    Color(0xFFC48A68),
    Color(0xFFA790AF),
    Color(0xFFBCC4CA),
  ];
  static List<Color> of(Brightness b) => b == Brightness.light ? light : dark;
}

/// 外观模式持久化在 app 层（lib/app/providers.dart 的 ThemeModeController），
/// 序列化函数 themeModeFromString/ToString 也定义在那里。

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
  final scheme =
      ColorScheme.fromSeed(
        seedColor: AppColors.navy,
        brightness: brightness,
      ).copyWith(
        primary: isLight ? AppColors.navy : AppColors.darkPrimary,
        secondary: AppColors.brassOf(brightness),
        error: AppColors.negativeOf(brightness),
        surface: isLight ? Colors.white : AppColors.darkSurface,
        surfaceContainerLowest: isLight
            ? Colors.white
            : const Color(0xFF070A0E),
        surfaceContainerLow: isLight
            ? AppColors.paper
            : const Color(0xFF10161D),
        surfaceContainer: isLight
            ? const Color(0xFFEBEFF3)
            : const Color(0xFF1A2430),
      );

  final baseText = (isLight ? AppColors.ink : AppColors.darkInk);
  final hairline = isLight
      ? const Color(0x141E2A38)
      : const Color(0x26E7ECF2); // 发丝线 8%~15% 透明度

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: isLight ? AppColors.paper : AppColors.darkBg,
    splashFactory: InkSparkle.splashFactory,
    appBarTheme: AppBarTheme(
      centerTitle: false,
      // 无边框窗口：页面顶栏一律透明，只保留文字与操作，避免出现
      // 「第二根标题条」；内容不滚到栏下，透明即无缝融入页面背景。
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
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
      fillColor: isLight ? Colors.white : const Color(0xFF10161D),
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
        borderSide: const BorderSide(color: AppColors.navy, width: 1.4),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: scheme.primary,
        foregroundColor: isLight ? Colors.white : AppColors.darkBg,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        side: const WidgetStatePropertyAll(BorderSide(color: AppColors.navy)),
      ),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.chip),
      ),
      side: BorderSide(color: hairline),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        color: isLight ? Colors.white : AppColors.darkBg,
        fontSize: 12,
      ),
    ),
  );
}
