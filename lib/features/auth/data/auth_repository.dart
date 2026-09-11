import 'package:bcrypt/bcrypt.dart';

import '../../../core/storage/secure_store.dart';

class AuthRepository {
  AuthRepository(this._store);

  final SecureStore _store;

  Future<bool> hasRegisteredUser() => _store.hasLocalUser();

  Future<bool> isSessionActive() => _store.isLocalSessionActive();

  Future<Map<String, String?>> readUser() => _store.readLocalCredentials();

  Future<void> register({
    required String username,
    required String password,
    String displayName = '',
  }) async {
    final trimmed = username.trim();
    if (trimmed.isEmpty || password.length < 6) {
      throw ArgumentError(
        'Usuario requerido y contraseña de al menos 6 caracteres',
      );
    }
    final hash = BCrypt.hashpw(password, BCrypt.gensalt());
    await _store.saveLocalCredentials(
      username: trimmed,
      passwordHash: hash,
      displayName: displayName.trim().isEmpty ? trimmed : displayName.trim(),
    );
    await _store.setLocalSessionActive(true);
  }

  Future<bool> login({
    required String username,
    required String password,
  }) async {
    final data = await _store.readLocalCredentials();
    final storedUser = data['username'];
    final hash = data['passwordHash'];
    if (storedUser == null || hash == null) return false;
    if (storedUser.toLowerCase() != username.trim().toLowerCase()) {
      return false;
    }
    final ok = BCrypt.checkpw(password, hash);
    if (ok) await _store.setLocalSessionActive(true);
    return ok;
  }

  Future<void> logout() => _store.clearLocalSession();
}
