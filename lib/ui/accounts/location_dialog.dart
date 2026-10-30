import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/ledger/account.dart';
import '../globe/city_locations.dart';
import '../widgets/particle_interactive.dart';
import 'accounts_providers.dart';

/// 设置/修改资产位置（3D 地球标记）。
///
/// 三种方式：城市快选 → 城市名微调坐标 → 手动经纬度。
Future<void> showLocationDialog(
  BuildContext context,
  WidgetRef ref,
  VaultUnlocked s,
  Account account,
) async {
  final nameCtrl = TextEditingController(text: account.locationName ?? '');
  final latCtrl = TextEditingController(
    text: account.locationLat?.toStringAsFixed(4) ?? '',
  );
  final lonCtrl = TextEditingController(
    text: account.locationLon?.toStringAsFixed(4) ?? '',
  );

  Future<void> save() async {
    final lat = double.tryParse(latCtrl.text.trim());
    final lon = double.tryParse(lonCtrl.text.trim());
    if (lat == null || lon == null) return;
    if (lat < -90 || lat > 90 || lon < -180 || lon > 180) return;
    await s.accounts.upsert(
      account.copyWith(
        locationLat: lat,
        locationLon: lon,
        locationName: nameCtrl.text.trim().isEmpty
            ? null
            : nameCtrl.text.trim(),
      ),
    );
    ref.invalidate(accountsViewProvider);
  }

  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetCtx) => Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        MediaQuery.of(sheetCtx).viewInsets.bottom + 20,
      ),
      child: StatefulBuilder(
        builder: (ctx, setSheet) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '「${account.name}」的位置',
              style: Theme.of(ctx).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              '设置后该资产将以呼吸标记出现在 3D 资产地球上',
              style: Theme.of(
                ctx,
              ).textTheme.bodySmall?.copyWith(color: Theme.of(ctx).hintColor),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 96,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final city in kCityLocations)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        label: Text(city.name),
                        onPressed: () {
                          latCtrl.text = city.lat.toStringAsFixed(4);
                          lonCtrl.text = city.lon.toStringAsFixed(4);
                          if (nameCtrl.text.trim().isEmpty) {
                            nameCtrl.text = city.name;
                          }
                          setSheet(() {});
                        },
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ParticleTextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: '位置名（如 上海·前滩）',
                suffixIcon: Icon(Icons.place),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ParticleTextField(
                    controller: latCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      signed: true,
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: '纬度 (-90 ~ 90)',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ParticleTextField(
                    controller: lonCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      signed: true,
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: '经度 (-180 ~ 180)',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '坐标为 WGS84；国内资产可用城市快选后在地图 App 里查小区坐标微调',
              style: Theme.of(
                ctx,
              ).textTheme.bodySmall?.copyWith(color: Theme.of(ctx).hintColor),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (account.hasLocation)
                  TextButton(
                    onPressed: () async {
                      // copyWith 无法置空字段：用完整构造清除位置。
                      await s.accounts.upsert(
                        Account(
                          id: account.id,
                          name: account.name,
                          type: account.type,
                          assetSubtype: account.assetSubtype,
                          liabilitySubtype: account.liabilitySubtype,
                          institution: account.institution,
                          currencyCode: account.currencyCode,
                          ownership: account.ownership,
                          includeInNetWorth: account.includeInNetWorth,
                          creditLimitMinor: account.creditLimitMinor,
                          statementDay: account.statementDay,
                          dueDay: account.dueDay,
                          isSystem: account.isSystem,
                          archived: account.archived,
                          sortOrder: account.sortOrder,
                          notes: account.notes,
                          costBasisAccountId: account.costBasisAccountId,
                          securityId: account.securityId,
                        ),
                      );
                      ref.invalidate(accountsViewProvider);
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: const Text('清除位置'),
                  ),
                ParticleFilledButton(
                  onPressed: () async {
                    await save();
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('保存'),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

