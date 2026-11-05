import '../../../common/domain/value_objects.dart';
import '../../domain/entities/subscription.dart';
import '../../domain/entities/subscription_payment.dart';
import '../../domain/entities/subscription_plan.dart';
import '../../domain/interfaces/subscription_interface.dart';
import '../data_sources/subscription_remote_data_provider.dart';

/// Implements [SubscriptionInterface] with the REST API. There is no offline
/// cache: every read goes to the remote data provider.
class SubscriptionRepository implements SubscriptionInterface {
  const SubscriptionRepository({required SubscriptionRemoteDataProvider remoteDataProvider})
    : _remote = remoteDataProvider;

  final SubscriptionRemoteDataProvider _remote;

  @override
  Future<List<Subscription>> getSubscriptions(LaboratoryId laboratoryId) async =>
      List<Subscription>.of(
        (await _remote.getSubscriptions(laboratoryId.value)).where((s) => s.laboratoryId == laboratoryId.value),
        growable: false,
      );

  @override
  Future<List<SubscriptionPayment>> getPayments(int subscriptionId) => _remote.getPayments(subscriptionId);

  @override
  Future<List<SubscriptionPlan>> getPlans() => _remote.getPlans();
}
