import 'package:material_ui/material_ui.dart';

import '../../core/analysis_exception.dart';
import '../../core/services.dart';
import '../../core/sessions/analysis_pipeline.dart';
import '../../core/sessions/session.dart';
import '../sessions/session_detail_page.dart';

/// Runs the analysis for a picked clip and shows how far along it is.
class AnalysisPage extends StatefulWidget {
  const AnalysisPage({
    super.key,
    required this.sourcePath,
    required this.discipline,
    required this.handedness,
  });

  final String sourcePath;
  final Discipline discipline;
  final Handedness handedness;

  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage> {
  bool _started = false;
  AnalysisStage _stage = AnalysisStage.savingClip;
  double? _progress;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _run(ServicesScope.of(context));
    }
  }

  Future<void> _run(AppServices services) async {
    final user = services.auth.user;
    if (user == null) return;
    try {
      final session = await services.pipeline.run(
        user: user,
        sourcePath: widget.sourcePath,
        discipline: widget.discipline,
        handedness: widget.handedness,
        onProgress: (stage, progress) {
          if (!mounted) return;
          setState(() {
            _stage = stage;
            _progress = progress;
          });
        },
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => SessionDetailPage(sessionId: session.id),
        ),
      );
    } on AnalysisException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } on Exception {
      if (mounted) {
        setState(
          () => _error = 'Something went wrong while analysing this clip. '
              'Try again, or use a different clip.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final error = _error;
    return PopScope(
      // Leaving mid-analysis would throw the work away, so wait for a result.
      canPop: error != null,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: error == null ? _buildProgress(context) : _buildError(context, error),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgress(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Analysing your clip', style: theme.textTheme.headlineMedium),
        const SizedBox(height: 20),
        LinearProgressIndicator(value: _progress),
        const SizedBox(height: 12),
        Text(_stage.label, style: theme.textTheme.bodyLarge),
        const SizedBox(height: 4),
        Text(
          'This usually takes under a minute. Keep the app open.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildError(BuildContext context, String message) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('This clip was not analysed', style: theme.textTheme.headlineMedium),
        const SizedBox(height: 12),
        Text(message, style: theme.textTheme.bodyLarge),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Back'),
        ),
      ],
    );
  }
}
