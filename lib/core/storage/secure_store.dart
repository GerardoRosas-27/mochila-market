import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
});

/// Persistencia de secretos / sesión.
/// En web usa SharedPreferences (flutter_secure_storage falla a menudo en HTTPS).
/// En móvil/desktop preferimos flutter_secure_storage.
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

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<void> _write(String key, String? value) async {
    if (kIsWeb) {
      final p = await _prefs;
      if (value == null) {
        await p.remove(key);
      } else {
        await p.setString(key, value);
      }
      return;
    }
    if (value == null) {
      await _storage.delete(key: key);
    } else {
      await _storage.write(key: key, value: value);
    }
  }

  Future<String?> _read(String key) async {
    if (kIsWeb) {
      return (await _prefs).getString(key);
    }
    try {
      return await _storage.read(key: key);
    } catch (_) {
      // Fallback si secure storage falla en alguna plataforma.
      return (await _prefs).getString(key);
    }
  }

  Future<void> saveImageApiKey(String value) =>
      _write(_keyImageApi, value);

  Future<String?> readImageApiKey() => _read(_keyImageApi);

  Future<void> saveMultimodalApiKey(String value) =>
      _write(_keyMultiApi, value);

  Future<String?> readMultimodalApiKey() => _read(_keyMultiApi);

  Future<void> saveRemoveBgApiKey(String value) =>
      _write(_keyRemoveBg, value);

  Future<String?> readRemoveBgApiKey() => _read(_keyRemoveBg);

  Future<void> saveSession({
    required String token,
    required String name,
    required String email,
  }) async {
    await _write(_keySessionToken, token);
    await _write(_keySessionName, name);
    await _write(_keySessionEmail, email);
  }

  Future<Map<String, String?>> readSession() async {
    return {
      'token': await _read(_keySessionToken),
      'name': await _read(_keySessionName),
      'email': await _read(_keySessionEmail),
    };
  }

  Future<void> clearSession() async {
    await _write(_keySessionToken, null);
    await _write(_keySessionName, null);
    await _write(_keySessionEmail, null);
  }

  // —— Auth local ——
  Future<void> saveLocalCredentials({
    required String username,
    required String passwordHash,
    required String displayName,
  }) async {
    await _write(_keyLocalUsername, username);
    await _write(_keyLocalPasswordHash, passwordHash);
    await _write(_keyLocalDisplayName, displayName);
  }

  Future<Map<String, String?>> readLocalCredentials() async {
    return {
      'username': await _read(_keyLocalUsername),
      'passwordHash': await _read(_keyLocalPasswordHash),
      'displayName': await _read(_keyLocalDisplayName),
    };
  }

  Future<bool> hasLocalUser() async {
    final u = await _read(_keyLocalUsername);
    final h = await _read(_keyLocalPasswordHash);
    return u != null && u.isNotEmpty && h != null && h.isNotEmpty;
  }

  Future<void> setLocalSessionActive(bool active) async {
    await _write(_keyLocalSessionActive, active ? '1' : '0');
  }

  Future<bool> isLocalSessionActive() async {
    return (await _read(_keyLocalSessionActive)) == '1';
  }

  Future<void> clearLocalSession() async {
    await _write(_keyLocalSessionActive, '0');
  }
}

final secureStoreProvider = Provider<SecureStore>((ref) {
  return SecureStore(ref.watch(secureStorageProvider));
});
