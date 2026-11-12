import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_theme.dart';
import '../../widgets/section_title.dart';

/// The player's own notes on a session.
class SessionNotes extends StatefulWidget {
  const SessionNotes({super.key, required this.notes, required this.onSave});

  final String notes;
  final Future<void> Function(String notes) onSave;

  @override
  State<SessionNotes> createState() => _SessionNotesState();
}

class _SessionNotesState extends State<SessionNotes> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.notes);
  bool _saving = false;

  bool get _changed => _controller.text.trim() != widget.notes;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await widget.onSave(_controller.text.trim());
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Divider(),
        const SizedBox(height: 20),
        const SectionTitle('Your notes'),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                key: const Key('notes-field'),
                controller: _controller,
                minLines: 2,
                maxLines: 6,
                maxLength: 1000,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (_) => setState(() {}),
                decoration: AppTheme.field(
                  'Notes',
                  hint: 'How it felt, the bowler, the pitch, what to try next',
                ),
              ),
              if (_changed)
                FilledButton.tonal(
                  key: const Key('notes-save'),
                  onPressed: _saving ? null : _save,
                  child: const Text('Save notes'),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
