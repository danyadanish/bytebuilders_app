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
  final TextEditingController _searchController = TextEditingController();

  // Helper to generate chatId
  String _getChatId(String userId1, String userId2) {
    final ids = [userId1, userId2]..sort();
    return ids.join('_');
  }

  Stream<List<Map<String, dynamic>>> _getLatestChats() {
    final currentUserId = _auth.currentUser!.uid;
    return _firestore.collection('chats').snapshots().map((snapshot) {
      // Filter messages where currentUser is sender or receiver
      final allMessages = snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .where((msg) =>
              msg['senderId'] == currentUserId ||
              msg['receiverId'] == currentUserId)
          .toList();

      // Group by chatId and get the latest message per chat
      final Map<String, Map<String, dynamic>> latestByChatId = {};
      for (var msg in allMessages) {
        final chatId = msg['chatId'];
        if (!latestByChatId.containsKey(chatId) ||
            (msg['timestamp'] != null &&
                (latestByChatId[chatId]?['timestamp'] == null ||
                    (msg['timestamp'] as Timestamp).millisecondsSinceEpoch >
                        (latestByChatId[chatId]?['timestamp'] as Timestamp)
                            .millisecondsSinceEpoch))) {
          latestByChatId[chatId] = msg;
        }
      }
      // Sort by timestamp descending
      final chats = latestByChatId.values.toList();
      chats.sort((a, b) {
        final aTime = a['timestamp'] as Timestamp?;
        final bTime = b['timestamp'] as Timestamp?;
        return (bTime?.millisecondsSinceEpoch ?? 0)
            .compareTo(aTime?.millisecondsSinceEpoch ?? 0);
      });
      return chats;
    });
  }

  Future<String?> _getUserRole(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.data()?['role'] as String?;
  }

  Widget _buildBottomNavBar(BuildContext context, String userRole) {
    List<BottomNavigationBarItem> items;
    int currentIndex = 1; // 1 = Chat

    void onTap(int index) {
      if (userRole == 'citizen') {
        switch (index) {
          case 0:
            Navigator.pushReplacementNamed(context, '/citizen-feed');
            break;
          case 1:
            // Already on Chat
            break;
          case 2:
            Navigator.pushReplacementNamed(context, '/emergency');
            break;
          case 3:
            Navigator.pushReplacementNamed(context, '/report');
            break;
          case 4:
            Navigator.pushReplacementNamed(context, '/notifications');
            break;
        }
      }
    }

    if (userRole == 'citizen') {
      items = const [
        BottomNavigationBarItem(
            icon: Icon(Icons.collections_bookmark), label: 'Feed'),
        BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline_rounded), label: 'Chat'),
        BottomNavigationBarItem(icon: Icon(Icons.phone), label: 'Emergency'),
        BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Report'),
        BottomNavigationBarItem(
            icon: Icon(Icons.notifications), label: 'Notifications'),
      ];
    } else {
      // No navbar for advertisers or unknown roles
      return const SizedBox.shrink();
    }

    return BottomNavigationBar(
      backgroundColor: const Color(0xFF161B33),
      selectedItemColor: Colors.blue,
      unselectedItemColor: Colors.grey,
      currentIndex: currentIndex,
      type: BottomNavigationBarType.fixed,
      items: items,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _auth.currentUser!.uid;

    return FutureBuilder<String?>(
      future: _getUserRole(currentUserId),
      builder: (context, snapshot) {
        final userRole = snapshot.data ?? 'citizen'; // default to citizen
        return Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/khaberny_background.png',
                fit: BoxFit.cover,
              ),
            ),
            Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                title: Text(
                  'My Chats',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                centerTitle: true,
              ),
              body: Column(
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search chats...',
                        hintStyle: TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: Colors.white10,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        prefixIcon: Icon(Icons.search, color: Colors.white54),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear, color: Colors.white54),
                                onPressed: () {
                                  setState(() {
                                    _searchQuery = '';
                                    _searchController.clear();
                                  });
                                },
                              )
                            : null,
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: StreamBuilder<List<Map<String, dynamic>>>(
                      stream: _getLatestChats(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Center(
                              child: Text('Error: ${snapshot.error}'));
                        }

                        if (!snapshot.hasData) {
                          return Center(child: CircularProgressIndicator());
                        }

                        final chats = snapshot.data!;

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
                            final chat = chats[index];
                            final lastMessage = chat['content'] ?? '';
                            final lastMessageTime = chat['timestamp'] != null
                                ? (chat['timestamp'] as Timestamp).toDate()
                                : DateTime.now();

                            // Figure out the other participant
                            final participants = chat['chatId'].split('_');
                            final otherParticipantId = participants
                                .firstWhere((id) => id != currentUserId);

                            return FutureBuilder<DocumentSnapshot>(
                              future: _firestore
                                  .collection('users')
                                  .doc(otherParticipantId)
                                  .get(),
                              builder: (context, userSnapshot) {
                                String otherName = 'Unknown User';
                                if (userSnapshot.hasData &&
                                    userSnapshot.data!.exists) {
                                  final userData = userSnapshot.data!.data()
                                      as Map<String, dynamic>?;
                                  otherName =
                                      userData?['name'] ?? 'Unknown User';
                                }
                                // Search filter
                                if (_searchQuery.isNotEmpty &&
                                    !otherName
                                        .toLowerCase()
                                        .contains(_searchQuery.toLowerCase())) {
                                  return SizedBox.shrink();
                                }
                                return Card(
                                  color: Colors.black26,
                                  margin: EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: Color(0xFF6C91BF),
                                      child: Icon(Icons.person,
                                          color: Color(0xFFFEFCFB)),
                                    ),
                                    title: Text(
                                      otherName,
                                      style:
                                          TextStyle(color: Color(0xFFFEFCFB)),
                                    ),
                                    subtitle: Text(
                                      lastMessage,
                                      style: TextStyle(color: Colors.white70),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    trailing: Text(
                                      '${lastMessageTime.hour}:${lastMessageTime.minute.toString().padLeft(2, '0')}',
                                      style:
                                          TextStyle(color: Color(0xFF6C91BF)),
                                    ),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ChatPage(
                                            receiverId: otherParticipantId,
                                            receiverName: otherName,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
              floatingActionButton: FloatingActionButton(
                backgroundColor: Colors.blue,
                child: Icon(Icons.chat),
                onPressed: () async {
                  String? selectedUserId;
                  String? selectedUserName;

                  await showDialog(
                    context: context,
                    builder: (context) {
                      String search = '';
                      return StatefulBuilder(
                        builder: (context, setState) {
                          return AlertDialog(
                            title: Text('Start New Chat'),
                            content: SizedBox(
                              width: double.maxFinite,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextField(
                                    decoration: InputDecoration(
                                        hintText: 'Search users'),
                                    onChanged: (value) =>
                                        setState(() => search = value),
                                  ),
                                  SizedBox(height: 10),
                                  Expanded(
                                    child: StreamBuilder<QuerySnapshot>(
                                      stream: _firestore
                                          .collection('users')
                                          .where('uid',
                                              isNotEqualTo: currentUserId)
                                          .snapshots(),
                                      builder: (context, snapshot) {
                                        if (!snapshot.hasData) {
                                          return Center(
                                              child:
                                                  CircularProgressIndicator());
                                        }
                                        final users = snapshot.data!.docs
                                            .map((doc) => doc.data()
                                                as Map<String, dynamic>)
                                            .where((user) => (user['name'] ??
                                                    '')
                                                .toLowerCase()
                                                .contains(search.toLowerCase()))
                                            .toList();
                                        if (users.isEmpty) {
                                          return Text('No users found');
                                        }
                                        return ListView.builder(
                                          shrinkWrap: true,
                                          itemCount: users.length,
                                          itemBuilder: (context, index) {
                                            final user = users[index];
                                            return ListTile(
                                              title: Text(
                                                  user['name'] ?? 'Unknown'),
                                              onTap: () {
                                                selectedUserId = user['uid'];
                                                selectedUserName = user['name'];
                                                Navigator.pop(context);
                                              },
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text('Cancel'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  );

                  if (selectedUserId != null && selectedUserName != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatPage(
                          receiverId: selectedUserId!,
                          receiverName: selectedUserName!,
                        ),
                      ),
                    );
                  }
                },
              ),
              bottomNavigationBar: userRole == 'citizen'
                  ? _buildBottomNavBar(context, userRole)
                  : null, // Only show for citizen,
            ),
          ],
        );
      },
    );
  }
}
