// ignore_for_file: avoid_print
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  const secret = '4024kdHBy2B3_Fg08Gh2q53F-uAotfsF1LPFf9yGfnk';
  const clientId = '4ca04a87-4618-4900-8283-971a2f470678';
  final res = await http.post(
    Uri.parse('https://apx.didit.me/auth/v2/token/'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'grant_type': 'client_credentials',
      'client_id': clientId,
      'client_secret': secret
    })
  );
  print('Status: ${res.statusCode}');
  print('Body: ${res.body}');
}
