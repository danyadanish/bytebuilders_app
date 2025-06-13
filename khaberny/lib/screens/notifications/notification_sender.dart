import 'package:http/http.dart' as http;
import 'dart:convert';

Future<void> sendPushNotificationFromFlutter({
  required String
      backendUrl, // e.g. 'http://192.168.1.105:3000/send-notification'
  required String token,
  required String title,
  required String body,
  Map<String, dynamic>? data,
}) async {
  final response = await http.post(
    Uri.parse(backendUrl),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'token': token,
      'title': title,
      'body': body,
      'data': data ?? {},
    }),
  );

  if (response.statusCode == 200) {
    print('Notification sent!');
  } else {
    print('Failed to send notification: ${response.body}');
  }
}
