import '../entities/app_notification.dart';
import '../entities/notification_preferences.dart';

/// Contract of the notifications repository: the in-app notices and the
/// preferences of the signed-in user. Implemented by the infrastructure layer.
abstract interface class NotificationInterface {
  Future<List<AppNotification>> getNotifications({bool unreadOnly = false, int limit = 50});
  Future<int> getUnreadCount();
  Future<void> markRead(int notificationId);
  Future<void> markAllRead();
  Future<NotificationPreferences> getPreferences();
  Future<NotificationPreferences> updatePreferences(NotificationPreferences preferences);
}
