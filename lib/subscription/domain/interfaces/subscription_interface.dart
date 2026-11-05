import '../../../common/domain/value_objects.dart';
import '../entities/subscription.dart';
import '../entities/subscription_payment.dart';
import '../entities/subscription_plan.dart';

/// Contract of the subscription repository: what can be read about the
/// subscriptions of a laboratory, not how. Implemented by the infrastructure
/// layer.
abstract interface class SubscriptionInterface {
  Future<List<Subscription>> getSubscriptions(LaboratoryId laboratoryId);
  Future<List<SubscriptionPayment>> getPayments(int subscriptionId);
  Future<List<SubscriptionPlan>> getPlans();
}
