import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:split_frontend/features/auth/data/auth_repository.dart';
import 'package:split_frontend/features/auth/domain/user.dart';

class AuthController extends AsyncNotifier<AuthSession?> {
  @override
  FutureOr<AuthSession?> build() async {
    final repo = ref.read(authRepositoryProvider);
    return repo.getCurrentUser();
  }

  bool validateEmail(String email) {
    final emailRegex = RegExp(r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+');
    return emailRegex.hasMatch(email);
  }

  bool validatePassword(String password) {
    return password.length >= 8;
  }

  bool validateFullName(String fullName) {
    return fullName.trim().isNotEmpty;
  }

  Future<bool> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(authRepositoryProvider);
      final session = await repo.signUp(
        fullName: fullName,
        email: email,
        password: password,
      );
      await repo.saveToken(session.token);
      return session;
    });
    return !state.hasError && state.value != null;
  }

  Future<bool> signIn({required String email, required String password}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(authRepositoryProvider);
      final session = await repo.signIn(email: email, password: password);
      await repo.saveToken(session.token);
      return session;
    });
    return !state.hasError && state.value != null;
  }

  Future<void> signOut() async {
    final repo = ref.read(authRepositoryProvider);
    await repo.deleteToken();
    state = const AsyncValue.data(null);
  }
}

final authControllerProvider =
    AsyncNotifierProvider<AuthController, AuthSession?>(AuthController.new);
