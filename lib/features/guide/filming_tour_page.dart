import 'package:material_ui/material_ui.dart';

import '../../core/guide/filming_tour.dart';
import '../../core/sessions/session.dart';
import 'tour_diagram.dart';

/// Opens the filming tour for [discipline]. Completes with true when the
/// player went through it or skipped it, and false when they backed out.
Future<bool> showFilmingTour(
  BuildContext context,
  Discipline discipline, {
  String doneLabel = 'Done',
}) async {
  final finished = await Navigator.of(context).push<bool>(
    MaterialPageRoute<bool>(
      fullscreenDialog: true,
      builder: (_) => FilmingTourPage(
        tour: FilmingTour.of(discipline),
        doneLabel: doneLabel,
      ),
    ),
  );
  return finished ?? false;
}

/// A step-by-step guide to filming one discipline, one step per page.
class FilmingTourPage extends StatefulWidget {
  const FilmingTourPage({
    super.key,
    required this.tour,
    this.doneLabel = 'Done',
  });

  final FilmingTour tour;

  /// Label of the button on the last step.
  final String doneLabel;

  @override
  State<FilmingTourPage> createState() => _FilmingTourPageState();
}

class _FilmingTourPageState extends State<FilmingTourPage> {
  final _pages = PageController();
  int _index = 0;

  List<TourStep> get _steps => widget.tour.steps;
  bool get _isLast => _index == _steps.length - 1;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _go(int index) {
    _pages.animateToPage(
      index,
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text('Filming ${widget.tour.discipline.label.toLowerCase()}'),
        actions: [
          if (!_isLast)
            TextButton(
              key: const Key('tour-skip'),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Skip'),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pages,
                itemCount: _steps.length,
                onPageChanged: (index) => setState(() => _index = index),
                itemBuilder: (context, index) =>
                    _StepView(tour: widget.tour, step: _steps[index]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(
                children: [
                  SizedBox(
                    width: 88,
                    child: _index == 0
                        ? null
                        : TextButton(
                            key: const Key('tour-back'),
                            onPressed: () => _go(_index - 1),
                            child: const Text('Back'),
                          ),
                  ),
                  Expanded(
                    child: Semantics(
                      label: 'Step ${_index + 1} of ${_steps.length}',
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var i = 0; i < _steps.length; i++)
                            Container(
                              width: i == _index ? 20 : 8,
                              height: 8,
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 3),
                              decoration: BoxDecoration(
                                color: i == _index
                                    ? scheme.primary
                                    : scheme.outlineVariant,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  FilledButton(
                    key: const Key('tour-next'),
                    onPressed: _isLast
                        ? () => Navigator.of(context).pop(true)
                        : () => _go(_index + 1),
                    child: Text(_isLast ? widget.doneLabel : 'Next'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepView extends StatelessWidget {
  const _StepView({required this.tour, required this.step});

  final FilmingTour tour;
  final TourStep step;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 260),
          child: TourDiagramView(tour: tour, step: step),
        ),
        const SizedBox(height: 24),
        Text(step.title, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          step.body,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        for (final point in step.points)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2, right: 10),
                  child: Icon(Icons.check, size: 20, color: scheme.primary),
                ),
                Expanded(
                  child: Text(point, style: theme.textTheme.bodyLarge),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
