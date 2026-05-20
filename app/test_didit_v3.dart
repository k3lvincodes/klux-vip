// ignore_for_file: avoid_print
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final apiKey = 'Ljgu4XQ0a_Ux3yMkPi6nLSGijRHOuUmTeBXyzPVVsjA';
  final workflowId = 'a902bb58-5817-4fda-90ea-306068ea8774';

  print('Testing Didit v3 API with x-api-key...');
  try {
    final res = await http.post(
      Uri.parse('https://verification.didit.me/v3/session/'),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
      },
      body: jsonEncode({
        'workflow_id': workflowId,
      }),
    );
    print('Status: ${res.statusCode}');
    print('Body: ${res.body}');
  } catch (e) {
    print('Error: $e');
  }
}
