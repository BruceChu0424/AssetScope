import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/invest/lots.dart';
import '../../domain/ledger/account.dart';
import '../../domain/money/fx_rate.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

/// 持仓账户的 FIFO 批次成本明细（分析视角；账面仍为平均成本法）。
class LotSection extends ConsumerWidget {
  const LotSection({super.key, required this.account});

  final Account account;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = sessionOf(ref.watch(vaultProvider));
    if (s == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final ccy = account.currencyCode;
    return FutureBuilder<LotLedgerResult?>(
      future: s.portfolioAnalytics.lotDetail(account.id),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox.shrink();
        final r = snap.data!;
        if (r.openLots.isEmpty && r.realized.isEmpty) {
          return const SizedBox.shrink();
        }
        final thisYear = r.realizedPnlByYear()[DateTime.now().year];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: Text('成本批次（FIFO）',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600)),
                ),
                _pnlChip(context, '累计已实现 ${fmtMinor(r.totalRealizedPnlMinor, ccy, sign: true)}',
                    r.totalRealizedPnlMinor),
              ],
            ),
            if (thisYear != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: _pnlChip(context,
                    '${DateTime.now().year} 年已实现 ${fmtMinor(thisYear, ccy, sign: true)}',
                    thisYear),
              ),
            const SizedBox(height: 4),
            for (final lot in r.openLots)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: SizedBox(
                  width: 92,
                  child: Text(
                      '${lot.acquiredDate.year}-${lot.acquiredDate.month.toString().padLeft(2, '0')}-${lot.acquiredDate.day.toString().padLeft(2, '0')}',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.hintColor)),
                ),
                title: Text(
                  '${lot.remainingQuantity.toDecimalString(4)} 份 × 单价 ${lot.unitCost.toDecimalString(6)}',
                  style: theme.textTheme.bodySmall,
                ),
                trailing: Text(
                  fmtMinor(lot.remainingCostMinor, ccy),
                  style: const TextStyle(
                      fontFeatures: [FontFeature.tabularFigures()]),
                ),
              ),
            if (r.shortfallQuantity > Rational.zero())
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '⚠ ${r.shortfallQuantity.toDecimalString(4)} 份卖出早于首笔买入（历史缺口，以零成本配对）',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: AppColors.brassOf(theme.brightness)),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '口径：先买先卖逐批配对，与账面平均成本法并行披露（docs/05 §11）',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.hintColor, fontSize: 11),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _pnlChip(BuildContext context, String label, BigInt v) {
    final theme = Theme.of(context);
    return Text(
      label,
      style: TextStyle(
        fontSize: 12,
        color: v.isNegative
            ? AppColors.negativeOf(theme.brightness)
            : AppColors.positiveOf(theme.brightness),
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}
