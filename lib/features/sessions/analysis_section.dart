import 'package:material_ui/material_ui.dart';

import '../../core/analysis/technique_analysis.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/section_title.dart';
import 'metric_bar.dart';

/// The score and measurements for a session.
class AnalysisSection extends StatelessWidget {
  const AnalysisSection({super.key, required this.analysis});

  final TechniqueAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final inRange = analysis.strengths.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                analysis.score.round().toString(),
                key: const Key('session-score'),
                style: AppTheme.numeral(theme, 72, color: scheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Technique score out of 100',
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        '$inRange of ${analysis.metrics.length} measurements '
                        'in their guide range',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SectionTitle('Measurements'),
        for (final metric in analysis.metrics) MetricBar(metric: metric),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Text(
            'Measured from the body positions in your clip. Guide ranges are '
            'general coaching starting points, not rules.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
