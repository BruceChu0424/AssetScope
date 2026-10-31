import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../l10n/app_localizations.dart';
import '../globe/space_backdrop.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../globe/glass_card.dart';
import 'settings_security.dart';
import 'settings_sections.dart';

/// 设置页 · 深空控制舱（v0.26 全站改版）：整页深空底幕（与首页同源：
/// 星野 + 星云 + 流星 + 游走星尘）上，左侧悬浮玻璃分类导航台 + 右侧
/// 自适应内容区；小屏为顶部标题带 + 横向分类胶囊 + 单列。
///
/// - 六分类：安全 / 备份与恢复 / 偏好 / 数据管理 / AI 与行情 / 关于
///   （各分类内容在 settings_security.dart / settings_sections.dart）；
/// - 全部状态与计数读真实数据（金库状态 / 设置表 / 加密库配置），
///   绝不展示假状态或无功能控件；
/// - 分类切换：内容 240ms 淡入轻上浮 + 卡片阶梯入场，导航稳定不闪；
/// - 顶部说明挂 info 悬停（提示语规范）；全局导航（A 按钮）是纯浮层，
///   悬浮在标题带首段让出的空白区（84px），不占布局空间。
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  int _selected = 0;

  /// 深空底色（与首页 GlobeHomePage 同一常数；设置页永远深空，玻璃卡
  /// 随明暗主题切换深蓝/雾白质感）。
  static const _space = Color(0xFF050A12);
  static const _bandInk = Color(0xFFE7ECF2); // 标题带文字（直接落在深空上）
  static const _bandHint = Color(0xB3A5B5C7);
  static const _bandHairline = Color(0x26E7ECF2);

  @override
  Widget build(BuildContext context) {
    final s = sessionOf(ref.watch(vaultProvider));
    final t = AppLocalizations.of(context);
    if (s == null) return ErrorPlaceholder(t.settingsNotUnlocked);
    final wide = MediaQuery.sizeOf(context).width >= PageMeasure.wide;
    final categories = <(IconData, String, Widget)>[
      (
        Icons.shield_outlined,
        t.settingsGroupSecurity,
        SecuritySection(session: s),
      ),
      (
        Icons.backup_outlined,
        t.settingsGroupBackup,
        BackupSection(session: s),
      ),
      (
        Icons.tune,
        t.settingsGroupPreferences,
        PrefsSection(session: s),
      ),
      (
        Icons.storage_outlined,
        t.settingsGroupData,
        DataSection(session: s),
      ),
      (
        Icons.smart_toy_outlined,
        t.settingsGroupAiQuotes,
        AiSection(session: s),
      ),
      (Icons.info_outline, t.settingsGroupAbout, const AboutSection()),
    ];
    final sel = _selected.clamp(0, categories.length - 1);
    return Scaffold(
      backgroundColor: _space,
      body: Stack(
        children: [
          const Positioned.fill(child: SpaceBackdrop()),
          Positioned.fill(
            child: wide
                ? _wideBody(context, t, categories, sel)
                : _smallBody(context, t, categories, sel),
          ),
        ],
      ),
    );
  }

  // ── 大屏（≥900）：标题带 + 左玻璃导航 + 右内容 ──

  Widget _wideBody(
    BuildContext context,
    AppLocalizations t,
    List<(IconData, String, Widget)> categories,
    int sel,
  ) {
    final topInset = MediaQuery.paddingOf(context).top;
    // 标题带与下方导航台/内容区同贴 28px 左缘（导航入口让位已删除）。
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(28, topInset + 16, 28, 0),
          child: _titleBand(t, compact: false),
        ),
        const SizedBox(height: 14),
        const Divider(height: 1, thickness: 1, color: _bandHairline),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 18, 28, 24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 236,
                  child: _SettingsNav(
                    categories: [
                      for (final c in categories) (c.$1, c.$2),
                    ],
                    selected: sel,
                    onSelect: (i) => setState(() => _selected = i),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(child: _switchableBody(categories, sel)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── 小屏（<900）：标题带 + 横向分类胶囊 + 单列 ──

  Widget _smallBody(
    BuildContext context,
    AppLocalizations t,
    List<(IconData, String, Widget)> categories,
    int sel,
  ) {
    final topInset = MediaQuery.paddingOf(context).top;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(8, topInset + 10, 12, 0),
          child: _titleBand(t, compact: true),
        ),
        SizedBox(
          height: 54,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            children: [
              for (var i = 0; i < categories.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                _CategoryChip(
                  icon: categories[i].$1,
                  label: categories[i].$2,
                  selected: i == sel,
                  onTap: () => setState(() => _selected = i),
                ),
              ],
            ],
          ),
        ),
        Expanded(child: _switchableBody(categories, sel, small: true)),
      ],
    );
  }

  /// 标题带：返回 + 设置 + info + 右上真实安全状态章。文字直接落在深空
  /// 上，用显式浅色（同首页顶栏做法，不随主题反转）。
  Widget _titleBand(AppLocalizations t, {required bool compact}) {
    return Row(
      children: [
        const PageBackButton(onDark: true),
        const SizedBox(width: 8),
        Text(
          t.settingsPageTitle,
          style: TextStyle(
            color: _bandInk,
            fontSize: compact ? 19 : 24,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(width: 8),
        Tooltip(
          message: t.settingsPageHint,
          waitDuration: const Duration(milliseconds: 300),
          child: const Icon(
            Icons.info_outline,
            size: 15,
            color: _bandHint,
          ),
        ),
        const Spacer(),
        _SecurityBadge(compact: compact),
      ],
    );
  }

  /// 分类内容切换：240ms 淡入轻上浮（旧内容渐隐，导航与标题带稳定）。
  Widget _switchableBody(
    List<(IconData, String, Widget)> categories,
    int sel, {
    bool small = false,
  }) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 240),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeOut,
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.014),
            end: Offset.zero,
          ).animate(anim),
          child: child,
        ),
      ),
      child: KeyedSubtree(
        key: ValueKey(sel),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            small ? 16 : 0,
            small ? 6 : 0,
            small ? 16 : 0,
            small ? 28 : 4,
          ),
          child: categories[sel].$3,
        ),
      ),
    );
  }
}

/// 右上安全状态章：整库加密恒真（金库机制），显示保护中徽标。
/// 说明挂悬停提示。
class _SecurityBadge extends StatelessWidget {
  const _SecurityBadge({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Tooltip(
      message: t.settingsHeaderShieldTip,
      waitDuration: const Duration(milliseconds: 300),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 13,
          vertical: 7,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: const Color(0xFF7EA6D9).withValues(alpha: 0.10),
          border: Border.all(color: const Color(0xFF7EA6D9).withValues(alpha: 0.38)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.verified_user_outlined,
              size: 15,
              color: Color(0xFFA5C7EE),
            ),
            if (!compact) ...[
              const SizedBox(width: 7),
              Text(
                t.settingsHeaderShield,
                style: const TextStyle(
                  color: Color(0xFFA5C7EE),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 左侧分类导航台：玻璃面板 + 图标条目。选中 = 主色渐变洗底 + 左缘
/// 高亮线 + 图标提亮 + 微辉光边；悬浮 = 轻微提亮；切换 180ms 平滑。
class _SettingsNav extends StatelessWidget {
  const _SettingsNav({
    required this.categories,
    required this.selected,
    required this.onSelect,
  });

  final List<(IconData, String)> categories;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < categories.length; i++)
              _NavTile(
                icon: categories[i].$1,
                label: categories[i].$2,
                selected: i == selected,
                onTap: () => onSelect(i),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavTile extends StatefulWidget {
  const _NavTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_NavTile> createState() => _NavTileState();
}

class _NavTileState extends State<_NavTile> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tint = theme.colorScheme.primary;
    final selected = widget.selected;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.chip),
            // 选中：主色斜向渐变洗底 + 微辉光；悬浮：轻提亮。
            gradient: selected
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      tint.withValues(alpha: 0.16),
                      tint.withValues(alpha: 0.04),
                    ],
                  )
                : null,
            color: !selected && _hover
                ? theme.colorScheme.onSurface.withValues(alpha: 0.05)
                : selected
                ? null
                : Colors.transparent,
            border: Border.all(
              color: selected
                  ? tint.withValues(alpha: 0.30)
                  : Colors.transparent,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: tint.withValues(alpha: 0.10),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : const [],
          ),
          child: Row(
            children: [
              // 左缘细高亮线：选中出现（宽度呼吸展开）。
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                width: selected ? 3 : 0,
                height: 20,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: tint.withValues(alpha: selected ? 0.9 : 0),
                ),
              ),
              Icon(
                widget.icon,
                size: 17,
                color: selected ? tint : theme.hintColor,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: selected ? tint : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 小屏分类胶囊：选中主色胶囊 + 微光，未选中玻璃幽灵。
class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: selected
                ? const Color(0xFF7EA6D9).withValues(alpha: 0.20)
                : Colors.white.withValues(alpha: 0.05),
            border: Border.all(
              color: selected
                  ? const Color(0xFF7EA6D9).withValues(alpha: 0.55)
                  : const Color(0x2EE7ECF2),
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: const Color(0xFF7EA6D9).withValues(alpha: 0.14),
                      blurRadius: 12,
                    ),
                  ]
                : const [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 15,
                color: selected ? const Color(0xFFA5C7EE) : _SettingsPageState._bandHint,
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected
                      ? const Color(0xFFDCE9F7)
                      : _SettingsPageState._bandHint,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
