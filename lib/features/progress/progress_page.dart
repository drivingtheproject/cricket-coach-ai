import 'package:material_ui/material_ui.dart';

import '../../core/progress/progress_summary.dart';
import '../../core/sessions/session.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/section_title.dart';
import '../sessions/session_list_builder.dart';
import 'score_chart.dart';

/// Scores over time and what to work on, one discipline at a time.
class ProgressPage extends StatefulWidget {
  const ProgressPage({super.key});

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  Discipline? _selected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Progress')),
      body: SessionListBuilder(
        builder: (context, sessions) {
          final disciplines = disciplinesWithScores(sessions);
          if (disciplines.isEmpty) {
            return const Align(
              alignment: Alignment.topLeft,
              child: EmptyState(
                icon: Icons.show_chart,
                title: 'Nothing to chart yet',
                message: 'Your scores over time appear here after your first '
                    'session.',
              ),
            );
          }
          final discipline =
              disciplines.contains(_selected) ? _selected! : disciplines.first;
          final summary = ProgressSummary.from(sessions, discipline);
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              if (disciplines.length > 1)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: Row(
                    children: [
                      for (final item in disciplines)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(item.label),
                            selected: item == discipline,
                            onSelected: (_) => setState(() => _selected = item),
                          ),
                        ),
                    ],
                  ),
                ),
              _Summary(summary: summary),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: ScoreChart(points: summary.points),
              ),
              if (summary.focusAreas.isNotEmpty) ...[
                const SectionTitle('What to work on'),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Text(
                    summary.recentCount == 1
                        ? 'From your latest session'
                        : 'From your last ${summary.recentCount} sessions',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
                for (final area in summary.focusAreas)
                  _FocusTile(area: area, outOf: summary.recentCount),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.summary});

  final ProgressSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final change = summary.change;
    final count = summary.points.length;
    final String trend;
    if (change == null) {
      trend = 'Analyse another clip to see how you are changing.';
    } else if (change.round() == 0) {
      trend = 'Level with your first session, over $count sessions.';
    } else {
      trend = '${change > 0 ? 'Up' : 'Down'} ${change.abs().round()} since '
          'your first session, over $count sessions.';
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                summary.latest!.round().toString(),
                key: const Key('progress-latest'),
                style: AppTheme.numeral(theme, 72, color: scheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    'Latest ${summary.discipline.label.toLowerCase()} score\n'
                    'Best ${summary.best!.round()}, average '
                    '${summary.average!.round()}',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            trend,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _FocusTile extends StatelessWidget {
  const _FocusTile({required this.area, required this.outOf});

  final FocusArea area;
  final int outOf;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final drill = area.drill;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(area.label, style: theme.textTheme.titleMedium),
          Text(
            'Out of range in ${area.count} of $outOf',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(area.note, style: theme.textTheme.bodyMedium),
          if (drill != null) ...[
            const SizedBox(height: 4),
            Text(
              'Drill, ${drill.title.toLowerCase()}: ${drill.how}',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }
}
