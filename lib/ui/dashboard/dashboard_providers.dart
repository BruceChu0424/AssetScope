import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/planning/cash_projection.dart';
import '../../domain/planning/recurrence.dart';
import '../../services/insight_service.dart';
import '../../services/stats_service.dart';

/// 仪表盘聚合数据（一次加载全部首页卡片区）。
class DashboardData {
  DashboardData({
    required this.nw,
    required this.report,
    required this.projection,
    required this.projectionDays,
    required this.upcoming,
    required this.series,
    required this.insights,
    required this.locatedAssets,
    this.pendingDueCount = 0,
  });

  final NetWorthBreakdown nw;
  final MonthReport report;
  final CashProjection projection;

  /// 现金预测口径天数（设置项）。
  final int projectionDays;

  /// 未来 30 天计划支出。
  final List<Occurrence> upcoming;

  /// 近 12 个月净资产（月, 净资产）。
  final List<(String, BigInt)> series;

  /// 智慧分析（健康/配速/异常/周期/里程碑）。
  final InsightBundle insights;

  /// 已设置地理位置的资产数（地球入口用）。
  final int locatedAssets;

  /// 到期未落地的计划发生数（待处理提醒）。
  final int pendingDueCount;

  BigInt get income =>
      report.incomeByCategory.values.fold(BigInt.zero, (a, b) => a + b);

  BigInt get expense =>
      report.expenseByCategory.values.fold(BigInt.zero, (a, b) => a + b);

  BigInt get surplus => income - expense;
}

final dashboardProvider = FutureProvider.autoDispose<DashboardData>((ref) async {
  final s = sessionOf(ref.watch(vaultProvider));
  if (s == null) throw StateError('locked');
  final now = DateTime.now();
  final nw = await s.statsService.netWorthAt(now);
  final report = await s.statsService.monthReport(now.year, now.month);
  final projection =
      await s.projectionService.project(horizonDays: s.projectionHorizonDays);
  final through = now.add(const Duration(days: 30));
  final upcoming = <Occurrence>[];
  final postedExtIds = await s.ledger.externalIds();
  for (final e in await s.planning.scheduledEvents()) {
    upcoming.addAll(e.expand(DateTime(now.year, now.month, now.day), through)
        .where((o) => !postedExtIds.contains(planExternalId(e.id, o.date))));
  }
  upcoming.sort((a, b) => a.date.compareTo(b.date));
  final series = await s.statsService.netWorthSeries(12, now: now);
  final insights = await s.insightService.dashboardInsights();
  final accounts = await s.accounts.all();
  final located = accounts
      .where((a) =>
          a.type.name == 'asset' && !a.isSystem && a.hasLocation && !a.archived)
      .length;
  final pendingDue = (await s.planExecution.pendingDue()).length;
  return DashboardData(
    nw: nw,
    report: report,
    projection: projection,
    projectionDays: s.projectionHorizonDays,
    upcoming: upcoming,
    series: series,
    insights: insights,
    locatedAssets: located,
    pendingDueCount: pendingDue,
  );
});
