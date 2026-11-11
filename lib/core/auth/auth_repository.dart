import 'user.dart';

enum AuthFailure { emailInUse, invalidCredentials }

class AuthException implements Exception {
  const AuthException(this.failure);

  final AuthFailure failure;

  /// Message suitable for showing next to the form.
  String get message => switch (failure) {
        AuthFailure.emailInUse =>
          'An account with this email already exists. Sign in instead.',
        AuthFailure.invalidCredentials => 'Email or password is incorrect.',
      };

  @override
  String toString() => 'AuthException(${failure.name})';
}

/// Account storage. The local SQLite implementation ships today; a Firebase
/// Auth implementation can replace it without touching the UI.
abstract interface class AuthRepository {
  /// The user who is signed in on this device, if any.
  Future<User?> currentUser();

  Future<User> register({
    required String email,
    required String password,
    required String displayName,
  });

  Future<User> signIn({required String email, required String password});

  Future<void> signOut();
}
