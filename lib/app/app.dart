import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../ui/accounts/accounts_page.dart';
import '../ui/budget/budgets_page.dart';
import '../ui/dashboard/dashboard_page.dart';
import '../ui/debts/debts_page.dart';
import '../ui/goals/goals_page.dart';
import '../ui/globe/globe_page.dart';
import '../ui/home_shell.dart';
import '../ui/lock/lock_page.dart';
import '../ui/planning/plans_page.dart';
import '../ui/reports/report_page.dart';
import '../ui/settings/settings_page.dart';
import '../ui/theme/app_theme.dart';
import '../ui/transactions/transactions_page.dart';
import 'providers.dart';

class AssetScopeApp extends ConsumerWidget {
  AssetScopeApp({super.key});

  final Map<bool, GoRouter> _routers = {};

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vault = ref.watch(vaultProvider);
    final locked = vault is! VaultUnlocked;
    final router = _routers.putIfAbsent(locked, () => _buildRouter(locked));
    return MaterialApp.router(
      title: '资观 AssetScope',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(Brightness.light),
      darkTheme: buildAppTheme(Brightness.dark),
      themeMode: ref.watch(themeModeProvider),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('zh'), Locale('en')],
      routerConfig: router,
      builder: (context, child) {
        if (!locked && child != null) {
          return Listener(
            onPointerDown: (_) => ref.read(vaultProvider.notifier).touch(),
            child: child,
          );
        }
        return child ?? const SizedBox.shrink();
      },
    );
  }

  GoRouter _buildRouter(bool locked) {
    return GoRouter(
      initialLocation: locked ? '/lock' : '/',
      redirect: (context, state) {
        final loc = state.matchedLocation;
        if (locked && loc != '/lock') return '/lock';
        if (!locked && loc == '/lock') return '/';
        return null;
      },
      routes: [
        GoRoute(path: '/lock', builder: (_, _) => const LockPage()),
        GoRoute(path: '/globe', builder: (_, _) => const GlobePage()),
        ShellRoute(
          builder: (_, _, child) => HomeShell(body: child),
          routes: [
            GoRoute(path: '/', builder: (_, _) => const DashboardPage()),
            GoRoute(path: '/accounts', builder: (_, _) => const AccountsPage()),
            GoRoute(
                path: '/transactions',
                builder: (_, _) => const TransactionsPage()),
            GoRoute(path: '/budgets', builder: (_, _) => const BudgetsPage()),
            GoRoute(path: '/plans', builder: (_, _) => const PlansPage()),
            GoRoute(path: '/goals', builder: (_, _) => const GoalsPage()),
            GoRoute(path: '/debts', builder: (_, _) => const DebtsPage()),
            GoRoute(path: '/reports', builder: (_, _) => const ReportPage()),
            GoRoute(path: '/settings', builder: (_, _) => const SettingsPage()),
          ],
        ),
      ],
    );
  }
}
