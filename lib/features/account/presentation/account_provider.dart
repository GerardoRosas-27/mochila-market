import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/models/account_session.dart';
import '../../../core/storage/secure_store.dart';

class AccountNotifier extends StateNotifier<AccountSession> {
  AccountNotifier(this._store) : super(const AccountSession()) {
    _restore();
  }

  final SecureStore _store;

  Future<void> _restore() async {
    final data = await _store.readSession();
    final token = data['token'];
    if (token != null && token.isNotEmpty) {
      state = AccountSession(
        isLoggedIn: true,
        displayName: data['name'] ?? 'Vendedor demo',
        email: data['email'] ?? 'demo@mochila.market',
        provider: 'demo',
      );
    }
  }

  Future<void> loginDemo({
    String name = 'Gerardo Vendedor',
    String email = 'vendedor@mochila.market',
  }) async {
    final token = const Uuid().v4();
    await _store.saveSession(token: token, name: name, email: email);
    state = AccountSession(
      isLoggedIn: true,
      displayName: name,
      email: email,
      provider: 'demo',
    );
  }

  Future<void> logout() async {
    await _store.clearSession();
    state = const AccountSession();
  }
}

final accountProvider =
    StateNotifierProvider<AccountNotifier, AccountSession>((ref) {
  return AccountNotifier(ref.watch(secureStoreProvider));
});
