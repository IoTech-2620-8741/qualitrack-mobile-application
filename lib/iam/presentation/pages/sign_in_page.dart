import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../shared/domain/failure.dart';
import '../../../shared/presentation/l10n/app_localizations.dart';
import '../../../shared/presentation/widgets/failure_message.dart';
import '../bloc/sign_in_bloc.dart';
import '../widgets/qualitrack_logo.dart';

class SignInPage extends StatelessWidget {
  const SignInPage({super.key, this.sessionExpired = false});

  final bool sessionExpired;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.xl),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight - AppSpacing.xl * 2),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: SignInForm(sessionExpired: sessionExpired),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SignInForm extends StatefulWidget {
  const SignInForm({super.key, this.sessionExpired = false});

  final bool sessionExpired;

  @override
  State<SignInForm> createState() => _SignInFormState();
}

class _SignInFormState extends State<SignInForm> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.read<SignInBloc>().add(
      SignInSubmitted(username: _username.text, password: _password.text),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return BlocBuilder<SignInBloc, SignInState>(
      builder: (context, state) {
        final submitting = state.status == SignInStatus.submitting;
        return AutofillGroup(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const QualiTrackLogo(size: 110),
                const SizedBox(height: AppSpacing.lg),
                Semantics(
                  header: true,
                  child: Text(
                    l10n.signInTitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.signInSubtitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.xl),
                if (widget.sessionExpired && state.status == SignInStatus.idle)
                  _Banner(message: l10n.sessionExpired, tone: AppColors.warning),
                if (state.status == SignInStatus.failure && state.failure != null)
                  _Banner(
                    message: state.failure is UnauthorizedFailure
                        ? l10n.invalidCredentials
                        : failureMessage(context, state.failure!),
                    tone: AppColors.critical,
                  ),
                Text(l10n.username, style: theme.textTheme.titleSmall),
                const SizedBox(height: AppSpacing.xs),
                TextFormField(
                  key: const Key('signIn.username'),
                  controller: _username,
                  enabled: !submitting,
                  autofillHints: const [AutofillHints.username, AutofillHints.email],
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    hintText: l10n.usernameHint,
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                  validator: (value) =>
                      (value == null || value.trim().isEmpty) ? l10n.usernameRequired : null,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(l10n.password, style: theme.textTheme.titleSmall),
                const SizedBox(height: AppSpacing.xs),
                TextFormField(
                  key: const Key('signIn.password'),
                  controller: _password,
                  enabled: !submitting,
                  obscureText: _obscure,
                  autofillHints: const [AutofillHints.password],
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    hintText: l10n.passwordHint,
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      tooltip: _obscure ? l10n.showPassword : l10n.hidePassword,
                      icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (value) =>
                      (value == null || value.isEmpty) ? l10n.passwordRequired : null,
                ),
                const SizedBox(height: AppSpacing.xl),
                FilledButton(
                  key: const Key('signIn.submit'),
                  onPressed: submitting ? null : _submit,
                  child: submitting
                      ? Semantics(
                          label: l10n.signingIn,
                          child: const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                          ),
                        )
                      : Text(l10n.signIn),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  l10n.accountsManagedOnWeb,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.message, required this.tone});

  final String message;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Semantics(
        liveRegion: true,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: tone.withValues(alpha: 0.08),
            borderRadius: AppRadius.mdAll,
            border: Border.all(color: tone.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              Icon(Icons.error_outline, color: tone),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(message, style: TextStyle(color: tone))),
            ],
          ),
        ),
      ),
    );
  }
}
