import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class ProfilService {
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<Map<String, dynamic>> updateProfil({
    required String name,
    required String email,
  }) async {
    final token = await _getToken();
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/profil'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'name': name, 'email': email}),
    );

    final data = jsonDecode(response.body);
    return {'statusCode': response.statusCode, ...data};
  }

  Future<Map<String, dynamic>> updatePassword({
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  }) async {
    final token = await _getToken();
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/profil/password'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'current_password': currentPassword,
        'password': password,
        'password_confirmation': passwordConfirmation,
      }),
    );

    final data = jsonDecode(response.body);
    return {'statusCode': response.statusCode, ...data};
  }
}