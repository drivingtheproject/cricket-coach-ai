import 'package:material_ui/material_ui.dart';

import '../../core/services.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/section_title.dart';
import '../sessions/session_list_builder.dart';
import '../sessions/session_tile.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.onOpenSessions});

  final VoidCallback onOpenSessions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firstName = ServicesScope.of(context).auth.user?.firstName ?? '';
    return Scaffold(
      body: SafeArea(
        child: SessionListBuilder(
          builder: (context, sessions) => ListView(
            padding: const EdgeInsets.symmetric(vertical: 24),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      firstName.isEmpty ? 'Welcome' : 'Welcome, $firstName',
                      style: theme.textTheme.displaySmall,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Film a shot from side-on and get feedback on your '
                      'technique.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: null, // Wired up with video capture.
                        child: Text('Analyse a clip'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SectionTitle(
                'Recent sessions',
                action: sessions.isEmpty
                    ? null
                    : TextButton(
                        onPressed: onOpenSessions,
                        child: const Text('See all'),
                      ),
              ),
              if (sessions.isEmpty)
                const EmptyState(
                  icon: Icons.sports_cricket,
                  title: 'No sessions yet',
                  message: 'Your analysed clips will appear here.',
                )
              else
                for (final session in sessions.take(3))
                  SessionTile(session: session),
            ],
          ),
        ),
      ),
    );
  }
}
