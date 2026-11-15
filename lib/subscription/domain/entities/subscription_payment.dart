import 'package:equatable/equatable.dart';

/// `SubscriptionPaymentResource`.
class SubscriptionPayment extends Equatable {
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
