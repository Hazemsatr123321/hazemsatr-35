import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:smart_iraq/src/core/services/notification_service.dart';
import 'package:smart_iraq/src/core/theme/app_theme.dart';
import 'package:smart_iraq/src/models/notification_model.dart';
import 'package:smart_iraq/src/models/product_model.dart';
import 'package:smart_iraq/src/repositories/chat_repository.dart';
import 'package:smart_iraq/src/ui/screens/auction/auction_detail_screen.dart';
import 'package:smart_iraq/src/ui/screens/chat/chat_screen.dart';
import 'package:smart_iraq/src/ui/screens/rfq/rfq_detail_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Notifications'),
        trailing: Consumer<NotificationService>(
          builder: (context, service, child) {
            if (service.unreadCount == 0) return const SizedBox.shrink();
            return CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Text('Mark all as read'),
              onPressed: () => service.markAllAsRead(),
            );
          },
        ),
      ),
      child: Consumer<NotificationService>(
        builder: (context, service, child) {
          if (service.notifications.isEmpty) {
            return const Center(
              child: Text(
                'You have no notifications.',
                style: TextStyle(color: AppTheme.secondaryTextColor),
              ),
            );
          }

          return ListView.builder(
            itemCount: service.notifications.length,
            itemBuilder: (context, index) {
              final notification = service.notifications[index];
              return NotificationTile(notification: notification);
            },
          );
        },
      ),
    );
  }
}

class NotificationTile extends StatelessWidget {
  final Notification notification;

  const NotificationTile({Key? key, required this.notification}) : super(key: key);

  Future<void> _navigateToDestination(BuildContext context) async {
    // First, mark as read
    Provider.of<NotificationService>(context, listen: false).markAsRead(notification.id);

    // Then, navigate
    switch (notification.type) {
      case 'new_message':
        Navigator.of(context).push(CupertinoPageRoute(
          builder: (context) => ChatScreen(
            roomId: notification.referenceId,
            chatRepository: context.read<ChatRepository>(),
          ),
        ));
        break;
      case 'new_bid':
        // We need to fetch the product first
        final supabase = Provider.of<SupabaseClient>(context, listen: false);
        try {
          final data = await supabase.from('products').select().eq('id', notification.referenceId).single();
          final product = Product.fromJson(data);
          Navigator.of(context).push(CupertinoPageRoute(
            builder: (context) => AuctionDetailScreen(product: product),
          ));
        } catch (e) {
          // Handle error, e.g., show a dialog
        }
        break;
      case 'new_offer':
        Navigator.of(context).push(CupertinoPageRoute(
          builder: (context) => RfqDetailScreen(rfqId: notification.referenceId),
        ));
        break;
      default:
        // Do nothing for unknown types
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _navigateToDestination(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        color: notification.isRead ? AppTheme.charcoalBackground : AppTheme.darkSurface,
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: notification.isRead ? AppTheme.charcoalBackground : AppTheme.goldAccent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.lightTextColor,
                    ),
                  ),
                  if (notification.body != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      notification.body!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppTheme.secondaryTextColor),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    timeago.format(notification.createdAt),
                    style: const TextStyle(color: AppTheme.secondaryTextColor, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
