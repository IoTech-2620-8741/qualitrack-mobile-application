import 'package:equatable/equatable.dart';

/// `nextStep` values of `GET /users/me/onboarding`.
enum OnboardingStep {
  subscription,
  laboratory,
  ready,
  unknown;

  static OnboardingStep fromCode(String? code) => switch (code) {
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

  @override
  List<Object?> get props => [nextStep, laboratoryId, subscriptionId, subscriptionStatus];
}
