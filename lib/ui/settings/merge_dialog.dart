import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../app/providers.dart';
import '../../security/dart_crypto_suite.dart';
import '../../services/backup_service.dart';
import '../../services/merge_counts.dart';
import '../../services/merge_service.dart';
import '../widgets/particle_interactive.dart';

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
  final picked = await openFile(
    acceptedTypeGroups: [
      const XTypeGroup(label: '备份', extensions: ['asbk']),
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
        _snack(context, '备份无法解密（口令不对或文件损坏）：$e');
      }
      return;
    }
  }
  if (!context.mounted) return;

  if (!pre.schemaOk) {
    _snack(context, '备份来自更新版本的应用（schema ${pre.backupSchemaVersion}），请先升级再合并');
    return;
  }
  if (pre.hasLineage && !pre.sameLineage) {
    _snack(context, '这份备份属于另一个账本（谱系指纹不一致），不能合并。恢复请用"从备份恢复"');
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
    if (context.mounted) _snack(context, '备份内容校验失败：$e');
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
        _snack(context, '两份账本已一致，没有需要合并的内容');
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
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('合并完成'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(result.summarize()),
            const SizedBox(height: 12),
            Text(
              '合并前的安全备份：\n${safety.path}\n'
              '各页面回到前台会自动刷新。',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          ParticleFilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  } catch (e) {
    if (context.mounted) _snack(context, '合并失败（账本未改动，已整体回滚）：$e');
  } finally {
    if (await plain.exists()) await plain.delete();
  }
}

Future<String?> _askPassphrase(BuildContext context) async {
  final pass = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (dialogCtx) => AlertDialog(
      title: const Text('输入备份口令'),
      content: ParticleTextField(
        controller: pass,
        obscureText: true,
        decoration: const InputDecoration(labelText: '这份 .asbk 的导出口令'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogCtx, null),
          child: const Text('取消'),
        ),
        ParticleFilledButton(
          onPressed: () => Navigator.pop(dialogCtx, pass.text),
          child: const Text('校验'),
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
  return showDialog<bool>(
    context: context,
    builder: (dialogCtx) => AlertDialog(
      title: const Text('确认合并'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('将并入：${preview.summarize()}。'),
          const SizedBox(height: 8),
          Text(
            '交易按"更新时间新者胜"合并，其余内容按表策略并入；'
            '合并会先自动生成一份安全备份，可随时用"从备份恢复"退回。',
            style: Theme.of(dialogCtx).textTheme.bodySmall,
          ),
          if (legacy) ...[
            const SizedBox(height: 8),
            Text(
              '注意：这份备份由旧版本导出、没有账本身份标识。请确认它确实来自同一本账。',
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
          child: const Text('取消'),
        ),
        ParticleFilledButton(
          onPressed: () => Navigator.pop(dialogCtx, true),
          child: const Text('安全备份并合并'),
        ),
      ],
    ),
  );
}

void _snack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
