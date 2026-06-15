import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class SendNotificationService {

  Future<void> sendNotificationViaCloudFunction({
  required String deviceToken,
  required String title,
  required String body,
}) async {
  // Get current user
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) throw Exception('User not signed in');

  // Get the ID token
  final idToken = await user.getIdToken();

  // Cloud Function URL (replace with your actual URL)
  final url = Uri.parse('https://us-central1-booking-cd20f.cloudfunctions.net/sendNotification');

  // Prepare the request body
  final Map<String, dynamic> requestBody = {
    'token': deviceToken,
    'title': title,
    'body': body,
  };

  try {
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode(requestBody),
    );

    if (response.statusCode == 200) {
      print('Notification sent successfully');
    } else {
      print('Failed to send notification: ${response.body}');
    }
  } catch (e) {
    print('Error calling function: $e');
  }
}
}