import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/budget/budget.dart';
import '../../domain/debt/debt_contract.dart';
import '../../domain/money/fx_rate.dart';
import '../../domain/planning/recurrence.dart';
import '../../domain/utils/dates.dart';
import '../app_database.dart';

/// 预算/计划/目标/债务合同仓储。
class PlanningRepo {
  PlanningRepo(this._db);

  final AppDatabase _db;

  // ---------- 预算 ----------

  Future<List<Budget>> budgets() async {
    final rows = await _db.select(_db.budgets).get();
    return [
      for (final r in rows)
        Budget(
          id: r.id,
          name: r.name,
          scope: BudgetScope.values.firstWhere((s) => s.name == r.scope),
          limitMinor: r.limitMinor,
          currencyCode: r.currencyCode,
          startMonthKey: r.startMonth,
          categoryId: r.categoryId,
          endMonthKey: r.endMonth,
          rollover:
              RolloverPolicy.values.firstWhere((p) => p.name == r.rollover),
          rolloverCapMinor: r.rolloverCapMinor,
          active: r.active,
        )
    ];
  }

  Future<void> saveBudget(Budget b) =>
      _db.into(_db.budgets).insertOnConflictUpdate(
          BudgetsCompanion.insert(
              id: b.id,
              name: b.name,
              scope: b.scope.name,
              limitMinor: b.limitMinor,
              currencyCode: b.currencyCode,
              startMonth: b.startMonthKey,
              endMonth: Value(b.endMonthKey),
              categoryId: Value(b.categoryId),
              rollover: Value(b.rollover.name),
              rolloverCapMinor: Value(b.rolloverCapMinor),
              active: Value(b.active)));

  Future<void> deleteBudget(String id) =>
      (_db.delete(_db.budgets)..where((b) => b.id.equals(id))).go();

  // ---------- 计划事件 ----------

  Future<List<ScheduledEvent>> scheduledEvents() async {
    final rows = await _db.select(_db.scheduledEvents).get();
    return [
      for (final r in rows)
        ScheduledEvent(
          id: r.id,
          name: r.name,
          direction: EventDirection.values
              .firstWhere((d) => d.name == r.direction),
          currencyCode: r.currencyCode,
          cadence: Cadence.values.firstWhere((c) => c.name == r.cadence),
          anchorDate: r.anchorDate,
          amountMinor: r.amountMinor,
          amountLowMinor: r.amountLowMinor,
          amountHighMinor: r.amountHighMinor,
          intervalValue: r.intervalValue,
          monthEndPolicy: MonthEndPolicy.values
              .firstWhere((p) => p.name == r.monthEndPolicy),
          endDate: r.endDate,
          paymentAccountId: r.paymentAccountId,
          categoryId: r.categoryId,
          autoPost: r.autoPost,
          notes: r.notes,
          status: PlanStatus.values.firstWhere((s) => s.name == r.status),
          skippedMonthKeys: {
            for (final m in (jsonDecode(r.skippedMonthsJson) as List))
              m as String
          },
          amountOverrides: {
            for (final e in (jsonDecode(r.amountOverridesJson)
                as Map<String, dynamic>).entries)
              e.key: BigInt.parse(e.value as String)
          },
        )
    ];
  }

  Future<void> saveScheduledEvent(ScheduledEvent e) =>
      _db.into(_db.scheduledEvents).insertOnConflictUpdate(
          ScheduledEventsCompanion.insert(
              id: e.id,
              name: e.name,
              direction: e.direction.name,
              currencyCode: e.currencyCode,
              cadence: e.cadence.name,
              anchorDate: e.anchorDate,
              amountMinor: Value(e.amountMinor),
              amountLowMinor: Value(e.amountLowMinor),
              amountHighMinor: Value(e.amountHighMinor),
              intervalValue: Value(e.intervalValue),
              monthEndPolicy: Value(e.monthEndPolicy.name),
              endDate: Value(e.endDate),
              paymentAccountId: Value(e.paymentAccountId),
              categoryId: Value(e.categoryId),
              autoPost: Value(e.autoPost),
              notes: Value(e.notes),
              status: Value(e.status.name),
              skippedMonthsJson:
                  Value(jsonEncode(e.skippedMonthKeys.toList())),
              amountOverridesJson: Value(jsonEncode({
                for (final e2 in e.amountOverrides.entries)
                  e2.key: e2.value.toString()
              }))));

  Future<void> deleteScheduledEvent(String id) =>
      (_db.delete(_db.scheduledEvents)..where((s) => s.id.equals(id))).go();

  // ---------- 目标 ----------

  Future<List<SavingsGoal>> goals() async {
    final rows = await _db.select(_db.goals).get();
    return [
      for (final r in rows)
        SavingsGoal(
          id: r.id,
          name: r.name,
          targetAmountMinor: r.targetMinor,
          targetDate: r.targetDate,
          priority: r.priority,
          reservedAmountMinor: r.reservedMinor,
          fundingAccountIds: [
            for (final a in (jsonDecode(r.fundingAccountIdsJson) as List))
              a as String
          ],
          notes: r.notes,
          status: GoalStatus.values.firstWhere((s) => s.name == r.status),
        )
    ];
  }

  Future<void> saveGoal(SavingsGoal g) =>
      _db.into(_db.goals).insertOnConflictUpdate(
          GoalsCompanion.insert(
              id: g.id,
              name: g.name,
              targetMinor: g.targetAmountMinor,
              targetDate: g.targetDate,
              priority: Value(g.priority),
              reservedMinor: Value(g.reservedAmountMinor),
              fundingAccountIdsJson:
                  Value(jsonEncode(g.fundingAccountIds)),
              notes: Value(g.notes),
              status: Value(g.status.name)));

  Future<void> deleteGoal(String id) =>
      (_db.delete(_db.goals)..where((g) => g.id.equals(id))).go();

  // ---------- 债务合同 ----------

  Future<Map<String, DebtContract>> debtContracts() async {
    final rows = await _db.select(_db.debtContracts).get();
    return {
      for (final r in rows)
        r.liabilityAccountId: DebtContract(
          liabilityAccountId: r.liabilityAccountId,
          principalOriginalMinor: r.principalOriginalMinor,
          aprPercent: parseRationalText(r.aprPercent),
          method: RepaymentMethod.values.firstWhere((m) => m.name == r.method),
          termMonths: r.termMonths,
          startDate: r.startDate,
          firstPaymentDate: r.firstPaymentDate,
          repaymentDay: r.repaymentDay,
          monthlyFeeMinor: r.monthlyFeeMinor,
          basis: DayCountBasis.values.firstWhere((b) => b.name == r.basis),
          prepayFeePercent:
              r.prepayFeePercent == null ? null : parseRationalText(r.prepayFeePercent!),
          notes: r.notes,
        )
    };
  }

  Future<void> saveDebtContract(DebtContract c) =>
      _db.into(_db.debtContracts).insertOnConflictUpdate(
          DebtContractsCompanion.insert(
              liabilityAccountId: c.liabilityAccountId,
              principalOriginalMinor: c.principalOriginalMinor,
              aprPercent: c.aprPercent.toString(),
              method: c.method.name,
              termMonths: c.termMonths,
              startDate: c.startDate,
              firstPaymentDate: Value(c.firstPaymentDate),
              repaymentDay: Value(c.repaymentDay),
              monthlyFeeMinor: Value(c.monthlyFeeMinor),
              basis: Value(c.basis.name),
              prepayFeePercent: Value(c.prepayFeePercent?.toString()),
              notes: Value(c.notes)));
}

/// Rational 文本互转：统一存 "n/d"（Rational.toString）。
Rational parseRationalText(String s) {
  final i = s.indexOf('/');
  if (i < 0) return Rational.parseDecimal(s);
  return Rational.fromInt(BigInt.parse(s.substring(0, i))) /
      Rational.fromInt(BigInt.parse(s.substring(i + 1)));
}
