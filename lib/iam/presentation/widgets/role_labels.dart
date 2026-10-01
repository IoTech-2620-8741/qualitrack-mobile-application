import '../../../shared/presentation/l10n/app_localizations.dart';
import '../../domain/user_role.dart';

extension UserRolePresentation on UserRole {
  String label(AppLocalizations l10n) => switch (this) {
    UserRole.admin => l10n.roleAdmin,
    UserRole.qaManager => l10n.roleQaManager,
    UserRole.labOperator => l10n.roleLabOperator,
  };
}
