import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:split_frontend/features/groups/domain/group_model.dart';
import 'package:split_frontend/features/groups/domain/expense_model.dart';
import 'package:split_frontend/features/groups/domain/balances_model.dart';

class GroupException implements Exception {
  const GroupException(this.message, {this.code});
  final String message;
  final String? code;

  @override
  String toString() => message;
}

class GroupRepository {
  GroupRepository({
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
  static const _localGroupsKey = 'local_user_groups';

  Future<String?> _getToken() async {
    return _storage.read(key: _tokenKey);
  }

  Future<List<GroupModel>> _getLocalGroups() async {
    try {
      final jsonStr = await _storage.read(key: _localGroupsKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final decoded = jsonDecode(jsonStr) as List<dynamic>;
        return decoded
            .map((item) => GroupModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  Future<void> _saveLocalGroups(List<GroupModel> groups) async {
    try {
      final jsonStr = jsonEncode(groups.map((e) => e.toJson()).toList());
      await _storage.write(key: _localGroupsKey, value: jsonStr);
    } catch (_) {}
  }

  Future<GroupModel> createGroup({
    required String name,
    required String description,
    required List<Map<String, dynamic>> members,
  }) async {
    final localGroups = await _getLocalGroups();
    final localId = 'group-${DateTime.now().millisecondsSinceEpoch}';
    final localMembers = members.asMap().entries.map((entry) {
      final m = entry.value;
      return GroupMemberModel(
        id: 'm-${entry.key}-$localId',
        groupId: localId,
        name: m['name'] as String? ?? 'Member',
        isOwner: m['is_owner'] as bool? ?? false,
      );
    }).toList();

    final localGroup = GroupModel(
      id: localId,
      name: name,
      description: description,
      ownerId: 'current_user',
      members: localMembers,
    );

    final token = await _getToken();
    if (token == null || token.isEmpty) {
      // If no token right now during local/offline testing, save locally and return
      await _saveLocalGroups([localGroup, ...localGroups]);
      return localGroup;
    }

    http.Response response;
    try {
      final uri = Uri.parse('$_baseUrl/api/groups');
      response = await _client.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'name': name,
          'description': description,
          'members': members,
        }),
      );
    } on SocketException catch (_) {
      await _saveLocalGroups([localGroup, ...localGroups]);
      return localGroup;
    } on http.ClientException catch (_) {
      await _saveLocalGroups([localGroup, ...localGroups]);
      return localGroup;
    }

    // If server responded with validation/error envelope, _parseGroupResponse will throw GroupException
    final remoteGroup = _parseGroupResponse(response);
    final updatedLocal = await _getLocalGroups();
    final merged = [
      remoteGroup,
      ...updatedLocal.where((g) => g.id != localId && g.id != remoteGroup.id),
    ];
    await _saveLocalGroups(merged);
    return remoteGroup;
  }

  Future<List<GroupModel>> getGroups() async {
    final localGroups = await _getLocalGroups();

    final token = await _getToken();
    if (token == null || token.isEmpty) {
      return localGroups;
    }

    http.Response response;
    try {
      final uri = Uri.parse('$_baseUrl/api/groups');
      response = await _client.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
    } on SocketException catch (_) {
      return localGroups;
    } on http.ClientException catch (_) {
      return localGroups;
    }

    final remoteGroups = _parseListResponse(response);
    final merged = <GroupModel>[];
    final seenIds = <String>{};

    for (final g in remoteGroups) {
      seenIds.add(g.id);
      merged.add(g);
    }
    for (final g in localGroups) {
      if (!seenIds.contains(g.id) && !seenIds.contains(g.name)) {
        seenIds.add(g.id);
        merged.add(g);
      }
    }

    await _saveLocalGroups(merged);
    return merged;
  }

  GroupModel _parseGroupResponse(http.Response response) {
    Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw GroupException(
        'Failed to parse server response (${response.statusCode})',
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = body['data'] as Map<String, dynamic>?;
      if (data != null) {
        return GroupModel.fromJson(data);
      }
      throw const GroupException('Invalid response structure from server');
    }

    final errorObj = body['error'] as Map<String, dynamic>?;
    if (errorObj != null) {
      final msg = errorObj['message'] as String? ?? 'An error occurred';
      final code = errorObj['code'] as String?;
      throw GroupException(msg, code: code);
    }

    throw GroupException('Server error (${response.statusCode})');
  }

  List<GroupModel> _parseListResponse(http.Response response) {
    Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw GroupException(
        'Failed to parse server response (${response.statusCode})',
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = body['data'] as List<dynamic>?;
      if (data != null) {
        return data
            .map((item) => GroupModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      throw const GroupException('Invalid response structure from server');
    }

    final errorObj = body['error'] as Map<String, dynamic>?;
    if (errorObj != null) {
      final msg = errorObj['message'] as String? ?? 'An error occurred';
      final code = errorObj['code'] as String?;
      throw GroupException(msg, code: code);
    }

    throw GroupException('Server error (${response.statusCode})');
  }

  Future<GroupModel> getGroupDetails(String groupId) async {
    final token = await _getToken();
    if (token == null || token.isEmpty) {
      // Offline fallback: find in local groups
      final localGroups = await _getLocalGroups();
      try {
        return localGroups.firstWhere((g) => g.id == groupId);
      } catch (_) {
        throw const GroupException(
          'Group not found locally and not authenticated',
        );
      }
    }

    http.Response response;
    try {
      final uri = Uri.parse('$_baseUrl/api/groups/$groupId');
      response = await _client.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
    } catch (_) {
      throw const GroupException('Network error fetching group details');
    }

    return _parseGroupResponse(response);
  }

  Future<List<ExpenseModel>> getGroupExpenses(String groupId) async {
    final token = await _getToken();
    if (token == null || token.isEmpty) return [];

    http.Response response;
    try {
      final uri = Uri.parse('$_baseUrl/api/groups/$groupId/expenses');
      response = await _client.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
    } catch (_) {
      return [];
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final data = body['data'] as List<dynamic>? ?? [];
      return data
          .map((e) => ExpenseModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return [];
  }

  Future<BalancesModel> getGroupBalances(String groupId) async {
    final token = await _getToken();
    if (token == null || token.isEmpty) {
      return const BalancesModel(userBalance: 0, totalGroupBalance: 0);
    }

    http.Response response;
    try {
      final uri = Uri.parse('$_baseUrl/api/groups/$groupId/balances');
      response = await _client.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
    } catch (_) {
      return const BalancesModel(userBalance: 0, totalGroupBalance: 0);
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>?;
      if (data != null) {
        return BalancesModel.fromJson(data);
      }
    }

    return const BalancesModel(userBalance: 0, totalGroupBalance: 0);
  }

  Future<void> addMembers({
    required String groupId,
    required List<Map<String, dynamic>> members,
  }) async {
    final token = await _getToken();
    if (token == null || token.isEmpty) {
      throw const GroupException('Authentication required to add members');
    }

    http.Response response;
    try {
      final uri = Uri.parse('$_baseUrl/api/groups/$groupId/members');
      response = await _client.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'members': members}),
      );
    } catch (_) {
      throw const GroupException('Network error adding members');
    }

    // This will throw if the server responded with an error
    _parseGroupResponse(response);
  }

  Future<void> deleteGroup(String groupId) async {
    final token = await _getToken();
    if (token == null || token.isEmpty) {
      throw const GroupException('Authentication required to delete a group');
    }

    http.Response response;
    try {
      final uri = Uri.parse('$_baseUrl/api/groups/$groupId');
      response = await _client.delete(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
    } catch (_) {
      throw const GroupException('Network error deleting group');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      // Successfully deleted. Now update local cache.
      final localGroups = await _getLocalGroups();
      final updatedGroups = localGroups.where((g) => g.id != groupId).toList();
      await _saveLocalGroups(updatedGroups);
      return;
    }

    // Try parsing error
    Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw GroupException(
        'Failed to parse server response (${response.statusCode})',
      );
    }

    final errorObj = body['error'] as Map<String, dynamic>?;
    if (errorObj != null) {
      final msg = errorObj['message'] as String? ?? 'An error occurred';
      final code = errorObj['code'] as String?;
      throw GroupException(msg, code: code);
    }

    throw GroupException('Server error (${response.statusCode})');
  }
}

final groupRepositoryProvider = Provider<GroupRepository>((ref) {
  return GroupRepository();
});
