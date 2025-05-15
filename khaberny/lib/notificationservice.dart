import 'package:cloud_firestore/cloud_firestore.dart';
import 'notifications.dart';
class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Collection reference
  CollectionReference get notificationsCollection => 
      _firestore.collection('notifications');
  
  // Get user notifications
  Stream<List<Notifications>> getUserNotifications(String userId) {
    return notificationsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Notifications.fromJson(doc.data() as Map<String, dynamic>))
              .toList();
        });
  }
  
  // Add a new notification
  Future<void> addNotification(Notifications notification) {
    return notificationsCollection.doc(notification.id).set(notification.toJson());
  }
  
  // Mark notification as read
  Future<void> markAsRead(String notificationId) {
    return notificationsCollection.doc(notificationId).update({'isRead': true});
  }
  
  // Delete notification
  Future<void> deleteNotification(String notificationId) {
    return notificationsCollection.doc(notificationId).delete();
  }
}