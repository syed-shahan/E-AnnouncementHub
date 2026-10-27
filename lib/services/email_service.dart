// email_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

/// This service calls your Cloud Function HTTP endpoint that sends emails to approved_emails.
/// Deploy a Firebase Cloud Function (or other backend) that accepts announcement details
/// and sends emails to the 'approved_emails' collection recipients.
///
/// Set functionUrl to the deployed function URL.
class EmailService {
  static String functionUrl = 'https://YOUR_CLOUD_FUNCTION_URL/sendAnnouncementEmail';

  static Future<bool> notifyApprovedEmails({
    required String title,
    required String body,
    required String announcementId,
  }) async {
    try {
      final resp = await http.post(
        Uri.parse(functionUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': title,
          'body': body,
          'announcementId': announcementId,
        }),
      );
      return resp.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
