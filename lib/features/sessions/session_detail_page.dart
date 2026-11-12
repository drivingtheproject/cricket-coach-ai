import 'dart:io';

import 'package:material_ui/material_ui.dart';

import '../../core/analysis/technique_analysis.dart';
import '../../core/pose/pose_frame.dart';
import '../../core/services.dart';
import '../../core/sessions/session.dart';
import '../../core/util/formatters.dart';
import 'analysis_section.dart';
import 'pose_video_player.dart';

/// Opens the review screen for a session.
void openSession(BuildContext context, String sessionId) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => SessionDetailPage(sessionId: sessionId),
    ),
  );
}

/// Review screen for one saved session.
class SessionDetailPage extends StatefulWidget {
  const SessionDetailPage({super.key, required this.sessionId});

  final String sessionId;

  @override
  State<SessionDetailPage> createState() => _SessionDetailPageState();
}

class _SessionDetailPageState extends State<SessionDetailPage> {
  AppServices? _services;
  Session? _session;
  List<PoseFrame> _frames = const [];
  File? _video;
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_services == null) {
      _services = ServicesScope.of(context);
      _load();
    }
  }

  Future<void> _load() async {
    final services = _services!;
    final session = await services.sessions.getById(widget.sessionId);
    var frames = const <PoseFrame>[];
    File? video;
    if (session != null) {
      final encoded = await services.sessions.loadPoses(session.id);
      if (encoded != null) frames = PoseCodec.decode(encoded);
      final path = session.videoPath;
      if (path != null) {
        final file = await services.videos.resolve(path);
        if (file.existsSync()) video = file;
      }
    }
    if (!mounted) return;
    setState(() {
      _session = session;
      _frames = frames;
      _video = video;
      _loaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = _session;
    if (!_loaded) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (session == null || session.deleted) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('This session is no longer available.')),
      );
    }
    final theme = Theme.of(context);
    final video = _video;
    final encoded = session.analysisJson;
    final analysis = encoded == null ? null : TechniqueAnalysis.decode(encoded);
    return Scaffold(
      appBar: AppBar(title: Text(session.title)),
      body: ListView(
        children: [
          if (video != null)
            PoseVideoPlayer(
              video: video,
              frames: _frames,
              markers: [
                for (final phase in analysis?.phases ?? const <PhaseMarker>[])
                  TimelineMarker(phase.label, phase.timeMs),
              ],
            )
          else
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text('The clip for this session is not on this device.'),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Text(
              '${session.discipline.label}, '
              '${session.handedness.label.toLowerCase()}\n'
              '${formatDate(session.createdAt)} at '
              '${formatTime(session.createdAt)}, '
              '${formatDuration(session.durationMs)} clip',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          if (analysis != null) AnalysisSection(analysis: analysis),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
