import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../l10n/app_localizations.dart';
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
  return showAppSheet<void>(
    context,
    scrollControlled: true,
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
  bool _directMode = true; // 当前预览结果的来源模式
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

  Future<void> _fetch({required bool direct}) async {
    final s = sessionOf(ref.read(vaultProvider));
    if (s == null) return;
    setState(() {
      _phase = _Phase.fetching;
      _directMode = direct;
    });
    try {
      final result = direct
          ? await s.directQuotes.fetch()
          : await s.quoteFetch.fetch();
      _selectedPrices
        ..clear()
        ..addAll({
          for (var i = 0; i < result.prices.length; i++)
            if (result.prices[i].accountId != null &&
                result.prices[i].currencyMismatch != true)
              i,
        });
      _selectedRates
        ..clear()
        ..addAll({for (var i = 0; i < result.rates.length; i++) i});
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
    final t = AppLocalizations.of(context);
    final s = sessionOf(ref.read(vaultProvider));
    if (s == null || _result == null) return;
    setState(() => _phase = _Phase.applying);
    try {
      final n = await s.quoteFetch.apply(
        prices: [for (final i in _selectedPrices) _result!.prices[i]],
        rates: [for (final i in _selectedRates) _result!.rates[i]],
        sourcePrefix: _directMode ? 'direct' : null,
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(t.quoteAppliedCount(n))));
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _error = t.quoteWriteFailed(e);
        _phase = _Phase.preview;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              t.quoteFetchTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Text(
              t.quoteFetchIntro,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.hintColor,
                height: 1.5,
              ),
            ),
          ),
          const Divider(height: 4),
          Expanded(child: _body(theme)),
        ],
      ),
    );
  }

  Widget _body(ThemeData theme) {
    final t = AppLocalizations.of(context);
    if (_phase == _Phase.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_phase == _Phase.ready) return _readyView(theme);
    if (_phase == _Phase.fetching) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 12),
            Text(_directMode ? t.quoteQueryingDirect : t.quoteQueryingAi),
          ],
        ),
      );
    }
    return _previewView(theme);
  }

  Widget _readyView(ThemeData theme) {
    final t = AppLocalizations.of(context);
    final hasTargets = _holdingNames.isNotEmpty || _fxPairs.isNotEmpty;
    final aiReady = _cfg != null && _cfg!.apiKey.isNotEmpty;
    final noWeb = aiReady && !_cfg!.enableWebSearch;
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
                t.quoteNoWebSearchWarning,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.brass,
                  height: 1.5,
                ),
              ),
            ),
          ),
        Text(
          t.quoteWillQuery,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        if (!hasTargets)
          Text(
            t.quoteNoTargets,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
          )
        else ...[
          if (_holdingNames.isNotEmpty)
            Text(
              t.quoteHoldingPrices(_holdingNames.length, _holdingNames.join('、')),
              style: theme.textTheme.bodySmall?.copyWith(height: 1.6),
            ),
          if (_fxPairs.isNotEmpty)
            Text(
              t.quoteFxPairs(_fxPairs.length, _fxPairs.join('、'), _base),
              style: theme.textTheme.bodySmall?.copyWith(height: 1.6),
            ),
          const SizedBox(height: 4),
          Text(
            t.quoteRoutingHint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.hintColor,
              fontSize: 11,
              height: 1.5,
            ),
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, style: const TextStyle(color: AppColors.negative)),
        ],
        const SizedBox(height: 16),
        ParticleFilledButton.icon(
          onPressed: hasTargets ? () => _fetch(direct: true) : null,
          icon: const Icon(Icons.bolt),
          label: Text(t.quoteDirectFetchButton),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: hasTargets
              ? () async {
                  if (!aiReady) {
                    final s = sessionOf(ref.read(vaultProvider));
                    if (s == null || !mounted) return;
                    await showAiConfigSheet(context, s);
                    await _load();
                    return;
                  }
                  await _fetch(direct: false);
                }
              : null,
          icon: const Icon(Icons.travel_explore),
          label: Text(aiReady ? t.quoteAiFetchFallback : t.quoteAiFetchNeedsConfig),
        ),
      ],
    );
  }

  Widget _previewView(ThemeData theme) {
    final t = AppLocalizations.of(context);
    final r = _result!;
    final applying = _phase == _Phase.applying;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
            children: [
              if (r.prices.isNotEmpty) _header(theme, t.quoteAssetPrices),
              for (var i = 0; i < r.prices.length; i++)
                _priceTile(theme, r.prices[i], i),
              if (r.rates.isNotEmpty) _header(theme, t.quoteFxRates),
              for (var i = 0; i < r.rates.length; i++)
                _rateTile(theme, r.rates[i], i),
              if (r.warnings.isNotEmpty) ...[
                _header(theme, t.quoteNotes),
                for (final w in r.warnings)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 3, 12, 3),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          size: 16,
                          color: AppColors.brass,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(w, style: theme.textTheme.bodySmall),
                        ),
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
                  t.quoteSelectedCount(_selectedPrices.length, _selectedRates.length),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.hintColor,
                  ),
                ),
              ),
              TextButton(
                onPressed: applying
                    ? null
                    : () => setState(() => _phase = _Phase.ready),
                child: Text(t.quoteBack),
              ),
              const SizedBox(width: 8),
              ParticleFilledButton(
                onPressed:
                    applying ||
                        (_selectedPrices.isEmpty && _selectedRates.isEmpty)
                    ? null
                    : _apply,
                child: applying
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(t.quoteApplyButton),
              ),
            ],
          ),
        ),
        if (_error != null && _phase == _Phase.preview)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text(
              _error!,
              style: const TextStyle(color: AppColors.negative),
            ),
          ),
      ],
    );
  }

  Widget _header(ThemeData theme, String label) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 10, 12, 2),
    child: Text(
      label,
      style: theme.textTheme.labelMedium?.copyWith(color: theme.hintColor),
    ),
  );

  Widget _priceTile(ThemeData theme, FetchedPrice p, int i) {
    final t = AppLocalizations.of(context);
    final enabled = p.accountId != null;
    final mismatch = p.currencyMismatch == true;
    return CheckboxListTile(
      dense: true,
      value: _selectedPrices.contains(i),
      onChanged: enabled && !mismatch
          ? (v) => setState(
              () => v == true
                  ? _selectedPrices.add(i)
                  : _selectedPrices.remove(i),
            )
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
              message: t.quoteUnmatchedTooltip,
              child: Icon(Icons.link_off, color: theme.hintColor),
            )
          : mismatch
          ? Tooltip(
              message: t.quoteCurrencyMismatchTooltip(p.currency),
              child: const Icon(Icons.error_outline, color: AppColors.brass),
            )
          : null,
    );
  }

  Widget _rateTile(ThemeData theme, FetchedRate r, int i) {
    return CheckboxListTile(
      dense: true,
      value: _selectedRates.contains(i),
      onChanged: (v) => setState(
        () => v == true ? _selectedRates.add(i) : _selectedRates.remove(i),
      ),
      title: Text('1 ${r.ccy} = ${r.rate.toDecimalString(6)} $_base'),
      subtitle: Text(
        '${r.asOf != null ? '${r.asOf!.month}/${r.asOf!.day}' : ''}'
        '${r.source != null ? ' · ${_hostOf(r.source!)}' : ''}',
      ),
    );
  }

  String _hostOf(String url) {
    final uri = Uri.tryParse(url);
    return uri?.host ?? url;
  }
}
