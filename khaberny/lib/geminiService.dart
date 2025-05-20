import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiService {
  final String _apiKey = dotenv.env['GEMINI_API_KEY']!;
  final String _url =
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent";

  Future<String> sendMessage(String userMessage) async {
    final systemPrompt = '''
You are the AI assistant inside the Khaberny mobile application.
Assist users with their questions and requests strictly related to the app's features and municipal services.
Provide short, direct answers without extra information or off-topic advice.

Khaberny is a smart governmental app that helps citizens interact with the local municipality.

Your responsibilities:
Explain app features: Help users navigate announcements, voting on local issues, and reporting problems (e.g., street damage, water leaks).

Guide communication: Show how to message the government or view emergency contacts.

Language support: Respond only in Arabic or English, matching the user's language.

Reject unrelated queries: Politely decline requests outside municipal services (e.g., personal advice, non-app topics).

Rules:
Be clear and concise: Use simple steps (e.g., Go to Services > Report Issue).

No opinions/jokes: Only provide factual, app-related guidance.

Redirect if unsure: Direct users to official channels (e.g., “Find more details in the Help section”).
''';

    final uri = Uri.parse("$_url?key=$_apiKey");

    final body = jsonEncode({
      "contents": [
        {
          "parts": [
            {"text": systemPrompt},
            {"text": userMessage}
          ]
        }
      ]
    });

    final response = await http.post(
      uri,
      headers: {
        "Content-Type": "application/json",
      },
      body: body,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['candidates'][0]['content']['parts'][0]['text'];
    } else {
      print("API error ${response.statusCode}: ${response.body}");
      return "Error ${response.statusCode}: ${jsonDecode(response.body)['error']['message']}";
    }
  }
}
