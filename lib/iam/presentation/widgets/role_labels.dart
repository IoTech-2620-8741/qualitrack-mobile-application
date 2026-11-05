import '../../../common/presentation/i18n/app_localizations.dart';
import '../../domain/entities/user_role.dart';

extension UserRolePresentation on UserRole {
  String label(AppLocalizations i18n) => switch (this) {
    UserRole.admin => i18n.roleAdmin,
    UserRole.qaManager => i18n.roleQaManager,
    UserRole.labOperator => i18n.roleLabOperator,
    UserRole.auditor => i18n.roleAuditor,
  };
}
