import 'package:cricket_coach_ai/core/analysis/batting_analyzer.dart';
import 'package:cricket_coach_ai/core/analysis/technique_analysis.dart';
import 'package:cricket_coach_ai/core/sessions/session.dart';

/// A batting analysis with one metric in range, one above and one below.
TechniqueAnalysis sampleAnalysis() => TechniqueAnalysis(
      discipline: Discipline.batting,
      handedness: Handedness.right,
      metrics: [
        BattingAnalyzer.frontKnee.evaluate(130), // in range
        BattingAnalyzer.headOverFoot.evaluate(30), // above range
        BattingAnalyzer.stride.evaluate(20), // below range
      ],
      phases: const [PhaseMarker('Impact', 900)],
    );

/// A batting analysis with everything inside its guide range.
TechniqueAnalysis cleanAnalysis() => TechniqueAnalysis(
      discipline: Discipline.batting,
      handedness: Handedness.right,
      metrics: [
        BattingAnalyzer.frontKnee.evaluate(130),
        BattingAnalyzer.stride.evaluate(45),
      ],
      phases: const [],
    );
