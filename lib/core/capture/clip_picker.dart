import 'package:image_picker/image_picker.dart';

enum ClipSource { camera, library }

/// Lets the user record a clip or choose one they already have.
abstract interface class ClipPicker {
  /// Returns the path of the chosen video, or null if the user cancelled.
  Future<String?> pick(ClipSource source);
}

class ImagePickerClipPicker implements ClipPicker {
  ImagePickerClipPicker([ImagePicker? picker])
      : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<String?> pick(ClipSource source) async {
    final file = await _picker.pickVideo(
      source: switch (source) {
        ClipSource.camera => ImageSource.camera,
        ClipSource.library => ImageSource.gallery,
      },
      maxDuration: const Duration(seconds: 12),
    );
    return file?.path;
  }
}
