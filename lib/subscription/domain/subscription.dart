import 'package:equatable/equatable.dart';

import '../../shared/domain/value_objects.dart';

/// `SubscriptionResource`. Stripe identifiers are intentionally not mapped:
/// payment administration stays in Web.
final class Subscription extends Equatable {
  const Subscription({
    required this.id,
    required this.laboratoryId,
    required this.planCode,
    required this.billingCycle,
    required this.status,
    this.currentPeriodStart,
    this.currentPeriodEnd,
    this.cancelledAt,
  });

  final int id;
  final int laboratoryId;
  final String planCode;
  final String billingCycle;
  final String status;
  final DateTime? currentPeriodStart;
  final DateTime? currentPeriodEnd;
  final DateTime? cancelledAt;

  bool get isActive => status == 'ACTIVE';

  @override
  List<Object?> get props => [
    id,
    laboratoryId,
    planCode,
    billingCycle,
    status,
    currentPeriodStart,
    currentPeriodEnd,
    cancelledAt,
  ];
}

/// `SubscriptionPaymentResource`.
final class SubscriptionPayment extends Equatable {
  const SubscriptionPayment({
    required this.id,
    required this.subscriptionId,
    required this.status,
    this.provider,
    this.amount,
    this.currency,
    this.paidAt,
  });

  final int id;
  final int subscriptionId;
  final String? provider;
  final double? amount;
  final String? currency;
  final String status;
  final DateTime? paidAt;

  @override
  List<Object?> get props => [id, subscriptionId, provider, amount, currency, status, paidAt];
}

/// `SubscriptionPlanResource` (used only to show the current plan limits).
final class SubscriptionPlan extends Equatable {
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

  @override
  List<Object?> get props => [code, name, billingCycle, amount, currency, maxUsers, maxEquipment, description];
}

abstract interface class SubscriptionRepository {
  /// Null when the laboratory has no ACTIVE subscription (HTTP 404).
  Future<Subscription?> getActive(LaboratoryId laboratoryId);
  Future<List<Subscription>> getBillingSummary(LaboratoryId laboratoryId);
  Future<List<SubscriptionPayment>> getPayments(int subscriptionId);
  Future<List<SubscriptionPlan>> getPlans();
}
