import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../services/insight_service.dart';
import '../accounts/accounts_providers.dart' show holdingsProvider;
import '../theme/app_theme.dart';
import '../widgets/common.dart';

final portfolioProvider = FutureProvider.autoDispose<PortfolioReturn>((ref) async {
  final s = sessionOf(ref.watch(vaultProvider));
  if (s == null) throw StateError('locked');
  return s.insightService.portfolioXirr();
});

/// 投资组合卡：年化 XIRR（资金加权）+ 持仓浮盈明细。
class InvestCard extends ConsumerWidget {
  const InvestCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final portfolio = ref.watch(portfolioProvider);
    final holdings = ref.watch(holdingsProvider);
    return SectionCard(
      title: '投资组合',
      trailing: portfolio.maybeWhen(
        data: (p) => p.xirr == null
            ? null
            : Text(
                '年化 XIRR ${(p.xirr! * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  color: p.xirr! >= 0
                      ? AppColors.positiveOf(theme.brightness)
                      : AppColors.negativeOf(theme.brightness),
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
        orElse: () => null,
      ),
      child: holdings.maybeWhen(
        data: (list) {
          if (list.isEmpty) {
            return Text(
              '还没有持仓。在账户页新建持仓账户后，用「买入」记录第一笔投资。',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.hintColor, height: 1.5),
            );
          }
          return Column(
            children: [
              for (final h in list.take(8))
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: SizedBox(
                    width: 90,
                    child: Text(h.account.name,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  title: Text(
                    '${h.quantity.toDecimalString(4)} 份'
                    '${h.unitPrice != null ? ' · 成本 ${fmtMinor(h.costMinor, h.account.currencyCode)}' : ''}',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.hintColor),
                  ),
                  trailing: h.marketValueMinor == null
                      ? Text('缺价',
                          style: TextStyle(
                              color: AppColors.brassOf(theme.brightness)))
                      : _pnlText(context, h),
                ),
              portfolio.maybeWhen(
                data: (p) => p.skippedFlows > 0
                    ? Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                            '⚠ ${p.skippedFlows} 笔含外币流水因缺历史汇率未计入 XIRR',
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.brassOf(theme.brightness))),
                      )
                    : const SizedBox.shrink(),
                orElse: () => const SizedBox.shrink(),
              ),
            ],
          );
        },
        orElse: () => const SizedBox(
            height: 60, child: Center(child: CircularProgressIndicator())),
      ),
    );
  }

  Widget _pnlText(BuildContext context, HoldingSnapshot h) {
    final theme = Theme.of(context);
    final pnl = h.unrealizedPnl;
    if (pnl == null) return const Text('—');
    final v = pnl.n; // 直接比较分子（分母恒正）
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(fmtMinor(h.marketValueMinor!, h.account.currencyCode),
            style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontFeatures: [FontFeature.tabularFigures()])),
        Text(
          '${v.isNegative ? '' : '+'}${fmtMinor(pnl.rounded(), h.account.currencyCode)}',
          style: TextStyle(
            fontSize: 12,
            color: v.isNegative
                ? AppColors.negativeOf(theme.brightness)
                : AppColors.positiveOf(theme.brightness),
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
