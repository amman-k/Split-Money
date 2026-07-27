import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:split_frontend/features/auth/domain/user.dart';

class AuthException implements Exception {
  const AuthException(this.message, {this.code});
  final String message;
  final String? code;

  @override
  String toString() => message;
}

class AuthRepository {
  AuthRepository({
    http.Client? client,
    FlutterSecureStorage? storage,
    String? baseUrl,
  }) : _client = client ?? http.Client(),
       _storage = storage ?? const FlutterSecureStorage(),
       _baseUrl =
           baseUrl ??
           const String.fromEnvironment(
             'API_BASE_URL',
             defaultValue: 'http://localhost:8080',
           );

  final http.Client _client;
  final FlutterSecureStorage _storage;
  final String _baseUrl;

  static const _tokenKey = 'jwt_auth_token';

  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return _storage.read(key: _tokenKey);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }

  Future<AuthSession?> getCurrentUser() async {
    final token = await getToken();
    if (token == null || token.isEmpty) {
      return null;
    }

    final uri = Uri.parse('$_baseUrl/api/me');
    try {
      final response = await _client.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final data = body['data'] as Map<String, dynamic>?;
        if (data != null) {
          final user = User.fromJson(data);
          return AuthSession(token: token, user: user);
        }
      }

      if (response.statusCode == 401) {
        await deleteToken();
        return null;
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  Future<AuthSession> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/signup');
    final response = await _client.post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'full_name': fullName,
        'email': email,
        'password': password,
      }),
    );

    return _parseResponse(response);
  }

  Future<AuthSession> signIn({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/signin');
    final response = await _client.post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    return _parseResponse(response);
  }

  AuthSession _parseResponse(http.Response response) {
    Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw AuthException(
        'Failed to parse server response (${response.statusCode})',
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = body['data'] as Map<String, dynamic>?;
      if (data != null) {
        return AuthSession.fromJson(data);
      }
      throw const AuthException('Invalid response structure from server');
    }

    final errorObj = body['error'] as Map<String, dynamic>?;
    if (errorObj != null) {
      final msg = errorObj['message'] as String? ?? 'An error occurred';
      final code = errorObj['code'] as String?;
      throw AuthException(msg, code: code);
    }

    throw AuthException('Server error (${response.statusCode})');
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});
