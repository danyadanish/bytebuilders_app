import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdvertiserProfileScreen extends StatelessWidget {
  const AdvertiserProfileScreen({super.key});

  Future<DocumentSnapshot<Map<String, dynamic>>> _getUserData() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return await FirebaseFirestore.instance.collection('users').doc(uid).get();
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
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: const Text(
              "My Profile",
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            future: _getUserData(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || !snapshot.data!.exists) {
                return const Center(
                  child: Text("User data not found.", style: TextStyle(color: Colors.white)),
                );
              }

              final user = snapshot.data!.data()!;

              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const Icon(Icons.account_circle, size: 100, color: Colors.white54),
                  const SizedBox(height: 20),
                  _buildInfoTile("Full Name", user['name']),
                  _buildInfoTile("Email", user['email']),
                  _buildInfoTile("Company", user['company']),
                  _buildInfoTile("Industry", user['industry']),
                  _buildInfoTile("Country", user['country']),
                  _buildInfoTile("Phone", user['phone']),
                  const SizedBox(height: 30),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      if (context.mounted) {
                        Navigator.pushReplacementNamed(context, '/accountType');
                      }
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text("Sign Out"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                  )
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTile(String label, String? value) {
    return Card(
      color: const Color.fromARGB(105, 117, 152, 179),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: Text(label, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
        subtitle: Text(value ?? "-", style: const TextStyle(color: Colors.white)),
      ),
    );
  }
}
