import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 主框架：侧边导航（桌面）/ 底部导航栏（窄屏）。
class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.body});

  final Widget body;

  static const _items = [
    (icon: Icons.dashboard_outlined, selected: Icons.dashboard, label: '总览', path: '/'),
    (icon: Icons.account_balance_wallet_outlined, selected: Icons.account_balance_wallet, label: '账户', path: '/accounts'),
    (icon: Icons.receipt_long_outlined, selected: Icons.receipt_long, label: '流水', path: '/transactions'),
    (icon: Icons.savings_outlined, selected: Icons.savings, label: '预算', path: '/budgets'),
    (icon: Icons.event_outlined, selected: Icons.event, label: '计划', path: '/plans'),
    (icon: Icons.flag_outlined, selected: Icons.flag, label: '目标', path: '/goals'),
    (icon: Icons.credit_card_outlined, selected: Icons.credit_card, label: '负债', path: '/debts'),
    (icon: Icons.assessment_outlined, selected: Icons.assessment, label: '月报', path: '/reports'),
    (icon: Icons.settings_outlined, selected: Icons.settings, label: '设置', path: '/settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _items.indexWhere((i) => location.startsWith(i.path));
    final wide = MediaQuery.sizeOf(context).width >= 900;
    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: currentIndex < 0 ? 0 : currentIndex,
              onDestinationSelected: (i) => context.go(_items[i].path),
              labelType: NavigationRailLabelType.all,
              destinations: [
                for (final i in _items)
                  NavigationRailDestination(
                    icon: Icon(i.icon),
                    selectedIcon: Icon(i.selected),
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
        selectedIndex: currentIndex < 0 ? 0 : currentIndex,
        onDestinationSelected: (i) => context.go(_items[i].path),
        destinations: [
          for (final i in _items)
            NavigationDestination(
              icon: Icon(i.icon),
              selectedIcon: Icon(i.selected),
              label: i.label,
            ),
        ],
      ),
    );
  }
}
