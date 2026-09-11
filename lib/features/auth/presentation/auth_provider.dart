import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/local_user.dart';
import '../../../core/storage/secure_store.dart';
import '../data/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(secureStoreProvider));
});

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._repo) : super(const AuthState()) {
    _bootstrap();
  }

  final AuthRepository _repo;

  Future<void> _bootstrap() async {
    final hasUser = await _repo.hasRegisteredUser();
    final session = hasUser && await _repo.isSessionActive();
    String username = '';
    String displayName = '';
    if (hasUser) {
      final data = await _repo.readUser();
      username = data['username'] ?? '';
      displayName = data['displayName'] ?? username;
    }
    state = AuthState(
      hasRegisteredUser: hasUser,
      isAuthenticated: session,
      username: username,
      displayName: displayName,
      loading: false,
    );
  }

  Future<bool> register({
    required String username,
    required String password,
    String displayName = '',
  }) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      await _repo.register(
        username: username,
        password: password,
        displayName: displayName,
      );
      state = AuthState(
        hasRegisteredUser: true,
        isAuthenticated: true,
        username: username.trim(),
        displayName:
            displayName.trim().isEmpty ? username.trim() : displayName.trim(),
        loading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> login({
    required String username,
    required String password,
  }) async {
    state = state.copyWith(loading: true, clearError: true);
    final ok = await _repo.login(username: username, password: password);
    if (ok) {
      final data = await _repo.readUser();
      state = AuthState(
        hasRegisteredUser: true,
        isAuthenticated: true,
        username: data['username'] ?? username,
        displayName: data['displayName'] ?? username,
        loading: false,
      );
    } else {
      state = state.copyWith(
        loading: false,
        error: 'Usuario o contraseña incorrectos',
      );
    }
    return ok;
  }

  Future<void> logout() async {
    await _repo.logout();
    state = AuthState(
      hasRegisteredUser: state.hasRegisteredUser,
      isAuthenticated: false,
      username: state.username,
      displayName: state.displayName,
      loading: false,
    );
  }

  Future<void> refresh() => _bootstrap();
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});
