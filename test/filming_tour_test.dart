import 'package:cricket_coach_ai/core/analysis/analyzers.dart';
import 'package:cricket_coach_ai/core/guide/filming_tour.dart';
import 'package:cricket_coach_ai/core/pose/pose_frame.dart';
import 'package:cricket_coach_ai/core/sessions/session.dart';
import 'package:cricket_coach_ai/core/settings/settings_repository.dart';
import 'package:cricket_coach_ai/core/theme/app_theme.dart';
import 'package:cricket_coach_ai/features/guide/filming_guides_page.dart';
import 'package:cricket_coach_ai/features/guide/filming_tour_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'support/synthetic_clips.dart';
import 'support/test_database.dart';

void main() {
  group('FilmingTour', () {
    for (final discipline in Discipline.values) {
      final tour = FilmingTour.of(discipline);

      test('${discipline.name} has a complete tour', () {
        expect(tour.discipline, discipline);
        expect(tour.distance, isNotEmpty);
        expect(tour.height, isNotEmpty);
        expect(tour.steps.length, greaterThanOrEqualTo(4));
        for (final step in tour.steps) {
          expect(step.title, isNotEmpty);
          expect(step.body, isNotEmpty);
        }
        final titles = tour.steps.map((s) => s.title).toList();
        expect(titles.toSet(), hasLength(titles.length));
      });

      test('${discipline.name} covers position, framing, moments and '
          'steadiness, and ends on a checklist', () {
        expect(tour.steps.map((s) => s.diagram), [
          TourDiagram.cameraPosition,
          TourDiagram.framing,
          TourDiagram.moments,
          TourDiagram.steady,
          TourDiagram.checklist,
        ]);
        expect(tour.steps.last.points, hasLength(4));
        expect(
          tour.steps.where((s) => s != tour.steps.last).expand((s) => s.points),
          isEmpty,
        );
      });
    }

    test('batting and bowling are filmed side-on, catching and keeping from '
        'in front', () {
      expect(FilmingTour.of(Discipline.batting).view, CameraView.sideOn);
      expect(FilmingTour.of(Discipline.bowling).view, CameraView.sideOn);
      expect(FilmingTour.of(Discipline.fielding).view, CameraView.frontOn);
      expect(FilmingTour.of(Discipline.wicketkeeping).view, CameraView.frontOn);
    });

    test('the moments each tour asks for are the ones the analyzer finds', () {
      final clips = <Discipline, List<PoseFrame>>{
        Discipline.batting: battingClip(),
        Discipline.bowling: bowlingClip(),
        Discipline.fielding: catchingClip(),
        Discipline.wicketkeeping: keepingClip(),
      };
      final analyzers = defaultAnalyzers();

      for (final discipline in Discipline.values) {
        final analysis = analyzers[discipline]!.analyze(
          clips[discipline]!,
          handedness: Handedness.right,
          aspectRatio: 1,
        );
        expect(
          FilmingTour.of(discipline).moments,
          analysis.phases.map((p) => p.label),
          reason: discipline.name,
        );
      }
    });
  });

  group('TourProgress', () {
    late Database db;
    late TourProgress progress;

    setUp(() async {
      db = await openTestDatabase();
      await insertTestUser(db);
      await insertTestUser(db, id: 'user-2');
      progress = TourProgress(SettingsRepository(db));
    });

    tearDown(() => db.close());

    test('a tour is unseen until it is marked, per discipline and user',
        () async {
      expect(await progress.hasSeen('user-1', Discipline.batting), isFalse);

      await progress.markSeen('user-1', Discipline.batting);

      expect(await progress.hasSeen('user-1', Discipline.batting), isTrue);
      expect(await progress.hasSeen('user-1', Discipline.bowling), isFalse);
      expect(await progress.hasSeen('user-2', Discipline.batting), isFalse);
    });

    test('marking twice is harmless and reset shows the tour again', () async {
      await progress.markSeen('user-1', Discipline.fielding);
      await progress.markSeen('user-1', Discipline.fielding);
      expect(await progress.hasSeen('user-1', Discipline.fielding), isTrue);

      await progress.reset('user-1', Discipline.fielding);
      expect(await progress.hasSeen('user-1', Discipline.fielding), isFalse);
    });
  });

  group('FilmingTourPage', () {
    final tour = FilmingTour.of(Discipline.bowling);

    Future<List<bool?>> pumpTour(WidgetTester tester) async {
      final results = <bool?>[];
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () async => results.add(
                    await showFilmingTour(
                      context,
                      Discipline.bowling,
                      doneLabel: 'Start filming',
                    ),
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      return results;
    }

    Future<void> next(WidgetTester tester) async {
      await tester.tap(find.byKey(const Key('tour-next')));
      await tester.pumpAndSettle();
    }

    testWidgets('opens on the first step with no Back button', (tester) async {
      await pumpTour(tester);

      expect(find.text('Filming bowling'), findsOneWidget);
      expect(find.text(tour.steps.first.title), findsOneWidget);
      expect(find.byKey(const Key('tour-back')), findsNothing);
      expect(find.text('Next'), findsOneWidget);
      expect(find.bySemanticsLabel('Step 1 of 5'), findsOneWidget);
    });

    testWidgets('Next and Back move between steps', (tester) async {
      await pumpTour(tester);

      await next(tester);
      expect(find.text(tour.steps[1].title), findsOneWidget);
      expect(find.bySemanticsLabel('Step 2 of 5'), findsOneWidget);

      await tester.tap(find.byKey(const Key('tour-back')));
      await tester.pumpAndSettle();
      expect(find.text(tour.steps.first.title), findsOneWidget);
    });

    testWidgets('the last step shows the checklist and finishes the tour',
        (tester) async {
      final results = await pumpTour(tester);

      for (var i = 0; i < tour.steps.length - 1; i++) {
        await next(tester);
      }

      expect(find.text(tour.steps.last.title), findsOneWidget);
      for (final point in tour.steps.last.points) {
        expect(find.text(point), findsOneWidget);
      }
      expect(find.text('Start filming'), findsOneWidget);
      expect(find.byKey(const Key('tour-skip')), findsNothing);

      await next(tester);
      expect(results, [true]);
      expect(find.text('open'), findsOneWidget);
    });

    testWidgets('Skip counts as finished', (tester) async {
      final results = await pumpTour(tester);

      await tester.tap(find.byKey(const Key('tour-skip')));
      await tester.pumpAndSettle();

      expect(results, [true]);
    });

    testWidgets('backing out does not count as finished', (tester) async {
      final results = await pumpTour(tester);

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(results, [false]);
    });

    testWidgets('every step of every tour draws without errors',
        (tester) async {
      for (final discipline in Discipline.values) {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.dark(),
            home: FilmingTourPage(tour: FilmingTour.of(discipline)),
          ),
        );
        for (var i = 0; i < FilmingTour.of(discipline).steps.length - 1; i++) {
          await next(tester);
          expect(tester.takeException(), isNull);
        }
      }
    });
  });

  testWidgets('the guides page lists every discipline and opens its tour',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light(), home: const FilmingGuidesPage()),
    );

    for (final discipline in Discipline.values) {
      expect(find.byKey(Key('guide-${discipline.name}')), findsOneWidget);
    }

    await tester.tap(find.byKey(const Key('guide-wicketkeeping')));
    await tester.pumpAndSettle();

    expect(find.text('Filming wicketkeeping'), findsOneWidget);
  });
}
