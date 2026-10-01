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
  });

  final Subscription? active;

  /// Plan matching the active subscription (code + billing cycle), if found.
  final SubscriptionPlan? plan;
  final List<Subscription> subscriptions;
  final List<SubscriptionPayment> payments;

  @override
  List<Object?> get props => [active, plan, subscriptions, payments];
}

/// Read-only billing overview (no checkout, plan change or cancellation).
class GetBillingSummary {
  const GetBillingSummary(this._repository);

  final SubscriptionRepository _repository;

  Future<BillingSummary> call(LaboratoryId laboratoryId) async {
    final active = await _repository.getActive(laboratoryId);
    final subscriptions = await _repository.getBillingSummary(laboratoryId);
    final current = active ?? (subscriptions.isEmpty ? null : subscriptions.first);

    SubscriptionPlan? plan;
    if (active != null) {
      try {
        final plans = await _repository.getPlans();
        plan = plans
            .where((p) => p.code == active.planCode && p.billingCycle == active.billingCycle)
            .firstOrNull;
      } on UnauthorizedFailure {
        rethrow;
      } on Failure {
        plan = null;
      }
    }

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
    );
  }
}
