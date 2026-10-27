import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../services/ai/ai_chat.dart';
import '../../services/ai/ai_quote.dart';
import '../accounts/accounts_providers.dart' show holdingsProvider;
import '../reports/invest_card.dart' show portfolioProvider;
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'ai_config_sheet.dart';

/// 行情/汇率 AI 抓取弹层：目标一览 → 抓取 → 逐条确认 → 入账。
/// 手动触发、来源可审计（写入 source=`ai:预设/模型`，note 保留网址）。
Future<void> showQuoteFetchSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => const _QuoteFetchSheet(),
  ).then((_) {
    ref.invalidate(holdingsProvider);
    ref.invalidate(portfolioProvider);
  });
}

class _QuoteFetchSheet extends ConsumerStatefulWidget {
  const _QuoteFetchSheet();

  @override
  ConsumerState<_QuoteFetchSheet> createState() => _QuoteFetchSheetState();
}

enum _Phase { loading, ready, fetching, preview, applying }

class _QuoteFetchSheetState extends ConsumerState<_QuoteFetchSheet> {
  _Phase _phase = _Phase.loading;
  String? _error;
  AiConfig? _cfg;
  List<String> _holdingNames = const [];
  List<String> _fxPairs = const [];
  String _base = 'CNY';
  QuoteFetchResult? _result;
  final Set<int> _selectedPrices = {};
  final Set<int> _selectedRates = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = sessionOf(ref.read(vaultProvider));
    if (s == null) return;
    try {
      final cfg = await s.quoteFetch.config();
      final (holdings, currencies, base) = await s.quoteFetch.targets();
      setState(() {
        _cfg = cfg;
        _holdingNames = [for (final h in holdings) h.name];
        _fxPairs = [for (final c in currencies) '$c/$base'];
        _base = base;
        _phase = _Phase.ready;
      });
    } catch (e) {
      setState(() {
        _error = '$e';
        _phase = _Phase.ready;
      });
    }
  }

  Future<void> _fetch() async {
    final s = sessionOf(ref.read(vaultProvider));
    if (s == null) return;
    setState(() => _phase = _Phase.fetching);
    try {
      final result = await s.quoteFetch.fetch();
      _selectedPrices
        ..clear()
        ..addAll({
          for (var i = 0; i < result.prices.length; i++)
            if (result.prices[i].accountId != null &&
                result.prices[i].currencyMismatch != true)
              i
        });
      _selectedRates
        ..clear()
        ..addAll({
          for (var i = 0; i < result.rates.length; i++) i,
        });
      setState(() {
        _result = result;
        _phase = _Phase.preview;
      });
    } catch (e) {
      setState(() {
        _error = '$e';
        _phase = _Phase.ready;
      });
    }
  }

  Future<void> _apply() async {
    final s = sessionOf(ref.read(vaultProvider));
    if (s == null || _result == null) return;
    setState(() => _phase = _Phase.applying);
    try {
      final n = await s.quoteFetch.apply(
        prices: [
          for (final i in _selectedPrices) _result!.prices[i],
        ],
        rates: [
          for (final i in _selectedRates) _result!.rates[i],
        ],
      );
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('已写入 $n 条行情/汇率')));
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _error = '写入失败：$e';
        _phase = _Phase.preview;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text('AI 行情 / 汇率抓取',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Text(
              'AI 联网搜索最新数据，预览确认后才写入；来源标记 ai:<模型> 可审计。'
              'AI 行情是二手数据，重大决策请到官方渠道核对。',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.hintColor, height: 1.5),
            ),
          ),
          const Divider(height: 4),
          Expanded(child: _body(theme)),
        ],
      ),
    );
  }

  Widget _body(ThemeData theme) {
    if (_phase == _Phase.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_cfg == null || _cfg!.apiKey.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.key_off_outlined, size: 36),
            const SizedBox(height: 10),
            const Text('尚未配置 AI 服务'),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: () async {
                final s = sessionOf(ref.read(vaultProvider));
                if (s == null || !mounted) return;
                await showAiConfigSheet(context, s);
                await _load();
              },
              child: const Text('去配置（支持智谱/Kimi/千问/OpenAI/Claude…）'),
            ),
          ],
        ),
      );
    }
    if (_phase == _Phase.ready) return _readyView(theme);
    if (_phase == _Phase.fetching) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('AI 正在联网搜索行情，约需 10–60 秒…'),
          ],
        ),
      );
    }
    return _previewView(theme);
  }

  Widget _readyView(ThemeData theme) {
    final noWeb = !_cfg!.enableWebSearch;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      children: [
        if (noWeb)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.brass.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '当前配置未开启联网搜索，模型可能返回记忆中的过时价格，请谨慎确认。',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: AppColors.brass, height: 1.5),
              ),
            ),
          ),
        Text('本次将查询：',
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        if (_holdingNames.isEmpty && _fxPairs.isEmpty)
          Text('没有在持的证券持仓，也没有需要折算的外币账户。',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.hintColor))
        else ...[
          if (_holdingNames.isNotEmpty)
            Text('· 持仓价格（${_holdingNames.length}）：${_holdingNames.join('、')}',
                style: theme.textTheme.bodySmall?.copyWith(height: 1.6)),
          if (_fxPairs.isNotEmpty)
            Text('· 汇率（${_fxPairs.length}）：${_fxPairs.join('、')} → $_base',
                style: theme.textTheme.bodySmall?.copyWith(height: 1.6)),
        ],
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, style: const TextStyle(color: AppColors.negative)),
        ],
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed:
              _holdingNames.isEmpty && _fxPairs.isEmpty ? null : _fetch,
          icon: const Icon(Icons.travel_explore),
          label: const Text('开始抓取'),
        ),
      ],
    );
  }

  Widget _previewView(ThemeData theme) {
    final r = _result!;
    final applying = _phase == _Phase.applying;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
            children: [
              if (r.prices.isNotEmpty) _header(theme, '资产价格'),
              for (var i = 0; i < r.prices.length; i++)
                _priceTile(theme, r.prices[i], i),
              if (r.rates.isNotEmpty) _header(theme, '汇率'),
              for (var i = 0; i < r.rates.length; i++)
                _rateTile(theme, r.rates[i], i),
              if (r.warnings.isNotEmpty) ...[
                _header(theme, '提示'),
                for (final w in r.warnings)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 3, 12, 3),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            size: 16, color: AppColors.brass),
                        const SizedBox(width: 6),
                        Expanded(
                            child:
                                Text(w, style: theme.textTheme.bodySmall)),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '已选 ${_selectedPrices.length} 条价格 + ${_selectedRates.length} 条汇率',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.hintColor),
                ),
              ),
              TextButton(
                onPressed: applying ? null : () => setState(() => _phase = _Phase.ready),
                child: const Text('返回'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: applying ||
                        (_selectedPrices.isEmpty && _selectedRates.isEmpty)
                    ? null
                    : _apply,
                child: applying
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('确认写入'),
              ),
            ],
          ),
        ),
        if (_error != null && _phase == _Phase.preview)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text(_error!,
                style: const TextStyle(color: AppColors.negative)),
          ),
      ],
    );
  }

  Widget _header(ThemeData theme, String label) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 2),
        child: Text(label,
            style: theme.textTheme.labelMedium
                ?.copyWith(color: theme.hintColor)),
      );

  Widget _priceTile(ThemeData theme, FetchedPrice p, int i) {
    final enabled = p.accountId != null;
    final mismatch = p.currencyMismatch == true;
    return CheckboxListTile(
      dense: true,
      value: _selectedPrices.contains(i),
      onChanged: enabled && !mismatch
          ? (v) => setState(() =>
              v == true ? _selectedPrices.add(i) : _selectedPrices.remove(i))
          : null,
      title: Text(p.accountName ?? p.query),
      subtitle: Text(
        '${p.price.toDecimalString(4)}${p.currency.isEmpty ? '' : ' ${p.currency}'}'
        '${p.asOf != null ? ' · ${p.asOf!.month}/${p.asOf!.day}' : ''}'
        '${p.source != null ? ' · ${_hostOf(p.source!)}' : ''}',
        style: TextStyle(color: mismatch ? AppColors.brass : null),
      ),
      secondary: !enabled
          ? Tooltip(
              message: '未匹配到在持仓账户，不入账',
              child: Icon(Icons.link_off, color: theme.hintColor))
          : mismatch
              ? Tooltip(
                  message: '币种与账户不一致（${p.currency} vs 账户币种），默认不勾选',
                  child: const Icon(Icons.error_outline, color: AppColors.brass))
              : null,
    );
  }

  Widget _rateTile(ThemeData theme, FetchedRate r, int i) {
    return CheckboxListTile(
      dense: true,
      value: _selectedRates.contains(i),
      onChanged: (v) => setState(
          () => v == true ? _selectedRates.add(i) : _selectedRates.remove(i)),
      title: Text('1 ${r.ccy} = ${r.rate.toDecimalString(6)} $_base'),
      subtitle: Text(
          '${r.asOf != null ? '${r.asOf!.month}/${r.asOf!.day}' : ''}'
          '${r.source != null ? ' · ${_hostOf(r.source!)}' : ''}'),
    );
  }

  String _hostOf(String url) {
    final uri = Uri.tryParse(url);
    return uri?.host ?? url;
  }
}
