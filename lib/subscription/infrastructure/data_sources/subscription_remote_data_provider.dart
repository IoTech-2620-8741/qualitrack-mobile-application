import '../../../common/infrastructure/http/api_client.dart';
import '../../../common/infrastructure/http/json_utils.dart';
import '../models/subscription_model.dart';
import '../models/subscription_payment_model.dart';
import '../models/subscription_plan_model.dart';

/// Talks to the subscription endpoints of the QualiTrack REST API.
class SubscriptionRemoteDataProvider {
  const SubscriptionRemoteDataProvider(this._client);

  final ApiClient _client;

  Future<List<SubscriptionModel>> getSubscriptions(int labId) async =>
      Json.asList(await _client.get('/laboratories/$labId/subscriptions')).map(SubscriptionModel.fromJson).toList();

  Future<List<SubscriptionPaymentModel>> getPayments(int subscriptionId) async =>
      Json.asList(await _client.get('/subscriptions/$subscriptionId/payments'))
          .map(SubscriptionPaymentModel.fromJson)
          .toList();

  Future<List<SubscriptionPlanModel>> getPlans() async =>
      Json.asList(await _client.get('/subscription-plans')).map(SubscriptionPlanModel.fromJson).toList();
}
