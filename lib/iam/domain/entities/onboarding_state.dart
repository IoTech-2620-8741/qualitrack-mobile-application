import 'package:equatable/equatable.dart';

import 'onboarding_step.dart';

class OnboardingState extends Equatable {
  const OnboardingState({
    required this.nextStep,
    this.laboratoryId,
    this.subscriptionId,
    this.subscriptionStatus,
  });

  final OnboardingStep nextStep;
  final int? laboratoryId;
  final int? subscriptionId;
  final String? subscriptionStatus;

  bool get isReady => nextStep == OnboardingStep.ready;

  /// Staff members sign in first with the temporary password received when
  /// their quality manager registered them and must replace it.
  bool get requiresPasswordChange => nextStep == OnboardingStep.passwordChange;

  @override
  List<Object?> get props => [nextStep, laboratoryId, subscriptionId, subscriptionStatus];
}
