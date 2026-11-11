import 'package:cricket_coach_ai/core/auth/auth_repository.dart';
import 'package:cricket_coach_ai/core/auth/user.dart';

/// In-memory accounts for tests that do not need a database.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({User? signedIn}) : _current = signedIn;

  final Map<String, (User, String)> _accounts = {};
  User? _current;

  @override
  Future<User?> currentUser() async => _current;

  @override
  Future<User> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    if (_accounts.containsKey(email)) {
      throw const AuthException(AuthFailure.emailInUse);
    }
    final user = User(
      id: 'id-${_accounts.length + 1}',
      email: email,
      displayName: displayName,
      createdAt: DateTime(2026),
    );
    _accounts[email] = (user, password);
    return _current = user;
  }

  @override
  Future<User> signIn({required String email, required String password}) async {
    final account = _accounts[email];
    if (account == null || account.$2 != password) {
      throw const AuthException(AuthFailure.invalidCredentials);
    }
    return _current = account.$1;
  }

  @override
  Future<void> signOut() async => _current = null;
}
