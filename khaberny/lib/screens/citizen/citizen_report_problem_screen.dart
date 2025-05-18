import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

class ReportProblemScreen extends StatefulWidget {
  const ReportProblemScreen({super.key});

  @override
  State<ReportProblemScreen> createState() => _ReportProblemScreenState();
}

class _ReportProblemScreenState extends State<ReportProblemScreen> {
  final _textController = TextEditingController();
  final _imageUrlController = TextEditingController();
  Position? _location;
  bool _isSubmitting = false;

  Future<void> _getLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.deniedForever || permission == LocationPermission.denied) {
          return;
        }
      }

      final pos = await Geolocator.getCurrentPosition();
      setState(() => _location = pos);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Location error: $e")),
      );
    }
  }

  Future<void> _submitProblem() async {
    final user = FirebaseAuth.instance.currentUser;
    final text = _textController.text.trim();
    final imageUrl = _imageUrlController.text.trim();

    if (text.isEmpty || user == null || _location == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields and tag a location.")),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final name = userDoc.data()?['name'] ?? 'Citizen';

    await FirebaseFirestore.instance.collection('posts').add({
      'authorId': user.uid,
      'authorName': name,
      'authorRole': 'citizen',
      'type': 'problem',
      'content': text,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.now(),
      'latitude': _location!.latitude,
      'longitude': _location!.longitude,
      'likes': [],
      'dislikes': [],
      'comments': [],
      'viewers': [],
      'status': null, // government sets this to "solved"/"not solved"
      'solutionReason': null, // government fills this if "not solved"
    });

    setState(() => _isSubmitting = false);
    Navigator.pop(context);
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
      body: Padding(
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
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _getLocation,
              icon: const Icon(Icons.location_on),
              label: Text(_location == null ? "Tag Location" : "Location Tagged"),
              style: ElevatedButton.styleFrom(
                backgroundColor: _location == null ? Colors.orange : Colors.green,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitProblem,
              child: _isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Submit Problem"),
            ),
          ],
        ),
      ),
    );
  }
}
