// ignore_for_file: avoid_print
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final secret = '4024kdHBy2B3_Fg08Gh2q53F-uAotfsF1LPFf9yGfnk';
  final clientId = '4ca04a87-4618-4900-8283-971a2f470678';
  final workflowId = 'a902bb58-5817-4fda-90ea-306068ea8774';

  print('Testing v1/session with Bearer secret...');
  final res1 = await http.post(
    Uri.parse('https://verification.didit.me/v1/session/'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $secret',
    },
    body: jsonEncode({
      'workflow_id': workflowId,
    }),
  );
  print('Status: ${res1.statusCode}');
  print('Body: ${res1.body}');
  
  print('\nTesting auth/v2/token with Basic Auth...');
  final credentials = base64Encode(utf8.encode('$clientId:$secret'));
  final res2 = await http.post(
    Uri.parse('https://apx.didit.me/auth/v2/token/'),
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
      'Authorization': 'Basic $credentials',
    },
    body: {
      'grant_type': 'client_credentials',
    },
  );
  print('Status: ${res2.statusCode}');
  print('Body: ${res2.body}');
}
