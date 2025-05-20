import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import '../notifications/notification_sender.dart';
import '../notifications/notificationservice.dart';

class ChatPage extends StatefulWidget {
  final String receiverId;
  final String receiverName;

  const ChatPage({
    required this.receiverId,
    required this.receiverName,
    super.key,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late final String currentUserId;
  late final String chatId;

  @override
  void initState() {
    super.initState();
    currentUserId = _auth.currentUser!.uid;
    chatId = _getChatId(currentUserId, widget.receiverId);
    _setupMessaging();
  }

  String _getChatId(String userId1, String userId2) {
    final ids = [userId1, userId2]..sort();
    return ids.join('_');
  }

  Future<void> _setupMessaging() async {
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);
  }

  Future<void> sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;
    _messageController.clear();

    try {
      // Add message as a new document in the chats collection
      await _firestore.collection('chats').add({
        'chatId': chatId,
        'senderId': currentUserId,
        'receiverId': widget.receiverId,
        'content': message,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Get sender info
      final userDoc =
          await _firestore.collection('users').doc(currentUserId).get();
      final senderName = userDoc.data()?['name'] ?? 'Unknown User';

      // Get receiver's FCM token
      final receiverDoc =
          await _firestore.collection('users').doc(widget.receiverId).get();
      final fcmToken = receiverDoc.data()?['fcmToken'];

      if (fcmToken != null) {
        final notificationData = {
          'type': 'chat_message',
          'senderId': currentUserId,
          'senderName': senderName,
          'chatId': chatId,
          'message': message,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        };

        await sendPushNotificationFromFlutter(
          backendUrl: 'http://192.168.1.105:3000/send-notification',
          token: fcmToken,
          title: 'New message from $senderName',
          body: message,
          data: notificationData,
        );
      }

      // Add notification to Firestore for in-app notification center
      await NotificationService().addNotification(
        receiverId: widget.receiverId,
        senderId: currentUserId,
        type: 'message',
        title: 'New message from $senderName',
        content: message,
        additionalData: {
          'chatId': chatId,
          'senderId': currentUserId,
        },
      );
    } catch (e) {
      print('Error sending message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.blueGrey[900],
        title: Text(widget.receiverName),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('chats')
                  .where('chatId', isEqualTo: chatId)
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, messageSnapshot) {
                if (messageSnapshot.hasError) {
                  return Center(child: Text('Error: ${messageSnapshot.error}'));
                }
                if (!messageSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = messageSnapshot.data!.docs;

                if (messages.isEmpty) {
                  return const Center(
                    child: Text(
                      'Send your first message!',
                      style: TextStyle(color: Colors.white54),
                    ),
                  );
                }

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message =
                        messages[index].data() as Map<String, dynamic>;
                    final isSentByMe = message['senderId'] == currentUserId;

                    // Handle Firestore Timestamp or String
                    String timeString = '';
                    final ts = message['timestamp'];
                    if (ts != null) {
                      DateTime dt;
                      if (ts is Timestamp) {
                        dt = ts.toDate();
                      } else if (ts is String) {
                        dt = DateTime.tryParse(ts) ?? DateTime.now();
                      } else {
                        dt = DateTime.now();
                      }
                      timeString = dt.toLocal().toString().substring(11, 16);
                    }

                    return _buildMessageBubble(
                      message: message['content'],
                      isSentByMe: isSentByMe,
                      timestamp: timeString,
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            color: Colors.blueGrey[900],
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Write a message...',
                      hintStyle: TextStyle(color: Colors.white54),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: Colors.blue),
                  onPressed: sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble({
    required String message,
    required bool isSentByMe,
    required String timestamp,
  }) {
    return Align(
      alignment: isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment:
            isSentByMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.symmetric(vertical: 5),
            padding: EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: isSentByMe ? Colors.blue : Colors.grey[800],
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(message, style: TextStyle(color: Colors.white)),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8.0, left: 8.0, bottom: 2.0),
            child: Text(
              timestamp,
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
