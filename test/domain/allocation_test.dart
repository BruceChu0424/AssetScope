import 'package:flutter_test/flutter_test.dart';
import 'package:assetscope/domain/invest/allocation.dart';
import 'package:assetscope/domain/ledger/account.dart';
import 'package:assetscope/domain/money/fx_rate.dart';

void main() {
  test('子类型 → 配置桶映射', () {
    expect(AllocationClass.fromSubtype(AssetSubtype.stock),
        AllocationClass.equity);
    expect(AllocationClass.fromSubtype(AssetSubtype.fund), AllocationClass.fund);
    expect(AllocationClass.fromSubtype(AssetSubtype.bond), AllocationClass.bond);
    expect(AllocationClass.fromSubtype(AssetSubtype.cash), AllocationClass.cash);
    expect(AllocationClass.fromSubtype(AssetSubtype.moneyFund),
        AllocationClass.cash);
    expect(AllocationClass.fromSubtype(AssetSubtype.brokerCash),
        AllocationClass.cash);
    expect(AllocationClass.fromSubtype(AssetSubtype.timeDeposit),
        AllocationClass.fixedIncome);
    expect(AllocationClass.fromSubtype(AssetSubtype.wealthMgmt),
        AllocationClass.fixedIncome);
    expect(AllocationClass.fromSubtype(AssetSubtype.preciousMetal),
        AllocationClass.alternatives);
    expect(AllocationClass.fromSubtype(AssetSubtype.crypto),
        AllocationClass.alternatives);
    expect(AllocationClass.fromSubtype(AssetSubtype.realEstate),
        AllocationClass.realAssets);
    expect(AllocationClass.fromSubtype(AssetSubtype.vehicle),
        AllocationClass.realAssets);
    expect(AllocationClass.fromSubtype(AssetSubtype.pension),
        AllocationClass.longTerm);
    expect(AllocationClass.fromSubtype(AssetSubtype.providentFund),
        AllocationClass.longTerm);
    expect(AllocationClass.fromSubtype(AssetSubtype.receivable),
        AllocationClass.other);
    expect(AllocationClass.fromSubtype(AssetSubtype.depositPaid),
        AllocationClass.other);
  });

  test('目标配置 JSON 往返与校验', () {
    const t = TargetAllocation({
      AllocationClass.equity: 40,
      AllocationClass.bond: 30,
      AllocationClass.cash: 20,
    });
    final json = t.toJson();
    expect(json, {'equity': 40, 'bond': 30, 'cash': 20});
    final back = TargetAllocation.parseJson(json);
    expect(back[AllocationClass.equity], 40);
    expect(back[AllocationClass.bond], 30);
    expect(back[AllocationClass.cash], 20);
    expect(back[AllocationClass.fund], isNull);
    expect(back.isValid, isTrue);

    const over = TargetAllocation({
      AllocationClass.equity: 60,
      AllocationClass.bond: 60,
    });
    expect(over.isValid, isFalse); // 合计 120%

    const negative = TargetAllocation({AllocationClass.equity: -5});
    expect(negative.isValid, isFalse);

    // 未知键忽略、double 取整。
    final parsed = TargetAllocation.parseJson({
      'equity': 33.0,
      'nope': 10,
    });
    expect(parsed[AllocationClass.equity], 33);
    expect(parsed.totalPercent, 33);
  });

  test('5/25 带宽：高配越带 → 卖回上带', () {
    // 目标 40%，阈值 = max(5, 40×25%) = 10pp；当前 55% → 卖到 50%。
    final total = BigInt.from(1000000);
    final advice = RebalanceAdvisor.advise(
      valuesBaseMinor: {
        AllocationClass.equity: BigInt.from(550000),
        AllocationClass.cash: BigInt.from(450000),
      },
      totalBaseMinor: total,
      targets: const TargetAllocation({AllocationClass.equity: 40}),
    );
    final eq = advice.firstWhere((a) => a.allocationClass == AllocationClass.equity);
    expect(eq.action, RebalanceAction.sell);
    expect(eq.currentShare, Rational.fromFrac(BigInt.from(55), BigInt.from(100)));
    expect(eq.tradeMinor, BigInt.from(50000)); // (55% − 50%) × 100 万
  });

  test('5/25 带宽：小目标类用绝对 5pp 下限', () {
    // 目标 3%，阈值 = max(5, 0.75) = 5pp。
    // 当前 7.5% → 偏离 4.5pp ≤ 5 → 不动。
    var advice = RebalanceAdvisor.advise(
      valuesBaseMinor: {AllocationClass.alternatives: BigInt.from(75000)},
      totalBaseMinor: BigInt.from(1000000),
      targets: const TargetAllocation({AllocationClass.alternatives: 3}),
    );
    expect(advice.single.action, RebalanceAction.none);
    expect(advice.single.tradeMinor, BigInt.zero);

    // 当前 8.2% → 偏离 5.2pp > 5 → 卖到 8%（带边），金额 = 0.2% × 100 万。
    advice = RebalanceAdvisor.advise(
      valuesBaseMinor: {AllocationClass.alternatives: BigInt.from(82000)},
      totalBaseMinor: BigInt.from(1000000),
      targets: const TargetAllocation({AllocationClass.alternatives: 3}),
    );
    expect(advice.single.action, RebalanceAction.sell);
    expect(advice.single.tradeMinor, BigInt.from(2000));
  });

  test('低配越带 → 买到下带；未设目标的类不产生建议', () {
    // 目标 20%，阈值 5pp；当前 12% → 买到 15%，金额 = 3% × 100 万。
    final advice = RebalanceAdvisor.advise(
      valuesBaseMinor: {
        AllocationClass.bond: BigInt.from(120000),
        AllocationClass.cash: BigInt.from(880000), // 未设目标
      },
      totalBaseMinor: BigInt.from(1000000),
      targets: const TargetAllocation({AllocationClass.bond: 20}),
    );
    expect(advice.length, 1); // cash 无目标 → 不在建议中
    final bond = advice.single;
    expect(bond.action, RebalanceAction.buy);
    expect(bond.tradeMinor, BigInt.from(30000));
  });

  test('总资产为 0 → 无建议；带内 → none', () {
    expect(
        RebalanceAdvisor.advise(
            valuesBaseMinor: const {},
            totalBaseMinor: BigInt.zero,
            targets: const TargetAllocation({AllocationClass.equity: 40})),
        isEmpty);
    final advice = RebalanceAdvisor.advise(
      valuesBaseMinor: {AllocationClass.equity: BigInt.from(430000)},
      totalBaseMinor: BigInt.from(1000000),
      targets: const TargetAllocation({AllocationClass.equity: 40}),
    );
    expect(advice.single.action, RebalanceAction.none); // 偏离 3pp ≤ 10pp
  });
}
