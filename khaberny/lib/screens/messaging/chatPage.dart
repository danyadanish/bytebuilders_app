import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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

  void sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final String currentUserId = _auth.currentUser!.uid;
    final String message = _messageController.text;
    _messageController.clear();

    try {
      // First, get or create the chat document
      final chatQuery = await _firestore
          .collection('chats')
          .where('participants', arrayContains: currentUserId)
          .where('participantId', isEqualTo: widget.receiverId)
          .get();

      String chatDocId;

      if (chatQuery.docs.isEmpty) {
        // Create new chat if it doesn't exist
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
        // Update existing chat
        await chatQuery.docs.first.reference.update({
          'lastMessage': message,
          'lastMessageTime': DateTime.now().toIso8601String(),
        });
      }

      // Add the message to messages subcollection
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
    } catch (e) {
      print('Error sending message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message. Please try again.')),
      );
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
              stream: _firestore
                  .collection('chats')
                  .where('participants', arrayContains: currentUserId)
                  .where('participantId', isEqualTo: widget.receiverId)
                  .snapshots(),
              builder: (context, chatSnapshot) {
                if (chatSnapshot.hasError) {
                  return Center(child: Text('Error: ${chatSnapshot.error}'));
                }

                if (!chatSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Even if there are no chats yet, we should still show an empty state
                if (chatSnapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No messages yet. Start a conversation!',
                      style: TextStyle(color: Colors.white54),
                    ),
                  );
                }

                final chatDocId = chatSnapshot.data!.docs.first.id;

                return StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('chats')
                      .doc(chatDocId)
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
