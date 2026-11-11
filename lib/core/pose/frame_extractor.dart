class VideoInfo {
  const VideoInfo({
    required this.durationMs,
    required this.width,
    required this.height,
  });

  final int durationMs;
  final int width;
  final int height;
}

/// Pulls still frames out of a video file.
abstract interface class FrameExtractor {
  /// Returns null when the file cannot be read as a video.
  Future<VideoInfo?> probe(String videoPath);

  /// Writes the frame nearest [timeMs] to [outputPath] as a JPEG and returns
  /// the path written, or null when no frame could be read.
  Future<String?> extractFrame(String videoPath, int timeMs, String outputPath);
}
