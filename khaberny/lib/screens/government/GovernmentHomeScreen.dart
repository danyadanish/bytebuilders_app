import 'package:flutter/material.dart';

class GovernmentHomeScreen extends StatelessWidget {
  const GovernmentHomeScreen({super.key});

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
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text('Khaberny Government Panel',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                )),
            centerTitle: true,
            iconTheme: const IconThemeData(color: Colors.white),
            leading: IconButton(
              onPressed: () =>
                  Navigator.pushReplacementNamed(context, '/accountType'),
              icon: const Icon(Icons.arrow_back),
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "What would you like to do today?",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 30),
                _buildActionButton(
                  context,
                  title: "Create a Poll",
                  description: "Add a poll to get citizen feedback",
                  onTap: () {
                    Navigator.pushNamed(context, '/createPoll');
                  },
                ),
                const SizedBox(height: 30),
                _buildActionButton(
                  context,
                  title: "View All Polls",
                  description: "See all created polls and their results",
                  onTap: () {
                    Navigator.pushNamed(context, '/polls');
                  },
                ),
                const SizedBox(height: 30),
                _buildActionButton(
                  context,
                  title: "Check ADS",
                  description: "Approve or deny ads created by advertisers.",
                  onTap: () {
                    Navigator.pushNamed(context, '/approveAds');
                  },
                ),
                const SizedBox(height: 30),
                _buildActionButton(
                  context,
                  title: "Delete Requests",
                  description: "Check and approve delete requests.",
                  onTap: () {
                    Navigator.pushNamed(context, '/deleteRequests');
                  },
                ),
                const SizedBox(height: 30),
                _buildActionButton(
                  context,
                  title: "Check Problems",
                  description: "Check and Solve problem reports.",
                  onTap: () {
                    Navigator.pushNamed(context, '/governmentProblemReports');
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context,
      {required String title,
      required String description,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
