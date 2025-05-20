// ✅ lib/screens/government_feed_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import './poll_detail_screen.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
class GovernmentFeedScreen extends StatefulWidget {
  const GovernmentFeedScreen({super.key});

  @override
  State<GovernmentFeedScreen> createState() => _GovernmentFeedScreenState();
}
class PollCard extends StatefulWidget {
  final String postId;
  final Map<String, dynamic> data;

  const PollCard({super.key, required this.postId, required this.data});

  @override
  State<PollCard> createState() => _PollCardState();
}

class _PollCardState extends State<PollCard> {
  final userId = 'government'; // or use FirebaseAuth.instance.currentUser?.uid
  Set<int> selectedIndexes = {};
  int? selectedSingleIndex;
  bool hasVoted = false;

  @override
  void initState() {
    super.initState();
    final voters = List<String>.from(widget.data['voters'] ?? []);
    hasVoted = voters.contains(userId);
  }

  Future<void> submitVote() async {
    final allowMultiple = widget.data['allowMultipleVotes'] ?? false;
    final votes = List<int>.from(widget.data['votes'] ?? []);
    final voters = List<String>.from(widget.data['voters'] ?? []);

    if (hasVoted) return;

    if (allowMultiple && selectedIndexes.isEmpty) return;
    if (!allowMultiple && selectedSingleIndex == null) return;

    final selected = allowMultiple ? selectedIndexes : {selectedSingleIndex!};

    for (final index in selected) {
      if (index < votes.length) votes[index]++;
    }

    voters.add(userId);

    await FirebaseFirestore.instance.collection('posts').doc(widget.postId).update({
      'votes': votes,
      'voters': voters,
    });

    await FirebaseFirestore.instance.collection('polls').doc(widget.postId).update({
      'votes': votes,
      'voters': voters,
    });


    setState(() => hasVoted = true);
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.data['question'] ?? '';
    final options = List<String>.from(widget.data['options'] ?? []);
    final votes = List<int>.from(widget.data['votes'] ?? []);
    final totalVotes = votes.fold(0, (a, b) => a + b);
    final allowMultiple = widget.data['allowMultipleVotes'] ?? false;

    return Card(
      color: Colors.white10,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(question, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ...List.generate(options.length, (i) {
              final percent = totalVotes == 0 ? 0 : ((votes[i] / totalVotes) * 100).round();
              final selected = allowMultiple ? selectedIndexes.contains(i) : selectedSingleIndex == i;

              return Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    if (!hasVoted)
                      allowMultiple
                          ? Checkbox(
                              value: selected,
                              onChanged: (val) {
                                setState(() {
                                  if (val == true) {
                                    selectedIndexes.add(i);
                                  } else {
                                    selectedIndexes.remove(i);
                                  }
                                });
                              },
                            )
                          : Radio<int>(
                              value: i,
                              groupValue: selectedSingleIndex ?? -1,
                              onChanged: (val) => setState(() => selectedSingleIndex = val),
                            )
                    else
                      const Icon(Icons.check_circle, color: Colors.greenAccent),
                    const SizedBox(width: 8),
                    Expanded(child: Text(options[i], style: const TextStyle(color: Colors.white))),
                    Text('$percent%', style: const TextStyle(color: Colors.white54)),
                    const SizedBox(width: 6),
                    Text('${votes[i]}', style: const TextStyle(color: Colors.white38)),
                  ],
                ),
              );
            }),
            const SizedBox(height: 10),
            if (!hasVoted)
              Center(
                child: ElevatedButton(
                  onPressed: submitVote,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                  child: const Text("Submit Vote"),
                ),
              )
            else
              const Center(
                child: Text("You already voted", style: TextStyle(color: Colors.greenAccent)),
              )
          ],
        ),
      ),
    );
  }
}

class _GovernmentFeedScreenState extends State<GovernmentFeedScreen> {
  final TextEditingController _postController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();
  bool _showOnlyMyPosts = false;
  String? _editingPostId;

  Future<void> _openCreatePostDialog({String? existingContent, String? existingImageUrl, String? postId}) async {
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
                  hintText: "Paste image URL",
                  hintStyle: TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Colors.white10,
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => _submitPost(),
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

    if (_editingPostId != null) {
      await FirebaseFirestore.instance.collection('posts').doc(_editingPostId).update({
        'content': text,
        'imageUrl': imageUrl,
      });
      _editingPostId = null;
    } else {
      await FirebaseFirestore.instance.collection('posts').add({
        'authorId': 'government',
        'authorRole': 'government',
        'authorName': 'Government',
        'content': text,
        'createdAt': Timestamp.now(),
        'likes': <String>[],
        'dislikes': <String>[],
        'viewers': <String>[],
        'imageUrl': imageUrl,
        'comments': [],
      });
    }

    _postController.clear();
    _imageUrlController.clear();
    Navigator.pop(context);
  }

  Future<void> _deletePost(String postId) async {
    final confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Post"),
        content: const Text("Are you sure you want to delete this post?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete")),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance.collection('posts').doc(postId).delete();
    }
  }

  Future<void> _toggleLike(String postId, List likes, List dislikes) async {
    final ref = FirebaseFirestore.instance.collection('posts').doc(postId);
    const userId = 'government';
    if (likes.contains(userId)) {
      await ref.update({'likes': FieldValue.arrayRemove([userId])});
    } else {
      await ref.update({
        'likes': FieldValue.arrayUnion([userId]),
        'dislikes': FieldValue.arrayRemove([userId])
      });
    }
  }

  Future<void> _toggleDislike(String postId, List likes, List dislikes) async {
    final ref = FirebaseFirestore.instance.collection('posts').doc(postId);
    const userId = 'government';
    if (dislikes.contains(userId)) {
      await ref.update({'dislikes': FieldValue.arrayRemove([userId])});
    } else {
      await ref.update({
        'dislikes': FieldValue.arrayUnion([userId]),
        'likes': FieldValue.arrayRemove([userId])
      });
    }
  }

  Future<void> _addComment(String postId, String commentText) async {
    if (commentText.trim().isEmpty) return;

    const userId = 'government';
    const name = 'Government';

    final comment = {
      'userId': userId,
      'username': name,
      'text': commentText.trim(),
      'timestamp': Timestamp.now(),
    };
    await FirebaseFirestore.instance.collection('posts').doc(postId).update({
      'comments': FieldValue.arrayUnion([comment])
    });
  }

  Future<void> _incrementView(String postId) async {
    final ref = FirebaseFirestore.instance.collection('posts').doc(postId);
    final snapshot = await ref.get();
    final data = snapshot.data();
    final viewers = List<String>.from(data?['viewers'] ?? []);
    if (!viewers.contains('government')) {
      await ref.update({'viewers': FieldValue.arrayUnion(['government'])});
    }
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
            title: const Text("Khaberny", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.grey)),
            actions: [
              IconButton(
                icon: Icon(_showOnlyMyPosts ? Icons.list : Icons.person, color: Colors.grey),
                onPressed: () {
                  setState(() {
                    _showOnlyMyPosts = !_showOnlyMyPosts;
                  });
                },
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
                    stream: FirebaseFirestore.instance.collection('posts').orderBy('createdAt', descending: true).snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                      final posts = snapshot.data!.docs;
                      final filteredPosts = _showOnlyMyPosts
                          ? posts.where((post) => (post.data() as Map<String, dynamic>)['authorId'] == 'government').toList()
                          : posts;

                      return ListView.builder(
                        itemCount: filteredPosts.length,
                        itemBuilder: (context, index) {
                          final post = filteredPosts[index];
                          final data = post.data() as Map<String, dynamic>;
                          final content = data['content'] ?? '';
                          final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
                          final likes = List<String>.from(data['likes'] ?? []);
                          final dislikes = List<String>.from(data['dislikes'] ?? []);
                          final viewers = List<String>.from(data['viewers'] ?? []);
                          final comments = data['comments'] ?? [];
                          final postId = post.id;
                          final username = data['authorName'] ?? 'Citizen';
                          final imageUrl = data['imageUrl'] ?? '';
                          final commentController = TextEditingController();

                          return Dismissible(
                            key: ValueKey(postId),
                            background: Container(
                              color: const Color.fromARGB(255, 0, 110, 253),
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
                              if (direction == DismissDirection.endToStart) {
                                await _deletePost(postId);
                                return false;
                              } else if (direction == DismissDirection.startToEnd) {
                                _openCreatePostDialog(
                                  existingContent: content,
                                  existingImageUrl: imageUrl,
                                  postId: postId,
                                );
                                return false;
                              }
                              return false;
                            },
                            child: GestureDetector(
                              onTap: () => _incrementView(postId),
                              child: Card(
                                color: const Color.fromARGB(255, 85, 153, 182).withOpacity(0.3),
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
                                        createdAt != null ? createdAt.toLocal().toString().split(' ')[0] : "Date Unknown",
                                        style: const TextStyle(fontSize: 12, color: Colors.white60),
                                      ),
                                      const SizedBox(height: 10),
                                      if (data['type'] == 'poll')
                                        GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => PollDetailScreen(pollId: postId),
                                              ),
                                            );
                                          },
                                          child: PollCard(postId: postId, data: data),
                                        )
                                      else if (data['type'] == 'problem') ...[
  Text(content, style: const TextStyle(fontSize: 16, color: Colors.white)),
  if (imageUrl.isNotEmpty)
    Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(imageUrl, fit: BoxFit.cover),
      ),
    ),
  const SizedBox(height: 8),
  if (data['status'] != null)
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Status: ${data['status']}",
          style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold),
        ),
        if (data['solutionReason'] != null)
          Text(
            "Reason: ${data['solutionReason']}",
            style: const TextStyle(color: Colors.white70),
          ),
      ],
    )
  else
    Row(
      children: [
        ElevatedButton.icon(
          icon: const Icon(Icons.check),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          label: const Text("Mark Solved"),
          onPressed: () async {
            await FirebaseFirestore.instance.collection('posts').doc(postId).update({
              'status': 'Solved',
              'solutionReason': 'Fixed by government',
            });
          },
        ),
        const SizedBox(width: 10),
        ElevatedButton.icon(
          icon: const Icon(Icons.close),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
          label: const Text("Not Solved"),
          onPressed: () {
            showDialog(
              context: context,
              builder: (_) {
                final reasonController = TextEditingController();
                return AlertDialog(
                  backgroundColor: const Color(0xFF1B203D),
                  title: const Text("Reason", style: TextStyle(color: Colors.white)),
                  content: TextField(
                    controller: reasonController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: "Enter reason",
                      hintStyle: TextStyle(color: Colors.white38),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                    ),
                    TextButton(
                      onPressed: () async {
                        await FirebaseFirestore.instance.collection('posts').doc(postId).update({
                          'status': 'Not Solved',
                          'solutionReason': reasonController.text.trim(),
                        });
                        Navigator.pop(context);
                      },
                      child: const Text("Submit", style: TextStyle(color: Colors.redAccent)),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ],
    ),
]                                      else
                                        Text(content, style: const TextStyle(fontSize: 16, color: Colors.white)),


                                      const SizedBox(height: 10),
                                      if (imageUrl.isNotEmpty)
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.network(imageUrl, fit: BoxFit.cover),
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
                child: const Icon(Icons.location_pin, color: Colors.red, size: 30),
              ),
            ],
          ),
        ],
      ),
    ),
  ),

                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: Icon(
                                              likes.contains('government') ? Icons.favorite : Icons.favorite_border,
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
                                          Text('${viewers.length}', style: const TextStyle(color: Colors.white38))
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
                                            onPressed: () {
                                              _addComment(postId, commentController.text);
                                              commentController.clear();
                                            },
                                          )
                                        ],
                                      )
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
                )
              ],
            ),
          ),
        ),
      ],
    );
  }
}