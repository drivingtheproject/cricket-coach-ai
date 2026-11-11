import 'pose_frame.dart';

/// Pairs of landmarks joined by a line when drawing the skeleton.
const List<(int, int)> skeletonBones = [
  (PoseLandmarkIndex.leftShoulder, PoseLandmarkIndex.rightShoulder),
  (PoseLandmarkIndex.leftShoulder, PoseLandmarkIndex.leftElbow),
  (PoseLandmarkIndex.leftElbow, PoseLandmarkIndex.leftWrist),
  (PoseLandmarkIndex.rightShoulder, PoseLandmarkIndex.rightElbow),
  (PoseLandmarkIndex.rightElbow, PoseLandmarkIndex.rightWrist),
  (PoseLandmarkIndex.leftShoulder, PoseLandmarkIndex.leftHip),
  (PoseLandmarkIndex.rightShoulder, PoseLandmarkIndex.rightHip),
  (PoseLandmarkIndex.leftHip, PoseLandmarkIndex.rightHip),
  (PoseLandmarkIndex.leftHip, PoseLandmarkIndex.leftKnee),
  (PoseLandmarkIndex.leftKnee, PoseLandmarkIndex.leftAnkle),
  (PoseLandmarkIndex.rightHip, PoseLandmarkIndex.rightKnee),
  (PoseLandmarkIndex.rightKnee, PoseLandmarkIndex.rightAnkle),
  (PoseLandmarkIndex.leftAnkle, PoseLandmarkIndex.leftFootIndex),
  (PoseLandmarkIndex.rightAnkle, PoseLandmarkIndex.rightFootIndex),
];

/// Landmarks drawn as dots.
const List<int> skeletonJoints = [
  PoseLandmarkIndex.nose,
  PoseLandmarkIndex.leftShoulder,
  PoseLandmarkIndex.rightShoulder,
  PoseLandmarkIndex.leftElbow,
  PoseLandmarkIndex.rightElbow,
  PoseLandmarkIndex.leftWrist,
  PoseLandmarkIndex.rightWrist,
  PoseLandmarkIndex.leftHip,
  PoseLandmarkIndex.rightHip,
  PoseLandmarkIndex.leftKnee,
  PoseLandmarkIndex.rightKnee,
  PoseLandmarkIndex.leftAnkle,
  PoseLandmarkIndex.rightAnkle,
];
