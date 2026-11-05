import '../../../common/infrastructure/http/json_utils.dart';
import '../../domain/entities/alert_severity.dart';
import '../../domain/entities/notification_preferences.dart';

/// `NotificationPreferenceResource {emailEnabled, inAppEnabled, minimumSeverity}`.
class NotificationPreferencesModel extends NotificationPreferences {
  const NotificationPreferencesModel({
    required super.inAppEnabled,
    required super.emailEnabled,
    required super.minimumSeverity,
  });

  factory NotificationPreferencesModel.fromJson(Map<String, dynamic> json) => NotificationPreferencesModel(
    inAppEnabled: Json.optBool(json, 'inAppEnabled') ?? true,
    emailEnabled: Json.optBool(json, 'emailEnabled') ?? false,
    minimumSeverity: AlertSeverity.fromCode(Json.optString(json, 'minimumSeverity')),
  );

  static Map<String, dynamic> body(NotificationPreferences preferences) => {
    'inAppEnabled': preferences.inAppEnabled,
    'emailEnabled': preferences.emailEnabled,
    'minimumSeverity': preferences.minimumSeverity.code,
  };
}
