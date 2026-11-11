import 'package:cricket_coach_ai/core/auth/auth_controller.dart';
import 'package:cricket_coach_ai/core/theme/app_theme.dart';
import 'package:cricket_coach_ai/features/auth/login_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/fake_auth_repository.dart';

void main() {
  late AuthController auth;

  setUp(() async {
    final repository = FakeAuthRepository();
    await repository.register(
      email: 'asha@club.org',
      password: 'cover-drive',
      displayName: 'Asha Rao',
    );
    await repository.signOut();
    auth = AuthController(repository);
    await auth.restore();
  });

  Future<void> pumpLogin(WidgetTester tester) => tester.pumpWidget(
        MaterialApp(theme: AppTheme.light(), home: LoginPage(auth: auth)),
      );

  Future<void> submit(WidgetTester tester) async {
    final button = find.byKey(const Key('login-submit'));
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  testWidgets('asks for email and password when they are missing',
      (tester) async {
    await pumpLogin(tester);

    await submit(tester);

    expect(find.text('Enter your email address.'), findsOneWidget);
    expect(find.text('Enter your password.'), findsOneWidget);
    expect(auth.status, AuthStatus.signedOut);
  });

  testWidgets('signs in with the right details', (tester) async {
    await pumpLogin(tester);

    await tester.enterText(
      find.byKey(const Key('login-email')),
      'asha@club.org',
    );
    await tester.enterText(
      find.byKey(const Key('login-password')),
      'cover-drive',
    );
    await submit(tester);

    expect(auth.status, AuthStatus.signedIn);
    expect(auth.user?.displayName, 'Asha Rao');
  });

  testWidgets('explains a wrong password', (tester) async {
    await pumpLogin(tester);

    await tester.enterText(
      find.byKey(const Key('login-email')),
      'asha@club.org',
    );
    await tester.enterText(find.byKey(const Key('login-password')), 'wrong');
    await submit(tester);

    expect(find.text('Email or password is incorrect.'), findsOneWidget);
    expect(auth.status, AuthStatus.signedOut);
  });

  testWidgets('opens the create-account screen', (tester) async {
    await pumpLogin(tester);

    final link = find.text('Create an account');
    await tester.ensureVisible(link);
    await tester.tap(link);
    await tester.pumpAndSettle();

    expect(find.text('Create your account'), findsOneWidget);
  });
}
