import '../ledger/account.dart';
import '../money/fx_rate.dart';

/// 资产配置大类（口径见 docs/05 §10）：把账户子类型收敛为九类配置桶，
/// 负债不参与配置。基金（股债混合）单列，符合国内习惯。
enum AllocationClass {
  equity('股票'),
  fund('基金'),
  bond('债券'),
  cash('现金及等价物'),
  fixedIncome('固收理财'),
  alternatives('另类资产'),
  realAssets('固定资产'),
  longTerm('长期权益'),
  other('其他资产');

  const AllocationClass(this.labelZh);
  final String labelZh;

  static AllocationClass fromSubtype(AssetSubtype s) => switch (s) {
    AssetSubtype.stock => equity,
    AssetSubtype.fund => fund,
    AssetSubtype.bond => bond,
    AssetSubtype.cash ||
    AssetSubtype.alipay ||
    AssetSubtype.wechat ||
    AssetSubtype.bank ||
    AssetSubtype.brokerCash ||
    AssetSubtype.moneyFund => cash,
    AssetSubtype.timeDeposit || AssetSubtype.wealthMgmt => fixedIncome,
    AssetSubtype.preciousMetal ||
    AssetSubtype.crypto ||
    AssetSubtype.equityOwnership => alternatives,
    AssetSubtype.realEstate || AssetSubtype.vehicle => realAssets,
    AssetSubtype.pension ||
    AssetSubtype.providentFund ||
    AssetSubtype.insuranceCashValue => longTerm,
    AssetSubtype.depositPaid ||
    AssetSubtype.receivable ||
    AssetSubtype.otherAsset => other,
  };
}

/// 目标配置：类 → 整数百分比（0–100），未出现的类"不设目标"。
/// 存设置键 `allocationTargets`（JSON：{"equity": 40, ...}）。
class TargetAllocation {
  const TargetAllocation(this._percents);

  final Map<AllocationClass, int> _percents;

  static const empty = TargetAllocation({});

  Map<AllocationClass, int> get percents => Map.unmodifiable(_percents);

  int? operator [](AllocationClass c) => _percents[c];

  int get totalPercent => _percents.values.fold(0, (a, b) => a + b);

  bool get isValid =>
      _percents.values.every((v) => v >= 0 && v <= 100) && totalPercent <= 100;

  static TargetAllocation parseJson(Map<String, Object?> json) {
    final m = <AllocationClass, int>{};
    for (final e in json.entries) {
      final c = AllocationClass.values
          .where((c) => c.name == e.key)
          .firstOrNull;
      if (c == null) continue;
      final v = e.value;
      if (v is int) m[c] = v;
      if (v is double) m[c] = v.round();
    }
    return TargetAllocation(m);
  }

  Map<String, int> toJson() => {
    for (final e in _percents.entries) e.key.name: e.value,
  };
}

/// 单类配置现状：本位币价值与占全部资产比例（Rational，避免浮点）。
class AllocationSlice {
  const AllocationSlice({
    required this.allocationClass,
    required this.valueBaseMinor,
    required this.share,
  });

  final AllocationClass allocationClass;
  final BigInt valueBaseMinor;

  /// 占比（0–1）。
  final Rational share;
}

/// 再平衡动作。
enum RebalanceAction { none, buy, sell }

/// 单类的再平衡建议（Vanguard 5/25 带宽法，见 docs/05 §10）：
/// 阈值 = max(5 个百分点, 目标的 25%)；偏离越带 → 交易回带边
/// （不是回到目标，减少换手）。
class RebalanceAdvice {
  const RebalanceAdvice({
    required this.allocationClass,
    required this.currentShare,
    required this.targetShare,
    required this.action,
    required this.tradeMinor,
  });

  final AllocationClass allocationClass;

  /// 当前占比（0–1）。
  final Rational currentShare;

  /// 目标占比（0–1）。
  final Rational targetShare;

  final RebalanceAction action;

  /// 建议交易金额（正数；action == none 时为 0）。
  final BigInt tradeMinor;

  bool get needsAction => action != RebalanceAction.none;
}

class RebalanceAdvisor {
  const RebalanceAdvisor._();

  static final _absBand = Rational.fromFrac(
    BigInt.from(5),
    BigInt.from(100),
  ); // 5 个百分点
  static final _relBand = Rational.fromFrac(
    BigInt.one,
    BigInt.from(4),
  ); // 目标的 25%

  /// 逐类建议。[valuesBaseMinor] 为各类本位币价值；
  /// [totalBaseMinor] 为全部资产总值（建议金额的分母）。
  static List<RebalanceAdvice> advise({
    required Map<AllocationClass, BigInt> valuesBaseMinor,
    required BigInt totalBaseMinor,
    required TargetAllocation targets,
  }) {
    final out = <RebalanceAdvice>[];
    if (totalBaseMinor <= BigInt.zero) return const [];
    final total = Rational.fromInt(totalBaseMinor);
    for (final c in AllocationClass.values) {
      final targetPct = targets[c];
      if (targetPct == null || targetPct <= 0) continue;
      final target = Rational.fromFrac(
        BigInt.from(targetPct),
        BigInt.from(100),
      );
      final value = Rational.fromInt(valuesBaseMinor[c] ?? BigInt.zero);
      final current = value / total;
      final drift = current - target;
      final threshold = _absBand > target * _relBand
          ? _absBand
          : target * _relBand;
      if (drift.abs() <= threshold) {
        out.add(
          RebalanceAdvice(
            allocationClass: c,
            currentShare: current,
            targetShare: target,
            action: RebalanceAction.none,
            tradeMinor: BigInt.zero,
          ),
        );
        continue;
      }
      // 越带：交易回带边（目标 ± 阈值）。
      final edge = drift.isNegative
          ? target -
                threshold // 低配 → 买入补到下带
          : target + threshold; // 高配 → 卖出减到上带
      final amount = ((current - edge) * total).abs().rounded();
      out.add(
        RebalanceAdvice(
          allocationClass: c,
          currentShare: current,
          targetShare: target,
          action: drift.isNegative ? RebalanceAction.buy : RebalanceAction.sell,
          tradeMinor: amount,
        ),
      );
    }
    return out;
  }
}
