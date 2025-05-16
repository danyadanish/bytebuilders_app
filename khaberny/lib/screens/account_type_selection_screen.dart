import 'package:flutter/material.dart';

class AccountTypeSelectionScreen extends StatelessWidget {
  const AccountTypeSelectionScreen({super.key});

  static const String governmentAccessCode = "1234";

  void _showGovernmentCodeDialog(BuildContext context) {
    final TextEditingController _codeController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("Enter Government Access Code"),
          content: TextField(
            controller: _codeController,
            obscureText: true,
            decoration: const InputDecoration(hintText: "Enter code"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                if (_codeController.text == governmentAccessCode) {
                  Navigator.pop(ctx);
                  Navigator.pushNamed(context, '/government');
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Incorrect code. Try again."),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text("Enter"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/khaberny_background.png',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 24),
                const Text(
                  'CHOOSE YOUR ACCOUNT TYPE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    children: [
                      AccountTypeCard(
                        backgroundColor: const Color(0xFF6FA8DC),
                        textColor: Colors.white,
                        title: 'Advertising Agency',
                        description:
                            'Add your Advertisements to our Platform to allow others to see your services.',
                        image: 'assets/ads.jpg',
                        onTap: () => Navigator.pushNamed(context, '/advertiserSignup'),
                      ),
                      const SizedBox(height: 28),
                      AccountTypeCard(
                        backgroundColor: Colors.white,
                        textColor: Colors.black,
                        title: 'Citizen',
                        description:
                            'Find out important Government Announcements, Access Emergency Services quickly, Engage with Government Institutions directly.',
                        image: 'assets/citizen.jpg',
                        onTap: () => Navigator.pushNamed(context, '/citizenSignup'),
                      ),
                      const SizedBox(height: 28),
                      AccountTypeCard(
                        backgroundColor: const Color(0xFF0A1A3A), // Dark blue
                        textColor: Colors.white,
                        title: 'Government',
                        description:
                            'Access tools to manage ads, polls, and notifications. Requires a secure access code.',
                        image: 'assets/images/government.jpg', // Add this image
                        onTap: () => _showGovernmentCodeDialog(context),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: GestureDetector(
                          onTap: () => Navigator.pushNamed(context, '/signIn'),
                          child: const Text(
                            "Already have an account? Sign in",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AccountTypeCard extends StatelessWidget {
  final String title;
  final String description;
  final String image;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback onTap;

  const AccountTypeCard({
    super.key,
    required this.title,
    required this.description,
    required this.image,
    required this.onTap,
    required this.backgroundColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 170,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        fontFamily: 'Cairo',
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        fontFamily: 'Cairo',
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                child: Image.asset(
                  image,
                  height: double.infinity,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
