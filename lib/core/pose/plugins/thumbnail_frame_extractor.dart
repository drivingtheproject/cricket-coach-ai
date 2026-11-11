import 'package:video_thumbnail_gen/video_thumbnail_gen.dart';

import '../frame_extractor.dart';

/// Extracts frames with the platform's native video decoder.
class ThumbnailFrameExtractor implements FrameExtractor {
  const ThumbnailFrameExtractor({this.maxHeight = 720, this.quality = 85});

  /// Frames are scaled down to this height; pose detection does not need more.
  final int maxHeight;
  final int quality;

  @override
  Future<VideoInfo?> probe(String videoPath) async {
    final metadata = await VideoThumbnail.getVideoMetadata(video: videoPath);
    if (metadata == null) return null;
    return VideoInfo(
      durationMs: metadata.durationMs,
      width: metadata.width,
      height: metadata.height,
    );
  }

  @override
  Future<String?> extractFrame(
    String videoPath,
    int timeMs,
    String outputPath,
  ) {
    return VideoThumbnail.thumbnailFile(
      video: videoPath,
      thumbnailPath: outputPath,
      imageFormat: ImageFormat.JPEG,
      timeMs: timeMs,
      maxHeight: maxHeight,
      quality: quality,
    );
  }
}
