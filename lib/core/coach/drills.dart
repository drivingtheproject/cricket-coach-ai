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
  'bowl_arm': (
    low: Drill(
      'Tall arm against a wall',
      'Stand side-on to a wall and bowl slow arm circles so that your hand '
          'brushes up the wall at full stretch. Two sets of ten.',
    ),
    high: null,
  ),
  'bowl_release_height': (
    low: Drill(
      'Bowl over a rope',
      'Tie a rope at head height a step in front of the crease and bowl '
          'over it from a standing start. Twelve balls.',
    ),
    high: null,
  ),
  'bowl_front_knee': (
    low: Drill(
      'Brace and hold',
      'Walk through your action and freeze at release with the front leg '
          'firm. Hold for two seconds. Ten repetitions.',
    ),
    high: null,
  ),
  'bowl_trunk_lean': (
    low: Drill(
      'Chest to the target',
      'Bowl from a two-step walk-in and finish with your chest over your '
          'front knee, facing the batter. Twelve balls.',
    ),
    high: Drill(
      'Bowl down the channel',
      'Lay two lines of cones a shoulder-width apart towards the batter '
          'and finish every ball inside them. Twelve balls.',
    ),
  ),
  'bowl_stride': (
    low: Drill(
      'Marked landing',
      'Mark where your front foot should land, a little past your usual '
          'spot, and hit the mark from a short run-up. Twelve balls.',
    ),
    high: Drill(
      'Shorter stride, taller finish',
      'Bring your landing mark back by a foot length and focus on getting '
          'up and over the front leg. Twelve balls.',
    ),
  ),
  'bowl_head_level': (
    low: null,
    high: Drill(
      'Eyes on a target',
      'Pick a spot on the pitch and keep your eyes level on it from the '
          'last stride until after release. Twelve balls.',
    ),
  ),
  'bowl_follow_through': (
    low: Drill(
      'Hand to opposite pocket',
      'After release let your bowling hand finish beside your opposite '
          'hip and take two more strides down the pitch. Twelve balls.',
    ),
    high: null,
  ),
  'field_hands_together': (
    low: null,
    high: Drill(
      'Little fingers together',
      'Take underarm feeds at waist height with your little fingers '
          'touching and fingers pointing down. Twenty catches.',
    ),
  ),
  'field_knees': (
    low: Drill(
      'Ready and move',
      'Start from a half-squat, not a full one, and take catches thrown a '
          'step either side of you. Twenty catches.',
    ),
    high: Drill(
      'Sit into the catch',
      'Bend your knees as each ball is thrown, as if sitting on a high '
          'stool, before you catch it. Twenty catches.',
    ),
  ),
  'field_base': (
    low: Drill(
      'Shoulder-width set',
      'Lay two markers a shoulder-width apart and set your feet on them '
          'before every catch. Twenty catches.',
    ),
    high: Drill(
      'Narrow and quick',
      'Bring your feet in to shoulder width and take catches that make '
          'you step to the ball. Twenty catches.',
    ),
  ),
  'field_head_line': (
    low: null,
    high: Drill(
      'Feet first',
      'Have a partner throw slightly to either side. Move your feet so '
          'that every ball is caught in front of your chin. Twenty catches.',
    ),
  ),
  'field_elbows': (
    low: Drill(
      'Reach and bring in',
      'Meet each ball with your hands a forearm\'s length in front of '
          'your body, then bring it in. Twenty catches.',
    ),
    high: Drill(
      'Soft elbows',
      'Catch a tennis ball with elbows bent and relaxed, letting your '
          'hands ride back. Twenty catches.',
    ),
  ),
  'field_give': (
    low: Drill(
      'Egg catches',
      'Catch a soft ball as if it were an egg, drawing your hands back '
          'towards your body as it arrives. Twenty catches.',
    ),
    high: Drill(
      'Catch and hold',
      'Give with the ball for a hand\'s length only, then hold it still '
          'for a second. Twenty catches.',
    ),
  ),
  'field_head_steady': (
    low: null,
    high: Drill(
      'Watch it into the hands',
      'Keep your eyes level and watch each ball all the way into your '
          'hands before you look up. Twenty catches.',
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
