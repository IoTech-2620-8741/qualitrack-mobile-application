import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../shared/presentation/l10n/app_localizations.dart';
import '../../../shared/presentation/widgets/failure_message.dart';
import '../../../shared/presentation/widgets/layout_widgets.dart';
import '../../domain/password_policy.dart';
import '../bloc/change_password_bloc.dart';
import '../widgets/qualitrack_logo.dart';

/// Replaces the password of the signed-in user. When [forced] is true it is
/// the first sign-in of a staff member with the temporary password received
/// from the quality manager, and nothing else is available until it changes.
class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({
    super.key,
    required this.forced,
    required this.onChanged,
    this.onSignOut,
  });

  final bool forced;
  final Future<void> Function() onChanged;
  final Future<void> Function()? onSignOut;

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.read<ChangePasswordBloc>().add(
      PasswordChangeSubmitted(currentPassword: _current.text, newPassword: _next.text),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return BlocConsumer<ChangePasswordBloc, ChangePasswordState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) async {
        if (state.status != ChangePasswordStatus.success) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.passwordChanged)));
        await widget.onChanged();
      },
      builder: (context, state) {
        final submitting = state.status == ChangePasswordStatus.submitting;
        final form = Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.forced) ...[
                const QualiTrackLogo(size: 90),
                const SizedBox(height: AppSpacing.lg),
                Semantics(
                  header: true,
                  child: Text(
                    l10n.changePasswordTitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(l10n.changePasswordForcedHint, textAlign: TextAlign.center),
                const SizedBox(height: AppSpacing.xl),
              ],
              if (state.status == ChangePasswordStatus.failure && state.failure != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                  child: InfoCard(
                    color: AppColors.critical.withValues(alpha: 0.06),
                    borderColor: AppColors.critical.withValues(alpha: 0.4),
                    child: Text(
                      failureMessage(context, state.failure!),
                      style: const TextStyle(color: AppColors.critical),
                    ),
                  ),
                ),
              _PasswordField(
                fieldKey: const Key('changePassword.current'),
                controller: _current,
                label: l10n.currentPassword,
                obscure: _obscure,
                enabled: !submitting,
                autofillHints: const [AutofillHints.password],
                validator: (value) => (value == null || value.isEmpty) ? l10n.passwordRequired : null,
              ),
              const SizedBox(height: AppSpacing.lg),
              _PasswordField(
                fieldKey: const Key('changePassword.new'),
                controller: _next,
                label: l10n.newPassword,
                helper: l10n.passwordPolicyHint,
                obscure: _obscure,
                enabled: !submitting,
                autofillHints: const [AutofillHints.newPassword],
                validator: (value) {
                  if (value == null || value.isEmpty) return l10n.passwordRequired;
                  if (!PasswordPolicy.isSatisfiedBy(value)) return l10n.passwordPolicyHint;
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              _PasswordField(
                fieldKey: const Key('changePassword.confirm'),
                controller: _confirm,
                label: l10n.confirmPassword,
                obscure: _obscure,
                enabled: !submitting,
                autofillHints: const [AutofillHints.newPassword],
                onSubmitted: (_) => _submit(),
                validator: (value) => value != _next.text ? l10n.passwordsDoNotMatch : null,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  label: Text(_obscure ? l10n.showPassword : l10n.hidePassword),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                key: const Key('changePassword.submit'),
                onPressed: submitting ? null : _submit,
                child: submitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                      )
                    : Text(l10n.changePassword),
              ),
              if (widget.forced && widget.onSignOut != null) ...[
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton.icon(
                  onPressed: submitting ? null : widget.onSignOut,
                  icon: const Icon(Icons.logout),
                  label: Text(l10n.signOut),
                ),
              ],
            ],
          ),
        );
        return Scaffold(
          backgroundColor: widget.forced ? AppColors.surface : null,
          appBar: widget.forced ? null : AppBar(title: Text(l10n.changePassword)),
          body: SafeArea(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: AutofillGroup(child: form),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.fieldKey,
    required this.controller,
    required this.label,
    required this.obscure,
    required this.enabled,
    required this.validator,
    required this.autofillHints,
    this.helper,
    this.onSubmitted,
  });

  final Key fieldKey;
  final TextEditingController controller;
  final String label;
  final String? helper;
  final bool obscure;
  final bool enabled;
  final String? Function(String?) validator;
  final Iterable<String> autofillHints;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: fieldKey,
      controller: controller,
      enabled: enabled,
      obscureText: obscure,
      autofillHints: autofillHints,
      textInputAction: onSubmitted == null ? TextInputAction.next : TextInputAction.done,
      onFieldSubmitted: onSubmitted,
      decoration: InputDecoration(
        labelText: label,
        helperText: helper,
        helperMaxLines: 2,
        errorMaxLines: 2,
        prefixIcon: const Icon(Icons.lock_outline),
      ),
      validator: validator,
    );
  }
}
