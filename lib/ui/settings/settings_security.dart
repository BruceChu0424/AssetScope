import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../data/repositories/meta_repo.dart';
import '../../l10n/app_localizations.dart';
import '../globe/glass_card.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'settings_dialogs.dart';
import 'settings_kit.dart';

/// 安全分类：概览大卡（呼吸锁 + 点阵地球弧面 + 三真实状态章）→ 三张
/// 核心操作卡 → 会话与保护 + 最近安全操作。全部状态读真实金库数据，
/// 事件日志与账本同库加密（MetaRepo.securityEvents）。
class SecuritySection extends ConsumerStatefulWidget {
  const SecuritySection({super.key, required this.session});

  final VaultUnlocked session;

  @override
  ConsumerState<SecuritySection> createState() => _SecuritySectionState();
}

class _SecuritySectionState extends ConsumerState<SecuritySection> {
  List<SecurityEvent>? _events;

  /// 会话内最新恢复码状态（重新生成后置真，不重开会话）。
  late bool _hasRecovery = widget.session.hasRecoveryCode;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final events = await widget.session.meta.securityEvents();
    if (mounted) setState(() => _events = events);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [        StaggerIn(index: 0, child: _SecurityHero(hasRecovery: _hasRecovery)),
        const SizedBox(height: 16),
        SettingsCardGrid(
          startIndex: 1,
          children: [
            SettingsActionCard(
              icon: Icons.lock,
              title: t.settingsLockNow,
              hint: t.settingsLockNowHint,
              onTap: () => ref.read(vaultProvider.notifier).lock(),
            ),
            SettingsActionCard(
              icon: Icons.password,
              title: t.settingsChangePassphrase,
              hint: t.settingsChangePassphraseHint,
              onTap: () async {
                await showChangePassphraseDialog(context, ref);
                await _reload();
              },
            ),
            SettingsActionCard(
              icon: Icons.key,
              title: t.settingsRegenRecoveryCode,
              hint: t.settingsRegenRecoveryCodeHint,
              onTap: () async {
                await showNewRecoveryCodeDialog(context, ref);
                if (mounted) setState(() => _hasRecovery = true);
                await _reload();
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, c) {
            final two = c.maxWidth >= 680;
            final session = StaggerIn(
              index: 4,
              child: _SessionPanel(session: widget.session, onChanged: _reload),
            );
            final recent = StaggerIn(
              index: 5,
              child: _RecentOpsPanel(events: _events),
            );
            if (!two) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [session, const SizedBox(height: 16), recent],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 11, child: session),
                const SizedBox(width: 16),
                Expanded(flex: 10, child: recent),
              ],
            );
          },
        ),
      ],
    );
  }
}

/// 安全概览大卡：呼吸锁光环 + 三真实状态章 + 右缘点阵地球弧面。
class _SecurityHero extends StatelessWidget {
  const _SecurityHero({required this.hasRecovery});

  final bool hasRecovery;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);
    return GlassCard(
      child: Stack(
        children: [
          // 右缘极淡点阵地球弧面（纯装饰，不参与命中）。
          const Positioned.fill(child: EarthArc()),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
            child: Row(
              children: [
                BreathingHalo(icon: Icons.shield_outlined, size: 88),
                const SizedBox(width: 26),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            t.settingsGroupSecurity,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(width: 8),
                          InfoHint(message: t.settingsSecHeroHint),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          StatusChip(
                            label: t.settingsStatLocalEncrypt,
                            value: t.settingsStatEnabled,
                            ok: true,
                            tooltip: t.settingsStatLocalEncryptTip,
                          ),
                          StatusChip(
                            label: t.settingsStatPassphrase,
                            value: t.settingsStatSet,
                            ok: true,
                            tooltip: t.settingsStatPassphraseTip,
                          ),
                          StatusChip(
                            label: t.settingsStatRecovery,
                            value: hasRecovery
                                ? t.settingsStatConfigured
                                : t.settingsStatNotConfigured,
                            ok: hasRecovery,
                            tooltip: t.settingsStatRecoveryTip,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 会话与保护：自动锁定时长（下拉即存，真实生效）+ 启动时验证（金库
/// 机制恒真，作状态行呈现而非假开关）。
class _SessionPanel extends ConsumerStatefulWidget {
  const _SessionPanel({required this.session, required this.onChanged});

  final VaultUnlocked session;
  final Future<void> Function() onChanged;

  @override
  ConsumerState<_SessionPanel> createState() => _SessionPanelState();
}

class _SessionPanelState extends ConsumerState<_SessionPanel> {
  late int _lockMinutes = widget.session.lockTimeoutMinutes;

  static const _options = [1, 5, 15, 30, 60];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);
    return SettingsPanel(
      title: t.settingsSessionTitle,
      icon: Icons.timer_outlined,
      hint: t.settingsSessionHint,
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                ),
                child: Icon(
                  Icons.schedule,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        t.settingsAutoLock,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    InfoHint(message: t.settingsAutoLockRowHint),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 150,
                child: ParticleDropdownField<int>(
                  initialValue: _lockMinutes,
                  items: [
                    for (final m in _options)
                      DropdownMenuItem(value: m, child: Text(t.settingsMinutes(m))),
                  ],
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (v) => _save(v),
                ),
              ),
            ],
          ),
          Divider(height: 26, color: theme.dividerColor.withValues(alpha: 0.6)),
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                ),
                child: Icon(
                  Icons.verified_user_outlined,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        t.settingsStartupVerify,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    InfoHint(message: t.settingsStartupVerifyHint),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Text(
                  t.settingsStartupVerifyValue,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.positiveOf(theme.brightness),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _save(int? minutes) async {
    if (minutes == null || minutes == _lockMinutes) return;
    await widget.session.meta.setSetting('lockTimeoutMinutes', minutes);
    await ref.read(vaultProvider.notifier).refreshTunables();
    await widget.session.meta.appendSecurityEvent('config');
    if (!mounted) return;
    setState(() => _lockMinutes = minutes);
    final t = AppLocalizations.of(context);
    showTopNotice(context, t.settingsAutoLockSet(minutes), tone: TopNoticeTone.info);
    await widget.onChanged();
  }
}

/// 最近安全操作：真实事件日志（解锁/锁定/改口令/换恢复码/改配置），
/// 行 = 事件图标 + 名称 + 相对时间；空态简洁文案，绝不虚构。
class _RecentOpsPanel extends StatelessWidget {
  const _RecentOpsPanel({required this.events});

  final List<SecurityEvent>? events;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);
    return SettingsPanel(
      title: t.settingsRecentTitle,
      icon: Icons.history,
      hint: t.settingsRecentHint,
      child: events == null
          ? const SizedBox(
              height: 96,
              child: Center(child: OrbitSpinner(size: 20)),
            )
          : events!.isEmpty
          ? SizedBox(
              height: 96,
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.shield_moon_outlined,
                      size: 20,
                      color: theme.hintColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      t.settingsEvEmpty,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                for (var i = 0; i < events!.length && i < 8; i++)
                  _EventRow(
                    key: ValueKey('secop-${events![i].at.millisecondsSinceEpoch}'),
                    event: events![i],
                    index: i,
                  ),
              ],
            ),
    );
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow({super.key, required this.event, required this.index});

  final SecurityEvent event;
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);
    final (icon, label) = switch (event.kind) {
      'unlock' => (Icons.lock_open_outlined, t.settingsEvUnlock),
      'lock' => (Icons.lock_outline, t.settingsEvLock),
      'pass' => (Icons.password_outlined, t.settingsEvPass),
      'recovery' => (Icons.key_outlined, t.settingsEvRecovery),
      _ => (Icons.tune, t.settingsEvConfig),
    };
    return Column(
      children: [
        if (index > 0)
          Divider(
            height: 1,
            color: theme.dividerColor.withValues(alpha: 0.6),
          ),
        StaggerIn(
          index: index.clamp(0, 4),
          rise: 8,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 9),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: theme.colorScheme.primary.withValues(alpha: 0.10),
                  ),
                  child: Icon(icon, size: 15, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                Text(
                  relTime(event.at, t),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.hintColor,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
