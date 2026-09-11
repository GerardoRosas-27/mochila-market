class AccountSession {
  const AccountSession({
    this.isLoggedIn = false,
    this.displayName = '',
    this.email = '',
    this.provider = 'demo',
  });

  final bool isLoggedIn;
  final String displayName;
  final String email;
  final String provider;

  AccountSession copyWith({
    bool? isLoggedIn,
    String? displayName,
    String? email,
    String? provider,
  }) {
    return AccountSession(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      provider: provider ?? this.provider,
    );
  }
}
