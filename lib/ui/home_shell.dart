import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'theme/app_theme.dart';

/// 主框架：桌面侧边导航（全量）；手机底部导航（4 个高频目的地 + "更多"弹层，
/// Material 3 建议 NavigationBar 不超过 5 个目的地）。
class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.body});

  final Widget body;

  static const _primary = [
    (icon: Icons.dashboard_outlined, selected: Icons.dashboard, label: '总览', path: '/'),
    (icon: Icons.account_balance_wallet_outlined, selected: Icons.account_balance_wallet, label: '账户', path: '/accounts'),
    (icon: Icons.receipt_long_outlined, selected: Icons.receipt_long, label: '流水', path: '/transactions'),
    (icon: Icons.assessment_outlined, selected: Icons.assessment, label: '月报', path: '/reports'),
  ];

  static const _secondary = [
    (icon: Icons.savings_outlined, label: '预算', path: '/budgets'),
    (icon: Icons.event_outlined, label: '计划', path: '/plans'),
    (icon: Icons.flag_outlined, label: '目标', path: '/goals'),
    (icon: Icons.credit_card_outlined, label: '负债', path: '/debts'),
    (icon: Icons.settings_outlined, label: '设置', path: '/settings'),
  ];

  /// 路径匹配：根路由精确匹配，其余允许子路径（/accounts/xx）。
  /// 注意不能用裸 startsWith——任何路径都以 '/' 开头会导致总览永远选中。
  static bool _matches(String location, String path) =>
      location == path || (path != '/' && location.startsWith('$path/'));

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final inPrimary =
        _primary.any((i) => _matches(location, i.path));
    final currentIndex = inPrimary
        ? _primary.indexWhere((i) => _matches(location, i.path))
        : _primary.length; // "更多"承载全部次要目的地
    final wide = MediaQuery.sizeOf(context).width >= 900;
    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: currentIndex.clamp(0, _primary.length + _secondary.length - 1),
              onDestinationSelected: (i) {
                if (i < _primary.length) {
                  context.go(_primary[i].path);
                } else {
                  context.go(_secondary[i - _primary.length].path);
                }
              },
              labelType: NavigationRailLabelType.all,
              destinations: [
                for (final i in _primary)
                  NavigationRailDestination(
                    icon: Icon(i.icon),
                    selectedIcon: Icon(i.selected),
                    label: Text(i.label),
                  ),
                for (final i in _secondary)
                  NavigationRailDestination(
                    icon: Icon(i.icon),
                    label: Text(i.label),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: body),
          ],
        ),
      );
    }
    return Scaffold(
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (i) {
          if (i < _primary.length) {
            context.go(_primary[i].path);
          } else {
            _openMore(context);
          }
        },
        destinations: [
          for (final i in _primary)
            NavigationDestination(
              icon: Icon(i.icon),
              selectedIcon: Icon(i.selected),
              label: i.label,
            ),
          const NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view),
            label: '更多',
          ),
        ],
      ),
    );
  }

  /// 次要目的地弹层：两列图标入口，当前页高亮。
  Future<void> _openMore(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final scheme = Theme.of(context).colorScheme;
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 12),
                child: Text('更多',
                    style: Theme.of(sheetCtx)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
              ),
              Row(
                children: [
                  for (var i = 0; i < _secondary.length; i++) ...[
                    if (i > 0) const SizedBox(width: AppSpace.gap),
                    Expanded(
                      child: _MoreTile(
                        item: _secondary[i],
                        active: _matches(location, _secondary[i].path),
                        activeColor: scheme.primary,
                        onTap: () {
                          Navigator.pop(sheetCtx);
                          context.go(_secondary[i].path);
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoreTile extends StatelessWidget {
  const _MoreTile({
    required this.item,
    required this.active,
    required this.activeColor,
    required this.onTap,
  });

  final ({IconData icon, String label, String path}) item;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = active ? activeColor : theme.hintColor;
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadii.chip),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadii.chip),
          color: active ? activeColor.withValues(alpha: 0.10) : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(item.icon, size: 26, color: color),
            const SizedBox(height: 6),
            Text(item.label, style: theme.textTheme.bodySmall?.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}
