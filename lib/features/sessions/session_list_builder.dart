import 'package:material_ui/material_ui.dart';

import '../../core/services.dart';
import '../../core/sessions/session.dart';

/// Loads the signed-in user's sessions and rebuilds whenever they change.
class SessionListBuilder extends StatefulWidget {
  const SessionListBuilder({super.key, required this.builder});

  final Widget Function(BuildContext context, List<Session> sessions) builder;

  @override
  State<SessionListBuilder> createState() => _SessionListBuilderState();
}

class _SessionListBuilderState extends State<SessionListBuilder> {
  AppServices? _services;
  List<Session>? _sessions;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_services == null) {
      final services = ServicesScope.of(context);
      _services = services;
      services.sessions.changes.addListener(_load);
      _load();
    }
  }

  @override
  void dispose() {
    _services?.sessions.changes.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final services = _services;
    final user = services?.auth.user;
    if (services == null || user == null) return;
    final sessions = await services.sessions.listForUser(user.id);
    if (mounted) setState(() => _sessions = sessions);
  }

  @override
  Widget build(BuildContext context) {
    final sessions = _sessions;
    if (sessions == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return widget.builder(context, sessions);
  }
}
