/// Public entry point of the Payments & Subscriptions context. Other bounded
/// contexts consume the billing overview through [SubscriptionApi] and never
/// import the domain or the infrastructure directly.
library;

import '../../common/domain/value_objects.dart';
import '../application/subscription_facade_service.dart';
import '../domain/entities/billing_summary.dart';

export '../domain/entities/billing_summary.dart';
export '../domain/entities/subscription.dart';
export '../domain/entities/subscription_payment.dart';
export '../domain/entities/subscription_plan.dart';

class SubscriptionApi {
  const SubscriptionApi(this._subscriptionService);

  final SubscriptionFacadeService _subscriptionService;

  /// Read-only billing overview of the laboratory.
  Future<BillingSummary> getBillingSummary(LaboratoryId laboratoryId) =>
      _subscriptionService.getBillingSummary(laboratoryId);
}
