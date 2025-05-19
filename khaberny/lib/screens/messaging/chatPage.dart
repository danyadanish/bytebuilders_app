import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../notificationservice.dart';
import '../../notifications.dart';

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
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _setupMessaging();
  }

  Future<void> _setupMessaging() async {
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<void> sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final String currentUserId = _auth.currentUser!.uid;
    final String message = _messageController.text;
    _messageController.clear();

    try {
      // Get or create chat document
      final chatQuery = await _firestore
          .collection('chats')
          .where('participants', arrayContains: currentUserId)
          .where('participantId', isEqualTo: widget.receiverId)
          .get();

      String chatDocId;

      if (chatQuery.docs.isEmpty) {
        final newChatDoc = await _firestore.collection('chats').add({
          'participants': [currentUserId, widget.receiverId],
          'participantId': widget.receiverId,
          'participantName': widget.receiverName,
          'lastMessage': message,
          'lastMessageTime': DateTime.now().toIso8601String(),
        });
        chatDocId = newChatDoc.id;
      } else {
        chatDocId = chatQuery.docs.first.id;
        await chatQuery.docs.first.reference.update({
          'lastMessage': message,
          'lastMessageTime': DateTime.now().toIso8601String(),
        });
      }

      // Add message to subcollection
      await _firestore
          .collection('chats')
          .doc(chatDocId)
          .collection('messages')
          .add({
        'senderId': currentUserId,
        'receiverId': widget.receiverId,
        'content': message,
        'timestamp': DateTime.now().toIso8601String(),
      });

      // Send notification
      final userDoc =
          await _firestore.collection('users').doc(currentUserId).get();
      final senderName = userDoc.data()?['name'] ?? 'Unknown User';

      final receiverDoc =
          await _firestore.collection('users').doc(widget.receiverId).get();
      final fcmToken = receiverDoc.data()?['fcmToken'];

      if (fcmToken != null) {
        await _notificationService.addNotification(Notifications(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          userId: widget.receiverId,
          title: 'New message from $senderName',
          status: 'unread',
          timestamp: DateTime.now(),
          isRead: false,
          type: 'message',
          sourceType: 'user',
          sourceId: currentUserId,
          sourceName: senderName,
          actionType: 'open_chat',
          reason: null,
        ));

        await _sendFCMNotification(
          token: fcmToken,
          title: 'New Message',
          body: '$senderName: $message',
          data: {
            'type': 'message',
            'chatId': chatDocId,
            'senderId': currentUserId,
            'senderName': senderName,
          },
        );
      }
    } catch (e) {
      print('Error sending message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message. Please try again.')),
        );
      }
    }
  }

  Future<void> _sendFCMNotification({
    required String token,
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization':
              'key=YOUR_FCM_SERVER_KEY', // Replace with your FCM server key
        },
        body: jsonEncode({
          'to': token,
          'notification': {
            'title': title,
            'body': body,
            'sound': 'default',
          },
          'data': data,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to send FCM notification');
      }
    } catch (e) {
      print('Error sending FCM notification: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _auth.currentUser!.uid;

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
              stream: _firestore.collection('chats').where('participants',
                  arrayContainsAny: [
                    currentUserId,
                    widget.receiverId
                  ]).snapshots(),
              builder: (context, chatSnapshot) {
                if (chatSnapshot.hasError) {
                  return Center(child: Text('Error: ${chatSnapshot.error}'));
                }

                if (!chatSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Find the correct chat document
                final chatDocs = chatSnapshot.data!.docs.where(
                  (doc) {
                    final participants = List<String>.from(doc['participants']);
                    return participants.contains(currentUserId) &&
                        participants.contains(widget.receiverId);
                  },
                ).toList();

                if (chatDocs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No messages yet. Start a conversation!',
                      style: TextStyle(color: Colors.white54),
                    ),
                  );
                }
                final chatDoc = chatDocs.first;

                return StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('chats')
                      .doc(chatDoc.id)
                      .collection('messages')
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, messageSnapshot) {
                    if (messageSnapshot.hasError) {
                      return Center(
                          child: Text('Error: ${messageSnapshot.error}'));
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

                        return _buildMessageBubble(
                          message: message['content'],
                          isSentByMe: isSentByMe,
                          timestamp: DateTime.parse(message['timestamp'])
                              .toLocal()
                              .toString()
                              .substring(11, 16),
                        );
                      },
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
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.thumb_up, color: Colors.white54, size: 16),
              SizedBox(width: 5),
              Icon(Icons.help_outline, color: Colors.white54, size: 16),
              SizedBox(width: 10),
              Text(
                timestamp,
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
