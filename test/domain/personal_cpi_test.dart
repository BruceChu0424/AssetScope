import 'package:flutter_test/flutter_test.dart';

import 'package:assetscope/domain/analytics/personal_cpi.dart';

/// 个人消费指数口径测试（docs/11 §8）。
/// 数据协议：compute 取尾部 12 个月对半分——前 6 个月为基期、后 6 个月为
/// 近期；首末月间隔 11 个月，年化 = 指数^(12/11) − 1。
void main() {
  List<(String, Map<String, BigInt>)> months(
    Map<String, BigInt> base,
    Map<String, BigInt> recent, {
    int n = 12,
  }) {
    final half = n ~/ 2;
    return [
      for (var i = 0; i < n; i++)
        (
          '${2024 + i ~/ 12}-${(i % 12 + 1).toString().padLeft(2, '0')}',
          i < half ? base : recent,
        ),
    ];
  }

  test('全篮子同涨 10% → 年化 = 1.1^(12/11) − 1 ≈ 10.96%', () {
    final r = PersonalCpi.compute(months(
      {'dining': BigInt.from(1000), 'transport': BigInt.from(500)},
      {'dining': BigInt.from(1100), 'transport': BigInt.from(550)},
    ));
    expect(r, isNotNull);
    expect(r!.basketCoverage, 1.0);
    expect(r.annualRate, closeTo(0.1096, 0.002));
    expect(r.reliable, isTrue);
    expect(r.gapMonths, 11);
  });

  test('篮子加权：餐饮涨 100%（占 2/3）、交通持平（占 1/3）→ 指数 5/3', () {
    final r = PersonalCpi.compute(months(
      {'dining': BigInt.from(2000), 'transport': BigInt.from(1000)},
      {'dining': BigInt.from(4000), 'transport': BigInt.from(1000)},
    ));
    // 年化 = (5/3)^(12/11) − 1 ≈ 0.746。
    expect(r!.annualRate, closeTo(0.746, 0.005));
    expect(r.contributions.first.categoryId, 'dining');
    expect(r.contributions.first.ratio, closeTo(2.0, 0.001));
  });

  test('消费习惯消失的分类剔除出篮子，剩余权重归一', () {
    final r = PersonalCpi.compute(months(
      {'dining': BigInt.from(1000), 'coffee': BigInt.from(1000)},
      {'dining': BigInt.from(1200), 'coffee': BigInt.zero},
    ));
    // coffee 覆盖率 0.5 剔除后 dining 独扛篮子：指数 = 1.2。
    expect(r!.basketCoverage, closeTo(0.5, 0.001));
    expect(r.reliable, isFalse, reason: '覆盖 <0.6 不足以解读');
    expect(r.annualRate, closeTo(0.220, 0.005));
  });

  test('基期不存在的新分类不影响指数', () {
    final r = PersonalCpi.compute(months(
      {'dining': BigInt.from(1000)},
      {'dining': BigInt.from(1000), 'newHobby': BigInt.from(9999)},
    ));
    expect(r!.annualRate, closeTo(0.0, 0.001));
    expect(r.basketCoverage, 1.0);
  });

  test('样本不足返回 null', () {
    expect(
        PersonalCpi.compute(months(
          {'a': BigInt.from(1)},
          {'a': BigInt.from(1)},
          n: 5,
        )),
        isNull);
    expect(PersonalCpi.compute(const []), isNull);
  });

  test('基期全零支出返回 null', () {
    final r = PersonalCpi.compute(
        months({'a': BigInt.zero}, {'a': BigInt.from(100)}));
    expect(r, isNull);
  });

  test('生活成本下降时年化为负', () {
    final r = PersonalCpi.compute(months(
      {'dining': BigInt.from(2000)},
      {'dining': BigInt.from(1500)},
    ));
    // 指数 0.75 → 0.75^(12/11) − 1 ≈ −0.269。
    expect(r!.annualRate, lessThan(0));
    expect(r.annualRate, closeTo(-0.269, 0.005));
  });
}
