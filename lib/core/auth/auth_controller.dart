import 'package:flutter/foundation.dart';

import 'auth_repository.dart';
import 'user.dart';

enum AuthStatus { unknown, signedOut, signedIn }

/// Holds who is signed in and tells the UI when that changes.
class AuthController extends ChangeNotifier {
  AuthController(this._repository);

  final AuthRepository _repository;

  AuthStatus _status = AuthStatus.unknown;
  User? _user;

  AuthStatus get status => _status;
  User? get user => _user;

  /// Restores the previous sign-in when the app starts.
  Future<void> restore() async => _set(await _repository.currentUser());

  /// Throws [AuthException] when the details are wrong.
  Future<void> signIn({required String email, required String password}) async {
    _set(await _repository.signIn(email: email, password: password));
  }

  /// Throws [AuthException] when the email is already registered.
  Future<void> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    _set(
      await _repository.register(
        email: email,
        password: password,
        displayName: displayName,
      ),
    );
  }

  Future<void> signOut() async {
    await _repository.signOut();
    _set(null);
  }

  void _set(User? user) {
    _user = user;
    _status = user == null ? AuthStatus.signedOut : AuthStatus.signedIn;
    notifyListeners();
  }
}
