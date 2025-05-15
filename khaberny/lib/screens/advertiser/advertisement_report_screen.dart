import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';

class AdReportScreen extends StatelessWidget {
  final String postId; // Post ID from 'posts' collection

  const AdReportScreen({super.key, required this.postId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('posts').doc(postId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            backgroundColor: Color(0xFF1B203D),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>?;
        if (data == null) {
          return const Scaffold(
            backgroundColor: Color(0xFF1B203D),
            body: Center(child: Text("No data found", style: TextStyle(color: Colors.white))),
          );
        }

        final int views = (data['viewers'] as List?)?.length ?? 0;
        final int likes = (data['likes'] as List?)?.length ?? 0;
        final int dislikes = (data['dislikes'] as List?)?.length ?? 0;
        final String imageUrl = data['imageUrl'] ?? '';
        final String content = data['content'] ?? '';
        final String author = data['authorName'] ?? 'Unknown';

        final int totalVotes = likes + dislikes;
        final double likePercentage = totalVotes == 0 ? 0 : likes / totalVotes;

        return Scaffold(
          backgroundColor: const Color(0xFF1B203D),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            title: const Text(
              "Advertisement Report",
              style: TextStyle(color: Colors.white),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        imageUrl,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Container(width: 100, height: 100, color: Colors.grey.shade700, child: const Icon(Icons.image, color: Colors.white)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(author, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                          const SizedBox(height: 4),
                          Text(content, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold), maxLines: 4, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildMetricBox("Views", views),
                    _buildMetricBox("Likes", likes),
                    _buildMetricBox("Dislikes", dislikes),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Text("Likes vs Dislikes", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      CircularPercentIndicator(
                        radius: 60.0,
                        lineWidth: 12.0,
                        percent: likePercentage,
                        center: Text("${(likePercentage * 100).toStringAsFixed(0)}%", style: const TextStyle(color: Colors.white)),
                        progressColor: Colors.greenAccent,
                        backgroundColor: Colors.redAccent,
                        circularStrokeCap: CircularStrokeCap.round,
                        animation: true,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildLegend(Colors.greenAccent, 'Likes: $likes'),
                          const SizedBox(width: 16),
                          _buildLegend(Colors.redAccent, 'Dislikes: $dislikes'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text("Feedback Summary", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                  _generateFeedbackMessage(likes, dislikes),
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text("Back"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetricBox(String label, int count) {
    return Container(
      width: 100,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(count.toString(), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildLegend(Color color, String label) {
    return Row(
      children: [
        CircleAvatar(radius: 6, backgroundColor: color),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  String _generateFeedbackMessage(int likes, int dislikes) {
    if (likes == 0 && dislikes == 0) return "No feedback received yet.";
    if (likes > dislikes) return "Users mostly liked this advertisement.";
    if (dislikes > likes) return "Users mostly disliked this advertisement.";
    return "User feedback is balanced.";
  }
}