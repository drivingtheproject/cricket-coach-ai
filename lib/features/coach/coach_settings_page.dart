import 'package:material_ui/material_ui.dart';

import '../../core/coach/coach_provider.dart';
import '../../core/services.dart';
import '../../widgets/section_title.dart';
import 'api_key_page.dart';
import 'local_model_section.dart';

/// Lets the player choose who writes their feedback and manage API keys.
class CoachSettingsPage extends StatefulWidget {
  const CoachSettingsPage({super.key});

  @override
  State<CoachSettingsPage> createState() => _CoachSettingsPageState();
}

class _CoachSettingsPageState extends State<CoachSettingsPage> {
  AppServices? _services;
  CoachProviderKind? _preferred;
  Map<CoachProviderKind, bool> _available = const {};
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_services == null) {
      _services = ServicesScope.of(context);
      _services!.localModel?.refresh();
      _load();
    }
  }

  Future<void> _load() async {
    final services = _services!;
    final userId = services.auth.user?.id;
    if (userId == null) return;
    final preferred = await services.coachSettings.preferred(userId);
    final available = <CoachProviderKind, bool>{};
    for (final provider in services.coach.providersFor(userId)) {
      available[provider.kind] = await provider.isAvailable();
    }
    if (!mounted) return;
    setState(() {
      _preferred = preferred;
      _available = available;
      _loaded = true;
    });
  }

  Future<void> _choose(CoachProviderKind? kind) async {
    final services = _services!;
    final userId = services.auth.user?.id;
    if (userId == null) return;
    await services.coachSettings.setPreferred(userId, kind);
    if (mounted) setState(() => _preferred = kind);
  }

  Future<void> _editKey(CoachProviderKind kind) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => ApiKeyPage(kind: kind)),
    );
    await _load();
  }

  String _status(CoachProviderKind kind) {
    final ready = _available[kind] ?? false;
    return switch (kind) {
      CoachProviderKind.builtIn => 'Works offline, no set-up needed',
      CoachProviderKind.localGemma =>
        ready ? 'Model downloaded, works offline' : 'Model not downloaded',
      _ => ready ? 'API key saved' : 'No API key',
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Coach')),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                const SectionTitle('Who writes your feedback'),
                _Choice(
                  key: const Key('coach-automatic'),
                  title: 'Automatic',
                  subtitle: 'Uses the best coach that is set up',
                  selected: _preferred == null,
                  onTap: () => _choose(null),
                ),
                for (final kind in _available.keys)
                  _Choice(
                    key: Key('coach-${kind.name}'),
                    title: kind.label,
                    subtitle: _status(kind),
                    selected: _preferred == kind,
                    onTap: () => _choose(kind),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: Text(
                    'If the coach you pick is not set up or cannot be '
                    'reached, the built-in coach writes the feedback.',
                    style: muted,
                  ),
                ),
                const SectionTitle('API keys'),
                for (final kind in _available.keys.where((k) => k.isCloud))
                  ListTile(
                    key: Key('key-${kind.name}'),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    leading: const Icon(Icons.key_outlined),
                    title: Text(kind.label),
                    subtitle: Text(_status(kind)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _editKey(kind),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: Text(
                    'Keys are kept in this phone\'s secure storage. Only your '
                    'measurements are sent to a cloud coach, never your video.',
                    style: muted,
                  ),
                ),
                if (_services!.localModel case final model?)
                  LocalModelSection(controller: model, onChanged: _load),
              ],
            ),
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({
    super.key,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      selected: selected,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
        leading: Icon(
          selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
          color: selected ? scheme.primary : scheme.onSurfaceVariant,
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        onTap: onTap,
      ),
    );
  }
}
