import 'package:equatable/equatable.dart';

import '../../shared/domain/failure.dart';
import '../../shared/domain/value_objects.dart';
import '../domain/subscription.dart';

final class BillingSummary extends Equatable {
  const BillingSummary({
    required this.active,
    required this.plan,
    required this.subscriptions,
    required this.payments,
    this.plans = const [],
  });

  final Subscription? active;

  /// Plan matching the active subscription (code + billing cycle), if found.
  final SubscriptionPlan? plan;
  final List<Subscription> subscriptions;
  final List<SubscriptionPayment> payments;

  /// Catalog of plans, to name every subscription of the history.
  final List<SubscriptionPlan> plans;

  /// "Standard Lab" instead of the plan code, when the plan is in the catalog.
  String planNameOf(Subscription subscription) =>
      _planOf(plans, subscription)?.name ??
      (subscription == active ? plan?.name : null) ??
      subscription.planCode;

  @override
  List<Object?> get props => [active, plan, subscriptions, payments, plans];
}

/// Read-only billing overview (no checkout, plan change or cancellation).
class GetBillingSummary {
  const GetBillingSummary(this._repository);

  final SubscriptionRepository _repository;

  Future<BillingSummary> call(LaboratoryId laboratoryId) async {
    final subscriptions = [...await _repository.getSubscriptions(laboratoryId)]
      ..sort((a, b) {
        final left = a.currentPeriodStart;
        final right = b.currentPeriodStart;
        if (left == null && right == null) return b.id.compareTo(a.id);
        if (left == null) return 1;
        if (right == null) return -1;
        return right.compareTo(left);
      });
    final active = subscriptions.where((s) => s.isActive).firstOrNull;
    final current = active ?? subscriptions.firstOrNull;

    var plans = const <SubscriptionPlan>[];
    if (subscriptions.isNotEmpty) {
      try {
        plans = await _repository.getPlans();
      } on UnauthorizedFailure {
        rethrow;
      } on Failure {
        plans = const [];
      }
    }
    final plan = active == null ? null : _planOf(plans, active);

    final payments = current == null
        ? const <SubscriptionPayment>[]
        : await _repository.getPayments(current.id);
    final sortedPayments = [...payments]..sort((a, b) {
      final left = a.paidAt;
      final right = b.paidAt;
      if (left == null && right == null) return b.id.compareTo(a.id);
      if (left == null) return 1;
      if (right == null) return -1;
      return right.compareTo(left);
    });

    return BillingSummary(
      active: active,
      plan: plan,
      subscriptions: subscriptions,
      payments: sortedPayments,
      plans: plans,
    );
  }
}

SubscriptionPlan? _planOf(List<SubscriptionPlan> plans, Subscription subscription) => plans
    .where((p) => p.code == subscription.planCode && p.billingCycle == subscription.billingCycle)
    .firstOrNull;
