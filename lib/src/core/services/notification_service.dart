import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:smart_iraq/src/models/notification_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService extends ChangeNotifier {
  final SupabaseClient _supabase;
  RealtimeChannel? _channel;

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
    _channel = _supabase.channel('public:notifications:for-user-$userId');
    _channel!.on(
      RealtimeListenTypes.postgresChanges,
      ChannelFilter(
        event: 'INSERT',
        schema: 'public',
        table: 'notifications',
        filter: 'recipient_id=eq.$userId',
      ),
      (payload, [ref]) {
        final newNotification = Notification.fromJson(payload['new']);
        _handleNewNotification(newNotification);
      },
    ).subscribe();
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
    if (_channel != null) {
      _supabase.removeChannel(_channel!);
    }
    super.dispose();
  }
}
