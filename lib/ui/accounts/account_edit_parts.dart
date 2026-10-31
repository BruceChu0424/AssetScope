import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/ledger/account.dart';
import '../../domain/money/currency.dart';
import '../../l10n/app_localizations.dart';
import '../globe/city_locations.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart'
    show OrbitSpinner, ParticleTextField, ParticleDropdownField;

/// 新建资产弹窗的表单部件：类型磁贴 / 子类型与币种下拉 / 地址自动适配 /
/// 校验横摇。状态一律由弹窗持有，这里只做呈现。

/// 表单横摇：触发计数变化即重摇（衰减正弦水平摆动 420ms）；
/// 「减少动画」时跳过摆动。同锁屏 _FormShake 的对话框轻量版。
class FormShake extends StatefulWidget {
  const FormShake({
    super.key,
    required this.trigger,
    required this.child,
  });

  final int trigger;
  final Widget child;

  @override
  State<FormShake> createState() => _FormShakeState();
}

class _FormShakeState extends State<FormShake>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  @override
  void didUpdateWidget(FormShake old) {
    super.didUpdateWidget(old);
    if (widget.trigger != old.trigger &&
        !MediaQuery.disableAnimationsOf(context)) {
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = _c.value;
        final dx = t == 0 || t == 1
            ? 0.0
            : math.sin(t * math.pi * 6) * 7 * (1 - t);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: widget.child,
    );
  }
}

/// 资产/负债类型磁贴（弹窗最上层的第一道选择）。
///
/// 选中态：主色 8% 洗底 + 1.4px 主色描边；未选中：发丝线幽灵贴。
/// 色彩/描边过渡 180ms easeOut（状态指示）；「减少动画」瞬时切换。
class TypeTiles extends StatelessWidget {
  const TypeTiles({super.key, required this.type, required this.onChanged});

  final AccountType type;
  final ValueChanged<AccountType> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: _tile(
            context,
            AccountType.asset,
            t.assetsTitle,
            Icons.north_east,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _tile(
            context,
            AccountType.liability,
            t.accountGroupLiabilities,
            Icons.south_east,
          ),
        ),
      ],
    );
  }

  Widget _tile(
    BuildContext context,
    AccountType value,
    String label,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    final selected = type == value;
    final fg = selected ? theme.colorScheme.primary : theme.hintColor;
    return AnimatedContainer(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      height: 58,
      decoration: BoxDecoration(
        color: selected
            ? theme.colorScheme.primary.withValues(alpha: 0.08)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected ? theme.colorScheme.primary : theme.dividerColor,
          width: selected ? 1.4 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => onChanged(value),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 20, color: fg),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: fg,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 子类型下拉（资产/负债两套选项在同一位置切换）。
class SubtypeField extends StatelessWidget {
  const SubtypeField({
    super.key,
    required this.type,
    required this.assetSubtype,
    required this.liabilitySubtype,
    required this.onChangedAsset,
    required this.onChangedLiability,
  });

  final AccountType type;
  final AssetSubtype assetSubtype;
  final LiabilitySubtype liabilitySubtype;
  final ValueChanged<AssetSubtype> onChangedAsset;
  final ValueChanged<LiabilitySubtype> onChangedLiability;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    if (type == AccountType.asset) {
      return ParticleDropdownField<AssetSubtype>(
        key: const ValueKey('subtype-asset'),
        isExpanded: true,
        initialValue: assetSubtype,
        decoration: InputDecoration(labelText: t.subtypeLabel),
        menuMaxHeight: 380,
        itemHeight: 48,
        borderRadius: BorderRadius.circular(14),
        items: [
          for (final st in AssetSubtype.values)
            DropdownMenuItem(
              value: st,
              child: Text(
                st.labelZh,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
        onChanged: (v) => onChangedAsset(v!),
      );
    }
    return ParticleDropdownField<LiabilitySubtype>(
      key: const ValueKey('subtype-liability'),
      isExpanded: true,
        initialValue: liabilitySubtype,
      decoration: InputDecoration(labelText: t.subtypeLabel),
      menuMaxHeight: 380,
      itemHeight: 48,
      borderRadius: BorderRadius.circular(14),
      items: [
        for (final st in LiabilitySubtype.values)
          DropdownMenuItem(value: st, child: Text(st.labelZh)),
      ],
      onChanged: (v) => onChangedLiability(v!),
    );
  }
}

/// 币种下拉（代码 + 符号）。
class CurrencyField extends StatelessWidget {
  const CurrencyField({
    super.key,
    required this.currency,
    required this.onChanged,
  });

  final String currency;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return ParticleDropdownField<String>(
      key: const ValueKey('currency'),
      isExpanded: true,
        initialValue: currency,
      decoration: InputDecoration(labelText: t.currencyLabel),
      menuMaxHeight: 380,
      itemHeight: 48,
      borderRadius: BorderRadius.circular(14),
      items: [
        for (final c in CurrencyInfo.builtin)
          DropdownMenuItem(value: c.code, child: Text('${c.code} ${c.symbol}')),
      ],
      onChanged: (v) => onChanged(v!),
    );
  }
}

/// 地址输入 + 城市建议（自动适配）+ AI 精确定位。
///
/// 定位状态由父层持有：[located] 非空即已定位（后缀金标指南针），
/// [suggestions] 为父层按当前文本算出的候选城市；文本含内置城市名
/// 即自动定位（父层 matcher），候选只在未直接命中时出现。
/// [geoBusy]：父层 AI 地理编码进行中（后缀小轨道指示器）；
/// [geoLabel] 为已定位的提示文案（内置城市 / AI 精确定位 / AI 城市级）。
/// [error] 为提交校验错误态（未定位）：红框；横摇由外层 FormShake 负责。
class AddressField extends StatelessWidget {
  const AddressField({
    super.key,
    required this.controller,
    required this.located,
    required this.suggestions,
    required this.onChanged,
    required this.onPick,
    this.error = false,
    this.geoBusy = false,
    this.geoLabel,
  });

  final TextEditingController controller;
  final CityLocation? located;
  final List<CityLocation> suggestions;
  final ValueChanged<String> onChanged;
  final ValueChanged<CityLocation> onPick;
  final bool error;
  final bool geoBusy;
  final String? geoLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);
    final bad = error && located == null;
    final errorBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: theme.colorScheme.error, width: 2),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ParticleTextField(
          controller: controller,
          onChanged: onChanged,
          decoration: InputDecoration(
            labelText: t.locationLabel,
            prefixIcon: Icon(
              Icons.location_on_outlined,
              size: 20,
              color: bad ? theme.colorScheme.error : null,
            ),
            suffixIcon: Padding(
              padding: const EdgeInsets.only(right: 10),
              child: _suffix(context, theme),
            ),
            enabledBorder: bad ? errorBorder : null,
            focusedBorder: bad ? errorBorder : null,
          ),
        ),
        // 候选城市：淡入 + 轻上滑 160ms easeOut（内容瞬移的桥接）。
        AnimatedSwitcher(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 160),
          switchInCurve: Curves.easeOut,
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, -0.08),
                end: Offset.zero,
              ).animate(anim),
              child: child,
            ),
          ),
          child: suggestions.isEmpty
              ? const SizedBox(width: double.infinity, key: ValueKey('none'))
              : Padding(
                  key: ValueKey(
                      'cities-${suggestions.map((s) => s.name).join()}'),
                  padding: const EdgeInsets.only(top: 6),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Material(
                      elevation: 2,
                      color: theme.colorScheme.surface,
                      child: Column(
                        children: [
                          for (final s in suggestions)
                            ListTile(
                              dense: true,
                              visualDensity: VisualDensity.compact,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              minLeadingWidth: 0,
                              leading: Icon(
                                Icons.location_on_outlined,
                                size: 16,
                                color: theme.hintColor,
                              ),
                              title: Text(
                                s.name,
                                style: const TextStyle(fontSize: 14),
                              ),
                              onTap: () => onPick(s),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  /// 后缀状态：未定位空 / AI 定位中小轨道 / 已定位金色图标
  /// （AI 精确到 POI 用准星标，城市级用指南针）。状态切换 160ms 桥接。
  Widget? _suffix(BuildContext context, ThemeData theme) {
    final t = AppLocalizations.of(context);
    Widget? current;
    if (geoBusy) {
      current = const OrbitSpinner(size: 16);
    } else if (located != null) {
      final precise = !(geoLabel ?? '').contains('城市');
      current = Tooltip(
        message: geoLabel ?? t.locLocatedFallback(located!.name),
        child: Icon(
          precise ? Icons.my_location : Icons.explore,
          size: 18,
          color: AppColors.brassOf(theme.brightness),
        ),
      );
    }
    if (current == null) return null;
    return AnimatedSwitcher(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 160),
      switchInCurve: Curves.easeOut,
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: ScaleTransition(scale: anim, child: child),
      ),
      child: SizedBox(
        key: ValueKey(geoBusy ? 'geo-busy' : (geoLabel ?? 'geo-none')),
        child: Center(child: current),
      ),
    );
  }
}
