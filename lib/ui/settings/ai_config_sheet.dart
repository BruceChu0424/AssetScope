import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/runtime_l10n.dart';
import '../../services/ai/ai_chat.dart';
import '../../services/ai/ai_usage.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

/// AI 服务配置弹层：预设（智谱/Kimi/千问/DeepSeek/OpenAI/Claude/自定义）
/// + Base URL + 模型 + API Key + 联网搜索开关 + 测试连接。
Future<void> showAiConfigSheet(BuildContext context, VaultUnlocked s) {
  return showAppDialog<void>(
    context,
    builder: (_) => const _AiConfigDialog(),
  );
}

class _AiConfigDialog extends ConsumerStatefulWidget {
  const _AiConfigDialog();

  @override
  ConsumerState<_AiConfigDialog> createState() => _AiConfigDialogState();
}

class _AiConfigDialogState extends ConsumerState<_AiConfigDialog> {
  String _presetId = 'glm';
  late final TextEditingController _baseUrl;
  late final TextEditingController _model;
  late final TextEditingController _apiKey;
  bool _webSearch = true;
  bool _obscure = true;
  bool _testing = false;
  String? _testResult;
  bool _loaded = false;
  AiUsage? _usage;
  AiBalanceResult? _balance;
  bool _balanceBusy = false;
  String? _balanceError;

  @override
  void initState() {
    super.initState();
    _baseUrl = TextEditingController();
    _model = TextEditingController();
    _apiKey = TextEditingController();
    _load();
  }

  @override
  void dispose() {
    _baseUrl.dispose();
    _model.dispose();
    _apiKey.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (_loaded) return;
    _loaded = true;
    final s = sessionOf(ref.read(vaultProvider));
    if (s == null) return;
    final usage = await s.aiUsage.load();
    if (!mounted) return;
    setState(() => _usage = usage);
    final cfg = await s.quoteFetch.config();
    if (!mounted) return;
    setState(() {
      if (cfg != null) {
        _presetId = cfg.presetId;
        _baseUrl.text = cfg.baseUrl;
        _model.text = cfg.model;
        _apiKey.text = cfg.apiKey;
        _webSearch = cfg.enableWebSearch;
        _migrateStaleModel();
      } else {
        _applyPreset('glm');
      }
    });
  }

  /// 旧存档里的模型名可能已被服务商下线（如智谱 glm-4.7-flash 及更早
  /// 的 4.x flash，2026-10 起模型列表只剩 GLM-5.x 系列），静默升到该
  /// 预设现行默认，避免「配置看着对、一直连不上」。
  void _migrateStaleModel() {
    const dead = {
      'glm-4-flash',
      'glm-4.5-flash',
      'glm-4-flash-250414',
      'glm-4.6-flash',
      'glm-4.7-flash',
    };
    if (dead.contains(_model.text.trim())) {
      _model.text = AiProviderPresets.byCode(_presetId)!.defaultModel;
    }
  }

  void _applyPreset(String id) {
    final preset = AiProviderPresets.byCode(id)!;
    _baseUrl.text = preset.defaultBaseUrl;
    _model.text = preset.defaultModel;
    _webSearch = preset.supportsWebSearch;
  }

  AiConfig _build() => AiConfig(
    presetId: _presetId,
    baseUrl: _baseUrl.text.trim(),
    apiKey: _apiKey.text.trim(),
    model: _model.text.trim(),
    enableWebSearch: _webSearch,
  );

  Future<void> _test() async {
    final t = AppLocalizations.of(context);
    var cfg = _build();
    if (cfg.apiKey.isEmpty || cfg.baseUrl.isEmpty) {
      setState(() => _testResult = t.aiCfgTestMissingInput);
      return;
    }
    // 连通性测试不带联网工具：工具参数的兼容问题不该伪装成「连不上」。
    cfg = AiConfig(
      presetId: cfg.presetId,
      baseUrl: cfg.baseUrl,
      apiKey: cfg.apiKey,
      model: cfg.model,
      enableWebSearch: false,
    );
    setState(() {
      _testing = true;
      _testResult = null;
    });
    try {
      final reply = await const AiChat().complete(
        cfg,
        '你是连通性测试助手。',
        '只回复两个字母：OK',
      );
      setState(
        () => _testResult =
            t.aiCfgTestConnected(reply.trim().substring(0, reply.trim().length.clamp(0, 40))),
      );
    } catch (e) {
      var msg = t.settingsFailed(e);
      // 智谱两类 Key 端点不通用（套餐 Key 打普通端点报「令牌已过期」，
      // 普通 Key 打套餐端点同样 401）：按形态提示换对服务商预设。
      if (msg.contains('401') || msg.contains('令牌') || msg.contains('token')) {
        if (_presetId == 'glm') {
          msg += '\n${t.aiCfgGlmCodingPlanKeyHint}';
        } else if (_presetId == 'glmCoding') {
          msg += '\n${t.aiCfgGlmRegularKeyHint}';
        }
      }
      setState(() => _testResult = msg);
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  Future<void> _save() async {
    final s = sessionOf(ref.read(vaultProvider));
    if (s == null) return;
    await s.quoteFetch.saveConfig(_build());
    if (mounted) Navigator.pop(context);
  }

  /// 智谱余额查询（其余服务商无公开接口，只显示本地统计）。
  Future<void> _fetchBalance() async {
    if (_balanceBusy) return;
    setState(() {
      _balanceBusy = true;
      _balanceError = null;
    });
    try {
      final b = await AiBalanceService.fetch(_build());
      if (!mounted) return;
      setState(() => _balance = b);
    } catch (e) {
      if (!mounted) return;
      setState(() => _balanceError = '$e');
    } finally {
      if (mounted) setState(() => _balanceBusy = false);
    }
  }

  /// 标题旁 icon 的悬停提示（提示语规范：静态说明文字一律收进悬停
  /// 弹窗，页面不留常驻副标题）。内容随所选服务商与联网开关联动。
  String _tipsText(AiProviderPreset preset) {
    final t = AppLocalizations.of(context);
    return [
      t.aiCfgKeyPrivacyTip,
      '${rt(preset.label)}：${preset.note != null ? rt(preset.note!) : t.aiCfgOpenAiCompatibleNote}',
      preset.supportsWebSearch
          ? (_webSearch ? t.aiCfgWebSearchOnTip : t.aiCfgWebSearchOffTip)
          : t.aiCfgNoWebSearchSupportTip,
    ].join('\n\n');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);
    final preset = AiProviderPresets.byCode(_presetId)!;
    return AppDialog(
      title: t.aiCfgDialogTitle,
      scroll: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: ParticleDropdownField<String>(
                  // initialValue 仅首帧生效；换 key 让 _load 异步回来后重建生效。
                  key: ValueKey('preset-$_presetId'),
                  initialValue: _presetId,
                  decoration: InputDecoration(labelText: t.aiCfgProvider),
                  items: [
                    for (final p in AiProviderPresets.all)
                      DropdownMenuItem(value: p.id, child: Text(rt(p.label))),
                  ],
                  onChanged: (v) => setState(() {
                    _presetId = v!;
                    _applyPreset(v);
                  }),
                ),
              ),
              const SizedBox(width: 10),
              // 悬停提示原在标题行；AppDialog 标题是纯文本，收到首字段旁。
              Padding(
                padding: const EdgeInsets.only(bottom: 15),
                child: Tooltip(
                  message: _tipsText(preset),
                  child: Icon(
                    Icons.info_outline,
                    size: 18,
                    color: theme.hintColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ParticleTextField(
            controller: _baseUrl,
            decoration: InputDecoration(
              labelText: t.aiCfgBaseUrlLabel,
            ),
          ),
          const SizedBox(height: 10),
          ParticleTextField(
            controller: _model,
            decoration: InputDecoration(labelText: t.aiCfgModelLabel),
          ),
          const SizedBox(height: 10),
          ParticleTextField(
            controller: _apiKey,
            obscureText: _obscure,
            decoration: InputDecoration(
              labelText: 'API Key',
              suffixIcon: IconButton(
                icon: Icon(
                  _obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(t.aiCfgWebSearch),
            value: _webSearch,
            onChanged: preset.supportsWebSearch
                ? (v) => setState(() => _webSearch = v)
                : null,
          ),
          if (_testResult != null) ...[
            const SizedBox(height: 4),
            Text(
              _testResult!,
              style: theme.textTheme.bodySmall?.copyWith(
                  color: _testResult!.startsWith(t.settingsFailedPrefix)
                      ? AppColors.negative
                      : AppColors.positive,
                ),
            ),
          ],
          const Divider(height: 28),
          _UsagePanel(
            usage: _usage,
            isGlm: preset.id == 'glm',
            balance: _balance,
            balanceBusy: _balanceBusy,
            balanceError: _balanceError,
            onRefreshBalance: _fetchBalance,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _testing ? null : _test,
          child: _testing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(t.aiCfgTestConnection),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(t.settingsCancel),
        ),
        ParticleFilledButton(onPressed: _save, child: Text(t.settingsSave)),
      ],
    );
  }
}

/// 用量与额度面板：本地调用统计（今日/7 天/累计）+ 服务商余额
/// （仅智谱有公开接口；免费模型不扣费，额度仅作透明参考）。
class _UsagePanel extends StatelessWidget {
  const _UsagePanel({
    required this.usage,
    required this.isGlm,
    required this.balance,
    required this.balanceBusy,
    required this.balanceError,
    required this.onRefreshBalance,
  });

  final AiUsage? usage;
  final bool isGlm;
  final AiBalanceResult? balance;
  final bool balanceBusy;
  final String? balanceError;
  final VoidCallback onRefreshBalance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                t.aiCfgUsageTitle,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Tooltip(
              message: t.aiCfgUsageTooltip,
              child: Icon(Icons.info_outline, size: 16, color: theme.hintColor),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _stat(context, t.aiCfgStatToday, t.aiCfgCalls(usage?.todayCalls ?? 0)),
            const SizedBox(width: 10),
            _stat(context, t.aiCfgStatLast7Days, t.aiCfgCalls(usage?.last7DaysCalls ?? 0)),
            const SizedBox(width: 10),
            _stat(context, t.aiCfgStatTotal, t.aiCfgCalls(usage?.totalCalls ?? 0)),
          ],
        ),
        const SizedBox(height: 12),
        if (isGlm) _balanceRow(context) else Text(t.aiCfgNoBalanceApi,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
      ],
    );
  }

  Widget _stat(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.4,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.hintColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _balanceRow(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);
    final b = balance;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.aiCfgBalanceGlm,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.hintColor,
                ),
              ),
              if (b != null) ...[
                const SizedBox(height: 2),
                Text(
                  [
                    if (b.total != null) t.aiCfgBalanceTotal(_trim(b.total!)),
                    if (b.voucher != null) t.aiCfgBalanceVoucher(_trim(b.voucher!)),
                    if (b.cash != null) t.aiCfgBalanceCash(_trim(b.cash!)),
                    if (b.total == null && b.voucher == null && b.cash == null)
                      t.aiCfgBalanceNoFields,
                  ].join(' · '),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ] else if (balanceError != null)
                Text(
                  t.aiCfgBalanceQueryFailed(balanceError ?? ''),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.negative,
                  ),
                ),
            ],
          ),
        ),
        TextButton.icon(
          onPressed: balanceBusy ? null : onRefreshBalance,
          icon: balanceBusy
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh, size: 18),
          label: Text(b == null ? t.aiCfgBalanceQuery : t.aiCfgBalanceRefresh),
        ),
      ],
    );
  }

  static String _trim(double v) =>
      v == v.roundToDouble() ? v.round().toString() : v.toStringAsFixed(2);
}
