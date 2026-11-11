import 'pose_frame.dart';

const Map<String, int> _indexByName = {
  'nose': PoseLandmarkIndex.nose,
  'leftEar': PoseLandmarkIndex.leftEar,
  'rightEar': PoseLandmarkIndex.rightEar,
  'leftShoulder': PoseLandmarkIndex.leftShoulder,
  'rightShoulder': PoseLandmarkIndex.rightShoulder,
  'leftElbow': PoseLandmarkIndex.leftElbow,
  'rightElbow': PoseLandmarkIndex.rightElbow,
  'leftWrist': PoseLandmarkIndex.leftWrist,
  'rightWrist': PoseLandmarkIndex.rightWrist,
  'leftHip': PoseLandmarkIndex.leftHip,
  'rightHip': PoseLandmarkIndex.rightHip,
  'leftKnee': PoseLandmarkIndex.leftKnee,
  'rightKnee': PoseLandmarkIndex.rightKnee,
  'leftAnkle': PoseLandmarkIndex.leftAnkle,
  'rightAnkle': PoseLandmarkIndex.rightAnkle,
  'leftHeel': PoseLandmarkIndex.leftHeel,
  'rightHeel': PoseLandmarkIndex.rightHeel,
  'leftFootIndex': PoseLandmarkIndex.leftFootIndex,
  'rightFootIndex': PoseLandmarkIndex.rightFootIndex,
};

/// Maps a detector's landmark to our index.
///
/// Landmarks the app measures are matched by [name], so they stay correct even
/// if a detector orders its enum differently. Others fall back to the
/// detector's own [position], which follows the same 33-point topology.
int landmarkIndexFor(String name, int position) =>
    _indexByName[name] ?? position;
