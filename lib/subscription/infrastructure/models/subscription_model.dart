import '../../../common/infrastructure/http/json_utils.dart';
import '../../domain/entities/subscription.dart';

/// `SubscriptionResource`.
class SubscriptionModel extends Subscription {
  const SubscriptionModel({
    required super.id,
    required super.laboratoryId,
    required super.planCode,
    required super.billingCycle,
    required super.status,
    super.currentPeriodStart,
    super.currentPeriodEnd,
    super.cancelledAt,
    super.cancelAtPeriodEnd,
  });

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) => SubscriptionModel(
    id: Json.requireInt(json, 'id'),
    laboratoryId: Json.requireInt(json, 'laboratoryId'),
    planCode: Json.optString(json, 'planCode') ?? '—',
    billingCycle: Json.optString(json, 'billingCycle') ?? '—',
    status: Json.optString(json, 'status') ?? 'UNKNOWN',
    currentPeriodStart: Json.optDateTime(json, 'currentPeriodStart'),
    currentPeriodEnd: Json.optDateTime(json, 'currentPeriodEnd'),
    cancelledAt: Json.optDateTime(json, 'cancelledAt'),
    cancelAtPeriodEnd: Json.optBool(json, 'cancelAtPeriodEnd') ?? false,
  );
}
