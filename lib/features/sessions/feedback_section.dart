import 'package:material_ui/material_ui.dart';

import '../../core/coach/coach_feedback.dart';
import '../../core/coach/coach_provider.dart';
import '../../widgets/section_title.dart';

/// The coach's written feedback for a session.
class FeedbackSection extends StatelessWidget {
  const FeedbackSection({
    super.key,
    required this.feedback,
    required this.coach,
    required this.busy,
    required this.onRefresh,
  });

  final CoachFeedback? feedback;
  final CoachProviderKind? coach;
  final bool busy;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final feedback = this.feedback;
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const SizedBox(height: 20),
        SectionTitle(
          'Coach feedback',
          action: busy
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : TextButton(
                  key: const Key('feedback-refresh'),
                  onPressed: onRefresh,
                  child: Text(
                    feedback == null ? 'Get feedback' : 'Get new feedback',
                  ),
                ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: feedback == null
              ? Text(
                  'No feedback has been written for this session yet.',
                  style: theme.textTheme.bodyMedium,
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (feedback.notice != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          feedback.notice!,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Text(feedback.summary, style: theme.textTheme.bodyLarge),
                    _Points('What is working', feedback.strengths),
                    _Points('What to work on', feedback.improvements),
                    _Points('Drills to try', feedback.drills),
                    if (coach != null) ...[
                      const SizedBox(height: 12),
                      Text('Written by ${coach!.label}', style: muted),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _Points extends StatelessWidget {
  const _Points(this.title, this.points);

  final String title;
  final List<String> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleMedium),
          for (final point in points)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 8, right: 10),
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(point, style: theme.textTheme.bodyMedium),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
