import 'package:material_ui/material_ui.dart';

import '../../core/analysis/filming_guide.dart';
import '../../core/sessions/session.dart';
import 'filming_tour_page.dart';

/// Lists the filming tours so they can be replayed at any time.
class FilmingGuidesPage extends StatelessWidget {
  const FilmingGuidesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('How to film')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          for (final discipline in Discipline.values)
            ListTile(
              key: Key('guide-${discipline.name}'),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              title: Text(discipline.label),
              subtitle: Text(FilmingGuide.of(discipline).intro),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => showFilmingTour(context, discipline),
            ),
        ],
      ),
    );
  }
}
