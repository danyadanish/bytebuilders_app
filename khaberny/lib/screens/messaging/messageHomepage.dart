import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MessageHomepage extends StatefulWidget {
  const MessageHomepage({super.key});

  @override
  _MessageHomepageState createState() => _MessageHomepageState();
}

class _MessageHomepageState extends State<MessageHomepage> {
  int _currentIndex = 2; // Default to Chat tab

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Chats'),
        actions: [
          IconButton(
            icon: Icon(Icons.create, color: Color(0xFFFEFCFB)),
            onPressed: () {
              // Handle create new message
              print('Create new message');
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: SvgPicture.asset(
              'assets\background text.svg', // Update with your SVG file path
              fit: BoxFit.cover,
            ),
          ),
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search messages...',
                    hintStyle: TextStyle(color: Color(0xFFFEFCFB)),
                    prefixIcon: Icon(Icons.search, color: Color(0xFF6C91BF)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide(
                        color: Color(0xFF6C91BF),
                        width: 1.0,
                      ),
                    ),
                  ),
                  onChanged: (value) {
                    // Handle search logic
                    print('Searching: $value');
                  },
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: 10, // Replace with actual chat count
                  itemBuilder: (context, index) {
                    return Opacity(
                      opacity: 0.8,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Color(0xFF6C91BF),
                          child: Icon(Icons.person, color: Color(0xFFFEFCFB)),
                        ),
                        title: Text(
                          'User $index',
                          style: TextStyle(color: Color(0xFFFEFCFB)),
                        ),
                        trailing: Text(
                          '12:00 PM',
                          style: TextStyle(color: Color(0xFF6C91BF)),
                        ),
                        subtitle: Text('Last message preview...'),
                        onTap: () {
                          // Handle chat tap
                          print('Tapped on chat $index');
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Color(0xFF161B33),
        selectedFontSize: 14,
        unselectedFontSize: 12,
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        showSelectedLabels: true,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          // Handle navigation
          print('Navigated to index $index');
        },
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
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
