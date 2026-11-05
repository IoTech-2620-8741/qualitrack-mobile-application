import 'package:equatable/equatable.dart';

import 'subscription.dart';
import 'subscription_payment.dart';
import 'subscription_plan.dart';

class BillingSummary extends Equatable {
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
      plans.where((p) => p.matches(subscription)).firstOrNull?.name ??
      (subscription == active ? plan?.name : null) ??
      subscription.planCode;

  @override
  List<Object?> get props => [active, plan, subscriptions, payments, plans];
}
