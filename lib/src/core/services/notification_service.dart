import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:smart_iraq/src/models/notification_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService extends ChangeNotifier {
  final SupabaseClient _supabase;
  StreamSubscription<List<Map<String, dynamic>>>? _subscription;

  List<Notification> _notifications = [];
  List<Notification> get notifications => _notifications;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  NotificationService(this._supabase);

  Future<void> init() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    // Fetch initial notifications
    final response = await _supabase
        .from('notifications')
        .select()
        .eq('recipient_id', userId)
        .order('created_at', ascending: false);

    _notifications = (response as List).map((json) => Notification.fromJson(json)).toList();
    notifyListeners();

    // Set up real-time subscription
    _subscription = _supabase
        .from('notifications:recipient_id=eq.$userId')
        .stream(primaryKey: ['id'])
        .listen((payload) {
          // This gives a list of all matching rows. We need to find the new one.
          // A simple approach is to refetch all, but a more optimized one is to find the new record.
          final newNotification = Notification.fromJson(payload.first);
          _handleNewNotification(newNotification);
        });
  }

  void _handleNewNotification(Notification newNotification) {
    // Avoid adding duplicates
    if (!_notifications.any((n) => n.id == newNotification.id)) {
      _notifications.insert(0, newNotification);
      notifyListeners();
      // Here you could also trigger a local notification
    }
  }

  Future<void> markAsRead(int notificationId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1 && !_notifications[index].isRead) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      notifyListeners();

      // Update in the database
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
    }
  }

  Future<void> markAllAsRead() async {
    _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
    notifyListeners();

    await _supabase
      .from('notifications')
      .update({'is_read': true})
      .eq('recipient_id', _supabase.auth.currentUser!.id)
      .eq('is_read', false);
  }


  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
