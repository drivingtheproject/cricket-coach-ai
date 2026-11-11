import 'package:cricket_coach_ai/core/auth/auth_repository.dart';
import 'package:cricket_coach_ai/core/auth/local_auth_repository.dart';
import 'package:cricket_coach_ai/core/auth/password_hasher.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'support/test_database.dart';

Matcher throwsAuth(AuthFailure failure) => throwsA(
      isA<AuthException>().having((e) => e.failure, 'failure', failure),
    );

void main() {
  late Database db;
  late LocalAuthRepository repository;

  LocalAuthRepository newRepository() => LocalAuthRepository(
        db,
        hasher: const PasswordHasher(iterations: 10),
      );

  setUp(() async {
    db = await openTestDatabase();
    repository = newRepository();
  });

  tearDown(() => db.close());

  Future<void> registerAsha() => repository.register(
        email: 'Asha@Club.org ',
        password: 'cover-drive',
        displayName: ' Asha Rao ',
      );

  test('register creates the account and signs the user in', () async {
    final user = await repository.register(
      email: 'Asha@Club.org ',
      password: 'cover-drive',
      displayName: ' Asha Rao ',
    );

    expect(user.email, 'asha@club.org');
    expect(user.displayName, 'Asha Rao');
    expect(user.firstName, 'Asha');
    expect((await repository.currentUser())?.id, user.id);
  });

  test('the password is stored hashed, never in plain text', () async {
    await registerAsha();
    final row = (await db.query('users')).single;
    final stored = row['password_hash']! as String;

    expect(stored, startsWith(r'pbkdf2_sha256$'));
    expect(stored, isNot(contains('cover-drive')));
  });

  test('an email can only be registered once, whatever its case', () async {
    await registerAsha();

    await expectLater(
      repository.register(
        email: 'asha@club.org',
        password: 'another-pass',
        displayName: 'Imposter',
      ),
      throwsAuth(AuthFailure.emailInUse),
    );
  });

  test('signIn accepts the right password', () async {
    await registerAsha();
    await repository.signOut();

    final user = await repository.signIn(
      email: 'ASHA@club.org',
      password: 'cover-drive',
    );

    expect(user.email, 'asha@club.org');
    expect((await repository.currentUser())?.id, user.id);
  });

  test('signIn rejects a wrong password and an unknown email', () async {
    await registerAsha();
    await repository.signOut();

    await expectLater(
      repository.signIn(email: 'asha@club.org', password: 'pull-shot'),
      throwsAuth(AuthFailure.invalidCredentials),
    );
    await expectLater(
      repository.signIn(email: 'nobody@club.org', password: 'cover-drive'),
      throwsAuth(AuthFailure.invalidCredentials),
    );
    expect(await repository.currentUser(), isNull);
  });

  test('signOut forgets the current user but keeps the account', () async {
    await registerAsha();
    await repository.signOut();

    expect(await repository.currentUser(), isNull);
    expect(await db.query('users'), hasLength(1));
  });

  test('the sign-in survives an app restart', () async {
    final user = await registerAsha().then((_) => repository.currentUser());

    final afterRestart = newRepository();

    expect((await afterRestart.currentUser())?.id, user?.id);
  });
}
