import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PollDetailScreen extends StatelessWidget {
  final String pollId;

  const PollDetailScreen({super.key, required this.pollId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B203D),
      appBar: AppBar(
        title: const Text("Poll Results"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future:
            FirebaseFirestore.instance.collection('posts').doc(pollId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
                child: Text("Poll not found",
                    style: TextStyle(color: Colors.white70)));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final question = data['question'] ?? 'Untitled';
          final options = List<String>.from(data['options'] ?? []);
          final votes = List<int>.from(data['votes'] ?? []);

          final totalVotes = votes.fold(0, (a, b) => a + b);
          final maxVotes =
              votes.isEmpty ? 0 : votes.reduce((a, b) => a > b ? a : b);

          final topOptions = <String>[];
          for (int i = 0; i < votes.length; i++) {
            if (votes[i] == maxVotes && maxVotes > 0) {
              topOptions.add(options[i]);
            }
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(question,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  ...List.generate(options.length, (i) {
                    final percent =
                        totalVotes == 0 ? 0.0 : (votes[i] / totalVotes) * 100;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(options[i],
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 16)),
                        const SizedBox(height: 6),
                        Stack(
                          children: [
                            Container(
                              height: 22,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white12,
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            Container(
                              height: 22,
                              width: MediaQuery.of(context).size.width *
                                  (percent / 100),
                              decoration: BoxDecoration(
                                color: votes[i] == maxVotes && totalVotes > 0
                                    ? Colors.greenAccent
                                    : Colors.blueAccent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${votes[i]} vote${votes[i] == 1 ? '' : 's'} (${percent.toStringAsFixed(1)}%)",
                          style: const TextStyle(color: Colors.white54),
                        ),
                        const SizedBox(height: 16),
                      ],
                    );
                  }),
                  const SizedBox(height: 16),
                  if (totalVotes == 0)
                    const Text("No votes yet.",
                        style: TextStyle(color: Colors.white70, fontSize: 16))
                  else
                    Text(
                      topOptions.length == 1
                          ? "🏆 Top option: ${topOptions.first}"
                          : "🤝 Tie between: ${topOptions.join(', ')}",
                      style: const TextStyle(
                          color: Colors.greenAccent, fontSize: 18),
                    ),
                  const SizedBox(height: 8),
                  Text("Total votes: $totalVotes",
                      style:
                          const TextStyle(color: Colors.white38, fontSize: 14)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
