// lib/screens/government_problem_reports_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GovernmentProblemReportsScreen extends StatefulWidget {
  const GovernmentProblemReportsScreen({super.key});

  @override
  State<GovernmentProblemReportsScreen> createState() => _GovernmentProblemReportsScreenState();
}

class _GovernmentProblemReportsScreenState extends State<GovernmentProblemReportsScreen> {
  Future<void> _markAsSolved(String postId) async {
    await FirebaseFirestore.instance.collection('posts').doc(postId).update({
      'status': 'Solved',
      'solutionReason': '',
    });
  }

  Future<void> _markAsNotSolved(String postId) async {
    final reasonController = TextEditingController();

    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Why is it not solved?'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(hintText: 'Enter the reason'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, reasonController.text.trim()), child: const Text('Submit')),
        ],
      ),
    );

    if (reason != null && reason.isNotEmpty) {
      await FirebaseFirestore.instance.collection('posts').doc(postId).update({
        'status': 'Not Solved',
        'solutionReason': reason,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B203D),
      appBar: AppBar(
        title: const Text('Reported Problems'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .where('type', isEqualTo: 'problem')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final problems = snapshot.data!.docs;

          return ListView.builder(
            itemCount: problems.length,
            itemBuilder: (context, index) {
              final post = problems[index];
              final data = post.data() as Map<String, dynamic>;
              final postId = post.id;
              final content = data['content'] ?? '';
              final imageUrl = data['imageUrl'] ?? '';
              final username = data['authorName'] ?? 'Citizen';
              final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
              final status = data['status'];
              final reason = data['solutionReason'];

              return Card(
                color: Colors.white10,
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('By: $username', style: const TextStyle(color: Colors.white70)),
                      const SizedBox(height: 6),
                      if (createdAt != null)
                        Text(
                          createdAt.toLocal().toString().split(' ')[0],
                          style: const TextStyle(fontSize: 12, color: Colors.white60),
                        ),
                      const SizedBox(height: 10),
                      Text(content, style: const TextStyle(color: Colors.white, fontSize: 16)),
                      if (imageUrl.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(imageUrl),
                          ),
                        ),
                      const SizedBox(height: 10),
                      if (status != null)
                        Text(
                          status == 'Solved'
                              ? '✅ Solved'
                              : '❌ Not Solved\nReason: ${reason ?? "N/A"}',
                          style: const TextStyle(color: Colors.orangeAccent),
                        ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: () => _markAsSolved(postId),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                            child: const Text('Mark as Solved'),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: () => _markAsNotSolved(postId),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                            child: const Text('Mark as Not Solved'),
                          ),
                        ],
                      )
                    ],
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