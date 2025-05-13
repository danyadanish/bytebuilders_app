import 'package:flutter/material.dart';
import 'package:khaberny/notificationservice.dart';
import 'package:khaberny/notifications.dart';

class NotificationScreen extends StatelessWidget {
  final String userId;
  
  const NotificationScreen({super.key, required this.userId});
  
  @override
  Widget build(BuildContext context) {
    final notificationService = NotificationService();
    
    return Scaffold(
      backgroundColor: const Color(0xFF1E293B), // Dark background from your design
      appBar: AppBar(
        title: Text('Notifications'),
        backgroundColor: const Color(0xFF1E293B),
        actions: [
          IconButton(
            icon: Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: StreamBuilder<List<Notifications>>(
        stream: notificationService.getUserNotifications(userId) as Stream<List<Notifications>>?,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No notifications', style: TextStyle(color: Colors.white)));
          }
          
          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final notification = snapshot.data![index];
              return NotificationTile(notification: notification);
            },
          );
        },
      ),
    );
  }
}

class NotificationTile extends StatelessWidget {
  final Notifications notification;
  
  const NotificationTile({super.key, required this.notification});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade800, width: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your ad ${notification.type} was ${notification.status}.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (notification.status == 'denied' && notification.reason != null)
                  Text(
                    'Reason: ${notification.reason}',
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            _formatTime(notification.timestamp),
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final notificationDate = DateTime(time.year, time.month, time.day);
    
    if (notificationDate == today) {
      return '${time.hour}:${time.minute.toString().padLeft(2, '0')} ${time.hour >= 12 ? 'pm' : 'am'}';
    }
    
    return '${time.day}/${time.month}/${time.year}';
  }
}