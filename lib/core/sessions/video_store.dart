import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Keeps session clips in the app's documents folder.
///
/// Sessions store a path relative to that folder, because its absolute
/// location can change between app launches on iOS.
class VideoStore {
  VideoStore({
    required Future<Directory> Function() documentsDirectory,
    required Future<Directory> Function() temporaryDirectory,
  })  : _documents = documentsDirectory,
        _temporary = temporaryDirectory;

  factory VideoStore.onDevice() => VideoStore(
        documentsDirectory: getApplicationDocumentsDirectory,
        temporaryDirectory: getTemporaryDirectory,
      );

  final Future<Directory> Function() _documents;
  final Future<Directory> Function() _temporary;

  static const String _folder = 'videos';

  /// Copies the picked clip into the app's storage and returns its relative
  /// path.
  Future<String> importClip(String sourcePath, String sessionId) async {
    final documents = await _documents();
    await Directory(p.join(documents.path, _folder)).create(recursive: true);
    final extension = p.extension(sourcePath).toLowerCase();
    final name = '$sessionId${extension.isEmpty ? '.mp4' : extension}';
    await File(sourcePath).copy(p.join(documents.path, _folder, name));
    return '$_folder/$name';
  }

  Future<File> resolve(String relativePath) async {
    final documents = await _documents();
    return File(p.joinAll([documents.path, ...relativePath.split('/')]));
  }

  Future<void> delete(String? relativePath) async {
    if (relativePath == null) return;
    final file = await resolve(relativePath);
    if (file.existsSync()) await file.delete();
  }

  /// A scratch folder for the frames extracted during one analysis.
  Future<Directory> createWorkDirectory(String sessionId) async {
    final directory = await _workDirectory(sessionId);
    return directory.create(recursive: true);
  }

  Future<void> removeWorkDirectory(String sessionId) async {
    final directory = await _workDirectory(sessionId);
    if (directory.existsSync()) await directory.delete(recursive: true);
  }

  Future<Directory> _workDirectory(String sessionId) async {
    final temporary = await _temporary();
    return Directory(p.join(temporary.path, 'frames_$sessionId'));
  }
}
