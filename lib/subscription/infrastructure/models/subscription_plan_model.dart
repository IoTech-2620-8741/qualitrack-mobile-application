import '../../../common/infrastructure/http/json_utils.dart';
import '../../domain/entities/subscription_plan.dart';

/// `SubscriptionPlanResource`.
class SubscriptionPlanModel extends SubscriptionPlan {
  const SubscriptionPlanModel({
    required super.code,
    required super.name,
    required super.billingCycle,
    super.amount,
    super.currency,
    super.maxUsers,
    super.maxEquipment,
    super.description,
  });

  factory SubscriptionPlanModel.fromJson(Map<String, dynamic> json) => SubscriptionPlanModel(
    code: Json.requireString(json, 'code'),
    name: Json.optString(json, 'name') ?? Json.requireString(json, 'code'),
    billingCycle: Json.optString(json, 'billingCycle') ?? '',
    amount: Json.optDouble(json, 'amount'),
    currency: Json.optString(json, 'currency'),
    maxUsers: Json.optInt(json, 'maxUsers'),
    maxEquipment: Json.optInt(json, 'maxEquipment'),
    description: Json.optString(json, 'description'),
  );
}
