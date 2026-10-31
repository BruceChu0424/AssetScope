import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_meta.dart';
import '../../app/providers.dart';
import '../../l10n/app_localizations.dart';
import '../../services/ai/ai_chat.dart';
import '../theme/app_theme.dart';
import '../transactions/import_wizard.dart';
import '../widgets/common.dart';
import 'ai_config_sheet.dart';
import '../globe/glass_card.dart';
import 'merge_dialog.dart';
import 'category_manager_sheet.dart';
import 'fx_manager_sheet.dart';
import 'quote_fetch_sheet.dart';
import 'settings_dialogs.dart';
import 'settings_kit.dart';

/// 备份与恢复分类：概览（真实备份时间）→ 三操作卡（导出/恢复/合并）。
/// 恢复的覆盖风险提示挂在恢复卡的 info（提示语规范）。
class BackupSection extends ConsumerStatefulWidget {
  const BackupSection({super.key, required this.session});

  final VaultUnlocked session;

  @override
  ConsumerState<BackupSection> createState() => _BackupSectionState();
}

class _BackupSectionState extends ConsumerState<BackupSection> {
  DateTime? _lastBackup;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final ms = await widget.session.meta.settingInt('lastBackupAtMs');
    if (mounted) {
      setState(() => _lastBackup = ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StaggerIn(
          index: 0,
          child: SettingsPanel(
            title: t.settingsBkOverviewTitle,
            icon: Icons.backup_outlined,
            hint: t.settingsBkOverviewHint,
            child: Wrap(
              spacing: 26,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SettingsStatTile(
                  label: t.settingsBkLastBackup,
                  value: _lastBackup == null
                      ? t.settingsBkNever
                      : relTime(_lastBackup!, t),
                  color: _lastBackup == null
                      ? AppColors.warnOf(theme.brightness)
                      : null,
                  tooltip: t.settingsBkLastBackupTip,
                ),
                SettingsStatTile(
                  label: t.settingsBkContainer,
                  value: '.asbk',
                  tooltip: t.settingsBkContainerTip,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        SettingsCardGrid(
          startIndex: 1,
          children: [
            SettingsActionCard(
              icon: Icons.upload_file,
              title: t.settingsExportBackup,
              hint: t.settingsExportBackupHint,
              onTap: () async {
                await showBackupExportDialog(context, ref, widget.session);
                await _reload();
              },
            ),
            SettingsActionCard(
              icon: Icons.restore,
              title: t.settingsRestoreBackup,
              hint: t.settingsRestoreBackupHint,
              onTap: () => showBackupRestoreDialog(context, ref, widget.session),
            ),
            SettingsActionCard(
              icon: Icons.merge_type,
              title: t.settingsMergeBackup,
              hint: t.settingsMergeBackupHint,
              onTap: () => showMergeDialog(context, ref, widget.session),
            ),
          ],
        ),
      ],
    );
  }
}

/// 偏好分类：外观 / 本位币 / 预测参数三张面板，两列自适应（440 瓦宽）。
class PrefsSection extends ConsumerWidget {
  const PrefsSection({super.key, required this.session});

  final VaultUnlocked session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);
    final panels = [
      SettingsPanel(
        title: t.settingsPrefAppearanceTitle,
        icon: Icons.dark_mode_outlined,
        hint: t.settingsPrefAppearanceHint,
        child: _ThemeModeRow(session: session),
      ),
      SettingsPanel(
        title: t.settingsPrefMoneyTitle,
        icon: Icons.attach_money,
        hint: t.settingsPrefMoneyHint,
        child: ListRow(
          icon: Icons.currency_exchange,
          title: t.settingsBaseCurrency,
          hint: t.settingsBaseCurrencyHint,
          onTap: () => showBaseCurrencyDialog(context, ref, session),
        ),
      ),
      SettingsPanel(
        title: t.settingsPrefForecastTitle,
        icon: Icons.timeline,
        hint: t.settingsPrefForecastHint,
        child: Column(
          children: [
            _HorizonRow(session: session),
            Divider(height: 4, color: theme.dividerColor.withValues(alpha: 0.6)),
            _CashFloorRow(session: session),
          ],
        ),
      ),
    ];
    return LayoutBuilder(
      builder: (context, c) {
        const gap = 16.0;
        final columns = c.maxWidth >= 920 ? 3 : (c.maxWidth >= 560 ? 2 : 1);
        if (columns == 1) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < panels.length; i++)
                Padding(
                  padding: EdgeInsets.only(
                    bottom: i == panels.length - 1 ? 0 : gap,
                  ),
                  child: StaggerIn(index: i, child: panels[i]),
                ),
            ],
          );
        }
        final tile = (c.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (var i = 0; i < panels.length; i++)
              SizedBox(
                width: tile,
                child: StaggerIn(index: i, child: panels[i]),
              ),
          ],
        );
      },
    );
  }
}

/// 数据管理分类：真实数据概览（账户/交易/币种计数）→ 四操作卡。
class DataSection extends ConsumerStatefulWidget {
  const DataSection({super.key, required this.session});

  final VaultUnlocked session;

  @override
  ConsumerState<DataSection> createState() => _DataSectionState();
}

class _DataSectionState extends ConsumerState<DataSection> {
  (int, int, int)? _counts; // 账户 / 交易 / 币种

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final accounts = await widget.session.accounts.all();
      final tx = await widget.session.db
          .customSelect('SELECT COUNT(*) AS c FROM transactions')
          .getSingle();
      final currencies = accounts.map((a) => a.currencyCode).toSet().length;
      if (mounted) {
        setState(() => _counts = (accounts.length, tx.read<int>('c'), currencies));
      }
    } catch (_) {
      if (mounted) setState(() => _counts = (0, 0, 0));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final counts = _counts;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StaggerIn(
          index: 0,
          child: SettingsPanel(
            title: t.settingsDataOverviewTitle,
            icon: Icons.storage_outlined,
            hint: t.settingsDataOverviewHint,
            child: counts == null
                ? const SizedBox(
                    height: 40,
                    child: Center(child: OrbitSpinner(size: 18)),
                  )
                : Wrap(
                    spacing: 26,
                    runSpacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      SettingsStatTile(
                        label: t.settingsDataAccounts,
                        value: '${counts.$1}',
                      ),
                      SettingsStatTile(
                        label: t.settingsDataTxns,
                        value: '${counts.$2}',
                      ),
                      SettingsStatTile(
                        label: t.settingsDataCurrencies,
                        value: '${counts.$3}',
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 16),
        SettingsCardGrid(
          startIndex: 1,
          wide3At: 640,
          wide2At: 440,
          children: [
            SettingsActionCard(
              icon: Icons.file_upload_outlined,
              title: t.settingsImportCsv,
              hint: t.settingsImportCsvHint,
              onTap: () => showImportWizard(context, ref),
            ),
            SettingsActionCard(
              icon: Icons.data_object,
              title: t.settingsExportJson,
              hint: t.settingsExportJsonHint,
              onTap: () => _exportFullJson(context, widget.session),
            ),
            SettingsActionCard(
              icon: Icons.currency_exchange,
              title: t.fxManagerTitle,
              hint: t.fxManualHint,
              onTap: () => showFxManagerSheet(context, ref, widget.session),
            ),
            SettingsActionCard(
              icon: Icons.category_outlined,
              title: t.categoryManagerTitle,
              hint: t.categoryManagerHint,
              onTap: () => showCategoryManagerSheet(context, ref, widget.session),
            ),
          ],
        ),
      ],
    );
  }
}

/// AI 与行情分类：真实服务状态（配置读加密库）→ 两操作卡。
/// API Key 永不回显（只显服务商/模型/联网开关三态）。
class AiSection extends ConsumerStatefulWidget {
  const AiSection({super.key, required this.session});

  final VaultUnlocked session;

  @override
  ConsumerState<AiSection> createState() => _AiSectionState();
}

class _AiSectionState extends ConsumerState<AiSection> {
  AiConfig? _cfg;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final cfg = await widget.session.quoteFetch.config();
    if (mounted) {
      setState(() {
        _cfg = cfg;
        _loaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);
    final cfg = _cfg;
    final configured = _loaded && cfg != null && cfg.apiKey.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StaggerIn(
          index: 0,
          child: SettingsPanel(
            title: t.settingsAiStatusTitle,
            icon: Icons.smart_toy_outlined,
            hint: t.settingsAiStatusHint,
            child: !_loaded
                ? const SizedBox(
                    height: 40,
                    child: Center(child: OrbitSpinner(size: 18)),
                  )
                : Wrap(
                    spacing: 26,
                    runSpacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      SettingsStatTile(
                        label: t.settingsAiProvider,
                        value: !configured
                            ? t.settingsAiUnconfigured
                            : (cfg.preset?.label ?? t.settingsAiCustom),
                        color: configured
                            ? null
                            : AppColors.warnOf(theme.brightness),
                      ),
                      if (configured) ...[
                        SettingsStatTile(
                          label: t.settingsAiModel,
                          value: cfg.model,
                        ),
                        SettingsStatTile(
                          label: t.settingsAiWebSearch,
                          value: cfg.enableWebSearch
                              ? t.settingsAiOn
                              : t.settingsAiOff,
                        ),
                      ],
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 16),
        SettingsCardGrid(
          startIndex: 1,
          wide2At: 460,
          children: [
            SettingsActionCard(
              icon: Icons.smart_toy_outlined,
              title: t.aiCfgDialogTitle,
              hint: t.aiCfgServiceHint,
              onTap: () async {
                await showAiConfigSheet(context, widget.session);
                await _load();
              },
            ),
            SettingsActionCard(
              icon: Icons.travel_explore,
              title: t.quoteFetchTitle,
              hint: t.quoteFetchHint,
              onTap: () => showQuoteFetchSheet(context, ref),
            ),
          ],
        ),
      ],
    );
  }
}

/// 关于分类：品牌时刻（粒子 A 标 + 名称 + 版本）+ 版本信息行。
class AboutSection extends StatelessWidget {
  const AboutSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StaggerIn(
          index: 0,
          child: GlassCard(
            child: Stack(
              children: [
                const Positioned.fill(child: EarthArc()),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
                  child: Row(
                    children: [
                      const ParticleBrandMark(size: 88),
                      const SizedBox(width: 26),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    appName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.headlineSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.2,
                                        ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(
                                      AppRadii.chip,
                                    ),
                                    border: Border.all(
                                      color: theme.colorScheme.primary
                                          .withValues(alpha: 0.4),
                                    ),
                                    color: theme.colorScheme.primary
                                        .withValues(alpha: 0.08),
                                  ),
                                  child: Text(
                                    'v$appVersion',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                      fontFeatures: const [
                                        FontFeature.tabularFigures(),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              t.settingsAboutTagline,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.hintColor,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        StaggerIn(
          index: 1,
          child: SettingsPanel(
            title: t.settingsGroupAbout,
            icon: Icons.info_outline,
            child: ListRow(
              icon: Icons.verified_outlined,
              title: t.settingsAboutVersion,
              hint: t.settingsAboutVersionHint,
              trailingValue: appVersion,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// 偏好设置行（自旧 settings_page 迁入，逻辑不变）
// ─────────────────────────────────────────────────────────────────────────

/// 外观模式：跟随系统 / 浅色 / 深色（存设置表，立即生效）。
class _ThemeModeRow extends ConsumerWidget {
  const _ThemeModeRow({required this.session});

  final VaultUnlocked session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final t = AppLocalizations.of(context);
    return ListRow(
      icon: Icons.dark_mode_outlined,
      title: t.settingsThemeModeLabel,
      hint: t.settingsAppearanceHint,
      trailingValue: switch (mode) {
        ThemeMode.system => t.settingsThemeSystem,
        ThemeMode.light => t.settingsThemeLight,
        ThemeMode.dark => t.settingsThemeDark,
      },
      onTap: () async {
        final picked = await showAppDialog<ThemeMode>(
          context,
          builder: (_) => AppDialog(
            title: t.settingsAppearance,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final m in ThemeMode.values)
                  InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => Navigator.pop(context, m),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      child: Text(switch (m) {
                        ThemeMode.system => t.settingsThemeSystem,
                        ThemeMode.light => t.settingsThemeLight,
                        ThemeMode.dark => t.settingsThemeDark,
                      }),
                    ),
                  ),
              ],
            ),
          ),
        );
        if (picked == null) return;
        await ref.read(themeModeProvider.notifier).set(picked, session);
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
    final t = AppLocalizations.of(context);
    return ListRow(
      icon: Icons.timeline,
      title: t.settingsCashHorizon,
      hint: t.settingsCashHorizonHint,
      trailingValue: t.settingsDays(session.projectionHorizonDays),
      onTap: () async {
        final picked = await showAppDialog<int>(
          context,
          builder: (_) => AppDialog(
            title: t.settingsCashHorizon,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final d in const [30, 60, 90, 180])
                  InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => Navigator.pop(context, d),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      child: Text(t.settingsDays(d)),
                    ),
                  ),
              ],
            ),
          ),
        );
        if (picked == null) return;
        await session.meta.setSetting('projectionHorizonDays', picked);
        session.projectionHorizonDays = picked;
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(t.settingsCashHorizonSet(picked))));
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
    final t = AppLocalizations.of(context);
    return ListRow(
      icon: Icons.vertical_align_bottom,
      title: t.settingsCashFloor,
      hint: t.settingsCashFloorHint,
      onTap: () async {
        final ctrl = TextEditingController();
        final field = AppAmountField(controller: ctrl, currencyCode: 'CNY');
        final ok = await showAppDialog<bool>(
          context,
          builder: (dctx) => AppDialog(
            title: t.settingsCashFloor,
            content: field,
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dctx, false),
                child: Text(t.settingsCancel),
              ),
              ParticleFilledButton(
                onPressed: () => Navigator.pop(dctx, true),
                child: Text(t.settingsSave),
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
          ).showSnackBar(SnackBar(content: Text(t.settingsCashFloorSaved)));
        }
      },
    );
  }
}

/// 全量 JSON 导出（自旧 settings_page 迁入，逻辑不变）。
Future<void> _exportFullJson(BuildContext context, VaultUnlocked s) async {
  final t = AppLocalizations.of(context);
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
    ).showSnackBar(SnackBar(content: Text(t.settingsFullJsonExported)));
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(t.settingsExportFailed(e))));
  }
}
