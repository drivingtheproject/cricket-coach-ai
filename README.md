# cricket-coach-ai

An AI cricket coach for Android and iOS. Record a short clip of a shot, and the
app tracks your body with on-device pose estimation, measures your technique,
and turns the measurements into coaching feedback using either a local model
(Gemma 4) or a cloud model with your own API key (Claude, OpenAI, Gemini).

Built with Flutter. Status: **M0 - scaffold**.

## How it works

1. **Capture** - record or import a short side-on clip (3-10 s).
2. **Pose** - MediaPipe Pose Landmarker extracts 33 body landmarks per frame, on-device.
3. **Metrics** - pure Dart code detects the shot phases (stance, backlift,
   downswing, impact, follow-through) and computes joint angles, head position,
   stride length, hip-shoulder separation and balance.
4. **Coach** - the metrics (never the video) go to a `CoachProvider`, which
   returns structured feedback: summary, strengths, improvements, drills.
5. **Review** - skeleton overlay playback, key frames, feedback cards, history.

### Hybrid AI

`CoachRouter` picks the provider. Local Gemma is the default and works offline.
A cloud provider is used when the user saves an API key for it and prefers it.
Keys are held in the device's secure storage and never committed or proxied.

## Project layout

```
lib/
  main.dart, app.dart
  core/
    pose/      PoseFrame, PoseLandmark, landmark indexes
    metrics/   geometry helpers, BattingMetrics
    coach/     CoachProvider interface, CoachRouter, CoachFeedback
  features/
    home/      landing screen
test/          unit tests for geometry and routing
```

## Getting started

Requires Flutter 3.47 or newer: the app uses the standalone `material_ui`
package, which replaced `package:flutter/material.dart`. CI runs on the current
stable channel.

The Android and iOS folders are not committed yet. Generate them once:

```sh
flutter create --platforms=android,ios --org com.drivingtheproject --project-name cricket_coach_ai .
flutter pub get
flutter test
flutter run
```

If `flutter create` adds `test/widget_test.dart`, delete it - it refers to a
template app that does not exist here.

## Milestones

| #  | Deliverable | Status |
|----|-------------|--------|
| M0 | Repo, Flutter scaffold, folder structure, CI | In progress |
| M1 | Video capture/import, pose extraction, skeleton overlay | |
| M2 | Batting metrics and phase detection, tested on saved landmark data | |
| M3 | Cloud coach: Claude first, then OpenAI and Gemini; API key settings | |
| M4 | Local Gemma 4: model download manager and auto-routing | |
| M5 | Session history, progress charts, drill suggestions | |
| M6 | Bowling action analysis, polish, store builds | |

## Known limits

- Pose tracking sees the body only, so v1 coaches body mechanics, not bat path
  or contact point.
- At 30 fps a fast bowling arm blurs; batting comes first for that reason.
- Gemma 4 is a multi-gigabyte download (E2B about 2.4 GB, E4B about 4.3 GB), so
  it is fetched on demand and suits mid-to-high-end phones.
