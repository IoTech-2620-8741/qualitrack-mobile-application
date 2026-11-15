import '../../../common/infrastructure/http/json_utils.dart';
import '../../domain/entities/onboarding_state.dart';
import '../../domain/entities/onboarding_step.dart';

/// `UserOnboardingResource {userId, laboratoryId, subscriptionId, subscriptionStatus, nextStep}`.
class OnboardingStateModel extends OnboardingState {
  const OnboardingStateModel({
    required super.nextStep,
    super.laboratoryId,
    super.subscriptionId,
    super.subscriptionStatus,
  });

  factory OnboardingStateModel.fromJson(Map<String, dynamic> json) => OnboardingStateModel(
    nextStep: OnboardingStep.fromCode(Json.optString(json, 'nextStep')),
    laboratoryId: Json.optInt(json, 'laboratoryId'),
    subscriptionId: Json.optInt(json, 'subscriptionId'),
    subscriptionStatus: Json.optString(json, 'subscriptionStatus'),
  );
}
