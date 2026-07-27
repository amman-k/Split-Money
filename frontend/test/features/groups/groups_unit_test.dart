import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:split_frontend/features/groups/data/group_repository.dart';

import 'package:split_frontend/features/groups/presentation/controllers/create_group_controller.dart';
import 'package:split_frontend/features/groups/presentation/controllers/groups_list_controller.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    FlutterSecureStorage.setMockInitialValues({'jwt_auth_token': 'mock-token'});
  });

  group('GroupRepository Unit Tests', () {
    test('createGroup parses success response correctly', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.toString(), 'http://localhost:8080/api/groups');
        expect(request.method, 'POST');
        expect(request.headers['Authorization'], 'Bearer mock-token');

        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['name'], 'Ski Trip 2024');

        return http.Response(
          jsonEncode({
            'data': {
              'id': 'group-101',
              'name': 'Ski Trip 2024',
              'description': 'Winter vacation',
              'owner_id': 'owner-1',
              'members': [
                {
                  'id': 'm-1',
                  'group_id': 'group-101',
                  'name': 'You',
                  'is_owner': true,
                },
                {
                  'id': 'm-2',
                  'group_id': 'group-101',
                  'name': 'Alex',
                  'is_owner': false,
                },
              ],
            },
            'error': null,
          }),
          201,
        );
      });

      final repo = GroupRepository(
        client: mockClient,
        baseUrl: 'http://localhost:8080',
      );
      final grp = await repo.createGroup(
        name: 'Ski Trip 2024',
        description: 'Winter vacation',
        members: [
          {'name': 'You', 'is_owner': true},
          {'name': 'Alex', 'is_owner': false},
        ],
      );

      expect(grp.id, 'group-101');
      expect(grp.name, 'Ski Trip 2024');
      expect(grp.description, 'Winter vacation');
      expect(grp.members.length, 2);
      expect(grp.members[0].name, 'You');
      expect(grp.members[0].isOwner, true);
      expect(grp.members[1].name, 'Alex');
      expect(grp.members[1].isOwner, false);
    });

    test('createGroup throws GroupException on server error', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'data': null,
            'error': {
              'code': 'invalid_input',
              'message': 'Group name required',
            },
          }),
          400,
        );
      });

      final repo = GroupRepository(
        client: mockClient,
        baseUrl: 'http://localhost:8080',
      );
      expect(
        () => repo.createGroup(name: '', description: '', members: []),
        throwsA(
          isA<GroupException>().having(
            (e) => e.message,
            'message',
            'Group name required',
          ),
        ),
      );
    });

    test('getGroups parses list of groups correctly', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.toString(), 'http://localhost:8080/api/groups');
        expect(request.method, 'GET');
        return http.Response(
          jsonEncode({
            'data': [
              {
                'id': 'group-1',
                'name': 'Dinner',
                'description': '',
                'owner_id': 'owner-1',
                'members': [],
              },
              {
                'id': 'group-2',
                'name': 'Trip',
                'description': 'Summer',
                'owner_id': 'owner-1',
                'members': [],
              },
            ],
            'error': null,
          }),
          200,
        );
      });

      final repo = GroupRepository(
        client: mockClient,
        baseUrl: 'http://localhost:8080',
      );
      final list = await repo.getGroups();

      expect(list.length, 2);
      expect(list[0].name, 'Dinner');
      expect(list[1].name, 'Trip');
    });
  });

  group('CreateGroupController Unit Tests', () {
    test('createGroup success updates state to data(groupModel)', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'data': {
              'id': 'group-555',
              'name': 'Road Trip',
              'description': 'Cross country',
              'owner_id': 'owner-1',
              'members': [
                {
                  'id': 'm-1',
                  'group_id': 'group-555',
                  'name': 'You',
                  'is_owner': true,
                },
                {
                  'id': 'm-2',
                  'group_id': 'group-555',
                  'name': 'Sarah',
                  'is_owner': false,
                },
              ],
            },
            'error': null,
          }),
          201,
        );
      });

      final repo = GroupRepository(
        client: mockClient,
        baseUrl: 'http://localhost:8080',
      );
      final container = ProviderContainer(
        overrides: [groupRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      await container.read(createGroupControllerProvider.future);

      final success = await container
          .read(createGroupControllerProvider.notifier)
          .createGroup(
            name: 'Road Trip',
            description: 'Cross country',
            memberNames: ['Sarah'],
          );

      expect(success, isTrue);
      final state = container.read(createGroupControllerProvider);
      expect(state.hasValue, isTrue);
      expect(state.value?.name, 'Road Trip');
      expect(state.value?.members.length, 2);
    });

    test('createGroup failure updates state to error', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'data': null,
            'error': {
              'code': 'server_error',
              'message': 'Internal database failure',
            },
          }),
          500,
        );
      });

      final repo = GroupRepository(
        client: mockClient,
        baseUrl: 'http://localhost:8080',
      );
      final container = ProviderContainer(
        overrides: [groupRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      await container.read(createGroupControllerProvider.future);

      final success = await container
          .read(createGroupControllerProvider.notifier)
          .createGroup(
            name: 'Road Trip',
            description: 'Cross country',
            memberNames: [],
          );

      expect(success, isFalse);
      final state = container.read(createGroupControllerProvider);
      expect(state.hasError, isTrue);
      expect(state.error.toString(), 'Internal database failure');
    });
  });

  group('GroupsListController Unit Tests', () {
    test('build fetches groups list from repository on startup', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'data': [
              {
                'id': 'g-1',
                'name': 'Weekend Trip',
                'description': '',
                'owner_id': 'u-1',
                'members': [],
              },
            ],
            'error': null,
          }),
          200,
        );
      });

      final repo = GroupRepository(
        client: mockClient,
        baseUrl: 'http://localhost:8080',
      );
      final container = ProviderContainer(
        overrides: [groupRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      final groups = await container.read(groupsListControllerProvider.future);
      expect(groups.length, 1);
      expect(groups.first.name, 'Weekend Trip');
    });
  });
}
