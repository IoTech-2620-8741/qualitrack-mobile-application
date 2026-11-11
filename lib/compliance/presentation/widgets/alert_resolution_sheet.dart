import 'package:flutter/material.dart';

import '../../../common/presentation/i18n/app_localizations.dart';
import '../../../common/presentation/labels.dart';
import '../../../common/presentation/theme/app_colors.dart';
import '../../../common/presentation/theme/app_spacing.dart';
import '../../../common/presentation/widgets/confirm_dialog.dart';
import '../../domain/entities/deviation_alert.dart';

/// "Mark as resolved" form, the same bottom-sheet pattern as the batch
/// review. It asks for the mandatory resolution notes, confirms and returns
/// them; `null` when the user cancels.
Future<String?> showAlertResolutionSheet(BuildContext context, {required DeviationAlert alert}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder:
        (context) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
          child: _AlertResolutionForm(alert: alert),
        ),
  );
}

class _AlertResolutionForm extends StatefulWidget {
  const _AlertResolutionForm({required this.alert});

  final DeviationAlert alert;

  @override
  State<_AlertResolutionForm> createState() => _AlertResolutionFormState();
}

class _AlertResolutionFormState extends State<_AlertResolutionForm> {
  final _formKey = GlobalKey<FormState>();
  final _notes = TextEditingController();

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final i18n = context.i18n;
    final navigator = Navigator.of(context);
    final confirmed = await showConfirmDialog(
      context,
      title: i18n.markAsResolved,
      message: i18n.resolveConfirm,
      confirmLabel: i18n.markAsResolved,
    );
    if (!confirmed || !mounted) return;
    navigator.pop(_notes.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.task_alt, color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    i18n.markAsResolved,
                    style: theme.textTheme.titleLarge?.copyWith(color: AppColors.primary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${alertVariable(i18n, widget.alert.parameterName)} · ${i18n.alertNumber(widget.alert.id)}',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              key: const Key('alert.resolutionNotes'),
              controller: _notes,
              autofocus: true,
              minLines: 3,
              maxLines: 6,
              maxLength: 500,
              decoration: InputDecoration(
                labelText: i18n.resolutionNotes,
                hintText: i18n.resolutionNotesHint,
                alignLabelWithHint: true,
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? i18n.resolutionNotesRequired : null,
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              key: const Key('alert.resolveSubmit'),
              onPressed: _submit,
              icon: const Icon(Icons.task_alt),
              label: Text(i18n.markAsResolved),
            ),
          ],
        ),
      ),
    );
  }
}
