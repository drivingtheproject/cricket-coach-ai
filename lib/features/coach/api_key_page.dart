import 'package:material_ui/material_ui.dart';

import '../../core/coach/coach_provider.dart';
import '../../core/coach/coach_settings.dart';
import '../../core/services.dart';
import '../../core/theme/app_theme.dart';

/// Add, replace or remove the API key and model name for one cloud coach.
class ApiKeyPage extends StatefulWidget {
  const ApiKeyPage({super.key, required this.kind});

  final CoachProviderKind kind;

  @override
  State<ApiKeyPage> createState() => _ApiKeyPageState();
}

class _ApiKeyPageState extends State<ApiKeyPage> {
  final _key = TextEditingController();
  final _model = TextEditingController();
  AppServices? _services;
  bool _hasKey = false;
  bool _showKey = false;
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_services == null) {
      _services = ServicesScope.of(context);
      _load();
    }
  }

  @override
  void dispose() {
    _key.dispose();
    _model.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final services = _services!;
    final userId = services.auth.user?.id;
    if (userId == null) return;
    final key = await services.coachSettings.apiKey(userId, widget.kind);
    final model = await services.coachSettings.model(userId, widget.kind);
    if (!mounted) return;
    setState(() {
      _hasKey = key != null && key.isNotEmpty;
      _model.text = model;
      _loaded = true;
    });
  }

  Future<void> _save() async {
    final services = _services!;
    final userId = services.auth.user?.id;
    if (userId == null) return;
    final navigator = Navigator.of(context);
    if (_key.text.trim().isNotEmpty) {
      await services.coachSettings.setApiKey(userId, widget.kind, _key.text);
    }
    await services.coachSettings.setModel(userId, widget.kind, _model.text);
    navigator.pop();
  }

  Future<void> _remove() async {
    final services = _services!;
    final userId = services.auth.user?.id;
    if (userId == null) return;
    final navigator = Navigator.of(context);
    await services.coachSettings.setApiKey(userId, widget.kind, '');
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.kind.label;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('$name API key')),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                Text(
                  _hasKey
                      ? 'A key is saved. Enter a new one to replace it.'
                      : 'Paste an API key from your $name developer account. '
                          'Usage is billed to that account.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                TextField(
                  key: const Key('api-key-field'),
                  controller: _key,
                  obscureText: !_showKey,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: AppTheme.field(
                    _hasKey ? 'New API key' : 'API key',
                    suffixIcon: IconButton(
                      tooltip: _showKey ? 'Hide key' : 'Show key',
                      icon: Icon(
                        _showKey ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () => setState(() => _showKey = !_showKey),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  key: const Key('api-model-field'),
                  controller: _model,
                  autocorrect: false,
                  decoration: AppTheme.field(
                    'Model',
                    helper: 'Default: '
                        '${CoachSettings.defaultModel(widget.kind)}',
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  key: const Key('api-key-save'),
                  onPressed: _save,
                  child: const Text('Save'),
                ),
                if (_hasKey) ...[
                  const SizedBox(height: 12),
                  OutlinedButton(
                    key: const Key('api-key-remove'),
                    onPressed: _remove,
                    child: const Text('Remove key'),
                  ),
                ],
              ],
            ),
    );
  }
}
