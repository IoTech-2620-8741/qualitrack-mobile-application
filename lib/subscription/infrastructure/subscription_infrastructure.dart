import '../../shared/domain/value_objects.dart';
import '../../shared/infrastructure/http/api_client.dart';
import '../../shared/infrastructure/http/json_utils.dart';
import '../domain/subscription.dart';

class SubscriptionDto {
  const SubscriptionDto(this.json);

  final Map<String, dynamic> json;

  Subscription toDomain() => Subscription(
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

class PaymentDto {
  const PaymentDto(this.json);

  final Map<String, dynamic> json;

  SubscriptionPayment toDomain() => SubscriptionPayment(
    id: Json.requireInt(json, 'id'),
    subscriptionId: Json.requireInt(json, 'subscriptionId'),
    provider: Json.optString(json, 'provider'),
    amount: Json.optDouble(json, 'amount'),
    currency: Json.optString(json, 'currency'),
    status: Json.optString(json, 'status') ?? 'UNKNOWN',
    paidAt: Json.optDateTime(json, 'paidAt'),
  );
}

class PlanDto {
  const PlanDto(this.json);

  final Map<String, dynamic> json;

  SubscriptionPlan toDomain() => SubscriptionPlan(
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

class SubscriptionRemoteDataSource {
  const SubscriptionRemoteDataSource(this._client);

  final ApiClient _client;

  Future<List<SubscriptionDto>> getSubscriptions(int labId) async =>
      Json.asList(await _client.get('/laboratories/$labId/subscriptions')).map(SubscriptionDto.new).toList();

  Future<List<PaymentDto>> getPayments(int subscriptionId) async => Json.asList(
    await _client.get('/subscriptions/$subscriptionId/payments'),
  ).map(PaymentDto.new).toList();

  Future<List<PlanDto>> getPlans() async =>
      Json.asList(await _client.get('/subscription-plans')).map(PlanDto.new).toList();
}

class SubscriptionRepositoryImpl implements SubscriptionRepository {
  const SubscriptionRepositoryImpl(this._remote);

  final SubscriptionRemoteDataSource _remote;

  @override
  Future<List<Subscription>> getSubscriptions(LaboratoryId laboratoryId) async =>
      (await _remote.getSubscriptions(laboratoryId.value))
          .map((d) => d.toDomain())
          .where((s) => s.laboratoryId == laboratoryId.value)
          .toList(growable: false);

  @override
  Future<List<SubscriptionPayment>> getPayments(int subscriptionId) async =>
      (await _remote.getPayments(subscriptionId)).map((d) => d.toDomain()).toList(growable: false);

  @override
  Future<List<SubscriptionPlan>> getPlans() async =>
      (await _remote.getPlans()).map((d) => d.toDomain()).toList(growable: false);
}
