import 'package:equatable/equatable.dart';

import 'subscription.dart';

/// `SubscriptionPlanResource` (used only to show the current plan limits).
class SubscriptionPlan extends Equatable {
  const SubscriptionPlan({
    required this.code,
    required this.name,
    required this.billingCycle,
    this.amount,
    this.currency,
    this.maxUsers,
    this.maxEquipment,
    this.description,
  });

  final String code;
  final String name;
  final String billingCycle;
  final double? amount;
  final String? currency;
  final int? maxUsers;
  final int? maxEquipment;
  final String? description;

  /// Whether this plan is the one a subscription is on (code and billing cycle).
  bool matches(Subscription subscription) =>
      code == subscription.planCode && billingCycle == subscription.billingCycle;

  @override
  List<Object?> get props => [code, name, billingCycle, amount, currency, maxUsers, maxEquipment, description];
}
