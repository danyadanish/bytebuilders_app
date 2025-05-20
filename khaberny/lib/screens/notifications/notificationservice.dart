import 'package:cloud_firestore/cloud_firestore.dart';
import 'notifications.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get notificationsCollection =>
      _firestore.collection('notifications');

  Stream<List<Notifications>> getUserNotifications(String userId) {
    return notificationsCollection
        .where('receiverId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                Notifications.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  Future<void> addNotification({
    required String receiverId,
    String? senderId,
    required String type,
    required String title,
    required String content,
    Map<String, dynamic>? additionalData,
  }) async {
    final notification = Notifications(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      receiverId: receiverId,
      senderId: senderId,
      timestamp: DateTime.now(),
      type: type,
      title: title,
      content: content,
      additionalData: additionalData,
    );

    await notificationsCollection
        .doc(notification.id)
        .set(notification.toMap());
  }

  Future<void> markAsRead(String notificationId) async {
    await notificationsCollection.doc(notificationId).update({'isRead': true});
  }

  Future<void> deleteNotification(String notificationId) async {
    await notificationsCollection.doc(notificationId).delete();
  }
}
