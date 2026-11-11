import 'dart:io';
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:video_player/video_player.dart';

import '../../core/pose/pose_frame.dart';
import '../../core/pose/pose_math.dart';
import '../../core/theme/app_theme.dart';
import '../../core/util/formatters.dart';
import 'pose_painter.dart';

/// A named moment in the clip, such as "Impact", that the player can jump to.
class TimelineMarker {
  const TimelineMarker(this.label, this.timeMs);

  final String label;
  final int timeMs;
}

/// Plays a session clip with the tracked skeleton drawn on top, with
/// slow-motion, frame stepping and jump-to-moment controls.
class PoseVideoPlayer extends StatefulWidget {
  const PoseVideoPlayer({
    super.key,
    required this.video,
    required this.frames,
    this.markers = const [],
  });

  final File video;
  final List<PoseFrame> frames;
  final List<TimelineMarker> markers;

  @override
  State<PoseVideoPlayer> createState() => _PoseVideoPlayerState();
}

class _PoseVideoPlayerState extends State<PoseVideoPlayer> {
  late final VideoPlayerController _controller;
  bool _ready = false;
  bool _failed = false;
  bool _showSkeleton = true;
  double _speed = 1;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(widget.video);
    _initialise();
  }

  Future<void> _initialise() async {
    try {
      await _controller.initialize();
      await _controller.setLooping(true);
      if (mounted) setState(() => _ready = true);
    } on Exception {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlay() {
    if (_controller.value.isPlaying) {
      _controller.pause();
    } else {
      _controller.play();
    }
  }

  Future<void> _seek(int timeMs) async {
    await _controller.pause();
    await _controller.seekTo(Duration(milliseconds: timeMs));
  }

  void _step(int direction) {
    final frames = widget.frames;
    if (frames.isEmpty) return;
    final current = nearestFrameIndex(
      frames,
      _controller.value.position.inMilliseconds,
    );
    final target = math.min(math.max(current + direction, 0), frames.length - 1);
    _seek(frames[target].timestampMs);
  }

  void _setSpeed(double speed) {
    setState(() => _speed = speed);
    _controller.setPlaybackSpeed(speed);
  }

  PoseFrame? _frameAt(Duration position) {
    final index = nearestFrameIndex(widget.frames, position.inMilliseconds);
    return index < 0 ? null : widget.frames[index];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_failed) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          'This clip cannot be played on this device.',
          style: theme.textTheme.bodyMedium,
        ),
      );
    }
    if (!_ready) {
      return const SizedBox(
        height: 220,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildVideo(context),
        _buildTransport(theme),
        _buildOptions(),
      ],
    );
  }

  Widget _buildVideo(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final aspectRatio = _controller.value.aspectRatio;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.55;
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = math.min(constraints.maxWidth / aspectRatio, maxHeight);
        return ColoredBox(
          color: Colors.black,
          child: SizedBox(
            height: height,
            child: Center(
              child: AspectRatio(
                aspectRatio: aspectRatio,
                child: GestureDetector(
                  onTap: _togglePlay,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      VideoPlayer(_controller),
                      if (_showSkeleton)
                        ValueListenableBuilder<VideoPlayerValue>(
                          valueListenable: _controller,
                          builder: (context, value, _) => CustomPaint(
                            painter: PosePainter(
                              frame: _frameAt(value.position),
                              boneColor: AppColors.pitchStraw,
                              jointColor: scheme.tertiary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTransport(ThemeData theme) {
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: _controller,
      builder: (context, value, _) {
        final durationMs = math.max(1, value.duration.inMilliseconds);
        final positionMs = math.min(
          math.max(value.position.inMilliseconds, 0),
          durationMs,
        );
        return Row(
          children: [
            IconButton(
              tooltip: value.isPlaying ? 'Pause' : 'Play',
              icon: Icon(value.isPlaying ? Icons.pause : Icons.play_arrow),
              onPressed: _togglePlay,
            ),
            IconButton(
              tooltip: 'Previous frame',
              icon: const Icon(Icons.skip_previous),
              onPressed: () => _step(-1),
            ),
            IconButton(
              tooltip: 'Next frame',
              icon: const Icon(Icons.skip_next),
              onPressed: () => _step(1),
            ),
            Expanded(
              child: Slider(
                value: positionMs.toDouble(),
                max: durationMs.toDouble(),
                onChanged: (position) => _seek(position.round()),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                formatDuration(positionMs),
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOptions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SegmentedButton<double>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: 0.25, label: Text('0.25x')),
              ButtonSegment(value: 0.5, label: Text('0.5x')),
              ButtonSegment(value: 1, label: Text('1x')),
            ],
            selected: {_speed},
            onSelectionChanged: (selection) => _setSpeed(selection.first),
          ),
          FilterChip(
            label: const Text('Skeleton'),
            selected: _showSkeleton,
            onSelected: (selected) => setState(() => _showSkeleton = selected),
          ),
          for (final marker in widget.markers)
            ActionChip(
              label: Text(marker.label),
              onPressed: () => _seek(marker.timeMs),
            ),
        ],
      ),
    );
  }
}
