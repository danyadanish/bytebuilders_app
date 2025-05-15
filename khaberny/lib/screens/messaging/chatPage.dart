import 'package:flutter/material.dart';

class ChatPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.blueGrey[900],
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: AssetImage(
                'assets/martina.jpg',
              ), // Replace with your image asset
            ),
            SizedBox(width: 10),
            Text('Martina Wolna'),
            Spacer(),
            CircleAvatar(
              backgroundImage: AssetImage(
                'assets/maciej.jpg',
              ), // Replace with your image asset
            ),
            SizedBox(width: 10),
            Text('Maciej Kowalski'),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(10),
              children: [
                _buildMessageBubble(
                  message: 'Hello, how are you?',
                  isSentByMe: true,
                  timestamp: '10:30 AM',
                ),
                _buildMessageBubble(
                  message: 'I\'m good, thanks! How about you?',
                  isSentByMe: false,
                  timestamp: '10:31 AM',
                ),
                _buildMessageBubble(
                  message: 'Here is my email: martina@example.com',
                  isSentByMe: true,
                  timestamp: '10:32 AM',
                ),
                _buildMessageBubble(
                  message: 'Thanks! Mine is maciej@example.com',
                  isSentByMe: false,
                  timestamp: '10:33 AM',
                ),
              ],
            ),
          ),
          _buildInputField(),
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

  Widget _buildInputField() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      color: Colors.blueGrey[900],
      child: Row(
        children: [
          Expanded(
            child: TextField(
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
            onPressed: () {
              // Handle send action
            },
          ),
        ],
      ),
    );
  }
}
