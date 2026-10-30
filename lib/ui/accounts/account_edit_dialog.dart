import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/ledger/account.dart';
import '../../domain/ledger/transaction.dart';
import '../../domain/money/currency.dart';
import '../../domain/money/fx_rate.dart';
import '../../domain/money/money.dart';
import '../../domain/valuation/valuation.dart';
import '../../services/ai/account_ai_service.dart';
import '../../services/ai/ai_chat.dart';
import '../globe/city_locations.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'account_edit_parts.dart';
import 'accounts_providers.dart';
import 'ownership.dart';

/// 新建资产对话框（类型磁贴 + 名称 AI 识别 + 子类型/币种 + 价值 +
/// 地址自动适配 + 机构/份额）。
///
/// 价值口径按子类型自动分流：现金类记期初余额（交易）、房产等手工估值
/// 类记 totalValue 估值、负债记期初欠款（对账调整负值）、持仓不填
/// （价值 = 数量 × 行情，买入后自然产生）。
///
/// 资产（非持仓）**必须定位**——保存瞬间整个弹窗碎裂成粒子光束，
/// 飞往地球对应坐标汇聚成资产标志（[DissolveController]，由首页挂
/// 地球联动钩子）。校验失败按规范反馈：顶部通知 + 红框 + 横摇，
/// 不用内联错误文字。
class AccountEditDialog extends ConsumerStatefulWidget {
  const AccountEditDialog({super.key, this.dissolve});

  /// 粒子化保存控制器（首页创建并挂地球钩子）；null = 普通关闭。
  final DissolveController? dissolve;

  @override
  ConsumerState<AccountEditDialog> createState() => _AccountEditDialogState();
}

class _AccountEditDialogState extends ConsumerState<AccountEditDialog> {
  final _name = TextEditingController();
  final _institution = TextEditingController();
  final _code = TextEditingController();
  final _value = TextEditingController();
  final _address = TextEditingController();
  final _ownership = TextEditingController(text: '100');
  final _saveKey = GlobalKey(debugLabel: 'account-save-btn');
  final _aiKey = GlobalKey(debugLabel: 'account-ai-btn');
  AccountType _type = AccountType.asset;
  AssetSubtype _assetSubtype = AssetSubtype.bank;
  LiabilitySubtype _liabilitySubtype = LiabilitySubtype.creditCard;
  String _currency = 'CNY';

  /// 已定位的城市（地址文本含城市名即自动适配；null = 未定位）。
  CityLocation? _locatedCity;

  /// 定位来源：'' 未定位 / 'builtin' 内置城市 / 'ai' AI 精确定位（POI）/
  /// 'ai-city' AI 城市级。决定后缀图标与提示文案。
  String _geoSource = '';
  Timer? _geoDebounce;
  bool _geoBusy = false;

  String? get _geoLabel {
    final name = _locatedCity?.name ?? '';
    switch (_geoSource) {
      case 'builtin':
        return '已定位：$name（内置城市坐标）';
      case 'ai':
        return 'AI 已定位：$name（精确位置）';
      case 'ai-city':
        return 'AI 已定位：$name（城市中心）';
    }
    return null;
  }

  bool _saving = false;
  bool _nameError = false;
  bool _locationError = false;
  bool _valueError = false;
  bool _aiValuation = true;
  int _nameShake = 0;
  int _locationShake = 0;
  int _valueShake = 0;

  bool get _isHolding => _type == AccountType.asset && _assetSubtype.isHolding;

  /// 位置区块只在「资产 · 非持仓」时出现（持仓/负债无地理概念）。
  bool get _needLocation =>
      _type == AccountType.asset && !_assetSubtype.isHolding;

  /// 每日 AI 估值开关：manualValue 类资产（房产/车辆等）默认开启——
  /// 联网检索真实市价，每天自动更新资产价值（详情弹层可随时关/纠正）。
  bool get _showAiValuation =>
      _type == AccountType.asset &&
      Account.valuationMethodOf(_assetSubtype) == ValuationMethod.manualValue;

  /// 价值输入：持仓隐藏（价值 = 数量 × 行情，买入后自然产生）。
  bool get _showValue => !_isHolding;

  String get _valueLabel => _type == AccountType.liability
      ? '当前欠款'
      : (Account.valuationMethodOf(_assetSubtype) ==
              ValuationMethod.manualValue
          ? '当前价值'
          : '当前余额');

  (double, double, String?)? get _location => _locatedCity == null
      ? null
      : (
          _locatedCity!.lat,
          _locatedCity!.lon,
          _address.text.trim().isEmpty ? null : _address.text.trim(),
        );

  @override
  void dispose() {
    _geoDebounce?.cancel();
    _name.dispose();
    _institution.dispose();
    _code.dispose();
    _value.dispose();
    _address.dispose();
    _ownership.dispose();
    super.dispose();
  }

  // ---------- 位置：输入地址自动适配 + AI 精确定位 ----------

  void _onAddressChanged(String t) {
    _geoDebounce?.cancel();
    final m = kCityLocations.where((c) => t.contains(c.name)).firstOrNull;
    setState(() {
      _locatedCity = m;
      _geoSource = m == null ? '' : 'builtin';
      if (m != null) _locationError = false;
    });
    if (m != null) return;
    // 未命中内置城市：足够长的地址交给 AI 地理编码（防抖 800ms）。
    if (t.trim().length < 4) return;
    _geoDebounce = Timer(const Duration(milliseconds: 800), _aiGeocode);
  }

  /// AI 地理编码：详细地址（小区/楼栋）→ 精确坐标。
  /// 未配置 AI 静默跳过（内置城市候选仍可用）；失败静默不打扰输入。
  Future<void> _aiGeocode() async {
    if (!mounted || _geoBusy || _locatedCity != null) return;
    final s = sessionOf(ref.read(vaultProvider));
    if (s == null) return;
    final address = _address.text.trim();
    if (address.length < 4) return;
    final ai = AccountAiService(s.meta, const AiChat());
    final cfg = await ai.config();
    if (cfg == null || !mounted) return;
    setState(() => _geoBusy = true);
    try {
      final g = await ai.geocode(cfg, address);
      if (!mounted) return;
      if (_address.text.trim() != address || _locatedCity != null) return;
      setState(() {
        _locatedCity = CityLocation(
          g.formatted.isEmpty ? address : g.formatted,
          g.lat,
          g.lon,
        );
        _geoSource = g.precision == 'poi' ? 'ai' : 'ai-city';
        _locationError = false;
      });
    } catch (_) {
      // 静默：候选城市仍在，用户可手选或继续输入。
    } finally {
      if (mounted) setState(() => _geoBusy = false);
    }
  }

  /// 候选城市：文本非空且未直接命中时，前缀匹配优先、包含次之，取 5。
  List<CityLocation> get _suggestions {
    final t = _address.text.trim();
    if (t.isEmpty || _locatedCity != null) return const [];
    final head = <CityLocation>[];
    final tail = <CityLocation>[];
    for (final c in kCityLocations) {
      if (c.name.startsWith(t)) {
        head.add(c);
      } else if (c.name.contains(t)) {
        tail.add(c);
      }
    }
    return [...head, ...tail].take(5).toList();
  }

  void _pickCity(CityLocation c) {
    setState(() {
      _address.text = c.name;
      _locatedCity = c;
      _geoSource = 'builtin';
      _locationError = false;
    });
  }

  // ---------- AI 识别 ----------

  /// 名称 → AI（复用设置里的 AI 绑定）→ 类型/子类型/币种/机构/城市坐标。
  /// 只发送名称文本（隐私边界）；价值永远由用户手动填写。
  Future<void> _aiFill() async {
    final s = sessionOf(ref.read(vaultProvider));
    if (s == null || _saving) return;
    final name = _name.text.trim();
    if (name.isEmpty) {
      showTopNotice(context, '先填写资产名称，AI 才能识别',
          tone: TopNoticeTone.info);
      return;
    }
    final ai = AccountAiService(s.meta, const AiChat());
    final cfg = await ai.config();
    if (!mounted) return;
    if (cfg == null) {
      showTopNotice(context, '尚未绑定 AI：设置 → AI 服务',
          tone: TopNoticeTone.info);
      return;
    }
    try {
      AiAccountSuggestion? sug;
      await runBusy(
        context,
        message: 'AI 识别中…',
        origin: _centerOf(_aiKey),
        task: () async {
          sug = await ai.recognize(cfg, name);
        },
      );
      if (!mounted) return;
      final g = sug;
      if (g == null) return;
      _applySuggestion(g);
      showTopNotice(context, 'AI 已填充，请确认价值', tone: TopNoticeTone.info);
    } catch (_) {
      // 失败详情已由 runBusy 舞台展示
    }
  }

  void _applySuggestion(AiAccountSuggestion g) {
    setState(() {
      if (g.type == AccountType.liability) {
        _type = AccountType.liability;
        if (g.liabilitySubtype != null) _liabilitySubtype = g.liabilitySubtype!;
      } else {
        _type = AccountType.asset;
        if (g.assetSubtype != null) _assetSubtype = g.assetSubtype!;
      }
      if (g.currency != null && _currencyCodes.contains(g.currency)) {
        _currency = g.currency!;
      }
      final inst = g.institution?.trim();
      if (inst != null && inst.isNotEmpty) _institution.text = inst;
      // 位置：AI 坐标优先（可能是内置城市表外地点），否则按城市名查
      // 内置表；两者皆无则不动位置字段。
      if (_needLocation) {
        final city = g.city?.trim();
        if (city != null && city.isNotEmpty) {
          CityLocation? loc = g.lat != null && g.lon != null
              ? CityLocation(city, g.lat!, g.lon!)
              : kCityLocations.where((c) => c.name == city).firstOrNull;
          if (loc != null) {
            _address.text = city;
            _locatedCity = loc;
            _geoSource = g.lat != null ? 'ai-city' : 'builtin';
            _locationError = false;
          }
        }
      } else {
        _locatedCity = null;
        _geoSource = '';
        _address.clear();
      }
    });
  }

  static final List<String> _currencyCodes = [
    for (final c in CurrencyInfo.builtin) c.code,
  ];

  // ---------- 保存 ----------

  Offset? _centerOf(GlobalKey key) {
    final ro = key.currentContext?.findRenderObject();
    if (ro is RenderBox && ro.hasSize) {
      return ro.localToGlobal(ro.size.center(Offset.zero));
    }
    return null;
  }

  /// 价值 → 最小单位；空返回 null；非法/非正同样返回 null（校验报错）。
  BigInt? _parseValueMinor() {
    final t = _value.text.trim();
    if (t.isEmpty) return null;
    final BigInt v;
    try {
      v = Money.parse(t, CurrencyInfo.parse(_currency)).amountMinor;
    } on FormatException {
      return null;
    }
    return v > BigInt.zero ? v : null;
  }

  Future<void> _save() async {
    if (_saving) return;
    final s = sessionOf(ref.read(vaultProvider));
    if (s == null) return;
    final nameEmpty = _name.text.trim().isEmpty;
    final locMissing = _needLocation && _location == null;
    final valueBad = _showValue &&
        _value.text.trim().isNotEmpty &&
        _parseValueMinor() == null;
    setState(() {
      _nameError = nameEmpty;
      _locationError = locMissing;
      _valueError = valueBad;
      if (nameEmpty) _nameShake++;
      if (locMissing) _locationShake++;
      if (valueBad) _valueShake++;
    });
    if (nameEmpty) {
      showTopNotice(context, '请填写资产名称');
      return;
    }
    if (locMissing) {
      showTopNotice(context, '请选择资产位置——保存后将在地球首页点亮对应坐标');
      return;
    }
    if (valueBad) {
      showTopNotice(context, '价值需为正数（如 1280000）');
      return;
    }

    _saving = true;
    setState(() {});
    final ownership = parseOwnership(_ownership.text) ?? Rational.one;
    final valueMinor = _showValue ? _parseValueMinor() : null;
    final Account acct;
    if (_isHolding) {
      final code = _code.text.trim().isEmpty
          ? _name.text.trim()
          : _code.text.trim();
      acct = await s.accounts.createHolding(
        name: _name.text.trim(),
        subtype: _assetSubtype,
        currencyCode: _currency,
        securityCode: code,
        institution:
            _institution.text.trim().isEmpty ? null : _institution.text.trim(),
      );
    } else {
      final id =
          'acc:${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}';
      final loc = _needLocation ? _location : null;
      acct = Account(
        id: id,
        name: _name.text.trim(),
        type: _type,
        assetSubtype: _type == AccountType.asset ? _assetSubtype : null,
        liabilitySubtype:
            _type == AccountType.liability ? _liabilitySubtype : null,
        institution:
            _institution.text.trim().isEmpty ? null : _institution.text.trim(),
        currencyCode: _currency,
        ownership: ownership == Rational.one ? null : ownership,
        locationLat: loc?.$1,
        locationLon: loc?.$2,
        locationName: loc?.$3,
        aiValuationEnabled: _showAiValuation && _aiValuation,
      );
      await s.accounts.upsert(acct);
    }
    await _writeValue(s, acct, valueMinor);
    ref.invalidate(accountsViewProvider);
    if (!mounted) return;
    // 粒子化保存：截图碎裂成粒子光束飞往地球落点（失败/减少动画则
    // 普通关闭，由外层即时重载标记）。
    final dis = widget.dissolve;
    if (dis != null && _needLocation && _location != null) {
      final ok = await dis.dissolveAndPop(
        origin: _centerOf(_saveKey),
        lat: _location!.$1,
        lon: _location!.$2,
      );
      if (ok) return;
    }
    if (mounted) Navigator.of(context).pop(true);
  }

  /// 初始价值按估值口径分流（见类注释）。
  Future<void> _writeValue(VaultUnlocked s, Account acct, BigInt? minor) async {
    if (minor == null) return;
    final now = DateTime.now();
    if (_type == AccountType.liability) {
      await s.ledger.post(TxBuilders.adjustment(
        account: acct,
        signedChangeMinor: -minor,
        date: now,
        note: '期初欠款',
      ));
    } else if (acct.valuationMethod == ValuationMethod.manualValue) {
      await s.meta.saveValuation(ValuationRecord(
        accountId: acct.id,
        date: now,
        kind: ValuationKind.totalValue,
        totalValueMinor: minor,
      ));
    } else {
      await s.ledger.post(TxBuilders.openingBalance(
        assetAccount: acct,
        amountMinor: minor,
        date: now,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final errorBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: theme.colorScheme.error, width: 2),
    );
    final motionDur = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 220);
    return AlertDialog(
      // 表单列内多为 Expanded 型子件（固有宽度为 0），不给最小宽度
      // AlertDialog 会把弹窗收缩到 label 宽度——下拉内部 Row 随之溢出。
      // 窄屏（手机）下会被外层约束自动钳制，不会越界。
      constraints: const BoxConstraints(minWidth: 432),
      title: Row(
        children: [
          const Expanded(child: Text('新建资产')),
          Tooltip(
            message: '资产需选位置——保存后弹窗将碎成光束，飞往地球点亮该坐标',
            child: Icon(Icons.info_outline, size: 18, color: theme.hintColor),
          ),
        ],
      ),
      contentPadding: const EdgeInsets.fromLTRB(24, 6, 24, 0),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TypeTiles(
            type: _type,
            onChanged: (t) => setState(() {
              _type = t;
              // 位置区块随类型重建，避免悬空选择。
              _locatedCity = null;
              _geoSource = '';
              _address.clear();
              _locationError = false;
            }),
          ),
          const SizedBox(height: 16),
          FormShake(
            trigger: _nameShake,
            child: ParticleTextField(
              controller: _name,
              autofocus: true,
              onChanged: (_) {
                if (_nameError) setState(() => _nameError = false);
              },
              decoration: InputDecoration(
                labelText: '名称',
                suffixIcon: IconButton(
                  key: _aiKey,
                  tooltip: 'AI 识别',
                  icon: Icon(
                    Icons.auto_awesome,
                    size: 20,
                    color: AppColors.brassOf(theme.brightness),
                  ),
                  onPressed: _aiFill,
                ),
                enabledBorder: _nameError ? errorBorder : null,
                focusedBorder: _nameError ? errorBorder : null,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: SubtypeField(
                  type: _type,
                  assetSubtype: _assetSubtype,
                  liabilitySubtype: _liabilitySubtype,
                  onChangedAsset: (v) => setState(() {
                    _assetSubtype = v;
                    if (v.isHolding) {
                      _locatedCity = null;
                      _geoSource = '';
                      _address.clear();
                      _locationError = false;
                    }
                  }),
                  onChangedLiability: (v) =>
                      setState(() => _liabilitySubtype = v),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: CurrencyField(
                  currency: _currency,
                  onChanged: (v) => setState(() => _currency = v),
                ),
              ),
            ],
          ),
          if (_showValue) ...[
            const SizedBox(height: 14),
            FormShake(
              trigger: _valueShake,
              child: ParticleTextField(
                controller: _value,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) {
                  if (_valueError) setState(() => _valueError = false);
                },
                decoration: InputDecoration(
                  labelText: _valueLabel,
                  suffixText: _currency,
                  enabledBorder: _valueError ? errorBorder : null,
                  focusedBorder: _valueError ? errorBorder : null,
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          // 位置 ↔ 证券代码：高度生长 + 淡入缩放（内容瞬移的桥接）。
          AnimatedSize(
            duration: motionDur,
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: AnimatedSwitcher(
              duration: motionDur,
              switchInCurve: Curves.easeOut,
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.97, end: 1).animate(anim),
                  child: child,
                ),
              ),
              child: _needLocation
                  ? FormShake(
                      key: const ValueKey('loc'),
                      trigger: _locationShake,
                      child: AddressField(
                        controller: _address,
                        located: _locatedCity,
                        suggestions: _suggestions,
                        onChanged: _onAddressChanged,
                        onPick: _pickCity,
                        error: _locationError,
                        geoBusy: _geoBusy,
                        geoLabel: _geoLabel,
                      ),
                    )
                  : _isHolding
                      ? ParticleTextField(
                          key: const ValueKey('code'),
                          controller: _code,
                          decoration:
                              const InputDecoration(labelText: '证券代码'),
                        )
                      : const SizedBox(
                          width: double.infinity,
                          key: ValueKey('none'),
                        ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ParticleTextField(
                  controller: _institution,
                  decoration: const InputDecoration(labelText: '机构'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ParticleTextField(
                  controller: _ownership,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: '份额',
                    suffixText: '%',
                  ),
                ),
              ),
            ],
          ),
          // 每日 AI 估值：仅 manualValue 类资产出现（内容变化的高度桥接）。
          AnimatedSize(
            duration: motionDur,
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: AnimatedSwitcher(
              duration: motionDur,
              switchInCurve: Curves.easeOut,
              child: _showAiValuation
                  ? Padding(
                      key: const ValueKey('ai-valuation'),
                      padding: const EdgeInsets.only(top: 4),
                      child: SwitchListTile(
                        key: const ValueKey('ai-switch'),
                        contentPadding: EdgeInsets.zero,
                        value: _aiValuation,
                        onChanged: (v) => setState(() => _aiValuation = v),
                        title: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              size: 17,
                              color: AppColors.brassOf(theme.brightness),
                            ),
                            const SizedBox(width: 7),
                            const Text('每日 AI 估值'),
                            const SizedBox(width: 5),
                            Tooltip(
                              message: '开启后每天联网检索该资产真实市价并自动'
                                  '更新价值（房产看成交行情、车辆看二手估值，'
                                  '多源交叉剔除营销噪音）；你随时可在账户详情'
                                  '纠正，当日人工值优先',
                              child: Icon(
                                Icons.info_outline,
                                size: 16,
                                color: theme.hintColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : const SizedBox(
                      width: double.infinity,
                      key: ValueKey('ai-none'),
                    ),
            ),
          ),
        ],
      ),
      actionsPadding: const EdgeInsets.fromLTRB(24, 20, 24, 22),
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context, false),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(46),
                ),
                child: const Text('取消'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: ParticleFilledButton(
                key: _saveKey,
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(46),
                ),
                child: const Text('创建资产'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
