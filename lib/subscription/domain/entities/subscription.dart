import 'package:equatable/equatable.dart';

/// `SubscriptionResource`. Stripe identifiers are intentionally not mapped:
/// payment administration stays in Web.
class Subscription extends Equatable {
  const Subscription({
    required this.id,
    required this.laboratoryId,
    required this.planCode,
    required this.billingCycle,
    required this.status,
    this.currentPeriodStart,
    this.currentPeriodEnd,
    this.cancelledAt,
    this.cancelAtPeriodEnd = false,
  });

  final int id;
  final int laboratoryId;
  final String planCode;
  final String billingCycle;
  final String status;
  final DateTime? currentPeriodStart;
  final DateTime? currentPeriodEnd;
  final DateTime? cancelledAt;

  /// The renewal was cancelled: access continues until [currentPeriodEnd].
  final bool cancelAtPeriodEnd;

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
    cancelAtPeriodEnd,
  ];
}
