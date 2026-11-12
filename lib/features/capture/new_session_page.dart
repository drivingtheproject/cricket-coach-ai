import 'package:material_ui/material_ui.dart';

import '../../core/analysis/filming_guide.dart';
import '../../core/capture/clip_picker.dart';
import '../../core/services.dart';
import '../../core/sessions/session.dart';
import '../guide/filming_tour_page.dart';
import 'analysis_page.dart';

/// Where a new analysis starts: pick what you are practising, then record or
/// choose a clip.
class NewSessionPage extends StatefulWidget {
  const NewSessionPage({super.key});

  @override
  State<NewSessionPage> createState() => _NewSessionPageState();
}

class _NewSessionPageState extends State<NewSessionPage> {
  Discipline _discipline = Discipline.batting;
  Handedness _handedness = Handedness.right;
  bool _picking = false;

  Future<void> _pick(ClipSource source) async {
    final services = ServicesScope.of(context);
    final picker = services.clipPicker;
    final messenger = ScaffoldMessenger.of(context);

    // The first time a discipline is filmed, walk through its tour first.
    final userId = services.auth.user?.id;
    final discipline = _discipline;
    if (source == ClipSource.camera &&
        userId != null &&
        !await services.tours.hasSeen(userId, discipline)) {
      if (!mounted) return;
      final finished = await showFilmingTour(
        context,
        discipline,
        doneLabel: 'Start filming',
      );
      if (!finished || !mounted) return;
      await services.tours.markSeen(userId, discipline);
    }
    if (!mounted) return;
    setState(() => _picking = true);
    String? path;
    try {
      path = await picker.pick(source);
    } on Exception {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            source == ClipSource.camera
                ? 'The camera could not be opened. Check this app\'s '
                    'permissions in your phone\'s settings.'
                : 'Your videos could not be opened. Check this app\'s '
                    'permissions in your phone\'s settings.',
          ),
        ),
      );
    }
    if (!mounted) return;
    setState(() => _picking = false);
    if (path == null) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => AnalysisPage(
          sourcePath: path!,
          discipline: _discipline,
          handedness: _handedness,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final guide = FilmingGuide.of(_discipline);
    final handQuestion = guide.handQuestion;
    return Scaffold(
      appBar: AppBar(title: const Text('New session')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Text('What are you practising?', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final discipline in Discipline.values)
                ChoiceChip(
                  key: Key('discipline-${discipline.name}'),
                  label: Text(discipline.label),
                  selected: discipline == _discipline,
                  onSelected: (_) => setState(() => _discipline = discipline),
                ),
            ],
          ),
          if (handQuestion != null) ...[
            const SizedBox(height: 28),
            Text(handQuestion, style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            SegmentedButton<Handedness>(
              showSelectedIcon: false,
              segments: [
                for (final hand in Handedness.values)
                  ButtonSegment(value: hand, label: Text(hand.label)),
              ],
              selected: {_handedness},
              onSelectionChanged: (selection) =>
                  setState(() => _handedness = selection.first),
            ),
          ],
          const SizedBox(height: 28),
          Text('For a clip we can read', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final tip in guide.tips) _Tip(tip),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: const Key('new-session-tour'),
              onPressed: () => showFilmingTour(context, _discipline),
              icon: const Icon(Icons.help_outline),
              label: Text(
                'Show me how to film ${_discipline.label.toLowerCase()}',
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            key: const Key('new-session-record'),
            onPressed: _picking ? null : () => _pick(ClipSource.camera),
            icon: const Icon(Icons.videocam_outlined),
            label: const Text('Record a clip'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            key: const Key('new-session-library'),
            onPressed: _picking ? null : () => _pick(ClipSource.library),
            icon: const Icon(Icons.video_library_outlined),
            label: const Text('Choose from library'),
          ),
        ],
      ),
    );
  }
}

class _Tip extends StatelessWidget {
  const _Tip(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2, right: 10),
            child: Icon(
              Icons.check,
              size: 18,
              color: theme.colorScheme.primary,
            ),
          ),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
