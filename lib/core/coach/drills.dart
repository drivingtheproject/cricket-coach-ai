import '../analysis/metric.dart';

/// A practice drill aimed at one measurement.
class Drill {
  const Drill(this.title, this.how);

  final String title;
  final String how;

  String get text => '$title: $how';
}

/// Drills by metric id. A metric can have one drill for when its value is
/// below the guide range and another for when it is above.
const Map<String, ({Drill? low, Drill? high})> _drills = {
  'front_knee': (
    low: Drill(
      'Hold the pose',
      'Step into a drive without a ball and hold the finish for three '
          'seconds with the front knee firm. Ten repetitions.',
    ),
    high: Drill(
      'Step and bend',
      'Place a cone a comfortable stride ahead. Step to it and bend the '
          'front knee until it is over your toes. Ten repetitions.',
    ),
  ),
  'front_elbow': (
    low: Drill(
      'Top-hand only drives',
      'Hit underarm feeds with only your top hand on the bat, leading with '
          'a high elbow. Two sets of ten.',
    ),
    high: Drill(
      'Elbow to the bowler',
      'Shadow bat in front of a mirror and point your front elbow at the '
          'bowler as the bat comes down. Two sets of ten.',
    ),
  ),
  'head_over_front_foot': (
    low: null,
    high: Drill(
      'Nose over toes',
      'Drive balls off a tee and freeze at contact. Check that your nose '
          'is above your front foot before you look up. Fifteen balls.',
    ),
  ),
  'stride': (
    low: Drill(
      'Stride to the line',
      'Mark a line a full stride in front of your stance and land your '
          'front foot on it for every drop-feed drive. Fifteen balls.',
    ),
    high: Drill(
      'Short step drives',
      'Play drives with a deliberately shorter step, staying tall, until '
          'you can hold your balance at the finish. Fifteen balls.',
    ),
  ),
  'backlift': (
    low: Drill(
      'Hands to shoulder height',
      'Shadow bat and pause at the top of the backlift with your hands '
          'level with your back shoulder. Two sets of ten.',
    ),
    high: Drill(
      'Compact backlift',
      'Face quick underarm feeds from close range so that you have to keep '
          'the backlift short. Fifteen balls.',
    ),
  ),
  'head_level': (
    low: null,
    high: Drill(
      'Book on the head',
      'Shadow bat slowly with a light book balanced on your head through '
          'the whole swing. Ten slow swings.',
    ),
  ),
  'finish_balance': (
    low: null,
    high: Drill(
      'Three-second finish',
      'After every drive, hold your finish for a count of three without '
          'moving your feet. Fifteen balls.',
    ),
  ),
};

/// The drill for a measurement outside its guide range, if there is one.
Drill? drillFor(MetricResult metric) {
  final drills = _drills[metric.id];
  return switch (metric.status) {
    MetricStatus.good => null,
    MetricStatus.low => drills?.low,
    MetricStatus.high => drills?.high,
  };
}

/// Metric ids that have at least one drill; used by tests to keep the
/// library in step with the analyzers.
Set<String> get metricIdsWithDrills => _drills.keys.toSet();
