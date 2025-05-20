import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';



class CitizenFeedScreen extends StatefulWidget {
  const CitizenFeedScreen({super.key});

  @override
  State<CitizenFeedScreen> createState() => _CitizenFeedScreenState();
}

class _CitizenFeedScreenState extends State<CitizenFeedScreen> {
  final user = FirebaseAuth.instance.currentUser;
  final TextEditingController _postController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();
  final Map<String, TextEditingController> _commentControllers = {};
  final Map<String, Set<int>> multiSelections = {};
  final Map<String, int> singleSelections = {};
  final Map<String, bool> hasVoted = {};
  bool _showOnlyMyPosts = false;
  String? _editingPostId;

  @override
  void dispose() {
    _postController.dispose();
    _imageUrlController.dispose();
    _commentControllers.forEach((_, c) => c.dispose());
    super.dispose();
  }
  Future<void> _openCreatePostDialog({
    String? existingContent,
    String? existingImageUrl,
    String? postId,
  }) async {
    _postController.text = existingContent ?? '';
    _imageUrlController.text = existingImageUrl ?? '';
    _editingPostId = postId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1B203D),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: MediaQuery.of(context).viewInsets,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _postController,
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: "What's on your mind?",
                  hintStyle: TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Colors.white10,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _imageUrlController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: "Paste image URL (optional)",
                  hintStyle: TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Colors.white10,
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _submitPost,
                child: Text(_editingPostId != null ? "Update Post" : "Post"),
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitPost() async {
    final text = _postController.text.trim();
    final imageUrl = _imageUrlController.text.trim();
    if (text.isEmpty) return;

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
    final name = userDoc.data()?['name'] ?? 'Citizen';

    if (_editingPostId != null) {
      await FirebaseFirestore.instance.collection('posts').doc(_editingPostId).update({
        'content': text,
        'imageUrl': imageUrl,
      });
    } else {
      await FirebaseFirestore.instance.collection('posts').add({
        'authorId': user!.uid,
        'authorRole': 'citizen',
        'authorName': name,
        'content': text,
        'imageUrl': imageUrl,
        'createdAt': Timestamp.now(),
        'likes': [],
        'dislikes': [],
        'comments': [],
        'viewers': [],
        'type': text.toLowerCase().startsWith('poll:') ? 'poll' : 'post',
        'question': text.toLowerCase().startsWith('poll:') ? text.substring(5) : null,
        'options': text.toLowerCase().startsWith('poll:') ? ['Yes', 'No'] : null,
        'votes': text.toLowerCase().startsWith('poll:') ? [0, 0] : null,
        'voters': text.toLowerCase().startsWith('poll:') ? [] : null,
        'allowMultipleVotes': false,
      });
    }

    _editingPostId = null;
    _postController.clear();
    _imageUrlController.clear();
    Navigator.pop(context);
  }

  Future<void> _deletePost(String postId) async {
    final confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Post"),
        content: const Text("Are you sure you want to delete this post?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Delete")),
        ],
      ),
    );
    if (confirm == true) {
      await FirebaseFirestore.instance.collection('posts').doc(postId).delete();
    }
  }
  Future<void> _addComment(String postId, String commentText) async {
    if (commentText.trim().isEmpty) return;

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
    final name = userDoc.data()?['name'] ?? 'Citizen';

    final comment = {
      'userId': user!.uid,
      'username': name,
      'text': commentText.trim(),
      'timestamp': Timestamp.now(),
    };

    await FirebaseFirestore.instance.collection('posts').doc(postId).update({
      'comments': FieldValue.arrayUnion([comment])
    });

    setState(() => _commentControllers[postId]?.clear());
  }

  void _showCommentsDialog(List comments) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black87,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Comments", style: TextStyle(color: Colors.white, fontSize: 18)),
            const Divider(color: Colors.white24),
            SizedBox(
              height: 300,
              child: ListView.builder(
                itemCount: comments.length,
                itemBuilder: (context, index) {
                  final comment = comments[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(comment['username'] ?? 'Unknown', style: const TextStyle(color: Colors.white70)),
                        Text(comment['text'] ?? '', style: const TextStyle(color: Colors.white)),
                      ],
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<void> _submitVote(String postId, Map<String, dynamic> pollData) async {
    final allowMultiple = pollData['allowMultipleVotes'] ?? false;
    final userId = user!.uid;

    final selected = allowMultiple
        ? multiSelections[postId]
        : singleSelections[postId] != null
            ? {singleSelections[postId]!}
            : null;

    if (selected == null || selected.isEmpty) return;

    final voters = List<String>.from(pollData['voters'] ?? []);
    if (voters.contains(userId)) return;

    final votes = List<int>.from(pollData['votes'] ?? []);
    for (var index in selected) {
      votes[index]++;
    }

    voters.add(userId);

    await FirebaseFirestore.instance.collection('posts').doc(postId).update({
      'votes': votes,
      'voters': voters,
    });

    setState(() => hasVoted[postId] = true);
  }

  Future<void> _incrementView(String postId) async {
    final ref = FirebaseFirestore.instance.collection('posts').doc(postId);
    final snapshot = await ref.get();
    final data = snapshot.data();
    final viewers = List<String>.from(data?['viewers'] ?? []);
    if (!viewers.contains(user!.uid)) {
      await ref.update({'viewers': FieldValue.arrayUnion([user!.uid])});
    }
  }

  void _showNotYourPostMessage() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1B203D),
        title: const Text("Access Denied", style: TextStyle(color: Colors.white)),
        content: const Text("You cannot delete or edit this post because it's not yours.",
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Okay", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  Future<void> _toggleLike(String postId, List likes, List dislikes) async {
    final ref = FirebaseFirestore.instance.collection('posts').doc(postId);
    if (likes.contains(user!.uid)) {
      await ref.update({'likes': FieldValue.arrayRemove([user!.uid])});
    } else {
      await ref.update({
        'likes': FieldValue.arrayUnion([user!.uid]),
        'dislikes': FieldValue.arrayRemove([user!.uid])
      });
    }
  }

  Future<void> _toggleDislike(String postId, List likes, List dislikes) async {
    final ref = FirebaseFirestore.instance.collection('posts').doc(postId);
    if (dislikes.contains(user!.uid)) {
      await ref.update({'dislikes': FieldValue.arrayRemove([user!.uid])});
    } else {
      await ref.update({
        'dislikes': FieldValue.arrayUnion([user!.uid]),
        'likes': FieldValue.arrayRemove([user!.uid])
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/images/khaberny_background.png',
            fit: BoxFit.cover,
          ),
        ),
        Scaffold(
          extendBodyBehindAppBar: true,
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            title: const Text(
              "khaberny",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(_showOnlyMyPosts ? Icons.list : Icons.person, color: Colors.grey),
                onPressed: () => setState(() => _showOnlyMyPosts = !_showOnlyMyPosts),
              )
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: InkWell(
                    onTap: () => _openCreatePostDialog(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white12,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.edit, color: Colors.white70),
                          SizedBox(width: 10),
                          Text("Hello, What’s on your mind ?", style: TextStyle(color: Colors.white70)),
                        ],
                      ),
                    ),
                  ),
                ),
                const Divider(color: Colors.white24),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('posts')
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                      final posts = snapshot.data!.docs;
                      final filtered = _showOnlyMyPosts
                          ? posts.where((doc) => (doc.data() as Map<String, dynamic>)['authorId'] == user?.uid).toList()
                          : posts;

                      return ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final post = filtered[index];
                          final data = post.data() as Map<String, dynamic>;
                          final postId = post.id;
                          final content = data['content'] ?? '';
                          final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
                          final likes = List<String>.from(data['likes'] ?? []);
                          final dislikes = List<String>.from(data['dislikes'] ?? []);
                          final viewers = List<String>.from(data['viewers'] ?? []);
                          final comments = List.from(data['comments'] ?? []);
                          final imageUrl = data['imageUrl'] ?? '';
                          final commentController = _commentControllers.putIfAbsent(postId, () => TextEditingController());
                          final userVoted = List<String>.from(data['voters'] ?? []).contains(user?.uid);
                          final username = data['authorName'] ?? 'Citizen';

                          return Dismissible(
                            key: ValueKey(postId),
                            background: Container(
                              color: Colors.blueAccent,
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.only(left: 20),
                              child: const Icon(Icons.edit, color: Colors.white),
                            ),
                            secondaryBackground: Container(
                              color: Colors.red,
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              child: const Icon(Icons.delete, color: Colors.white),
                            ),
                            confirmDismiss: (direction) async {
                              if (user!.uid != data['authorId']) {
                                _showNotYourPostMessage();
                                return false;
                              }
                              if (direction == DismissDirection.endToStart) {
                                await _deletePost(postId);
                              } else if (direction == DismissDirection.startToEnd) {
                                _openCreatePostDialog(
                                  existingContent: content,
                                  existingImageUrl: imageUrl,
                                  postId: postId,
                                );
                              }
                              return false;
                            },
                            child: GestureDetector(
                              onTap: () => _incrementView(postId),
                              child: Card(
                                color: const Color.fromARGB(198, 85, 95, 111),
                                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const CircleAvatar(radius: 16, backgroundImage: AssetImage('assets/avatar.png')),
                                          const SizedBox(width: 8),
                                          Text(username, style: const TextStyle(color: Colors.white)),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        createdAt != null
                                            ? createdAt.toLocal().toString().split(' ')[0]
                                            : "Date Unknown",
                                        style: const TextStyle(fontSize: 12, color: Colors.white60),
                                      ),
                                      const SizedBox(height: 10),
                                      if (data['type'] == 'poll') ...[
                                        Text(data['question'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 16)),
                                        const SizedBox(height: 8),
                                        ...List.generate(List<String>.from(data['options'] ?? []).length, (i) {
                                          final options = List<String>.from(data['options']);
                                          final votes = List<int>.from(data['votes']);
                                          final totalVotes = votes.fold(0, (a, b) => a + b);
                                          final allowMultiple = data['allowMultipleVotes'] ?? false;
                                          final percent = totalVotes == 0 ? 0 : ((votes[i] / totalVotes) * 100).round();
                                          final isSelected = allowMultiple
                                              ? (multiSelections[postId] ?? {}).contains(i)
                                              : singleSelections[postId] == i;

                                          return Container(
                                            margin: const EdgeInsets.symmetric(vertical: 4),
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                            decoration: BoxDecoration(
                                              color: Colors.white10,
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Row(
                                              children: [
                                                if (!userVoted)
                                                  allowMultiple
                                                      ? Checkbox(
                                                          value: isSelected,
                                                          onChanged: (val) {
                                                            setState(() {
                                                              multiSelections.putIfAbsent(postId, () => <int>{});
                                                              if (val == true) {
                                                                multiSelections[postId]!.add(i);
                                                              } else {
                                                                multiSelections[postId]!.remove(i);
                                                              }
                                                            });
                                                          },
                                                          activeColor: Colors.greenAccent,
                                                        )
                                                      : Radio(
                                                          value: i,
                                                          groupValue: singleSelections[postId],
                                                          onChanged: (val) => setState(() => singleSelections[postId] = i),
                                                          activeColor: Colors.greenAccent,
                                                        )
                                                else
                                                  const Icon(Icons.check_circle, color: Colors.greenAccent),
                                                const SizedBox(width: 6),
                                                Expanded(child: Text(options[i], style: const TextStyle(color: Colors.white))),
                                                Text("$percent%", style: const TextStyle(color: Colors.white54)),
                                                const SizedBox(width: 8),
                                                Text("${votes[i]}", style: const TextStyle(color: Colors.white38)),
                                              ],
                                            ),
                                          );
                                        }),
                                        if (!userVoted)
                                          Center(
                                            child: ElevatedButton(
                                              onPressed: () => _submitVote(postId, data),
                                              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                                              child: const Text("Submit Vote"),
                                            ),
                                          )
                                        else
                                          const Center(
                                            child: Text("You already voted", style: TextStyle(color: Colors.greenAccent)),
                                          ),
                                      ] else if (data['type'] == 'problem') ...[
                                            Text(content, style: const TextStyle(fontSize: 16, color: Colors.white)),

                                            if (imageUrl.isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets.only(top: 8.0),
                                                child: ClipRRect(
                                                  borderRadius: BorderRadius.circular(8),
                                                  child: Image.network(imageUrl, fit: BoxFit.cover),
                                                ),
                                              ),

                                            if (data['latitude'] != null && data['longitude'] != null)
                                              Container(
                                                height: 200,
                                                margin: const EdgeInsets.only(top: 10),
                                                child: ClipRRect(
                                                  borderRadius: BorderRadius.circular(12),
                                                  child: FlutterMap(
                                                    options: MapOptions(
                                                      initialCenter: LatLng(data['latitude'], data['longitude']),
                                                      initialZoom: 15,
                                                      interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
                                                    ),
                                                    children: [
                                                      TileLayer(
                                                        urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                                                        subdomains: const ['a', 'b', 'c'],
                                                      ),
                                                      MarkerLayer(
                                                        markers: [
                                                          Marker(
                                                            point: LatLng(data['latitude'], data['longitude']),
                                                            width: 40,
                                                            height: 40,
                                                            child: const Icon(Icons.location_on, color: Colors.red, size: 30),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),

                                            // ✅ Status block — shows only if government added status
                                            if (data['status'] != null)
                                              Container(
                                                margin: const EdgeInsets.only(top: 8),
                                                padding: const EdgeInsets.all(10),
                                                decoration: BoxDecoration(
                                                  color: data['status'] == 'Solved'
                                                      ? Colors.green.withOpacity(0.2)
                                                      : Colors.red.withOpacity(0.2),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      "Status: ${data['status']}",
                                                      style: TextStyle(
                                                        color: data['status'] == 'Solved' ? Colors.green : Colors.red,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                    if (data['solutionReason'] != null && data['solutionReason'].toString().isNotEmpty)
                                                      Text(
                                                        "Reason: ${data['solutionReason']}",
                                                        style: const TextStyle(color: Colors.white),
                                                      ),
                                                  ],
                                                ),
                                              ),

                                      ] else ...[
                                        Text(content, style: const TextStyle(fontSize: 16, color: Colors.white)),
                                        if (imageUrl.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 8.0),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(8),
                                              child: Image.network(imageUrl, fit: BoxFit.cover),
                                            ),
                                          ),
                                      ],

                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: Icon(
                                              likes.contains(user!.uid) ? Icons.favorite : Icons.favorite_border,
                                              color: Colors.red,
                                            ),
                                            onPressed: () => _toggleLike(postId, likes, dislikes),
                                          ),
                                          Text('${likes.length}', style: const TextStyle(color: Colors.white70)),
                                          const SizedBox(width: 12),
                                          IconButton(
                                            icon: const Icon(Icons.thumb_down, color: Colors.white38),
                                            onPressed: () => _toggleDislike(postId, likes, dislikes),
                                          ),
                                          Text('${dislikes.length}', style: const TextStyle(color: Colors.white38)),
                                          const Spacer(),
                                          const Icon(Icons.remove_red_eye, color: Colors.white38, size: 20),
                                          const SizedBox(width: 4),
                                          Text('${viewers.length}', style: const TextStyle(color: Colors.white38)),
                                        ],
                                      ),
                                      TextButton(
                                        onPressed: () => _showCommentsDialog(comments),
                                        child: const Text("View Comments", style: TextStyle(color: Colors.white70)),
                                      ),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: TextField(
                                              controller: commentController,
                                              style: const TextStyle(color: Colors.white),
                                              decoration: InputDecoration(
                                                hintText: "Write a comment",
                                                hintStyle: const TextStyle(color: Colors.white70),
                                                filled: true,
                                                fillColor: Colors.white10,
                                                border: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                  borderSide: BorderSide.none,
                                                ),
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.send, color: Colors.white),
                                            onPressed: () => _addComment(postId, commentController.text),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
