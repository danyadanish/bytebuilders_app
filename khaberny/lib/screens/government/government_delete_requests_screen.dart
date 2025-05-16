import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GovernmentDeleteRequestsScreen extends StatefulWidget {
  const GovernmentDeleteRequestsScreen({super.key});

  @override
  State<GovernmentDeleteRequestsScreen> createState() => _GovernmentDeleteRequestsScreenState();
}

class _GovernmentDeleteRequestsScreenState extends State<GovernmentDeleteRequestsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B203D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Delete Requests",
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('deleteRequests')
            .where('status', isEqualTo: 'pending') // You can temporarily comment this out for debugging
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error: ${snapshot.error}",
                style: const TextStyle(color: Colors.redAccent),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("No delete requests found.", style: TextStyle(color: Colors.white70)),
            );
          }

          final requests = snapshot.data!.docs;

          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              final data = request.data() as Map<String, dynamic>;
              final postId = data['postId'];
              final advertiserId = data['advertiserId'];
              final requestId = request.id;

              return Card(
                color: Colors.white10,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  title: Text("Post ID: $postId", style: const TextStyle(color: Colors.white)),
                  subtitle: Text("Advertiser: $advertiserId", style: const TextStyle(color: Colors.white70)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check_circle, color: Colors.green),
                        tooltip: "Approve and Delete Post",
                        onPressed: () async {
                          try {
                            await FirebaseFirestore.instance.collection('posts').doc(postId).delete();
                            await FirebaseFirestore.instance
                                .collection('deleteRequests')
                                .doc(requestId)
                                .update({'status': 'approved'});

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Post deleted and request approved.")),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Error deleting post: $e")),
                            );
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.redAccent),
                        tooltip: "Deny Request",
                        onPressed: () async {
                          try {
                            await FirebaseFirestore.instance
                                .collection('deleteRequests')
                                .doc(requestId)
                                .update({'status': 'denied'});

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Delete request denied.")),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Error denying request: $e")),
                            );
                          }
                        },
                      ),
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
