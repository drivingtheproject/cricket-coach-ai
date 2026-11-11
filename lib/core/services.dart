import 'package:flutter/widgets.dart';
import 'package:sqflite/sqflite.dart';

import 'auth/auth_controller.dart';
import 'auth/local_auth_repository.dart';
import 'db/app_database.dart';
import 'sessions/session_repository.dart';

/// The long-lived objects the app is built from.
class AppServices {
  AppServices({
    required this.database,
    required this.auth,
    required this.sessions,
  });

  final Database database;
  final AuthController auth;
  final SessionRepository sessions;

  /// Opens the on-device database and restores the previous sign-in.
  static Future<AppServices> create() async {
    final database = await AppDatabase.openOnDevice();
    final auth = AuthController(LocalAuthRepository(database));
    await auth.restore();
    return AppServices(
      database: database,
      auth: auth,
      sessions: SessionRepository(database),
    );
  }
}

/// Makes [AppServices] available to every widget below it.
class ServicesScope extends InheritedWidget {
  const ServicesScope({
    super.key,
    required this.services,
    required super.child,
  });

  final AppServices services;

  static AppServices of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ServicesScope>();
    assert(scope != null, 'No ServicesScope above this widget.');
    return scope!.services;
  }

  @override
  bool updateShouldNotify(ServicesScope oldWidget) =>
      oldWidget.services != services;
}
