import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../iam/domain/user_role.dart';
import '../../../iam/presentation/widgets/role_labels.dart';
import '../../../shared/presentation/formatting/formatters.dart';
import '../../../shared/presentation/l10n/app_localizations.dart';
import '../../../shared/presentation/widgets/confirm_dialog.dart';
import '../../../shared/presentation/widgets/failure_message.dart';
import '../../../shared/presentation/widgets/layout_widgets.dart';
import '../../../shared/presentation/widgets/remote_state_view.dart';
import '../../../shared/presentation/widgets/status_badge.dart';
import '../../domain/profile.dart';
import '../bloc/profile_bloc.dart';
import '../widgets/profile_avatar.dart';

/// Profile of the signed-in user: photo, personal data, account and access to
/// the password change and the notification preferences.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, required this.onSignOut});

  final Future<void> Function() onSignOut;

  Future<void> _pickPhoto(BuildContext context) async {
    final bloc = context.read<ProfileBloc>();
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1024, maxHeight: 1024, imageQuality: 85);
    if (file == null) return;
    final contentType = ProfilePhoto.contentTypeOf(file.name) ?? file.mimeType;
    if (contentType == null || !ProfilePhoto.allowedTypes.contains(contentType)) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.photoTypeNotAllowed)));
      return;
    }
    final bytes = await file.readAsBytes();
    if (bytes.length > ProfilePhoto.maxBytes) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.photoTooLarge)));
      return;
    }
    bloc.add(ProfilePhotoPicked(ProfilePhoto(bytes: bytes, contentType: contentType)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bloc = context.read<ProfileBloc>();
    return Scaffold(
      appBar: AppBar(title: Text(l10n.profile)),
      body: BlocConsumer<ProfileBloc, ProfileState>(
        listenWhen: (a, b) => a.actionStatus != b.actionStatus,
        listener: (context, state) {
          final messenger = ScaffoldMessenger.of(context);
          if (state.actionStatus == ProfileActionStatus.success) {
            messenger.showSnackBar(SnackBar(
              content: Text(switch (state.lastAction) {
                ProfileAction.photo => l10n.photoUpdated,
                ProfileAction.removePhoto => l10n.photoRemoved,
                _ => l10n.profileSaved,
              }),
            ));
          } else if (state.actionStatus == ProfileActionStatus.failure && state.actionFailure != null) {
            messenger.showSnackBar(SnackBar(
              backgroundColor: AppColors.critical,
              content: Text(failureMessage(context, state.actionFailure!)),
            ));
          }
        },
        builder: (context, state) => RemoteStateView<ProfileData>(
          state: state.remote,
          onRetry: () => bloc.add(const ProfileRequested()),
          builder: (context, data) {
            final profile = data.profile;
            final lab = data.laboratory;
            final roles = UserRole.parseAll(profile.roles);
            final busy = state.submitting;
            return ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                Center(child: ProfileAvatar(initials: profile.initials, photo: data.photo, radius: 44)),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: AppSpacing.sm,
                  children: [
                    TextButton.icon(
                      onPressed: busy ? null : () => _pickPhoto(context),
                      icon: const Icon(Icons.photo_camera_outlined),
                      label: Text(profile.hasPhoto ? l10n.changePhoto : l10n.addPhoto),
                    ),
                    if (profile.hasPhoto)
                      TextButton.icon(
                        style: TextButton.styleFrom(foregroundColor: AppColors.critical),
                        onPressed: busy
                            ? null
                            : () async {
                                final ok = await showConfirmDialog(
                                  context,
                                  title: l10n.removePhoto,
                                  message: l10n.removePhotoConfirm,
                                  confirmLabel: l10n.removePhoto,
                                  destructive: true,
                                );
                                if (ok) bloc.add(const ProfilePhotoRemoved());
                              },
                        icon: const Icon(Icons.delete_outline),
                        label: Text(l10n.removePhoto),
                      ),
                  ],
                ),
                Text(profile.displayName, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
                if (profile.position != null)
                  Text(profile.position!, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: [for (final role in roles) StatusBadge(label: role.label(l10n), tone: BadgeTone.brand)],
                ),
                if (busy) ...[const SizedBox(height: AppSpacing.md), const LinearProgressIndicator()],
                const SizedBox(height: AppSpacing.lg),
                InfoCard(
                  title: l10n.personalData,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Wrap(
                        spacing: AppSpacing.xl,
                        runSpacing: AppSpacing.lg,
                        children: [
                          KeyValue(label: l10n.fullName, value: profile.fullName ?? '—'),
                          KeyValue(label: l10n.dni, value: profile.dni ?? '—'),
                          KeyValue(label: l10n.phone, value: profile.phoneNumber ?? '—'),
                          KeyValue(label: l10n.location, value: profile.location ?? '—'),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Align(
                        alignment: Alignment.centerRight,
                        child: OutlinedButton.icon(
                          onPressed: busy ? null : () => _editPersonalData(context, profile),
                          icon: const Icon(Icons.edit_outlined),
                          label: Text(l10n.edit),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                InfoCard(
                  title: l10n.account,
                  child: Wrap(
                    spacing: AppSpacing.xl,
                    runSpacing: AppSpacing.lg,
                    children: [
                      KeyValue(label: l10n.username, value: profile.username),
                      KeyValue(label: l10n.email, value: profile.email ?? '—'),
                    ],
                  ),
                ),
                if (lab != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  InfoCard(
                    title: l10n.laboratory,
                    child: Wrap(
                      spacing: AppSpacing.xl,
                      runSpacing: AppSpacing.lg,
                      children: [
                        KeyValue(label: l10n.name, value: lab.name),
                        KeyValue(label: l10n.ruc, value: lab.ruc ?? '—'),
                        KeyValue(label: l10n.phone, value: lab.phone ?? '—'),
                        KeyValue(label: l10n.address, value: lab.address ?? '—'),
                        KeyValue(label: l10n.status, value: Formatters.humanize(lab.status)),
                        if (lab.applicableRegulations.isNotEmpty)
                          KeyValue(label: l10n.regulations, value: lab.applicableRegulations.join(', ')),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.lock_reset, color: AppColors.primary),
                        title: Text(l10n.changePassword),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/profile/password'),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.notifications_active_outlined, color: AppColors.primary),
                        title: Text(l10n.notificationPreferences),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/profile/notifications'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.critical),
                  onPressed: onSignOut,
                  icon: const Icon(Icons.logout),
                  label: Text(l10n.signOut),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _editPersonalData(BuildContext context, UserProfile profile) async {
    final bloc = context.read<ProfileBloc>();
    final data = await showModalBottomSheet<PersonalData>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _PersonalDataSheet(profile: profile),
    );
    if (data != null) bloc.add(ProfileSaved(data));
  }
}

class _PersonalDataSheet extends StatefulWidget {
  const _PersonalDataSheet({required this.profile});

  final UserProfile profile;

  @override
  State<_PersonalDataSheet> createState() => _PersonalDataSheetState();
}

class _PersonalDataSheetState extends State<_PersonalDataSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _fullName = TextEditingController(text: widget.profile.fullName ?? '');
  late final _dni = TextEditingController(text: widget.profile.dni ?? '');
  late final _phone = TextEditingController(text: widget.profile.phoneNumber ?? '');
  late final _location = TextEditingController(text: widget.profile.location ?? '');

  @override
  void dispose() {
    _fullName.dispose();
    _dni.dispose();
    _phone.dispose();
    _location.dispose();
    super.dispose();
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(PersonalData(
      fullName: _fullName.text,
      dni: _dni.text,
      phoneNumber: _phone.text,
      location: _location.text,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    String? optional(String? value, bool Function(String) valid, String message) =>
        (value == null || value.trim().isEmpty || valid(value)) ? null : message;
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.personalData, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                key: const Key('profile.fullName'),
                controller: _fullName,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(labelText: l10n.fullName),
                validator: (v) => PersonalDataRules.isValidFullName(v ?? '') ? null : l10n.fullNameInvalid,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                key: const Key('profile.dni'),
                controller: _dni,
                keyboardType: TextInputType.number,
                maxLength: 8,
                decoration: InputDecoration(labelText: l10n.dni),
                validator: (v) => optional(v, PersonalDataRules.isValidDni, l10n.dniInvalid),
              ),
              TextFormField(
                key: const Key('profile.phone'),
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(labelText: l10n.phone),
                validator: (v) => optional(v, PersonalDataRules.isValidPhone, l10n.phoneInvalid),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                key: const Key('profile.location'),
                controller: _location,
                decoration: InputDecoration(labelText: l10n.location),
                validator: (v) => optional(v, PersonalDataRules.isValidLocation, l10n.locationInvalid),
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(key: const Key('profile.save'), onPressed: _save, child: Text(l10n.save)),
            ],
          ),
        ),
      ),
    );
  }
}
