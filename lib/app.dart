import 'package:material_ui/material_ui.dart';

import 'core/auth/auth_controller.dart';
import 'core/services.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/login_page.dart';
import 'features/shell/app_shell.dart';

class CricketCoachApp extends StatelessWidget {
  const CricketCoachApp({super.key, required this.services});

  final AppServices services;

  @override
  Widget build(BuildContext context) {
    return ServicesScope(
      services: services,
      child: MaterialApp(
        title: 'Cricket Coach',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        home: ListenableBuilder(
          listenable: services.auth,
          builder: (context, _) => switch (services.auth.status) {
            AuthStatus.unknown => const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              ),
            AuthStatus.signedOut => LoginPage(auth: services.auth),
            AuthStatus.signedIn => const AppShell(),
          },
        ),
      ),
    );
  }
}
