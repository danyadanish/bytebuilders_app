import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationType {
  static const String message = 'message';
  static const String adStatus = 'ad_status';
  static const String comment = 'comment';
  static const String like = 'like';
  static const String adReview = 'ad_review';
  static const String reportResponse = 'report_response';
  static const String systemNotice = 'system_notice';
}

class Notifications {
  final String id;
  final String receiverId;
  final String? senderId;
  final DateTime timestamp;
  final String type;
  final String title;
  final String content;
  final bool isRead;
  final Map<String, dynamic>? additionalData;

  Notifications({
    required this.id,
    required this.receiverId,
    this.senderId,
    required this.timestamp,
    required this.type,
    required this.title,
    required this.content,
    this.isRead = false,
    this.additionalData,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'receiverId': receiverId,
      'senderId': senderId,
      'timestamp': timestamp,
      'type': type,
      'title': title,
      'content': content,
      'isRead': isRead,
      'additionalData': additionalData,
    };
  }

  factory Notifications.fromMap(Map<String, dynamic> map) {
    return Notifications(
      id: map['id'] ?? '',
      receiverId: map['receiverId'] ?? '',
      senderId: map['senderId'],
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      type: map['type'] ?? '',
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      isRead: map['isRead'] ?? false,
      additionalData: map['additionalData'],
    );
  }
}
