import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/ledger/account.dart';
import '../../services/insight_service.dart';
import '../../services/stats_service.dart';

/// 账户页/详情弹层共用的聚合 provider。
final accountsViewProvider =
    FutureProvider.autoDispose<(List<Account>, NetWorthBreakdown)>((ref) async {
  final s = sessionOf(ref.watch(vaultProvider));
  if (s == null) throw StateError('locked');
  final list = await s.accounts.all();
  final nw = await s.statsService.netWorthAt(DateTime.now());
  return (list, nw);
});

/// 持仓快照（账户详情、月报投资卡共用）。
final holdingsProvider =
    FutureProvider.autoDispose<List<HoldingSnapshot>>((ref) async {
  final s = sessionOf(ref.watch(vaultProvider));
  if (s == null) return const [];
  return s.insightService.holdings();
});
