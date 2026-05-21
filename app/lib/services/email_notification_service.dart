import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class EmailNotificationService {
  String? get _apiKey => dotenv.env['RESEND_API_KEY'];

  Future<bool> sendVerificationSuccessEmail({
    required String toEmail,
    required String userName,
  }) async {
    final apiKey = _apiKey;
    if (apiKey == null || apiKey.isEmpty) return false;

    try {
      final response = await http.post(
        Uri.parse('https://api.resend.com/emails'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'from': 'Kenick Transportation LLC <onboarding@kenicktransportation.com>',
          'to': [toEmail],
          'subject': 'Identity Verification Successful – Klux VIP',
          'html': '''
            <div style="font-family: Arial, sans-serif; max-width: 480px; margin: 0 auto;">
              <h2 style="color: #1a1a1a;">Identity Verified ✅</h2>
              <p>Hi <strong>$userName</strong>,</p>
              <p>Your identity verification was successful. You can now continue to register your vehicle and start driving with Klux VIP.</p>
              <hr style="border: none; border-top: 1px solid #eee;" />
              <p style="color: #666; font-size: 12px;">If you did not initiate this verification, please contact support immediately.</p>
            </div>
          ''',
        }),
      );

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> sendVerificationFailedEmail({
    required String toEmail,
    required String userName,
  }) async {
    final apiKey = _apiKey;
    if (apiKey == null || apiKey.isEmpty) return false;

    try {
      final response = await http.post(
        Uri.parse('https://api.resend.com/emails'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'from': 'Kenick Transportation LLC <onboarding@kenicktransportation.com>',
          'to': [toEmail],
          'subject': 'Identity Verification Failed – Klux VIP',
          'html': '''
            <div style="font-family: Arial, sans-serif; max-width: 480px; margin: 0 auto;">
              <h2 style="color: #1a1a1a;">Identity Verification Failed ❌</h2>
              <p>Hi <strong>$userName</strong>,</p>
              <p>Unfortunately, your identity verification was not successful. Please try again or contact support for assistance.</p>
              <hr style="border: none; border-top: 1px solid #eee;" />
              <p style="color: #666; font-size: 12px;">If you need help, please contact our support team.</p>
            </div>
          ''',
        }),
      );

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
