class Notification {
  final String id;
  final String userId;  // Recipient user ID
  final String title;
  final String status; // 'approved', 'denied', 'pending'
  final DateTime timestamp;
  final String? reason;
  final bool isRead;
  final String type;  // e.g., 'Summer Offer', 'Winter Deals', 'Back to School'
  final String sourceType;  // e.g., 'government', 'user', 'system', 'community'
  final String? sourceId;  // ID of the entity that sent the notification (user ID, department ID, etc.)
  final String? sourceName;  // Display name of the source
  final String? actionType;  // Type of action required/suggested, if any
  final String? actionData;  // Data needed for the action
  
  Notification({
    required this.id,
    required this.userId,
    required this.title,
    required this.status,
    required this.timestamp,
    this.reason,
    this.isRead = false,
    required this.type,
    required this.sourceType,
    this.sourceId,
    this.sourceName,
    this.actionType,
    this.actionData,
  });
  
  // Convert to/from JSON for Firebase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'status': status,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'reason': reason,
      'isRead': isRead,
      'type': type,
      'sourceType': sourceType,
      'sourceId': sourceId,
      'sourceName': sourceName,
      'actionType': actionType,
      'actionData': actionData,
    };
  }
  
  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['id'],
      userId: json['userId'],
      title: json['title'],
      status: json['status'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
      reason: json['reason'],
      isRead: json['isRead'] ?? false,
      type: json['type'],
      sourceType: json['sourceType'] ?? 'system',
      sourceId: json['sourceId'],
      sourceName: json['sourceName'],
      actionType: json['actionType'],
      actionData: json['actionData'],
    );
  }
}