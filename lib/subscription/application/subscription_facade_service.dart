import '../../common/domain/failure.dart';
import '../../common/domain/value_objects.dart';
import '../domain/entities/billing_summary.dart';
import '../domain/entities/subscription_payment.dart';
import '../domain/entities/subscription_plan.dart';
import '../domain/interfaces/subscription_interface.dart';
import '../domain/logic/subscription_logic.dart';

/// Use cases of Payments & Subscriptions exposed to the presentation layer. It
/// only orchestrates: the rules live in [SubscriptionLogic] and the data access
/// behind [SubscriptionInterface].
class SubscriptionFacadeService with SubscriptionLogic {
  const SubscriptionFacadeService({required SubscriptionInterface repository}) : _repository = repository;

  final SubscriptionInterface _repository;

  /// Read-only billing overview (no checkout, plan change or cancellation).
  Future<BillingSummary> getBillingSummary(LaboratoryId laboratoryId) async {
    final subscriptions = sortNewestFirst(await _repository.getSubscriptions(laboratoryId));
    final active = activeOf(subscriptions);
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

    final payments = current == null
        ? const <SubscriptionPayment>[]
        : await _repository.getPayments(current.id);

    return BillingSummary(
      active: active,
      plan: active == null ? null : planOf(plans, active),
      subscriptions: subscriptions,
      payments: sortPaymentsNewestFirst(payments),
      plans: plans,
    );
  }
}
