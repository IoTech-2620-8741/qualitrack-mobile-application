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
