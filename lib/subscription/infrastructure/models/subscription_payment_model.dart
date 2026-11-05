import '../../../common/infrastructure/http/json_utils.dart';
import '../../domain/entities/subscription_payment.dart';

/// `SubscriptionPaymentResource`.
class SubscriptionPaymentModel extends SubscriptionPayment {
  const SubscriptionPaymentModel({
    required super.id,
    required super.subscriptionId,
    required super.status,
    super.provider,
    super.amount,
    super.currency,
    super.paidAt,
  });

  factory SubscriptionPaymentModel.fromJson(Map<String, dynamic> json) => SubscriptionPaymentModel(
    id: Json.requireInt(json, 'id'),
    subscriptionId: Json.requireInt(json, 'subscriptionId'),
    provider: Json.optString(json, 'provider'),
    amount: Json.optDouble(json, 'amount'),
    currency: Json.optString(json, 'currency'),
    status: Json.optString(json, 'status') ?? 'UNKNOWN',
    paidAt: Json.optDateTime(json, 'paidAt'),
  );
}
