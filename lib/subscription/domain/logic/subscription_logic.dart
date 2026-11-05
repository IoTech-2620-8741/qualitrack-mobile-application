import '../entities/subscription.dart';
import '../entities/subscription_payment.dart';
import '../entities/subscription_plan.dart';

/// Business rules of Payments & Subscriptions. Pure Dart: the facade applies
/// them on top of the repository.
mixin SubscriptionLogic {
  /// Newest period first; subscriptions without a start go last, newest id first.
  List<Subscription> sortNewestFirst(List<Subscription> subscriptions) =>
      _newestFirst(subscriptions, (s) => s.currentPeriodStart, (s) => s.id);

  /// Latest payment first; payments without a date go last, newest id first.
  List<SubscriptionPayment> sortPaymentsNewestFirst(List<SubscriptionPayment> payments) =>
      _newestFirst(payments, (p) => p.paidAt, (p) => p.id);

  /// The active subscription, if any.
  Subscription? activeOf(List<Subscription> subscriptions) => subscriptions.where((s) => s.isActive).firstOrNull;

  /// Plan of a subscription (code + billing cycle) in the catalog.
  SubscriptionPlan? planOf(List<SubscriptionPlan> plans, Subscription subscription) =>
      plans.where((p) => p.matches(subscription)).firstOrNull;

  List<T> _newestFirst<T>(List<T> items, DateTime? Function(T) date, int Function(T) id) => [...items]
    ..sort((a, b) {
      final left = date(a);
      final right = date(b);
      if (left == null && right == null) return id(b).compareTo(id(a));
      if (left == null) return 1;
      if (right == null) return -1;
      return right.compareTo(left);
    });
}
