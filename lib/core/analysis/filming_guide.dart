import '../sessions/session.dart';

/// How to film each discipline so that the clip can be measured.
class FilmingGuide {
  const FilmingGuide({
    required this.intro,
    required this.tips,
    this.handQuestion,
  });

  /// One line on what to film, shown on the home and new-session screens.
  final String intro;
  final List<String> tips;

  /// The question about the playing hand; null when it does not matter.
  final String? handQuestion;

  static FilmingGuide of(Discipline discipline) => switch (discipline) {
        Discipline.batting => const FilmingGuide(
            intro: 'Film one shot from side-on.',
            handQuestion: 'Which hand do you bat with?',
            tips: [
              'Film from side-on, level with the hips.',
              'Keep the whole body in the frame, head to feet.',
              'Prop the phone up or have someone hold it still.',
              'One shot per clip, 3 to 10 seconds, in good light.',
            ],
          ),
        Discipline.bowling => const FilmingGuide(
            intro: 'Film one delivery from side-on.',
            handQuestion: 'Which arm do you bowl with?',
            tips: [
              'Film from side-on, level with the crease.',
              'Stand far enough back to keep the raised arm in the frame.',
              'Include the last two strides and the follow-through.',
              'One ball per clip, in good light. Slow-motion video helps.',
            ],
          ),
        Discipline.fielding => const FilmingGuide(
            intro: 'Film one two-handed catch.',
            tips: [
              'Film from in front or from the side, at chest height.',
              'Keep the whole body in the frame, head to feet.',
              'Start a second before the ball arrives and keep filming '
                  'until the ball is under control.',
              'One catch per clip, in good light.',
            ],
          ),
      };
}
