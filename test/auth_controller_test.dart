import 'package:cricket_coach_ai/core/auth/auth_controller.dart';
import 'package:cricket_coach_ai/core/auth/auth_repository.dart';
import 'package:cricket_coach_ai/core/auth/user.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_auth_repository.dart';

void main() {
  test('starts unknown, then signed out when nobody is remembered', () async {
    final controller = AuthController(FakeAuthRepository());
    expect(controller.status, AuthStatus.unknown);

    await controller.restore();

    expect(controller.status, AuthStatus.signedOut);
    expect(controller.user, isNull);
  });

  test('restore picks up a remembered user', () async {
    final remembered = User(
      id: 'u1',
      email: 'asha@club.org',
      displayName: 'Asha Rao',
      createdAt: DateTime(2026),
    );
    final controller = AuthController(FakeAuthRepository(signedIn: remembered));

    await controller.restore();

    expect(controller.status, AuthStatus.signedIn);
    expect(controller.user?.email, 'asha@club.org');
  });

  test('register, sign out and sign in move through the states', () async {
    final controller = AuthController(FakeAuthRepository());
    final seen = <AuthStatus>[];
    controller.addListener(() => seen.add(controller.status));

    await controller.register(
      email: 'asha@club.org',
      password: 'cover-drive',
      displayName: 'Asha Rao',
    );
    await controller.signOut();
    await controller.signIn(email: 'asha@club.org', password: 'cover-drive');

    expect(seen, [
      AuthStatus.signedIn,
      AuthStatus.signedOut,
      AuthStatus.signedIn,
    ]);
    expect(controller.user?.displayName, 'Asha Rao');
  });

  test('a failed sign-in throws and leaves the state alone', () async {
    final controller = AuthController(FakeAuthRepository());
    await controller.restore();

    await expectLater(
      controller.signIn(email: 'asha@club.org', password: 'wrong'),
      throwsA(isA<AuthException>()),
    );

    expect(controller.status, AuthStatus.signedOut);
  });
}
