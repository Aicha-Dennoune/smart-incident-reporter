import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class BackendApiService {
  BackendApiService();

  String get _baseUrl {
    if (kIsWeb) return 'http://localhost:5000/api';
    return 'http://10.0.2.2:5000/api';
  }

  Future<void> sendWelcomeEmail({
    required String to,
    required String nom,
    required String email,
    required String password,
    required String role,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/send-email'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'to': to,
        'nom': nom,
        'email': email,
        'password': password,
        'role': role,
      }),
    );
    if (response.statusCode >= 400) {
      throw Exception(_extractMessage(response.body, 'Echec envoi email'));
    }
  }

  Future<void> deleteUser(String uid) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/users/$uid'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode >= 400) {
      throw Exception(
        _extractMessage(response.body, 'Echec suppression utilisateur'),
      );
    }
  }

  String _extractMessage(String body, String fallback) {
    try {
      final data = jsonDecode(body) as Map<String, dynamic>;
      final message = data['message']?.toString();
      final error = data['error']?.toString();
      if (message != null &&
          message.isNotEmpty &&
          error != null &&
          error.isNotEmpty) {
        return '$message: $error';
      }
      if (message != null && message.isNotEmpty) return message;
      return fallback;
    } catch (_) {
      return fallback;
    }
  }
}
