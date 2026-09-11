import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
});

class SecureStore {
  SecureStore(this._storage);

  final FlutterSecureStorage _storage;

  static const _keyImageApi = 'ai_image_api_key';
  static const _keyMultiApi = 'ai_multimodal_api_key';
  static const _keyRemoveBg = 'remove_bg_api_key';
  static const _keySessionToken = 'account_session_token';
  static const _keySessionName = 'account_display_name';
  static const _keySessionEmail = 'account_email';

  // Local app auth
  static const _keyLocalUsername = 'local_auth_username';
  static const _keyLocalPasswordHash = 'local_auth_password_hash';
  static const _keyLocalDisplayName = 'local_auth_display_name';
  static const _keyLocalSessionActive = 'local_auth_session_active';

  Future<void> saveImageApiKey(String value) =>
      _storage.write(key: _keyImageApi, value: value);

  Future<String?> readImageApiKey() => _storage.read(key: _keyImageApi);

  Future<void> saveMultimodalApiKey(String value) =>
      _storage.write(key: _keyMultiApi, value: value);

  Future<String?> readMultimodalApiKey() => _storage.read(key: _keyMultiApi);

  Future<void> saveRemoveBgApiKey(String value) =>
      _storage.write(key: _keyRemoveBg, value: value);

  Future<String?> readRemoveBgApiKey() => _storage.read(key: _keyRemoveBg);

  Future<void> saveSession({
    required String token,
    required String name,
    required String email,
  }) async {
    await _storage.write(key: _keySessionToken, value: token);
    await _storage.write(key: _keySessionName, value: name);
    await _storage.write(key: _keySessionEmail, value: email);
  }

  Future<Map<String, String?>> readSession() async {
    return {
      'token': await _storage.read(key: _keySessionToken),
      'name': await _storage.read(key: _keySessionName),
      'email': await _storage.read(key: _keySessionEmail),
    };
  }

  Future<void> clearSession() async {
    await _storage.delete(key: _keySessionToken);
    await _storage.delete(key: _keySessionName);
    await _storage.delete(key: _keySessionEmail);
  }

  // —— Auth local ——
  Future<void> saveLocalCredentials({
    required String username,
    required String passwordHash,
    required String displayName,
  }) async {
    await _storage.write(key: _keyLocalUsername, value: username);
    await _storage.write(key: _keyLocalPasswordHash, value: passwordHash);
    await _storage.write(key: _keyLocalDisplayName, value: displayName);
  }

  Future<Map<String, String?>> readLocalCredentials() async {
    return {
      'username': await _storage.read(key: _keyLocalUsername),
      'passwordHash': await _storage.read(key: _keyLocalPasswordHash),
      'displayName': await _storage.read(key: _keyLocalDisplayName),
    };
  }

  Future<bool> hasLocalUser() async {
    final u = await _storage.read(key: _keyLocalUsername);
    final h = await _storage.read(key: _keyLocalPasswordHash);
    return u != null && u.isNotEmpty && h != null && h.isNotEmpty;
  }

  Future<void> setLocalSessionActive(bool active) async {
    await _storage.write(
      key: _keyLocalSessionActive,
      value: active ? '1' : '0',
    );
  }

  Future<bool> isLocalSessionActive() async {
    return (await _storage.read(key: _keyLocalSessionActive)) == '1';
  }

  Future<void> clearLocalSession() async {
    await _storage.write(key: _keyLocalSessionActive, value: '0');
  }
}

final secureStoreProvider = Provider<SecureStore>((ref) {
  return SecureStore(ref.watch(secureStorageProvider));
});
