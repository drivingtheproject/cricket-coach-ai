import '../sessions/session.dart';
import '../settings/settings_repository.dart';

/// The picture shown with a step of the tour.
enum TourDiagram { cameraPosition, framing, moments, steady, checklist }

/// Where the camera goes relative to the player.
enum CameraView {
  sideOn('Side-on'),
  frontOn('Front-on');

  const CameraView(this.label);
  final String label;
}

class TourStep {
  const TourStep({
    required this.diagram,
    required this.title,
    required this.body,
    this.points = const [],
  });

  final TourDiagram diagram;
  final String title;
  final String body;

  /// Short lines listed under the body; used by the final checklist.
  final List<String> points;
}

/// A step-by-step guide to filming one discipline so the clip can be
/// measured.
class FilmingTour {
  const FilmingTour({
    required this.discipline,
    required this.view,
    required this.distance,
    required this.height,
    required this.moments,
    required this.steps,
  });

  final Discipline discipline;
  final CameraView view;

  /// How far back the camera stands, as shown on the position diagram.
  final String distance;

  /// How high the camera is held, as shown on the framing diagram.
  final String height;

  /// The moments the clip must contain, in order. These match the moments
  /// the analyzer looks for.
  final List<String> moments;
  final List<TourStep> steps;

  static FilmingTour of(Discipline discipline) => switch (discipline) {
        Discipline.batting => _batting,
        Discipline.bowling => _bowling,
        Discipline.fielding => _fielding,
        Discipline.wicketkeeping => _keeping,
      };
}

const _steadyStep = TourStep(
  diagram: TourDiagram.steady,
  title: 'Keep the phone still and the light behind it',
  body: 'Prop the phone on a bag, a stump or a tripod, or ask someone to hold '
      'it with both hands. Film with the sun or the lights behind the camera '
      'so the player is not a silhouette.',
);

const _batting = FilmingTour(
  discipline: Discipline.batting,
  view: CameraView.sideOn,
  distance: '4 to 6 m',
  height: 'Hip height',
  moments: ['Stance', 'Backlift', 'Impact', 'Finish'],
  steps: [
    TourStep(
      diagram: TourDiagram.cameraPosition,
      title: 'Stand side-on to the batter',
      body: 'Place the camera square of the wicket, level with the batting '
          'crease, 4 to 6 metres away. Film from the side the batter\'s '
          'chest faces: the off side.',
    ),
    TourStep(
      diagram: TourDiagram.framing,
      title: 'Fit the whole batter in the frame',
      body: 'Hold the phone sideways at hip height. Leave space above the '
          'head for the backlift and in front for the stride. The feet must '
          'stay in view.',
    ),
    TourStep(
      diagram: TourDiagram.moments,
      title: 'Film one whole shot',
      body: 'Start recording while the batter is still in their stance and '
          'stop a second after the swing has finished. One shot per clip, 3 '
          'to 10 seconds.',
    ),
    _steadyStep,
    TourStep(
      diagram: TourDiagram.checklist,
      title: 'Ready to film batting',
      body: 'Check these before you press record.',
      points: [
        'Camera side-on, level with the crease',
        'Head, bat hands and both feet in the frame',
        'Stance first, then the full swing and finish',
        'Phone steady, light behind the camera',
      ],
    ),
  ],
);

const _bowling = FilmingTour(
  discipline: Discipline.bowling,
  view: CameraView.sideOn,
  distance: '8 to 10 m',
  height: 'Chest height',
  moments: ['Front foot lands', 'Release', 'Follow-through'],
  steps: [
    TourStep(
      diagram: TourDiagram.cameraPosition,
      title: 'Stand side-on to the bowling crease',
      body: 'Place the camera square of the wicket, level with the bowling '
          'crease, 8 to 10 metres away. Film from the side of the bowling '
          'arm so that the arm is not hidden by the body.',
    ),
    TourStep(
      diagram: TourDiagram.framing,
      title: 'Leave room for the raised arm',
      body: 'Hold the phone sideways at chest height. At release the hand '
          'is well above the head, so stand far enough back that the hand '
          'and both feet are in the frame together.',
    ),
    TourStep(
      diagram: TourDiagram.moments,
      title: 'Film the last strides to the follow-through',
      body: 'Start recording before the final two strides and stop once '
          'the bowler has followed through. One ball per clip. Slow-motion '
          'video gives a sharper picture of the arm.',
    ),
    _steadyStep,
    TourStep(
      diagram: TourDiagram.checklist,
      title: 'Ready to film bowling',
      body: 'Check these before you press record.',
      points: [
        'Camera side-on, level with the bowling crease',
        'Raised hand and both feet in the frame',
        'Last two strides, release and follow-through',
        'Phone steady, light behind the camera',
      ],
    ),
  ],
);

const _fielding = FilmingTour(
  discipline: Discipline.fielding,
  view: CameraView.frontOn,
  distance: '4 to 6 m',
  height: 'Chest height',
  moments: ['Ready', 'Catch', 'Give'],
  steps: [
    TourStep(
      diagram: TourDiagram.cameraPosition,
      title: 'Stand in front of the fielder',
      body: 'Place the camera 4 to 6 metres in front of the fielder, just '
          'to one side of the thrower so the ball does not hit it. Both '
          'hands must be visible when the ball arrives.',
    ),
    TourStep(
      diagram: TourDiagram.framing,
      title: 'Fit the whole fielder in the frame',
      body: 'Hold the phone at chest height. Keep the head, both hands and '
          'both feet in view, with a little space above for a high catch.',
    ),
    TourStep(
      diagram: TourDiagram.moments,
      title: 'Film one two-handed catch',
      body: 'Start recording a second before the throw, with the fielder '
          'in the ready position, and stop once the ball is under control. '
          'One catch per clip.',
    ),
    _steadyStep,
    TourStep(
      diagram: TourDiagram.checklist,
      title: 'Ready to film a catch',
      body: 'Check these before you press record.',
      points: [
        'Camera in front, beside the thrower',
        'Head, both hands and both feet in the frame',
        'Ready position first, then the catch',
        'Phone steady, light behind the camera',
      ],
    ),
  ],
);

const _keeping = FilmingTour(
  discipline: Discipline.wicketkeeping,
  view: CameraView.frontOn,
  distance: '4 to 6 m',
  height: 'Waist height',
  moments: ['Set', 'Take', 'Give'],
  steps: [
    TourStep(
      diagram: TourDiagram.cameraPosition,
      title: 'Stand in front of the keeper',
      body: 'Place the camera 4 to 6 metres in front of the keeper, just '
          'to one side of the line of the ball. Practise without a batter '
          'so that nothing blocks the view.',
    ),
    TourStep(
      diagram: TourDiagram.framing,
      title: 'Frame the crouch and the rise',
      body: 'Hold the phone at waist height. The keeper should fit in the '
          'frame both crouched and standing, with gloves and feet in view '
          'the whole time.',
    ),
    TourStep(
      diagram: TourDiagram.moments,
      title: 'Film one ball from the set position',
      body: 'Start recording once the keeper is set in the crouch, before '
          'the ball is thrown or bowled, and stop when the ball is in the '
          'gloves. One ball per clip.',
    ),
    _steadyStep,
    TourStep(
      diagram: TourDiagram.checklist,
      title: 'Ready to film keeping',
      body: 'Check these before you press record.',
      points: [
        'Camera in front, beside the line of the ball',
        'Head, gloves and both feet in the frame',
        'Crouch first, then the take',
        'Phone steady, light behind the camera',
      ],
    ),
  ],
);

/// Remembers which filming tours a player has already been through, so each
/// one opens by itself only the first time.
class TourProgress {
  const TourProgress(this._settings);

  final SettingsRepository _settings;

  static String _key(Discipline discipline) => 'tour.seen.${discipline.name}';

  Future<bool> hasSeen(String userId, Discipline discipline) async =>
      await _settings.get(userId, _key(discipline)) != null;

  Future<void> markSeen(String userId, Discipline discipline) =>
      _settings.set(userId, _key(discipline), '1');

  /// Makes the tour open by itself again next time.
  Future<void> reset(String userId, Discipline discipline) =>
      _settings.remove(userId, _key(discipline));
}
