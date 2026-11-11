import 'package:material_ui/material_ui.dart';

import '../../core/sessions/session.dart';
import '../../core/theme/app_theme.dart';
import '../../core/util/formatters.dart';

/// One row in a list of sessions: title, date, and the score on the right.
class SessionTile extends StatelessWidget {
  const SessionTile({super.key, required this.session, this.onTap});

  final Session session;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final score = session.score;
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      title: Text(
        session.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${session.discipline.label}, ${formatDate(session.createdAt)}',
      ),
      trailing: score == null
          ? null
          : Text(
              score.round().toString(),
              style: AppTheme.numeral(theme, 30),
            ),
    );
  }
}
