import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_meta.dart';
import '../../app/providers.dart';
import '../transactions/import_wizard.dart';
import '../widgets/common.dart';
import 'ai_config_sheet.dart';
import 'category_manager_sheet.dart';
import 'fx_manager_sheet.dart';
import 'quote_fetch_sheet.dart';
import 'settings_dialogs.dart';

/// 设置：安全、备份与恢复、偏好（外观/本位币/锁定/预测/底线）、数据管理。
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = sessionOf(ref.watch(vaultProvider));
    if (s == null) return const ErrorPlaceholder('未解锁');
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          const _SectionHeader('安全'),
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text('立即锁定'),
            subtitle: const Text('关闭数据库并清除内存密钥；无操作也会自动锁定'),
            onTap: () => ref.read(vaultProvider.notifier).lock(),
          ),
          ListTile(
            leading: const Icon(Icons.password),
            title: const Text('修改主口令'),
            subtitle: const Text('只重新包裹密钥，数据不需要重加密'),
            onTap: () => showChangePassphraseDialog(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.key),
            title: const Text('重新生成恢复码'),
            subtitle: const Text('旧恢复码立即失效'),
            onTap: () => showNewRecoveryCodeDialog(context, ref),
          ),
          const _SectionHeader('备份与恢复'),
          ListTile(
            leading: const Icon(Icons.upload_file),
            title: const Text('导出加密备份'),
            subtitle: const Text('生成 .asbk 加密容器，请用独立口令并离线保存'),
            onTap: () => showBackupExportDialog(context, ref, s),
          ),
          ListTile(
            leading: const Icon(Icons.restore),
            title: const Text('从备份恢复'),
            subtitle: const Text('先隔离校验，通过后才替换当前账本（原库保留 .bak）'),
            onTap: () => showBackupRestoreDialog(context, ref, s),
          ),
          const _SectionHeader('偏好'),
          _ThemeModeTile(session: s),
          ListTile(
            leading: const Icon(Icons.attach_money),
            title: const Text('本位币'),
            subtitle: const Text('统计、净资产与预测的基准货币'),
            onTap: () => showBaseCurrencyDialog(context, ref, s),
          ),
          _LockTimeoutTile(session: s),
          _HorizonTile(session: s),
          _CashFloorTile(session: s),
          const _SectionHeader('数据管理'),
          ListTile(
            leading: const Icon(Icons.file_upload_outlined),
            title: const Text('导入账单 CSV'),
            subtitle: const Text('UTF-8/GBK 自动识别，去重幂等，智慧分类建议'),
            onTap: () => showImportWizard(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.data_object),
            title: const Text('导出全量 JSON'),
            subtitle: const Text('账户/估值/交易/计划/预算的明文快照（不含密钥），可审计可迁移'),
            onTap: () => _exportFullJson(context, s),
          ),
          ListTile(
            leading: const Icon(Icons.currency_exchange),
            title: const Text('汇率管理'),
            subtitle: const Text('手工录入各币种对本位币汇率'),
            onTap: () => showFxManagerSheet(context, ref, s),
          ),
          ListTile(
            leading: const Icon(Icons.category_outlined),
            title: const Text('分类与规则'),
            subtitle: const Text('管理收支分类、商户→分类关键词规则'),
            onTap: () => showCategoryManagerSheet(context, ref, s),
          ),
          const _SectionHeader('AI 与行情'),
          ListTile(
            leading: const Icon(Icons.smart_toy_outlined),
            title: const Text('AI 服务配置'),
            subtitle: const Text('智谱/Kimi/千问/OpenAI/Claude/自定义；Key 加密存本地'),
            onTap: () => showAiConfigSheet(context, s),
          ),
          ListTile(
            leading: const Icon(Icons.travel_explore),
            title: const Text('行情 / 汇率抓取'),
            subtitle: const Text('AI 联网搜索最新价格与汇率，预览确认后入账'),
            onTap: () => showQuoteFetchSheet(context, ref),
          ),
          const AboutListTile(
            icon: Icon(Icons.info_outline),
            applicationName: appName,
            applicationVersion: appVersion,
            aboutBoxChildren: [
              Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                    '本地优先的个人资产、负债与财务规划系统。\n数据全程加密存储，任何联网功能默认关闭。'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _exportFullJson(BuildContext context, VaultUnlocked s) async {
    final loc = await getSaveLocation(
      suggestedName:
          'assetscope-full-${DateTime.now().toIso8601String().substring(0, 10)}.json',
      acceptedTypeGroups: const [
        XTypeGroup(label: 'JSON', extensions: ['json']),
      ],
    );
    if (loc == null) return;
    try {
      final json = await s.exportService.fullLedgerJson(appVersion: appVersion);
      await File(loc.path).writeAsString(json, flush: true);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已导出全量 JSON（明文，不含任何密钥）')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('导出失败：$e')));
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
        child: Text(title,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.3)),
      );
}

/// 外观模式：跟随系统 / 浅色 / 深色（存设置表，立即生效）。
class _ThemeModeTile extends ConsumerWidget {
  const _ThemeModeTile({required this.session});

  final VaultUnlocked session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    return ListTile(
      leading: const Icon(Icons.dark_mode_outlined),
      title: const Text('外观'),
      subtitle: Text(switch (mode) {
        ThemeMode.system => '跟随系统',
        ThemeMode.light => '浅色',
        ThemeMode.dark => '深色',
      }),
      onTap: () async {
        final picked = await showDialog<ThemeMode>(
          context: context,
          builder: (_) => SimpleDialog(
            title: const Text('外观'),
            children: [
              for (final m in ThemeMode.values)
                SimpleDialogOption(
                  child: Text(switch (m) {
                    ThemeMode.system => '跟随系统',
                    ThemeMode.light => '浅色',
                    ThemeMode.dark => '深色',
                  }),
                  onPressed: () => Navigator.pop(context, m),
                ),
            ],
          ),
        );
        if (picked == null) return;
        await ref.read(themeModeProvider.notifier).set(picked, session);
      },
    );
  }
}

/// 自动锁定时长（设置项，立即生效）。
class _LockTimeoutTile extends ConsumerWidget {
  const _LockTimeoutTile({required this.session});

  final VaultUnlocked session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: const Icon(Icons.timer_outlined),
      title: const Text('自动锁定'),
      subtitle: Text('${session.lockTimeoutMinutes} 分钟无操作后锁定'),
      onTap: () async {
        final picked = await showDialog<int>(
          context: context,
          builder: (_) => SimpleDialog(
            title: const Text('无操作自动锁定'),
            children: [
              for (final m in const [1, 5, 15, 30, 60])
                SimpleDialogOption(
                  child: Text('$m 分钟'),
                  onPressed: () => Navigator.pop(context, m),
                ),
            ],
          ),
        );
        if (picked == null) return;
        await session.meta.setSetting('lockTimeoutMinutes', picked);
        await ref.read(vaultProvider.notifier).refreshTunables();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('自动锁定已设为 $picked 分钟')));
        }
      },
    );
  }
}

/// 现金预测期（设置项）。
class _HorizonTile extends StatelessWidget {
  const _HorizonTile({required this.session});

  final VaultUnlocked session;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.timeline),
      title: const Text('现金预测期'),
      subtitle: Text('首页"还能花多少"的推演天数：${session.projectionHorizonDays} 天'),
      onTap: () async {
        final picked = await showDialog<int>(
          context: context,
          builder: (_) => SimpleDialog(
            title: const Text('现金预测期'),
            children: [
              for (final d in const [30, 60, 90, 180])
                SimpleDialogOption(
                  child: Text('$d 天'),
                  onPressed: () => Navigator.pop(context, d),
                ),
            ],
          ),
        );
        if (picked == null) return;
        await session.meta.setSetting('projectionHorizonDays', picked);
        session.projectionHorizonDays = picked;
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('现金预测期已设为 $picked 天')));
        }
      },
    );
  }
}

/// 现金底线（预测公式中的 R(t) 下限）。
class _CashFloorTile extends StatelessWidget {
  const _CashFloorTile({required this.session});

  final VaultUnlocked session;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.vertical_align_bottom),
      title: const Text('现金底线'),
      subtitle: const Text('低于此值视为现金短缺（预测与可支配上限会扣除）'),
      onTap: () async {
        final ctrl = TextEditingController();
        final field = AppAmountField(controller: ctrl, currencyCode: 'CNY');
        final ok = await showDialog<bool>(
          context: context,
          builder: (dctx) => AlertDialog(
            title: const Text('现金底线'),
            content: field,
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(dctx, false),
                  child: const Text('取消')),
              FilledButton(
                  onPressed: () => Navigator.pop(dctx, true),
                  child: const Text('保存')),
            ],
          ),
        );
        if (ok != true) return;
        final v = field.parseMinor();
        if (v == null) return;
        // 存最小单位字符串（与 seed 格式一致）。
        await session.meta.setSetting('baselineMinCashMinor', v.toString());
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('现金底线已保存')));
        }
      },
    );
  }
}
