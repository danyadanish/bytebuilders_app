import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chatPage.dart';

class MessageHomepage extends StatefulWidget {
  const MessageHomepage({super.key});

  @override
  _MessageHomepageState createState() => _MessageHomepageState();
}

class _MessageHomepageState extends State<MessageHomepage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _searchQuery = '';
  int _currentIndex = 2;

  Stream<QuerySnapshot> _getChats() {
    final currentUserId = _auth.currentUser!.uid;
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }

  Future<void> _createNewChat(BuildContext context) async {
    final users = await _firestore
        .collection('users')
        .where('uid', isNotEqualTo: _auth.currentUser!.uid)
        .get();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select User'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: users.docs.length,
            itemBuilder: (context, index) {
              final user = users.docs[index].data();
              // Use null coalescing to handle missing fields
              final String userId = user['uid'] ?? '';
              final String userName = user['name'] ?? 'Unknown User';

              return ListTile(
                title: Text(userName),
                onTap: () async {
                  // Create chat document first
                  final chatDocRef = await _firestore.collection('chat').add({
                    'participants': [_auth.currentUser!.uid, userId],
                    'participantId': userId,
                    'participantName': userName,
                    'lastMessage': '',
                    'lastMessageTime': DateTime.now().toIso8601String(),
                  });

                  if (!mounted) return;
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatPage(
                        receiverId: userId,
                        receiverName: userName,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _onNavigationTap(int index) {
    setState(() {
      _currentIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/citizenHome');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/feed');
        break;
      case 2:
        // Already on chat page
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/report');
        break;
      case 4:
        Navigator.pushReplacementNamed(context, '/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B203D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('My Chats'),
        actions: [
          IconButton(
            icon: Icon(Icons.create, color: Color(0xFFFEFCFB)),
            onPressed: () => _createNewChat(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search messages...',
                hintStyle: TextStyle(color: Color(0xFFFEFCFB)),
                prefixIcon: Icon(Icons.search, color: Color(0xFF6C91BF)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide(color: Color(0xFF6C91BF)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide(color: Color(0xFF6C91BF)),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getChats(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                final chats = snapshot.data!.docs;

                if (chats.isEmpty) {
                  return Center(
                    child: Text(
                      'No chats yet. Start a new conversation!',
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: chats.length,
                  itemBuilder: (context, index) {
                    final chat = chats[index].data() as Map<String, dynamic>;
                    final lastMessage = chat['lastMessage'] ?? '';
                    final lastMessageTime = chat['lastMessageTime'] != null
                        ? DateTime.parse(chat['lastMessageTime'])
                        : DateTime.now();

                    // Filter based on search query
                    if (_searchQuery.isNotEmpty &&
                        !chat['participantName']
                            .toString()
                            .toLowerCase()
                            .contains(_searchQuery.toLowerCase())) {
                      return SizedBox.shrink();
                    }

                    return Card(
                      color: Colors.black26,
                      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Color(0xFF6C91BF),
                          child: Icon(Icons.person, color: Color(0xFFFEFCFB)),
                        ),
                        title: Text(
                          chat['participantName'] ?? 'Unknown User',
                          style: TextStyle(color: Color(0xFFFEFCFB)),
                        ),
                        subtitle: Text(
                          lastMessage,
                          style: TextStyle(color: Colors.white70),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Text(
                          '${lastMessageTime.hour}:${lastMessageTime.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(color: Color(0xFF6C91BF)),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatPage(
                                receiverId: chat['participantId'],
                                receiverName: chat['participantName'],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Color(0xFF161B33),
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.collections_bookmark),
            label: 'Feed',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Reports',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        onTap: _onNavigationTap,
      ),
    );
  }
}
