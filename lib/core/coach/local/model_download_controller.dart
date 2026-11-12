import 'package:flutter/foundation.dart';

import 'on_device_llm.dart';

enum ModelStatus { checking, notInstalled, downloading, installed }

/// Tracks the on-device model's download so the UI can show it.
class ModelDownloadController extends ChangeNotifier {
  ModelDownloadController(this.llm);

  final OnDeviceLlm llm;

  ModelStatus _status = ModelStatus.checking;
  int _percent = 0;
  String? _error;

  ModelStatus get status => _status;

  /// Download progress, 0-100.
  int get percent => _percent;

  /// Why the last download or removal failed, written for the player.
  String? get error => _error;

  Future<void> refresh() async {
    if (_status == ModelStatus.downloading) return;
    try {
      _set(await llm.isInstalled()
          ? ModelStatus.installed
          : ModelStatus.notInstalled);
    } on Exception {
      _set(ModelStatus.notInstalled);
    }
  }

  Future<void> download() async {
    if (_status == ModelStatus.downloading) return;
    _percent = 0;
    _error = null;
    _set(ModelStatus.downloading);
    try {
      await llm.install(
        onProgress: (percent) {
          _percent = percent.clamp(0, 100);
          notifyListeners();
        },
      );
      _set(ModelStatus.installed);
    } on Exception {
      _error = 'The download did not finish. Check your connection and free '
          'storage, then try again.';
      _set(ModelStatus.notInstalled);
    }
  }

  Future<void> remove() async {
    if (_status != ModelStatus.installed) return;
    _error = null;
    try {
      await llm.uninstall();
      _set(ModelStatus.notInstalled);
    } on Exception {
      _error = 'The model could not be removed.';
      notifyListeners();
    }
  }

  void _set(ModelStatus status) {
    _status = status;
    notifyListeners();
  }
}
