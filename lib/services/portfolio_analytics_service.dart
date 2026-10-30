import 'dart:convert';

import '../data/repositories/ledger_repo.dart';
import '../data/repositories/meta_repo.dart';
import '../domain/invest/allocation.dart';
import '../domain/invest/lots.dart';
import '../domain/invest/returns.dart';
import '../domain/invest/risk_metrics.dart';
import '../domain/ledger/account.dart';
import '../domain/ledger/transaction.dart';
import '../domain/money/fx_rate.dart';
import 'portfolio_service.dart';
import 'stats_service.dart';

/// 风险报告结果：指标 + 参与计算的估值点数（披露用）。
class RiskReportResult {
  const RiskReportResult({required this.report, required this.valuationPoints});

  final RiskReport? report;
  final int valuationPoints;
}

/// 资产配置报告（资产端；负债不参与配置）。
class AllocationReport {
  const AllocationReport({
    required this.baseCurrencyCode,
    required this.slices,
    required this.totalAssetsMinor,
    required this.missingValuations,
    required this.targets,
    required this.advice,
  });

  final String baseCurrencyCode;

  /// 按价值降序。
  final List<AllocationSlice> slices;
  final BigInt totalAssetsMinor;

  /// 估值缺失（价值按 0 计）的账户数——解读配置时须知。
  final int missingValuations;

  final TargetAllocation targets;
  final List<RebalanceAdvice> advice;

  bool get hasAdvice => advice.any((a) => a.needsAction);
}

/// 投资组合分析服务：风险指标（docs/05 §9）、资产配置与再平衡
/// （§10）、FIFO 批次成本明细（§11）。收益计算（XIRR/TWR）在
/// [PortfolioService]，本服务只做衍生分析，两者共用其估值点/现金流。
class PortfolioAnalyticsService {
  PortfolioAnalyticsService(
    this._ledger,
    this._meta,
    this._stats,
    this._portfolio,
  );

  final LedgerRepo _ledger;
  final MetaRepo _meta;
  final StatsService _stats;
  final PortfolioService _portfolio;

  static const riskFreeRateKey = 'riskFreeRatePercent';
  static const allocationTargetsKey = 'allocationTargets';
  static const defaultRiskFreeRatePercent = 2.0;

  // ---------- 风险指标 ----------

  Future<double> riskFreeRatePercent() async =>
      await _meta.settingDouble(riskFreeRateKey) ?? defaultRiskFreeRatePercent;

  Future<void> setRiskFreeRatePercent(double v) =>
      _meta.setSetting(riskFreeRateKey, v);

  /// 近 36 个月月末估值点 → TWR 子期间收益 → 波动率/回撤/Sharpe 等。
  /// 估值点不足（< 2 个期间）时 report 为 null。
  Future<RiskReportResult> riskReport() async {
    final points = await _portfolio.twrValuationPoints(months: 36);
    final flows = await _portfolio.externalFlows();
    final subs = TwrCalculator.subPeriodReturns(
      valuations: points,
      flows: [for (final e in flows.byDay.entries) TwrFlow(e.key, e.value)],
    );
    if (subs == null) {
      return RiskReportResult(report: null, valuationPoints: points.length);
    }
    final rf = await riskFreeRatePercent();
    return RiskReportResult(
      report: RiskMetrics.compute(subs, riskFreeAnnual: rf / 100),
      valuationPoints: points.length,
    );
  }

  // ---------- 资产配置与再平衡 ----------

  Future<TargetAllocation> targetAllocation() async {
    final raw = await _meta.settingString(allocationTargetsKey);
    if (raw == null) return TargetAllocation.empty;
    try {
      final json = jsonDecode(raw);
      if (json is Map<String, Object?>) return TargetAllocation.parseJson(json);
    } on FormatException {
      // 损坏的设置按未配置处理
    }
    return TargetAllocation.empty;
  }

  Future<void> setTargetAllocation(TargetAllocation t) =>
      _meta.setSetting(allocationTargetsKey, jsonEncode(t.toJson()));

  /// 当前配置（净资产构成的资产端按九类桶聚合）+ 再平衡建议。
  Future<AllocationReport> allocationReport() async {
    final nw = await _stats.netWorthAt(DateTime.now());
    final base = nw.baseCurrencyCode;
    final byClass = <AllocationClass, BigInt>{};
    var total = BigInt.zero;
    var missing = 0;
    for (final i in nw.items) {
      if (i.account.type != AccountType.asset) continue;
      if (i.valuationMissing) missing++;
      final c = i.account.assetSubtype == null
          ? AllocationClass.other
          : AllocationClass.fromSubtype(i.account.assetSubtype!);
      byClass[c] = (byClass[c] ?? BigInt.zero) + i.valueBaseMinor;
      total += i.valueBaseMinor;
    }
    final slices = <AllocationSlice>[];
    if (total > BigInt.zero) {
      for (final e in byClass.entries) {
        if (e.value == BigInt.zero) continue;
        slices.add(
          AllocationSlice(
            allocationClass: e.key,
            valueBaseMinor: e.value,
            share: e.value > BigInt.zero
                ? Rational.fromInt(e.value) / Rational.fromInt(total)
                : Rational.zero(),
          ),
        );
      }
      slices.sort((a, b) => b.valueBaseMinor.compareTo(a.valueBaseMinor));
    }
    final targets = await targetAllocation();
    final advice = RebalanceAdvisor.advise(
      valuesBaseMinor: byClass,
      totalBaseMinor: total,
      targets: targets,
    );
    return AllocationReport(
      baseCurrencyCode: base,
      slices: slices,
      totalAssetsMinor: total,
      missingValuations: missing,
      targets: targets,
      advice: advice,
    );
  }

  // ---------- FIFO 批次成本 ----------

  /// 单持仓账户的批次明细（账户计价币种，分析视角；账面仍为平均成本法）。
  Future<LotLedgerResult?> lotDetail(String holdingAccountId) async {
    final txs = await _ledger.list(
      from: DateTime(2000),
      to: DateTime.now().add(const Duration(days: 1)),
    );
    final events = <LotEvent>[];
    for (final tx in txs) {
      if (tx.status == TxStatus.voided) continue;
      if (tx.kind != TxKind.buy && tx.kind != TxKind.sell) continue;
      Rational? qty;
      BigInt? amount;
      for (final p in tx.postings) {
        if (p.accountId == holdingAccountId && p.isQuantity) {
          qty = p.quantity;
        } else if (amount == null &&
            p.amountMinor != null &&
            p.amountMinor! > BigInt.zero) {
          // 取第一条正金额分录：buy = 成本镜像入账（总付），
          // sell = 现金回款（构造器中现金分录在最前，
          // 亏损时的已实现损益分录虽为正但排其后，不会误取）。
          amount = p.amountMinor;
        }
      }
      if (qty == null || amount == null) continue;
      if (tx.kind == TxKind.buy) {
        events.add(LotBuy(qty, amount, tx.date));
      } else {
        events.add(LotSell(-qty, amount, tx.date));
      }
    }
    if (events.isEmpty) return null;
    return LotEngine.run(events);
  }
}
