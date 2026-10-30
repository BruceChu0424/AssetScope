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
import 'merge_dialog.dart';
import 'settings_dialogs.dart';

/// 设置页 · 控制台：按域分组的卡片墙（安全 / 备份与恢复 / 偏好 / 数据
/// 管理 / AI 与行情 / 关于）。说明文字一律挂 info 悬停提示（提示语
/// 规范），不再铺静态副标题。大屏 480 定宽分组网格，小屏单列。
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = sessionOf(ref.watch(vaultProvider));
    if (s == null) return const ErrorPlaceholder('未解锁');
    final groups = <Widget>[
      _GroupCard(
        title: '安全',
        icon: Icons.shield_outlined,
        rows: [
          ListRow(
            icon: Icons.lock,
            title: '立即锁定',
            hint: '关闭数据库并清除内存密钥；无操作也会自动锁定',
            onTap: () => ref.read(vaultProvider.notifier).lock(),
          ),
          ListRow(
            icon: Icons.password,
            title: '修改主口令',
            hint: '只重新包裹密钥，数据不需要重加密',
            onTap: () => showChangePassphraseDialog(context, ref),
          ),
          ListRow(
            icon: Icons.key,
            title: '重新生成恢复码',
            hint: '旧恢复码立即失效',
            onTap: () => showNewRecoveryCodeDialog(context, ref),
          ),
        ],
      ),
      _GroupCard(
        title: '备份与恢复',
        icon: Icons.backup_outlined,
        rows: [
          ListRow(
            icon: Icons.upload_file,
            title: '导出加密备份',
            hint: '生成 .asbk 加密容器，请用独立口令并离线保存',
            onTap: () => showBackupExportDialog(context, ref, s),
          ),
          ListRow(
            icon: Icons.restore,
            title: '从备份恢复',
            hint: '先隔离校验，通过后才替换当前账本（原库保留 .bak）',
            onTap: () => showBackupRestoreDialog(context, ref, s),
          ),
          ListRow(
            icon: Icons.merge_type,
            title: '从备份合并（多设备）',
            hint: '把另一设备的 .asbk 并入当前账本：交易按时间新者胜，先自动安全备份',
            onTap: () => showMergeDialog(context, ref, s),
          ),
        ],
      ),
      _GroupCard(
        title: '偏好',
        icon: Icons.tune,
        rows: [
          _ThemeModeRow(session: s),
          ListRow(
            icon: Icons.attach_money,
            title: '本位币',
            hint: '统计、净资产与预测的基准货币',
            onTap: () => showBaseCurrencyDialog(context, ref, s),
          ),
          _LockTimeoutRow(session: s),
          _HorizonRow(session: s),
          _CashFloorRow(session: s),
        ],
      ),
      _GroupCard(
        title: '数据管理',
        icon: Icons.storage_outlined,
        rows: [
          ListRow(
            icon: Icons.file_upload_outlined,
            title: '导入账单 CSV',
            hint: 'UTF-8/GBK 自动识别，去重幂等，智慧分类建议',
            onTap: () => showImportWizard(context, ref),
          ),
          ListRow(
            icon: Icons.data_object,
            title: '导出全量 JSON',
            hint: '账户/估值/交易/计划/预算的明文快照（不含密钥），可审计可迁移',
            onTap: () => _exportFullJson(context, s),
          ),
          ListRow(
            icon: Icons.currency_exchange,
            title: '汇率管理',
            hint: '手工录入各币种对本位币汇率',
            onTap: () => showFxManagerSheet(context, ref, s),
          ),
          ListRow(
            icon: Icons.category_outlined,
            title: '分类与规则',
            hint: '管理收支分类、商户→分类关键词规则',
            onTap: () => showCategoryManagerSheet(context, ref, s),
          ),
        ],
      ),
      _GroupCard(
        title: 'AI 与行情',
        icon: Icons.smart_toy_outlined,
        rows: [
          ListRow(
            icon: Icons.smart_toy_outlined,
            title: 'AI 服务配置',
            hint: '智谱/Kimi/千问/OpenAI/Claude/自定义；Key 加密存本地',
            onTap: () => showAiConfigSheet(context, s),
          ),
          ListRow(
            icon: Icons.travel_explore,
            title: '行情 / 汇率抓取',
            hint: 'AI 联网搜索最新价格与汇率，预览确认后入账',
            onTap: () => showQuoteFetchSheet(context, ref),
          ),
        ],
      ),
      _AboutCard(),
    ];
    return PageFrame(
      title: '设置',
      maxWidth: 1040,
      child: LayoutBuilder(
        builder: (context, c) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            if (c.maxWidth >= 720)
              CardWrap(tileWidth: 480, children: groups)
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final g in groups)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: g,
                    ),
                ],
              ),
          ],
        ),
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('已导出全量 JSON（明文，不含任何密钥）')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('导出失败：$e')));
    }
  }
}

/// 分组卡：小节标题行 + ListRow 列。
class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.title, required this.icon, required this.rows});

  final String title;
  final IconData icon;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // 底缘光尘（docs/12 §9 卡片规范）：分组卡与区块卡同一家族。
    return ParticleEdge(
      band: 22,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 6),
              child: Row(
                children: [
                  Icon(icon, size: 17, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
            for (final r in rows)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: r,
              ),
          ],
        ),
      ),
      ),
    );
  }
}

/// 关于卡：品牌 + 版本 + 一句定位。
class _AboutCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ParticleEdge(
      band: 22,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const BrandMark(size: 40),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$appName $appVersion',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '本地优先的个人资产、负债与财务规划系统。数据全程加密存储，任何联网功能默认关闭。',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.hintColor,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 外观模式：跟随系统 / 浅色 / 深色（存设置表，立即生效）。
class _ThemeModeRow extends ConsumerWidget {
  const _ThemeModeRow({required this.session});

  final VaultUnlocked session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    return ListRow(
      icon: Icons.dark_mode_outlined,
      title: '外观',
      hint: '浅色冷雾白 / 深色财富终端，跟随系统自动切换',
      trailingValue: switch (mode) {
        ThemeMode.system => '跟随系统',
        ThemeMode.light => '浅色',
        ThemeMode.dark => '深色',
      },
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
class _LockTimeoutRow extends ConsumerWidget {
  const _LockTimeoutRow({required this.session});

  final VaultUnlocked session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListRow(
      icon: Icons.timer_outlined,
      title: '自动锁定',
      hint: '无操作达到该时长后自动锁定账本',
      trailingValue: '${session.lockTimeoutMinutes} 分钟',
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
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('自动锁定已设为 $picked 分钟')));
        }
      },
    );
  }
}

/// 现金预测期（设置项）。
class _HorizonRow extends StatelessWidget {
  const _HorizonRow({required this.session});

  final VaultUnlocked session;

  @override
  Widget build(BuildContext context) {
    return ListRow(
      icon: Icons.timeline,
      title: '现金预测期',
      hint: '首页「还能花多少」的推演天数',
      trailingValue: '${session.projectionHorizonDays} 天',
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
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('现金预测期已设为 $picked 天')));
        }
      },
    );
  }
}

/// 现金底线（预测公式中的 R(t) 下限）。
class _CashFloorRow extends StatelessWidget {
  const _CashFloorRow({required this.session});

  final VaultUnlocked session;

  @override
  Widget build(BuildContext context) {
    return ListRow(
      icon: Icons.vertical_align_bottom,
      title: '现金底线',
      hint: '低于此值视为现金短缺（预测与可支配上限会扣除）',
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
                child: const Text('取消'),
              ),
              ParticleFilledButton(
                onPressed: () => Navigator.pop(dctx, true),
                child: const Text('保存'),
              ),
            ],
          ),
        );
        if (ok != true) return;
        final v = field.parseMinor();
        if (v == null) return;
        // 存最小单位字符串（与 seed 格式一致）。
        await session.meta.setSetting('baselineMinCashMinor', v.toString());
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('现金底线已保存')));
        }
      },
    );
  }
}
