import 'package:equatable/equatable.dart';

/// `nextStep` values of `GET /users/me/onboarding`.
enum OnboardingStep {
  passwordChange,
  subscription,
  laboratory,
  ready,
  unknown;

  static OnboardingStep fromCode(String? code) => switch (code) {
    'PASSWORD_CHANGE' => OnboardingStep.passwordChange,
    'SUBSCRIPTION' => OnboardingStep.subscription,
    'LABORATORY' => OnboardingStep.laboratory,
    'READY' => OnboardingStep.ready,
    _ => OnboardingStep.unknown,
  };
}

final class OnboardingState extends Equatable {
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
