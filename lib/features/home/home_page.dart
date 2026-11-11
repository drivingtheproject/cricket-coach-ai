import 'package:flutter/material.dart';

/// Landing screen. Capture and analysis arrive in M1.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Cricket Coach AI')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.sports_cricket, size: 72),
              const SizedBox(height: 16),
              Text('Analyse your batting', style: textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                'Record or import a short side-on clip to get feedback.',
                style: textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              const FilledButton(
                onPressed: null, // Enabled in M1 (video capture + pose).
                child: Text('Analyse a clip'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
