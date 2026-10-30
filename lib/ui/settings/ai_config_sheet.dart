import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../services/ai/ai_chat.dart';
import '../../services/ai/ai_usage.dart';
import '../theme/app_theme.dart';
import '../widgets/particle_interactive.dart';

/// AI 服务配置弹层：预设（智谱/Kimi/千问/DeepSeek/OpenAI/Claude/自定义）
/// + Base URL + 模型 + API Key + 联网搜索开关 + 测试连接。
Future<void> showAiConfigSheet(BuildContext context, VaultUnlocked s) {
  return showDialog<void>(
    context: context,
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

  /// 旧存档里的模型名可能已被服务商下线（如智谱 glm-4-flash，2026-01
  /// 起 404），静默升到该预设现行默认，避免「配置看着对、一直连不上」。
  void _migrateStaleModel() {
    const dead = {'glm-4-flash', 'glm-4.5-flash', 'glm-4-flash-250414'};
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
    final cfg = _build();
    if (cfg.apiKey.isEmpty || cfg.baseUrl.isEmpty) {
      setState(() => _testResult = '请先填写 Base URL 与 API Key');
      return;
    }
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
            '连接成功：${reply.trim().substring(0, reply.trim().length.clamp(0, 40))}',
      );
    } catch (e) {
      setState(() => _testResult = '失败：$e');
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final preset = AiProviderPresets.byCode(_presetId)!;
    return AlertDialog(
      title: const Text('AI 服务配置'),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'API Key 加密存储在本地账本库中，仅用于行情/汇率联网抓取；'
                '抓取时只发送查询名称与币种对，绝不发送余额与金额。',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.hintColor,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                // initialValue 仅首帧生效；换 key 让 _load 异步回来后重建生效。
                key: ValueKey('preset-$_presetId'),
                initialValue: _presetId,
                decoration: const InputDecoration(labelText: '服务商'),
                items: [
                  for (final p in AiProviderPresets.all)
                    DropdownMenuItem(value: p.id, child: Text(p.label)),
                ],
                onChanged: (v) => setState(() {
                  _presetId = v!;
                  _applyPreset(v);
                }),
              ),
              if (preset.note != null) ...[
                const SizedBox(height: 6),
                Text(
                  preset.note!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: preset.supportsWebSearch
                        ? theme.hintColor
                        : AppColors.brass,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              ParticleTextField(
                controller: _baseUrl,
                decoration: const InputDecoration(
                  labelText: 'Base URL（https://…，不含 /chat/completions）',
                ),
              ),
              const SizedBox(height: 10),
              ParticleTextField(
                controller: _model,
                decoration: const InputDecoration(labelText: '模型（须支持联网搜索）'),
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
                title: const Text('联网搜索'),
                subtitle: Text(
                  preset.supportsWebSearch
                      ? '行情抓取必须开启（否则价格可能来自模型记忆）'
                      : '该服务商 API 不支持联网，抓取结果可能是过时数据',
                ),
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
                    color: _testResult!.startsWith('失败')
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
        ),
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
              : const Text('测试连接'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ParticleFilledButton(onPressed: _save, child: const Text('保存')),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '用量与额度',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Tooltip(
              message: '调用次数由本应用本地统计（设置页关闭后重新打开刷新）；'
                  '额度来自服务商接口，免费模型不扣费',
              child: Icon(Icons.info_outline, size: 16, color: theme.hintColor),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _stat(context, '今日调用', '${usage?.todayCalls ?? 0} 次'),
            const SizedBox(width: 10),
            _stat(context, '近 7 天', '${usage?.last7DaysCalls ?? 0} 次'),
            const SizedBox(width: 10),
            _stat(context, '累计', '${usage?.totalCalls ?? 0} 次'),
          ],
        ),
        const SizedBox(height: 12),
        if (isGlm) _balanceRow(context) else Text('该服务商暂无余额查询接口，可到其控制台查看',
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
    final b = balance;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '服务商余额（智谱）',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.hintColor,
                ),
              ),
              if (b != null) ...[
                const SizedBox(height: 2),
                Text(
                  [
                    if (b.total != null) '总额度 ¥${_trim(b.total!)}',
                    if (b.voucher != null) '免费额度 ¥${_trim(b.voucher!)}',
                    if (b.cash != null) '现金 ¥${_trim(b.cash!)}',
                    if (b.total == null && b.voucher == null && b.cash == null)
                      '接口未返回额度字段',
                  ].join(' · '),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ] else if (balanceError != null)
                Text(
                  '查询失败：$balanceError',
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
          label: Text(b == null ? '查询' : '刷新'),
        ),
      ],
    );
  }

  static String _trim(double v) =>
      v == v.roundToDouble() ? v.round().toString() : v.toStringAsFixed(2);
}
