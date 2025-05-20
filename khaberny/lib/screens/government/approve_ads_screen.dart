import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ApproveAdsScreen extends StatefulWidget {
  const ApproveAdsScreen({super.key});

  @override
  State<ApproveAdsScreen> createState() => _ApproveAdsScreenState();
}

class _ApproveAdsScreenState extends State<ApproveAdsScreen> {
  String _search = '';
  String _selectedCategory = 'All';
  String _selectedStatus = 'All';
  final TextEditingController _denyCommentController = TextEditingController();

  @override
  void dispose() {
    _denyCommentController.dispose();
    super.dispose();
  }

  final List<String> _categories = [
    'All',
    'Discount',
    'New Product',
    'Vacation',
    'Closure',
    'Hiring',
    'Other'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B203D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("My Advertisements"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                TextField(
                  onChanged: (value) => setState(() => _search = value),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "SEARCH BY AD TITLE...",
                    hintStyle: const TextStyle(color: Colors.white54),
                    prefixIcon: const Icon(Icons.search, color: Colors.white54),
                    filled: true,
                    fillColor: Colors.white10,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        dropdownColor: const Color(0xFF1B203D),
                        items: _categories
                            .map((cat) => DropdownMenuItem(
                                  value: cat,
                                  child: Text(cat,
                                      style:
                                          const TextStyle(color: Colors.white)),
                                ))
                            .toList(),
                        onChanged: (val) =>
                            setState(() => _selectedCategory = val!),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white10,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                          labelText: 'Category',
                          labelStyle: const TextStyle(color: Colors.white70),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedStatus,
                        dropdownColor: const Color(0xFF1B203D),
                        items: ['All', 'Pending', 'Approved', 'Denied']
                            .map((status) => DropdownMenuItem(
                                  value: status,
                                  child: Text(status,
                                      style:
                                          const TextStyle(color: Colors.white)),
                                ))
                            .toList(),
                        onChanged: (val) =>
                            setState(() => _selectedStatus = val!),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white10,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                          labelText: 'Status',
                          labelStyle: const TextStyle(color: Colors.white70),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('ads')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var ads = snapshot.data!.docs;
                ads = ads.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final title = (data['title'] ?? '').toString().toLowerCase();
                  final category = data['category']?.toString();
                  final status = data['status']?.toString();
                  return (_search.isEmpty ||
                          title.contains(_search.toLowerCase())) &&
                      (_selectedCategory == 'All' ||
                          category == _selectedCategory) &&
                      (_selectedStatus == 'All' || status == _selectedStatus);
                }).toList();

                if (ads.isEmpty) {
                  return const Center(
                    child: Text("No advertisements found.",
                        style: TextStyle(color: Colors.white70)),
                  );
                }

                return ListView.builder(
                  itemCount: ads.length,
                  itemBuilder: (context, index) {
                    final ad = ads[index].data() as Map<String, dynamic>;
                    final adId = ads[index].id;
                    final status = ad['status'] ?? 'Pending';
                    final date = (ad['createdAt'] as Timestamp?)?.toDate();

                    return Card(
                      color: Colors.white10,
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if ((ad['imageUrl'] ?? '').toString().isNotEmpty)
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(12)),
                              child: Image.network(
                                ad['imageUrl'],
                                height: 180,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(ad['title'] ?? 'No Title',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text(ad['description'] ?? '',
                                    style:
                                        const TextStyle(color: Colors.white70)),
                                const SizedBox(height: 4),
                                if (date != null)
                                  Text(
                                      "📅 ${date.day}-${date.month}-${date.year}",
                                      style: const TextStyle(
                                          color: Colors.white54)),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: status == 'Approved'
                                            ? Colors.green
                                            : status == 'Denied'
                                                ? Colors.red
                                                : Colors.orange,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(status,
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12)),
                                    ),
                                    const Spacer(),
                                    TextButton(
                                      onPressed: () => _openAdDetailDialog(
                                          context, adId, ad),
                                      child: const Text("More Info >",
                                          style:
                                              TextStyle(color: Colors.white)),
                                    )
                                  ],
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _openAdDetailDialog(
      BuildContext context, String adId, Map<String, dynamic> ad) {
    _denyCommentController.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1B203D),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(ad['title'] ?? 'Ad Title',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(ad['description'] ?? '',
                  style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 12),
              if ((ad['imageUrl'] ?? '').toString().isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(ad['imageUrl'],
                      height: 200, width: double.infinity, fit: BoxFit.cover),
                ),
              const SizedBox(height: 16),
              TextField(
                controller: _denyCommentController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Write a reason if Denied...",
                  hintStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.white10,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () =>
                        _updateAdStatus(context, adId, ad, 'Approved', ''),
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: const Text("Approve"),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      final reason = _denyCommentController.text.trim();
                      if (reason.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text("Please provide a reason for denial."),
                              backgroundColor: Colors.red),
                        );
                        return;
                      }
                      _updateAdStatus(context, adId, ad, 'Denied', reason);
                    },
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text("Deny"),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  void _updateAdStatus(BuildContext context, String adId,
      Map<String, dynamic> ad, String status, String denialReason) async {
    final updateData = {'status': status};
    if (status == 'Denied') updateData['denialReason'] = denialReason;

    await FirebaseFirestore.instance
        .collection('ads')
        .doc(adId)
        .update(updateData);

    if (status == 'Approved') {
      // 1. Create post
      await FirebaseFirestore.instance.collection('posts').add({
        'authorId': ad['advertiserId'],
        'authorName': ad['business'] ?? 'Unknown',
        'authorRole': 'advertiser',
        'content': ad['title'] + "\n" + ad['description'],
        'imageUrl': ad['imageUrl'] ?? '',
        'createdAt': Timestamp.now(),
        'likes': [],
        'dislikes': [],
        'viewers': [],
        'comments': [],
        'approvedByGovernment': true,
      });

      // 2. Save notification in Firestore
      await FirebaseFirestore.instance.collection('notifications').add({
        'receiverId': ad['advertiserId'],
        'senderId': 'government', // or your gov user id if you have one
        'type': 'ad_approval',
        'title': 'Ad Approved',
        'content':
            'Your advertisement titled "${ad['title']}" has been approved.',
        'timestamp': Timestamp.now(),
        'isRead': false,
      });

      // 3. Send push notification
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(ad['advertiserId'])
          .get();
      final fcmToken = userDoc.data()?['fcmToken'];

      if (fcmToken != null) {
        await sendPushNotification(
          fcmToken,
          title: "Ad Approved",
          body: "Your ad '${ad['title']}' has been approved by the government.",
        );
      }

      // 4. Show approval dialog
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Ad Approved"),
          content: const Text(
              "The ad has been approved and the advertiser will be notified."),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("OK"),
            ),
          ],
        ),
      );
    } else if (status == 'Denied') {
      // Save denial notification only
      await FirebaseFirestore.instance.collection('notifications').add({
        'receiverId': ad['advertiserId'],
        'senderId': 'government',
        'type': 'ad_denied',
        'title': 'Ad Denied',
        'content':
            'Your advertisement titled "${ad['title']}" was denied.\nReason: $denialReason',
        'timestamp': Timestamp.now(),
        'isRead': false,
      });
      // Show denial dialog
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Ad Denied"),
          content:
              const Text("The advertiser has been notified of the denial."),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("OK"),
            ),
          ],
        ),
      );
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Advertisement marked as $status."),
        backgroundColor: status == 'Approved' ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> sendPushNotification(String token,
      {required String title, required String body}) async {
    const String serverKey = 'YOUR_SERVER_KEY_HERE';

    try {
      await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=$serverKey',
        },
        body: jsonEncode({
          'to': token,
          'notification': {
            'title': title,
            'body': body,
          },
          'priority': 'high',
        }),
      );
    } catch (e) {
      print('Failed to send push notification: $e');
    }
  }
}
