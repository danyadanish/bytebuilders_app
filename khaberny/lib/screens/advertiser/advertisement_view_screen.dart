import 'package:flutter/material.dart';
import 'edit_advertisement_screen.dart';
import 'advertisement_report_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdvertisementViewScreen extends StatelessWidget {
  final Map<String, dynamic> ad;

  const AdvertisementViewScreen({super.key, required this.ad});

  @override
  Widget build(BuildContext context) {
    final String status = ad['status'] ?? 'Pending';
    final String adId = ad['id'];

    final String? imageUrl = ad['imageUrl'];

    return Stack(
      children: [
        SizedBox.expand(
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
              ad['title'] ?? 'Ad Details',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            actions: [
              if (status == 'Pending')
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blueAccent),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditAdvertisementScreen(
                          adId: adId,
                          adData: ad,
                        ),
                      ),
                    );
                  },
                ),
              if (status == 'Pending')
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text("Confirm Delete"),
                        content: const Text("Are you sure you want to delete this ad?"),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
                          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Delete")),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      await FirebaseFirestore.instance.collection('ads').doc(adId).delete();
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Advertisement deleted.")),
                      );
                    }
                  },
                ),
              IconButton(
                icon: const Icon(Icons.bar_chart_rounded, color: Colors.deepPurple),
                onPressed: () async {
                  if (status != 'Approved') {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Report is available only for approved ads.")),
                    );
                    return;
                  }

                  final query = await FirebaseFirestore.instance
                      .collection('posts')
                      .where('authorId', isEqualTo: ad['advertiserId'])
                      .where('content', isEqualTo: "${ad['title']}\n${ad['description']}")
                      .get();

                  if (query.docs.isNotEmpty) {
                    final postId = query.docs.first.id;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AdReportScreen(postId: postId),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Post not found for this ad.")),
                    );
                  }
                },
              )
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (imageUrl != null && imageUrl.trim().isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        imageUrl,
                        errorBuilder: (context, error, stackTrace) {
                          return const Text(
                            "Image failed to load.",
                            style: TextStyle(color: Colors.redAccent),
                          );
                        },
                      ),
                    )
                  else
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(8),
                        child: Text(
                          "No image available",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  _buildIconLabel(Icons.title, ad['title'], color: Colors.indigo, isBold: true, overrideColor: Colors.black),
                  const SizedBox(height: 14),
                  _buildIconLabel(Icons.campaign, ad['description'], color: Colors.blueGrey, overrideColor: Colors.black),
                  const SizedBox(height: 14),
                  _buildIconLabel(Icons.location_on_outlined, ad['location'], color: Colors.orangeAccent, overrideColor: Colors.black),
                  const SizedBox(height: 14),
                  _buildIconLabel(Icons.category, ad['category'], color: Colors.deepPurpleAccent, overrideColor: Colors.black),
                  const SizedBox(height: 14),
                  _buildIconLabel(Icons.business_center, ad['business'], color: Colors.teal, overrideColor: Colors.black),
                  const SizedBox(height: 24),
                  _buildStatusBadge(status),
                  if (status == 'Denied' && (ad['denialReason'] ?? '').isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildIconLabel(Icons.info_outline, ad['denialReason'], color: Colors.redAccent, overrideColor: Colors.black),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIconLabel(IconData icon, String? text, {Color color = Colors.black87, bool isBold = false, Color? overrideColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text ?? 'N/A',
            style: TextStyle(
              color: overrideColor ?? Colors.black87,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'Approved':
        color = Colors.green;
        break;
      case 'Denied':
        color = Colors.red;
        break;
      default:
        color = Colors.orange;
    }

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            status,
            style: const TextStyle(color: Colors.white),
          ),
        ),
        const SizedBox(width: 10),
        const Text("Status", style: TextStyle(color: Colors.black87)),
      ],
    );
  }
}
