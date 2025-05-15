import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'poll_detail_screen.dart';

class PollListScreen extends StatelessWidget {
  const PollListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B203D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text("Available Polls", style: TextStyle(color: Colors.white)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .where('type', isEqualTo: 'poll')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error loading polls: ${snapshot.error}",
                style: const TextStyle(color: Colors.redAccent),
              ),
            );
          }

          final polls = snapshot.data?.docs ?? [];

          if (polls.isEmpty) {
            return const Center(
              child: Text("No polls available.", style: TextStyle(color: Colors.white70)),
            );
          }

          return ListView.builder(
            itemCount: polls.length,
            itemBuilder: (context, index) {
              final pollDoc = polls[index];
              final poll = pollDoc.data() as Map<String, dynamic>;
              final pollId = pollDoc.id;
              final createdAt = (poll['createdAt'] as Timestamp?)?.toDate();

              return Card(
                color: Colors.white10,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  title: Text(
                    poll['question'] ?? 'Untitled',
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    createdAt != null
                        ? "🕒 ${createdAt.day}/${createdAt.month}/${createdAt.year}"
                        : '',
                    style: const TextStyle(color: Colors.white54),
                  ),
                  trailing: const Icon(Icons.poll, color: Colors.white70),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PollDetailScreen(pollId: pollId),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
