import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../app/providers.dart';
import '../../l10n/app_localizations.dart';
import '../../security/dart_crypto_suite.dart';
import '../../services/backup_service.dart';
import '../../services/merge_counts.dart';
import '../../services/merge_service.dart';
import '../widgets/common.dart';

/// 从备份合并（多设备同步）：预览 → 安全备份 → 单事务合并。
///
/// 典型场景：手机与电脑各自记账，把任一端导出的 .asbk 放进网盘，
/// 在另一端"从备份合并"，两边的交易/计划/估值就会并到一起。
/// 表级策略见 docs/08 §5（交易 LWW、计划并集、汇率/估值自然键、设置只补缺）。
Future<void> showMergeDialog(
  BuildContext context,
  WidgetRef ref,
  VaultUnlocked s,
) async {
  final t = AppLocalizations.of(context);
  final picked = await openFile(
    acceptedTypeGroups: [
      XTypeGroup(label: t.settingsBackupFileType, extensions: ['asbk']),
    ],
  );
  if (picked == null || !context.mounted) return;
  final bytes = await File(picked.path).readAsBytes();
  final dek = s.keyManager.dek;
  final myFingerprint = MergeService.vaultFingerprint(
    s.keyManager.databaseKeyHex(),
  );

  // 先试 DEK 直开（同谱系 DEK 模式备份），失败再问口令。
  // 记住哪种凭据可用，解密临时库时用同一凭据。
  Uint8List? workingDek;
  String? workingPass;
  MergePrecheck? pre;
  try {
    pre = await MergeService.precheck(
      container: bytes,
      currentFingerprint: myFingerprint,
      currentSchemaVersion: s.db.schemaVersion,
      dek: dek,
    );
    workingDek = dek;
  } catch (_) {
    pre = null;
  }
  if (pre == null) {
    if (!context.mounted) return;
    final pass = await _askPassphrase(context);
    if (pass == null || !context.mounted) return;
    try {
      pre = await MergeService.precheck(
        container: bytes,
        currentFingerprint: myFingerprint,
        currentSchemaVersion: s.db.schemaVersion,
        passphrase: pass,
      );
      workingPass = pass;
    } catch (e) {
      if (context.mounted) {
        _snack(context, t.mergeDecryptFailed(e));
      }
      return;
    }
  }
  if (!context.mounted) return;

  if (!pre.schemaOk) {
    _snack(context, t.mergeSchemaTooNew(pre.backupSchemaVersion));
    return;
  }
  if (pre.hasLineage && !pre.sameLineage) {
    _snack(context, t.mergeLineageMismatch);
    return;
  }

  // 解密到明文临时库并预览。
  final dir = await ref.read(vaultProvider.notifier).appDir();
  final merge = MergeService(s.db);
  late final File plain;
  try {
    plain = await MergeService.decryptToPlain(
      container: bytes,
      workDir: dir,
      dek: workingDek,
      passphrase: workingPass,
    );
  } catch (e) {
    if (context.mounted) _snack(context, t.mergeVerifyFailed(e));
    return;
  }
  if (!context.mounted) {
    await plain.delete();
    return;
  }

  try {
    final preview = await merge.previewFrom(plain);
    if (preview.isEmpty) {
      if (context.mounted) {
        _snack(context, t.mergeNothingToMerge);
      }
      return;
    }
    if (!context.mounted) return;
    final confirmed = await _confirm(context, preview, legacy: !pre.hasLineage);
    if (confirmed != true || !context.mounted) return;

    // 合并前自动安全备份（同谱系 DEK 模式，本机可随时"从备份恢复"）。
    final safety = File(
      p.join(
        dir.path,
        'assetscope-premerge-${DateTime.now().millisecondsSinceEpoch}.asbk',
      ),
    );
    await BackupService(s.db, DartCryptoSuite.instance).exportTo(
      target: safety,
      dek: s.keyManager.dek,
      vaultFingerprint: myFingerprint,
    );

    final result = await merge.applyFrom(plain);
    if (!context.mounted) return;
    await showAppDialog<void>(
      context,
      builder: (_) => AppDialog(
        title: t.mergeDone,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(result.summarize()),
            const SizedBox(height: 12),
            Text(
              t.mergeSafetyBackupNote(safety.path),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          ParticleFilledButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t.settingsGotIt),
          ),
        ],
      ),
    );
  } catch (e) {
    if (context.mounted) _snack(context, t.mergeFailed(e));
  } finally {
    if (await plain.exists()) await plain.delete();
  }
}

Future<String?> _askPassphrase(BuildContext context) async {
  final t = AppLocalizations.of(context);
  final pass = TextEditingController();
  return showAppDialog<String>(
    context,
    builder: (dialogCtx) => AppDialog(
      title: t.settingsBackupPassphraseTitle,
      content: ParticleTextField(
        controller: pass,
        obscureText: true,
        decoration: InputDecoration(labelText: t.mergePassphraseLabel),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogCtx, null),
          child: Text(t.settingsCancel),
        ),
        ParticleFilledButton(
          onPressed: () => Navigator.pop(dialogCtx, pass.text),
          child: Text(t.settingsVerify),
        ),
      ],
    ),
  );
}

Future<bool?> _confirm(
  BuildContext context,
  MergeCounts preview, {
  required bool legacy,
}) async {
  final t = AppLocalizations.of(context);
  return showAppDialog<bool>(
    context,
    builder: (dialogCtx) => AppDialog(
      title: t.mergeConfirmTitle,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.mergeWillImport(preview.summarize())),
          const SizedBox(height: 8),
          Text(
            t.mergeConfirmNote,
            style: Theme.of(dialogCtx).textTheme.bodySmall,
          ),
          if (legacy) ...[
            const SizedBox(height: 8),
            Text(
              t.mergeLegacyWarning,
              style: Theme.of(dialogCtx).textTheme.bodySmall?.copyWith(
                color: Theme.of(dialogCtx).colorScheme.error,
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogCtx, false),
          child: Text(t.settingsCancel),
        ),
        ParticleFilledButton(
          onPressed: () => Navigator.pop(dialogCtx, true),
          child: Text(t.mergeBackupAndMerge),
        ),
      ],
    ),
  );
}

void _snack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
