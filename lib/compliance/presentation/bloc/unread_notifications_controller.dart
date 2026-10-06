import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../shared/domain/failure.dart';
import '../../application/compliance_queries.dart';

/// Unread count of the bell, shared by every screen. It refreshes every
/// [interval] while [start]ed (app in foreground with a ready session) and
/// whenever notifications are read.
class UnreadNotificationsController extends ChangeNotifier {
  UnreadNotificationsController({
    required GetUnreadNotificationCount getUnreadCount,
    this.interval = const Duration(seconds: 60),
  }) : _getUnreadCount = getUnreadCount;

  final GetUnreadNotificationCount _getUnreadCount;
  final Duration interval;

  Timer? _timer;
  int _count = 0;
  bool _disposed = false;

  int get count => _count;

  void start() {
    if (_timer != null) return;
    refresh();
    _timer = Timer.periodic(interval, (_) => refresh());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// Clears the count when the session ends.
  void reset() {
    stop();
    _set(0);
  }

  Future<void> refresh() async {
    try {
      _set(await _getUnreadCount());
    } on Failure {
      // The bell keeps the last known count; screens show their own errors.
    }
  }

  void _set(int value) {
    if (_disposed || value == _count) return;
    _count = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    stop();
    super.dispose();
  }
}
