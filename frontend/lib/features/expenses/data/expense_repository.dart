import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:split_frontend/features/expenses/domain/expense_models.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return ExpenseRepository();
});

class ExpenseRepository {
  final http.Client _client;
  final FlutterSecureStorage _storage;
  final String _baseUrl;

  static const _tokenKey = 'jwt_auth_token';

  ExpenseRepository({
    http.Client? client,
    FlutterSecureStorage? storage,
    String? baseUrl,
  }) : _client = client ?? http.Client(),
       _storage = storage ?? const FlutterSecureStorage(),
       _baseUrl =
           baseUrl ??
           const String.fromEnvironment(
             'API_BASE_URL',
             defaultValue: 'http://127.0.0.1:8080',
           );

  Future<String> createExpense(
    String groupId,
    CreateExpenseRequest request,
  ) async {
    final token = await _storage.read(key: _tokenKey);

    final response = await _client.post(
      Uri.parse('$_baseUrl/api/groups/$groupId/expenses'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);
      return data['data']['id'] as String;
    } else {
      throw Exception('Failed to create expense: ${response.body}');
    }
  }

  Future<ExpenseDetailModel> getExpenseDetails(
    String groupId,
    String expenseId,
  ) async {
    final token = await _storage.read(key: _tokenKey);

    final response = await _client.get(
      Uri.parse('$_baseUrl/api/groups/$groupId/expenses/$expenseId'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);
      return ExpenseDetailModel.fromJson(data['data']);
    } else {
      throw Exception('Failed to fetch expense details: ${response.body}');
    }
  }

  Future<void> updateExpense(
    String groupId,
    String expenseId,
    CreateExpenseRequest request,
  ) async {
    final token = await _storage.read(key: _tokenKey);

    final response = await _client.put(
      Uri.parse('$_baseUrl/api/groups/$groupId/expenses/$expenseId'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to update expense: ${response.body}');
    }
  }

  Future<void> deleteExpense(String groupId, String expenseId) async {
    final token = await _storage.read(key: _tokenKey);

    final response = await _client.delete(
      Uri.parse('$_baseUrl/api/groups/$groupId/expenses/$expenseId'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to delete expense: ${response.body}');
    }
  }

  Future<List<SettlementModel>> getSettlements(String groupId) async {
    final token = await _storage.read(key: _tokenKey);

    final response = await _client.get(
      Uri.parse('$_baseUrl/api/groups/$groupId/settlements'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);
      final list = data['data'] as List<dynamic>? ?? [];
      return list.map((e) => SettlementModel.fromJson(e)).toList();
    } else {
      throw Exception('Failed to fetch settlements: ${response.body}');
    }
  }
}
