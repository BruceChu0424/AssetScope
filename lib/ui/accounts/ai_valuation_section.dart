import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/ledger/account.dart';
import '../../domain/valuation/valuation.dart';
import '../../services/ai/ai_valuation_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'accounts_providers.dart';

/// 账户详情的「AI 估值」区块：每日自动估值开关 + 检索线索编辑 +
/// 立即估值（预览→采用）+ 估值历史（来源可审计）。
///
/// 只对 manualValue 口径的资产资产渲染（父层判断）。
class AiValuationSection extends ConsumerStatefulWidget {
  const AiValuationSection({super.key, required this.account});

  final Account account;

  @override
  ConsumerState<AiValuationSection> createState() =>
      _AiValuationSectionState();
}

class _AiValuationSectionState extends ConsumerState<AiValuationSection> {
  late bool _enabled = widget.account.aiValuationEnabled;
  late final _query = TextEditingController(
    text: widget.account.aiValuationQuery ?? widget.account.locationName ?? '',
  );
  bool _busy = false;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _toggle(bool v) async {
    final s = sessionOf(ref.read(vaultProvider));
    if (s == null) return;
    setState(() => _enabled = v);
    await s.accounts.upsert(
      widget.account.copyWith(aiValuationEnabled: v),
    );
    ref.invalidate(accountsViewProvider);
  }

  /// 保存检索线索（空 = 回退到 名称+位置 推导）。
  Future<void> _saveQuery() async {
    final s = sessionOf(ref.read(vaultProvider));
    if (s == null) return;
    final q = _query.text.trim();
    await s.accounts.upsert(
      widget.account.copyWith(
        aiValuationQuery: q.isEmpty ? null : q,
        clearAiValuationQuery: q.isEmpty,
      ),
    );
    ref.invalidate(accountsViewProvider);
    if (mounted) {
      showTopNotice(context, 'AI 估值线索已保存', tone: TopNoticeTone.info);
    }
  }

  /// 立即估值：AI 联网检索 → 预览结果（区间/依据/来源）→ 采用写入。
  Future<void> _estimateNow() async {
    final s = sessionOf(ref.read(vaultProvider));
    if (s == null || _busy) return;
    final cfg = await s.aiValuation.config();
    if (!mounted) return;
    if (cfg == null) {
      showTopNotice(context, '先在 设置 → AI 服务 绑定你的 AI Key',
          tone: TopNoticeTone.info);
      return;
    }
    setState(() => _busy = true);
    try {
      final est = await s.aiValuation.estimateOne(cfg, widget.account);
      if (!mounted) return;
      final adopted = await _preview(est);
      if (adopted == true) {
        await s.aiValuation.applyEstimate(widget.account, est, cfg);
        ref.invalidate(accountsViewProvider);
        if (mounted) {
          showTopNotice(
            context,
            '已更新估值：${fmtMinor(est.valueMinor, est.currency)}',
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      showTopNotice(context, 'AI 估值：$e', tone: TopNoticeTone.error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// 估值预览：区间 + 置信度 + 依据 + 来源，采用/放弃。
  Future<bool?> _preview(AiAssetEstimate est) {
    final theme = Theme.of(context);
    return showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        title: const Text('AI 估值结果'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              fmtMinor(est.valueMinor, est.currency),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            if (est.low != null && est.high != null)
              _kv(
                dctx,
                '区间',
                '${fmtRational(est.low!)} ~ ${fmtRational(est.high!)}',
              ),
            if (est.confidence != null) _kv(dctx, '置信度', '${est.confidence}%'),
            if (est.rationale != null) _kv(dctx, '依据', est.rationale!),
            for (final src in est.sources) _kv(dctx, '来源', src),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dctx, false),
            child: const Text('不用'),
          ),
          ParticleFilledButton(
            onPressed: () => Navigator.pop(dctx, true),
            child: const Text('采用'),
          ),
        ],
      ),
    );
  }

  Widget _kv(BuildContext context, String k, String v) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 52,
            child: Text(
              k,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.hintColor,
              ),
            ),
          ),
          Expanded(
            child: Text(
              v,
              style: theme.textTheme.bodySmall?.copyWith(height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = sessionOf(ref.watch(vaultProvider));
    if (s == null) return const SizedBox.shrink();
    return SectionCard(
      title: 'AI 估值',
      titleWidget: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.auto_awesome,
            size: 17,
            color: AppColors.brassOf(theme.brightness),
          ),
          const SizedBox(width: 7),
          const Text('AI 估值'),
          const SizedBox(width: 5),
          Tooltip(
            message: '每天解锁后自动联网检索真实市价并更新价值；'
                '你手动改过的估值当日优先，AI 不覆盖',
            child: Icon(Icons.info_outline, size: 16, color: theme.hintColor),
          ),
        ],
      ),
      trailing: Switch(
        value: _enabled,
        onChanged: _toggle,
      ),
      child: AnimatedSize(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        alignment: Alignment.topCenter,
        child: _enabled
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                key: const ValueKey('ai-on'),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ParticleTextField(
                          controller: _query,
                          decoration: const InputDecoration(
                            labelText: '检索线索（小区/栋/室 · 年款型号）',
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: '保存线索',
                        icon: const Icon(Icons.save_outlined, size: 20),
                        onPressed: _saveQuery,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      ActionChip(
                        avatar: _busy
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: Center(child: OrbitSpinner(size: 14)),
                              )
                            : null,
                        label: Text(_busy ? '检索中…' : '立即估值'),
                        onPressed: _busy ? null : _estimateNow,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '检索词空 = 「${widget.account.effectiveAiValuationQuery}」',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.hintColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _ValuationHistory(
                    accountId: widget.account.id,
                    currency: widget.account.currencyCode,
                  ),
                ],
              )
            : const SizedBox(
                width: double.infinity,
                key: ValueKey('ai-off'),
                child: Text(''),
              ),
      ),
    );
  }
}

/// 估值历史（最近 5 条 totalValue 记录，AI/手动来源徽标）。
class _ValuationHistory extends ConsumerWidget {
  const _ValuationHistory({required this.accountId, required this.currency});

  final String accountId;
  final String currency;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = sessionOf(ref.watch(vaultProvider));
    if (s == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return FutureBuilder<List<ValuationRecord>>(
      future: s.meta.valuations(accountId: accountId),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox.shrink();
        final records = snap.data!
            .where((r) => r.kind == ValuationKind.totalValue)
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));
        if (records.isEmpty) {
          return Text(
            '暂无估值记录',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.hintColor,
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final r in records.take(5))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    SizedBox(
                      width: 86,
                      child: Text(
                        '${r.date.year}-${r.date.month.toString().padLeft(2, '0')}-${r.date.day.toString().padLeft(2, '0')}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontFeatures: const [FontFeature.tabularFigures()],
                          color: theme.hintColor,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        r.note ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      fmtMinor(r.totalValueMinor ?? BigInt.zero, currency),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      r.source.startsWith('ai:')
                          ? Icons.auto_awesome
                          : Icons.edit_outlined,
                      size: 13,
                      color: r.source.startsWith('ai:')
                          ? AppColors.brassOf(theme.brightness)
                          : theme.hintColor,
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
