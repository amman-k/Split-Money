import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:split_frontend/features/auth/presentation/controllers/auth_controller.dart';
import 'package:split_frontend/features/auth/data/auth_repository.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    FlutterSecureStorage.setMockInitialValues({});
  });

  group('AuthRepository Unit Tests', () {
    test('signUp parses success response accurately', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.toString(), 'http://localhost:8080/api/signup');
        expect(request.method, 'POST');
        return http.Response(
          jsonEncode({
            'data': {
              'token': 'mock-token-123',
              'user': {
                'id': 'user-1',
                'email': 'test@example.com',
                'full_name': 'Test User',
              },
            },
            'error': null,
          }),
          201,
        );
      });

      final repo = AuthRepository(
        client: mockClient,
        baseUrl: 'http://localhost:8080',
      );
      final session = await repo.signUp(
        fullName: 'Test User',
        email: 'test@example.com',
        password: 'password123',
      );

      expect(session.token, 'mock-token-123');
      expect(session.user.id, 'user-1');
      expect(session.user.email, 'test@example.com');
      expect(session.user.fullName, 'Test User');
    });

    test(
      'signIn throws AuthException when server returns error envelope',
      () async {
        final mockClient = MockClient((request) async {
          return http.Response(
            jsonEncode({
              'data': null,
              'error': {
                'code': 'invalid_credentials',
                'message': 'Invalid email or password',
              },
            }),
            401,
          );
        });

        final repo = AuthRepository(
          client: mockClient,
          baseUrl: 'http://localhost:8080',
        );
        expect(
          () => repo.signIn(
            email: 'wrong@example.com',
            password: 'wrongpassword',
          ),
          throwsA(
            isA<AuthException>()
                .having(
                  (e) => e.message,
                  'message',
                  'Invalid email or password',
                )
                .having((e) => e.code, 'code', 'invalid_credentials'),
          ),
        );
      },
    );

    test('saveToken, getToken, deleteToken persist securely', () async {
      final repo = AuthRepository();
      expect(await repo.getToken(), isNull);

      await repo.saveToken('jwt-abc-123');
      expect(await repo.getToken(), 'jwt-abc-123');

      await repo.deleteToken();
      expect(await repo.getToken(), isNull);
    });

    test(
      'getCurrentUser returns session when token valid and server returns 200',
      () async {
        final mockClient = MockClient((request) async {
          expect(request.headers['Authorization'], 'Bearer stored-jwt-token');
          return http.Response(
            jsonEncode({
              'data': {
                'id': 'user-99',
                'email': 'stored@example.com',
                'full_name': 'Stored User',
              },
              'error': null,
            }),
            200,
          );
        });

        final repo = AuthRepository(
          client: mockClient,
          baseUrl: 'http://localhost:8080',
        );
        await repo.saveToken('stored-jwt-token');

        final session = await repo.getCurrentUser();
        expect(session, isNotNull);
        expect(session?.token, 'stored-jwt-token');
        expect(session?.user.email, 'stored@example.com');
      },
    );
  });

  group('AuthController Riverpod Tests', () {
    test(
      'initial state completes build() as data(null) when no token stored',
      () async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        // Await initial async build
        final initialSession = await container.read(
          authControllerProvider.future,
        );
        expect(initialSession, isNull);

        final state = container.read(authControllerProvider);
        expect(state.value, isNull);
        expect(state.isLoading, isFalse);
      },
    );

    test(
      'signIn transitions state to data(session) on success and saves token',
      () async {
        final mockClient = MockClient((request) async {
          return http.Response(
            jsonEncode({
              'data': {
                'token': 'mock-token-abc',
                'user': {
                  'id': 'user-abc',
                  'email': 'abc@example.com',
                  'full_name': 'ABC User',
                },
              },
              'error': null,
            }),
            200,
          );
        });

        final repo = AuthRepository(
          client: mockClient,
          baseUrl: 'http://localhost:8080',
        );

        final container = ProviderContainer(
          overrides: [authRepositoryProvider.overrideWithValue(repo)],
        );
        addTearDown(container.dispose);

        await container.read(authControllerProvider.future);

        final success = await container
            .read(authControllerProvider.notifier)
            .signIn(email: 'abc@example.com', password: 'password123');

        expect(success, isTrue);
        final state = container.read(authControllerProvider);
        expect(state.hasValue, isTrue);
        expect(state.value?.token, 'mock-token-abc');
        expect(state.value?.user.email, 'abc@example.com');

        expect(await repo.getToken(), 'mock-token-abc');
      },
    );

    test('signIn transitions state to error on failure', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'data': null,
            'error': {
              'code': 'invalid_credentials',
              'message': 'Wrong password',
            },
          }),
          401,
        );
      });

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            AuthRepository(
              client: mockClient,
              baseUrl: 'http://localhost:8080',
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authControllerProvider.future);

      final success = await container
          .read(authControllerProvider.notifier)
          .signIn(email: 'abc@example.com', password: 'wrong');

      expect(success, isFalse);
      final state = container.read(authControllerProvider);
      expect(state.hasError, isTrue);
      expect(state.error.toString(), 'Wrong password');
    });

    test('signOut deletes token and resets state to null', () async {
      final repo = AuthRepository();
      await repo.saveToken('token-to-be-deleted');

      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      await container.read(authControllerProvider.future);

      await container.read(authControllerProvider.notifier).signOut();
      final state = container.read(authControllerProvider);
      expect(state.value, isNull);
      expect(state.isLoading, isFalse);

      expect(await repo.getToken(), isNull);
    });
  });
}
