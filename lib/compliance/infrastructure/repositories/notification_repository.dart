import '../../domain/entities/app_notification.dart';
import '../../domain/entities/notification_preferences.dart';
import '../../domain/interfaces/notification_interface.dart';
import '../data_sources/compliance_remote_data_provider.dart';

/// Implements [NotificationInterface] with the REST API.
class NotificationRepository implements NotificationInterface {
  const NotificationRepository({required ComplianceRemoteDataProvider remoteDataProvider}) : _remote = remoteDataProvider;

  final ComplianceRemoteDataProvider _remote;

  @override
  Future<List<AppNotification>> getNotifications({bool unreadOnly = false, int limit = 50}) =>
      _remote.getNotifications(unreadOnly: unreadOnly, limit: limit);

  @override
  Future<int> getUnreadCount() => _remote.getUnreadCount();

  @override
  Future<void> markRead(int notificationId) => _remote.markRead(notificationId);

  @override
  Future<void> markAllRead() => _remote.markAllRead();

  @override
  Future<NotificationPreferences> getPreferences() => _remote.getPreferences();

  @override
  Future<NotificationPreferences> updatePreferences(NotificationPreferences preferences) =>
      _remote.updatePreferences(preferences);
}
