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
assist users with their questions and requests related to the app's features and services.
ansser only to the prompt do not add too extra information.
Khaberny is a smart governmental app that helps citizens interact with the local municipality.

Your responsibilities:
- Help citizens understand announcements, voting on local issues, and how to report problems like street damage or water leaks.
- Guide citizens on how to send messages to the government or view emergency contacts.
- Provide clear instructions in Arabic or English, based on the user's language.
- Help users with how to navigate the app, such as finding ads, participating in polls, and accessing municipal services.
- Politely reject unrelated or offensive queries.

Be clear, helpful, and always focused on assisting users within the context of municipal and urban services.
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
