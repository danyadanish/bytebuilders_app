import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';

class ReportProblemScreen extends StatefulWidget {
  const ReportProblemScreen({super.key});

  @override
  State<ReportProblemScreen> createState() => _ReportProblemScreenState();
}

class _ReportProblemScreenState extends State<ReportProblemScreen> {
  final _textController = TextEditingController();
  final _imageUrlController = TextEditingController();
  LatLng? _selectedLocation;
  bool _isSubmitting = false;
  final MapController _mapController = MapController();

  static const LatLng _defaultLocation = LatLng(30.0444, 31.2357);

  Future<void> _checkPermissions() async {
    final status = await Permission.location.request();
    if (status.isDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location permission is required")),
        );
      }
    }
  }

  Future<void> _submitProblem() async {
    final user = FirebaseAuth.instance.currentUser;
    final text = _textController.text.trim();
    final imageUrl = _imageUrlController.text.trim();

    if (text.isEmpty || user == null || _selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill all fields and select a location."),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final name = userDoc.data()?['name'] ?? 'Citizen';

      await FirebaseFirestore.instance.collection('posts').add({
        'authorId': user.uid,
        'authorName': name,
        'authorRole': 'citizen',
        'type': 'problem',
        'content': text,
        'imageUrl': imageUrl,
        'createdAt': Timestamp.now(),
        'latitude': _selectedLocation!.latitude,
        'longitude': _selectedLocation!.longitude,
        'likes': [],
        'dislikes': [],
        'comments': [],
        'viewers': [],
        'status': null,
        'solutionReason': null,
      });

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error submitting problem: $e")),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  @override
  void dispose() {
    _textController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B203D),
      appBar: AppBar(
        title: const Text("Report a Problem"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _textController,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: "Describe the problem...",
                hintStyle: TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _imageUrlController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: "Image URL (optional)",
                hintStyle: TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _defaultLocation,
                    initialZoom: 12,
                    onTap: (tapPosition, point) {
                      setState(() {
                        _selectedLocation = point;
                      });
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.khaberny',
                    ),
                    if (_selectedLocation != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _selectedLocation!,
                            width: 30,
                            height: 30,
                            child: const Icon(
                              Icons.location_pin,
                              color: Colors.red,
                              size: 30,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  backgroundColor: Colors.blue,
                ),
                onPressed: _isSubmitting ? null : _submitProblem,
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Submit Problem",
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
