import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fluttertoast/fluttertoast.dart';

class EmergencyNumbersScreen extends StatelessWidget {
  const EmergencyNumbersScreen({super.key});

  final List<Map<String, String>> emergencyContacts = const [
    {
      'title': '🚓 Police',
      'subtitle': 'Emergency police assistance',
      'number': '122',
    },
    {
      'title': '🚑 Ambulance',
      'subtitle': 'Medical emergencies',
      'number': '123',
    },
    {
      'title': '🚒 Fire Department',
      'subtitle': 'Fire & rescue services',
      'number': '180',
    },
    {
      'title': '🏥 Public Hospital',
      'subtitle': 'Nearest government hospital',
      'number': '137',
    },
    {
      'title': '🚨 General Emergency',
      'subtitle': 'Unified emergency number',
      'number': '112',
    },
  ];

  void _callNumber(String number) async {
    final Uri url = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      debugPrint('Could not launch $number');
    }
  }

  void _copyNumber(BuildContext context, String number) {
    Clipboard.setData(ClipboardData(text: number));
    Fluttertoast.showToast(
      msg: "Number copied: $number",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.black87,
      textColor: Colors.white,
      fontSize: 14.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FA),
      appBar: AppBar(
        title: Text(
          'Emergency Numbers',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF003366),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: emergencyContacts.length,
        itemBuilder: (context, index) {
          final contact = emergencyContacts[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 4,
            child: ListTile(
              leading: const Icon(Icons.local_phone, color: Color(0xFF003366), size: 30),
              title: Text(
                contact['title']!,
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.call, color: Colors.green),
                onPressed: () => _callNumber(contact['number']!),
              ),
              onTap: () => _callNumber(contact['number']!),
              onLongPress: () => _copyNumber(context, contact['number']!),
              isThreeLine: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contact['subtitle']!,
                    style: GoogleFonts.cairo(fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () => _copyNumber(context, contact['number']!),
                    child: Text(
                      contact['number']!,
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
