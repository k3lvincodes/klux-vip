import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:kenick_vip/config/env_config.dart';

class EmailNotificationService {
  String get _apiKey => EnvConfig.resendApiKey;
  String get _fromEmail => EnvConfig.resendFromEmail;

  Future<bool> sendVerificationSuccessEmail({
    required String toEmail,
    required String userName,
  }) async {
    final apiKey = _apiKey;
    if (apiKey.isEmpty) return false;

    try {
      final response = await http.post(
        Uri.parse('https://api.resend.com/emails'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'from': _fromEmail,
          'to': [toEmail],
          'subject': 'Identity Verification Approved – Klux VIP',
          'html': '''
            <div style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; max-width: 500px; margin: 0 auto; background: #ffffff; border-radius: 12px; border: 1px solid #e5e7eb; padding: 28px;">
              <div style="text-align: center; margin-bottom: 20px;">
                <h1 style="color: #1a1a1a; font-size: 24px; font-weight: 700; margin: 0;">Klux VIP</h1>
                <p style="color: #6b7280; font-size: 13px; margin: 4px 0 0;">Chauffeur Verification</p>
              </div>
              <div style="background-color: #ecfdf5; border-radius: 50%; width: 56px; height: 56px; line-height: 56px; text-align: center; margin: 0 auto 16px; font-size: 26px; color: #059669;">
                ✓
              </div>
              <h2 style="color: #059669; font-size: 20px; font-weight: 600; text-align: center; margin: 0 0 12px;">Driver's License Approved</h2>
              <p style="color: #374151; font-size: 14px; line-height: 1.5; margin: 0 0 12px;">Hi <strong>$userName</strong>,</p>
              <p style="color: #374151; font-size: 14px; line-height: 1.5; margin: 0 0 16px;">Your USA Driver's License and identity scan have been automatically approved. You can now proceed with vehicle registration to start accepting premium chauffeur bookings.</p>
              <hr style="border: none; border-top: 1px solid #f3f4f6; margin: 20px 0;" />
              <p style="color: #9ca3af; font-size: 12px; text-align: center; margin: 0;">Safe driving,<br>The Klux VIP Team</p>
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
    String? reason,
  }) async {
    final apiKey = _apiKey;
    if (apiKey.isEmpty) return false;

    final reasonBlock = (reason != null && reason.trim().isNotEmpty)
        ? '<div style="background-color: #fef2f2; border: 1px solid #fee2e2; border-radius: 8px; padding: 12px; margin: 16px 0;"><p style="color: #991b1b; font-size: 13px; margin: 0;"><strong>Reason:</strong> $reason</p></div>'
        : '';

    try {
      final response = await http.post(
        Uri.parse('https://api.resend.com/emails'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'from': _fromEmail,
          'to': [toEmail],
          'subject': 'Identity Verification Declined – Klux VIP',
          'html': '''
            <div style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; max-width: 500px; margin: 0 auto; background: #ffffff; border-radius: 12px; border: 1px solid #e5e7eb; padding: 28px;">
              <div style="text-align: center; margin-bottom: 20px;">
                <h1 style="color: #1a1a1a; font-size: 24px; font-weight: 700; margin: 0;">Klux VIP</h1>
                <p style="color: #6b7280; font-size: 13px; margin: 4px 0 0;">Chauffeur Verification</p>
              </div>
              <div style="background-color: #fee2e2; border-radius: 50%; width: 56px; height: 56px; line-height: 56px; text-align: center; margin: 0 auto 16px; font-size: 26px; color: #dc2626;">
                ✕
              </div>
              <h2 style="color: #dc2626; font-size: 20px; font-weight: 600; text-align: center; margin: 0 0 12px;">Driver's License Declined</h2>
              <p style="color: #374151; font-size: 14px; line-height: 1.5; margin: 0 0 12px;">Hi <strong>$userName</strong>,</p>
              <p style="color: #374151; font-size: 14px; line-height: 1.5; margin: 0 0 12px;">Your submitted documents could not be approved for chauffeur verification.</p>
              $reasonBlock
              <p style="color: #374151; font-size: 14px; line-height: 1.5; margin: 0 0 16px;">Please open the Klux VIP app and re-submit a clear, valid USA Driver's License and complete the 3D selfie scan in good lighting.</p>
              <hr style="border: none; border-top: 1px solid #f3f4f6; margin: 20px 0;" />
              <p style="color: #9ca3af; font-size: 12px; text-align: center; margin: 0;">If you need assistance, our support team is available 24/7.</p>
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
