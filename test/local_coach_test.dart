import 'package:cricket_coach_ai/core/coach/coach_provider.dart';
import 'package:cricket_coach_ai/core/coach/local/gemma_coach.dart';
import 'package:cricket_coach_ai/core/coach/local/model_download_controller.dart';
import 'package:cricket_coach_ai/core/coach/local/on_device_llm.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/sample_analysis.dart';

class FakeLlm implements OnDeviceLlm {
  FakeLlm({this.installed = false, this.reply = '{"summary": "local"}'});

  bool installed;
  String reply;
  bool failInstall = false;
  bool failUninstall = false;
  bool failGenerate = false;
  bool failCheck = false;
  List<int> progressSteps = [10, 60, 100];
  String? lastPrompt;
  int? lastMaxTokens;

  @override
  LocalModelInfo get info => gemma4E2b;

  @override
  Future<bool> isInstalled() async {
    if (failCheck) throw Exception('plugin missing');
    return installed;
  }

  @override
  Future<void> install({void Function(int percent)? onProgress}) async {
    for (final step in progressSteps) {
      onProgress?.call(step);
      if (failInstall && step >= 60) throw Exception('network dropped');
    }
    installed = true;
  }

  @override
  Future<void> uninstall() async {
    if (failUninstall) throw Exception('busy');
    installed = false;
  }

  @override
  Future<String> generate(String prompt, {int maxOutputTokens = 512}) async {
    if (failGenerate) throw Exception('out of memory');
    lastPrompt = prompt;
    lastMaxTokens = maxOutputTokens;
    return reply;
  }
}

void main() {
  test('the Gemma 4 model is described for download', () {
    expect(gemma4E2b.url, startsWith('https://huggingface.co/'));
    expect(gemma4E2b.url, endsWith(gemma4E2b.fileName));
    expect(gemma4E2b.fileName, endsWith('.litertlm'));
  });

  group('GemmaCoach', () {
    test('is available only once the model is downloaded', () async {
      final llm = FakeLlm();
      final coach = GemmaCoach(llm);

      expect(coach.kind, CoachProviderKind.localGemma);
      expect(await coach.isAvailable(), isFalse);
      llm.installed = true;
      expect(await coach.isAvailable(), isTrue);
    });

    test('is unavailable rather than failing when the check throws', () async {
      final llm = FakeLlm()..failCheck = true;
      expect(await GemmaCoach(llm).isAvailable(), isFalse);
    });

    test('sends one combined prompt and parses the reply', () async {
      final llm = FakeLlm(installed: true);

      final feedback = await GemmaCoach(llm).analyze(sampleAnalysis());

      expect(feedback.summary, 'local');
      expect(llm.lastPrompt, contains('cricket coach'));
      expect(llm.lastPrompt, contains('Front knee bend at impact'));
    });

    test('explains when the model cannot run', () async {
      final llm = FakeLlm(installed: true)..failGenerate = true;

      await expectLater(
        GemmaCoach(llm).analyze(sampleAnalysis()),
        throwsA(
          isA<CoachException>().having(
            (e) => e.message,
            'message',
            contains('could not run on this phone'),
          ),
        ),
      );
    });

    test('rejects an empty reply', () async {
      final llm = FakeLlm(installed: true, reply: '');
      await expectLater(
        GemmaCoach(llm).analyze(sampleAnalysis()),
        throwsA(isA<CoachException>()),
      );
    });
  });

  group('ModelDownloadController', () {
    test('starts by checking, then reports what is on the phone', () async {
      final controller = ModelDownloadController(FakeLlm());
      expect(controller.status, ModelStatus.checking);

      await controller.refresh();
      expect(controller.status, ModelStatus.notInstalled);

      final installed = ModelDownloadController(FakeLlm(installed: true));
      await installed.refresh();
      expect(installed.status, ModelStatus.installed);
    });

    test('treats a failed check as not installed', () async {
      final controller = ModelDownloadController(FakeLlm()..failCheck = true);
      await controller.refresh();
      expect(controller.status, ModelStatus.notInstalled);
    });

    test('reports progress while downloading and ends installed', () async {
      final controller = ModelDownloadController(FakeLlm());
      final seen = <(ModelStatus, int)>[];
      controller.addListener(
        () => seen.add((controller.status, controller.percent)),
      );

      await controller.download();

      expect(seen, [
        (ModelStatus.downloading, 0),
        (ModelStatus.downloading, 10),
        (ModelStatus.downloading, 60),
        (ModelStatus.downloading, 100),
        (ModelStatus.installed, 100),
      ]);
      expect(controller.error, isNull);
    });

    test('keeps progress within 0-100', () async {
      final llm = FakeLlm()..progressSteps = [-5, 250];
      final controller = ModelDownloadController(llm);
      final seen = <int>[];
      controller.addListener(() => seen.add(controller.percent));

      await controller.download();

      expect(seen, everyElement(inInclusiveRange(0, 100)));
    });

    test('a failed download returns to not installed with a reason', () async {
      final controller = ModelDownloadController(FakeLlm()..failInstall = true);

      await controller.download();

      expect(controller.status, ModelStatus.notInstalled);
      expect(controller.error, contains('did not finish'));

      // Trying again clears the old error.
      (controller.llm as FakeLlm).failInstall = false;
      await controller.download();
      expect(controller.status, ModelStatus.installed);
      expect(controller.error, isNull);
    });

    test('remove deletes the model', () async {
      final llm = FakeLlm(installed: true);
      final controller = ModelDownloadController(llm);
      await controller.refresh();

      await controller.remove();

      expect(controller.status, ModelStatus.notInstalled);
      expect(llm.installed, isFalse);
    });

    test('a failed removal keeps the model and says so', () async {
      final llm = FakeLlm(installed: true)..failUninstall = true;
      final controller = ModelDownloadController(llm);
      await controller.refresh();

      await controller.remove();

      expect(controller.status, ModelStatus.installed);
      expect(controller.error, contains('could not be removed'));
    });

    test('remove does nothing when no model is installed', () async {
      final llm = FakeLlm();
      final controller = ModelDownloadController(llm);
      await controller.refresh();

      await controller.remove();

      expect(controller.status, ModelStatus.notInstalled);
    });
  });
}
