import '../sessions/session.dart';
import 'batting_analyzer.dart';
import 'bowling_analyzer.dart';
import 'fielding_analyzer.dart';
import 'technique_analyzer.dart';

/// The analyzers that ship with the app, by discipline.
Map<Discipline, TechniqueAnalyzer> defaultAnalyzers() => {
      for (final analyzer in const <TechniqueAnalyzer>[
        BattingAnalyzer(),
        BowlingAnalyzer(),
        FieldingAnalyzer(),
      ])
        analyzer.discipline: analyzer,
    };
