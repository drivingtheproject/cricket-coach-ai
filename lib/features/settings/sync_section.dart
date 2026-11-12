import 'package:material_ui/material_ui.dart';

import '../../core/services.dart';
import '../../core/sync/cloud_backend.dart';
import '../../core/util/formatters.dart';
import '../../widgets/section_title.dart';

/// Cloud backup status and the "Sync now" action.
class SyncSection extends StatefulWidget {
  const SyncSection({super.key});

  @override
  State<SyncSection> createState() => _SyncSectionState();
}

class _SyncSectionState extends State<SyncSection> {
  AppServices? _services;
  int _pending = 0;
  DateTime? _lastSynced;
  bool _syncing = false;

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
    final userId = services?.auth.user?.id;
    if (services == null || userId == null) return;
    final pending = await services.sync.pendingCount(userId);
    final last = await services.sync.lastSyncedAt(userId);
    if (!mounted) return;
    setState(() {
      _pending = pending;
      _lastSynced = last;
    });
  }

  Future<void> _sync() async {
    final services = _services!;
    final userId = services.auth.user?.id;
    if (userId == null) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _syncing = true);
    try {
      final report = await services.sync.sync(userId);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Synced. ${report.pushed} sent, ${report.pulled} received.',
          ),
        ),
      );
    } on SyncException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _syncing = false);
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final configured = _services?.sync.isConfigured ?? false;
    final last = _lastSynced;
    final String status;
    if (!configured) {
      status = 'Not set up in this version. Your sessions are saved on this '
          'phone.';
    } else if (_pending == 0) {
      status = last == null
          ? 'Nothing to sync yet.'
          : 'Up to date. Last synced ${formatDate(last)} at '
              '${formatTime(last)}.';
    } else {
      status = _pending == 1
          ? '1 change waiting to sync.'
          : '$_pending changes waiting to sync.';
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Cloud sync'),
        ListTile(
          key: const Key('settings-sync'),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
          leading: Icon(
            configured ? Icons.cloud_outlined : Icons.cloud_off_outlined,
          ),
          title: Text(status),
          subtitle: const Text(
            'Scores, measurements, feedback and notes sync. Clips stay on '
            'this phone.',
          ),
          trailing: !configured
              ? null
              : _syncing
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : TextButton(
                      key: const Key('sync-now'),
                      onPressed: _sync,
                      child: const Text('Sync now'),
                    ),
        ),
      ],
    );
  }
}
