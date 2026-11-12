import 'package:material_ui/material_ui.dart';

import '../../core/services.dart';
import '../../widgets/section_title.dart';
import '../coach/coach_settings_page.dart';
import 'sync_section.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Future<void> _confirmSignOut(BuildContext context) async {
    final auth = ServicesScope.of(context).auth;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          'Your sessions stay on this device and will be here when you sign '
          'back in.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) await auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final user = ServicesScope.of(context).auth.user;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          const SectionTitle('Coach'),
          ListTile(
            key: const Key('settings-coach'),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            leading: const Icon(Icons.record_voice_over_outlined),
            title: const Text('Who writes your feedback'),
            subtitle: const Text('Choose a coach and add your API keys'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const CoachSettingsPage(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const SyncSection(),
          const SizedBox(height: 16),
          const SectionTitle('Account'),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            leading: const Icon(Icons.person_outline),
            title: Text(user?.displayName ?? ''),
            subtitle: Text(user?.email ?? ''),
          ),
          ListTile(
            key: const Key('settings-sign-out'),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            leading: const Icon(Icons.logout),
            title: const Text('Sign out'),
            onTap: () => _confirmSignOut(context),
          ),
        ],
      ),
    );
  }
}
