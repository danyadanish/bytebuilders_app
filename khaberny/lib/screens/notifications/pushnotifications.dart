import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FirebaseMessagingService {
  final _messaging = FirebaseMessaging.instance;
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // Request permission
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // Initialize local notifications
      await _initLocalNotifications();

      // Get FCM token
      final token = await _messaging.getToken();
      if (token != null) {
        await _updateUserToken(token);
      }

      // Listen for token refresh
      _messaging.onTokenRefresh.listen(_updateUserToken);

      // Handle incoming messages when app is in foreground
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    }
  }

  Future<void> _initLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _handleNotificationTap,
    );
  }

  Future<void> _updateUserToken(String token) async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .update({'fcmToken': token});
      } catch (e) {
        // Optionally handle error (e.g., user doc doesn't exist)
        print('Error updating FCM token: $e');
      }
    }
  }

  void _handleForegroundMessage(RemoteMessage message) async {
    // Show local notification
    await _localNotifications.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'chat_messages',
          'Chat Messages',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      payload: message.data.toString(),
    );
  }

  void _handleNotificationTap(NotificationResponse response) {
    // Handle notification tap
    // Navigate to appropriate screen based on payload
  }
}
