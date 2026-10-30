import '../money/fx_rate.dart';
import '../utils/dates.dart';

/// FIFO 批次成本引擎（口径见 docs/05 §11）。
///
/// 账面卖出成本仍按平均成本法过账（TxBuilders.sell）；
/// 本引擎是对同一份交易的**分析视角**：先买先卖逐批配对，
/// 给出批次明细、逐笔已实现收益与按年汇总。买入金额含费用
/// （费用资本化），卖出为净回款，与分录口径一致。

/// 输入事件（单持仓账户，按时间升序传入）。
sealed class LotEvent {
  const LotEvent(this.date);
  final DateTime date;
}

class LotBuy extends LotEvent {
  const LotBuy(this.quantity, this.totalPaidMinor, DateTime date) : super(date);

  final Rational quantity;
  final BigInt totalPaidMinor;
}

class LotSell extends LotEvent {
  const LotSell(this.quantity, this.netProceedsMinor, DateTime date)
    : super(date);

  final Rational quantity;
  final BigInt netProceedsMinor;
}

/// 内部批次队列项。
class _Lot {
  _Lot(this.acquiredDate, this.qty, this.unitCost, this.cost);

  final DateTime acquiredDate;

  /// 剩余数量。
  Rational qty;

  /// 批次单位成本 = 买入总额 / 数量（有理数精确，不随部分卖出变化）。
  final Rational unitCost;

  /// 剩余成本。
  BigInt cost;
}

/// 未平仓批次。
class OpenLot {
  const OpenLot({
    required this.acquiredDate,
    required this.remainingQuantity,
    required this.unitCost,
    required this.remainingCostMinor,
  });

  final DateTime acquiredDate;
  final Rational remainingQuantity;
  final Rational unitCost;
  final BigInt remainingCostMinor;
}

/// 一笔卖出对一批次的部分配对（已实现）。
class RealizedMatch {
  const RealizedMatch({
    required this.sellDate,
    required this.acquiredDate,
    required this.quantity,
    required this.proceedsMinor,
    required this.costMinor,
  });

  final DateTime sellDate;
  final DateTime acquiredDate;
  final Rational quantity;
  final BigInt proceedsMinor;
  final BigInt costMinor;

  BigInt get pnlMinor => proceedsMinor - costMinor;

  int get daysHeld => calendarDaysBetween(acquiredDate, sellDate);
}

class LotLedgerResult {
  const LotLedgerResult({
    required this.openLots,
    required this.realized,
    required this.shortfallQuantity,
  });

  /// 剩余批次（FIFO 顺序）。
  final List<OpenLot> openLots;

  /// 全部已实现配对（时间升序）。
  final List<RealizedMatch> realized;

  /// 卖出量超过已知批次的部分（历史早于首笔买入的数据缺口，
  /// 以零成本批次处理并在此披露，绝不静默）。
  final Rational shortfallQuantity;

  BigInt get totalRealizedPnlMinor =>
      realized.fold(BigInt.zero, (s, m) => s + m.pnlMinor);

  /// 剩余数量合计。
  Rational get openQuantity =>
      openLots.fold(Rational.zero(), (s, l) => s + l.remainingQuantity);

  /// 剩余成本合计。
  BigInt get openCostMinor =>
      openLots.fold(BigInt.zero, (s, l) => s + l.remainingCostMinor);

  /// 剩余平均单位成本（数量为 0 时为 null）。
  Rational? get averageOpenUnitCost => openQuantity.isZero
      ? null
      : Rational.fromInt(openCostMinor) / openQuantity;

  /// 按年汇总已实现损益。
  Map<int, BigInt> realizedPnlByYear() {
    final out = <int, BigInt>{};
    for (final m in realized) {
      final y = m.sellDate.year;
      out[y] = (out[y] ?? BigInt.zero) + m.pnlMinor;
    }
    return out;
  }
}

class LotEngine {
  const LotEngine._();

  static LotLedgerResult run(List<LotEvent> events) {
    final sorted = [...events]..sort((a, b) => a.date.compareTo(b.date));
    final lots = <_Lot>[];
    final realized = <RealizedMatch>[];
    var shortfall = Rational.zero();

    for (final e in sorted) {
      switch (e) {
        case LotBuy(:var quantity, :var totalPaidMinor, :var date):
          if (quantity.isZero || quantity.isNegative) continue;
          lots.add(
            _Lot(
              date,
              quantity,
              Rational.fromInt(totalPaidMinor) / quantity,
              totalPaidMinor,
            ),
          );
        case LotSell(:var quantity, :var netProceedsMinor, :var date):
          if (quantity.isZero || quantity.isNegative) continue;
          final proceedsPerUnit = Rational.fromInt(netProceedsMinor) / quantity;
          var remaining = quantity;
          var proceedsLeft = netProceedsMinor;
          while (remaining > Rational.zero() && lots.isNotEmpty) {
            final lot = lots.first;
            final exhaustsLot = lot.qty <= remaining;
            final take = exhaustsLot ? lot.qty : remaining;
            var sliceProceeds = (proceedsPerUnit * take).rounded();
            var sliceCost = (lot.unitCost * take).rounded();
            // 两个独立的尾差吸收点：卖量用尽 → Σ配对回款 = 净回款；
            // 批次耗尽 → Σ配对成本 = 批次成本。
            if (take == remaining) sliceProceeds = proceedsLeft;
            if (exhaustsLot) sliceCost = lot.cost;
            realized.add(
              RealizedMatch(
                sellDate: date,
                acquiredDate: lot.acquiredDate,
                quantity: take,
                proceedsMinor: sliceProceeds,
                costMinor: sliceCost,
              ),
            );
            proceedsLeft -= sliceProceeds;
            remaining = remaining - take;
            lot.cost -= sliceCost;
            lot.qty = lot.qty - take;
            if (exhaustsLot) lots.removeAt(0);
          }
          if (remaining > Rational.zero()) {
            // 数据缺口：以零成本批次配对并披露。
            shortfall += remaining;
            realized.add(
              RealizedMatch(
                sellDate: date,
                acquiredDate: date,
                quantity: remaining,
                proceedsMinor: proceedsLeft,
                costMinor: BigInt.zero,
              ),
            );
          }
      }
    }
    return LotLedgerResult(
      openLots: [
        for (final l in lots)
          OpenLot(
            acquiredDate: l.acquiredDate,
            remainingQuantity: l.qty,
            unitCost: l.unitCost,
            remainingCostMinor: l.cost,
          ),
      ],
      realized: realized,
      shortfallQuantity: shortfall,
    );
  }
}
