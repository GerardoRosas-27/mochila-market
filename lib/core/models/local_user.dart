class LocalUser {
  const LocalUser({
    required this.username,
    this.displayName = '',
  });

  final String username;
  final String displayName;
}

class AuthState {
  const AuthState({
    this.hasRegisteredUser = false,
    this.isAuthenticated = false,
    this.username = '',
    this.displayName = '',
    this.loading = true,
    this.error,
  });

  final bool hasRegisteredUser;
  final bool isAuthenticated;
  final String username;
  final String displayName;
  final bool loading;
  final String? error;

  AuthState copyWith({
    bool? hasRegisteredUser,
    bool? isAuthenticated,
    String? username,
    String? displayName,
    bool? loading,
    String? error,
    bool clearError = false,
  }) {
    return AuthState(
      hasRegisteredUser: hasRegisteredUser ?? this.hasRegisteredUser,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
