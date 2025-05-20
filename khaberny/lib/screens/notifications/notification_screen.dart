import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'notificationservice.dart';
import 'notifications.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notificationService = NotificationService();
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF1E293B),
        body: Center(
          child: Text('Please sign in to view notifications',
              style: TextStyle(color: Colors.white)),
        ),
      );
    }

    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/images/khaberny_background.png',
            fit: BoxFit.cover,
          ),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text('Notifications'),
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: StreamBuilder<List<Notifications>>(
            stream: notificationService.getUserNotifications(currentUser.uid),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text('Error: ${snapshot.error}',
                      style: const TextStyle(color: Colors.redAccent)),
                );
              }

              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final notifications = snapshot.data!;

              if (notifications.isEmpty) {
                return const Center(
                  child: Text('No notifications yet',
                      style: TextStyle(color: Colors.white70)),
                );
              }

              return ListView.builder(
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notification = notifications[index];
                  return NotificationTile(notification: notification);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class NotificationTile extends StatelessWidget {
  final Notifications notification;

  const NotificationTile({super.key, required this.notification});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: const Color.fromARGB(105, 117, 152, 179),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: _getNotificationIcon(),
        title: Text(
          notification.title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              notification.content,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 6),
            Text(
              _formatTimestamp(notification.timestamp),
              style: const TextStyle(color: Colors.white30, fontSize: 12),
            ),
          ],
        ),
        trailing: notification.isRead
            ? null
            : Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              ),
        onTap: () => _handleNotificationTap(context),
      ),
    );
  }

  Widget _getNotificationIcon() {
    IconData iconData;
    Color iconColor;

    switch (notification.type) {
      case NotificationType.message:
        iconData = Icons.message;
        iconColor = Colors.blue;
        break;
      case NotificationType.adStatus:
        iconData = Icons.campaign;
        iconColor = Colors.green;
        break;
      case NotificationType.comment:
        iconData = Icons.comment;
        iconColor = Colors.orange;
        break;
      default:
        iconData = Icons.notifications;
        iconColor = Colors.grey;
    }

    return CircleAvatar(
      backgroundColor: iconColor.withOpacity(0.2),
      child: Icon(iconData, color: iconColor),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}-${timestamp.month}-${timestamp.year}';
    }
  }

  void _handleNotificationTap(BuildContext context) {
    // Handle navigation based on notification type
    if (!notification.isRead) {
      NotificationService().markAsRead(notification.id);
    }

    switch (notification.type) {
      case NotificationType.message:
        if (notification.additionalData?['chatId'] != null) {
          // Navigate to chat
        }
        break;
      case NotificationType.adStatus:
        if (notification.additionalData?['adId'] != null) {
          // Navigate to ad details
        }
        break;
      // Add more cases as needed
    }
  }
}
