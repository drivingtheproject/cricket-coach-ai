# Cricket Coach

An AI cricket coach for Android and iOS, built with Flutter. Record a short
clip, and the app tracks your body with on-device pose estimation, measures
your technique, and turns the measurements into coaching feedback using either
a local model (Gemma 4) or a cloud model with your own API key (Claude, OpenAI,
Gemini). Sessions are saved to a local SQLite database under your account so
you can review them and follow your progress.

## How it works

1. **Sign in** - accounts live in the on-device database. Passwords are stored
   as salted PBKDF2 hashes.
2. **Capture** - record or import a short clip (3-10 s), filmed side-on.
3. **Pose** - 33 body landmarks are extracted per frame, on the device.
4. **Metrics** - pure Dart code finds the phases of the movement and computes
   joint angles, head position, stride, balance and timing.
5. **Coach** - the metrics (never the video) go to a `CoachProvider`, which
   returns a summary, strengths, improvements and drills.
6. **Review** - skeleton overlay playback, metric bars, feedback, notes,
   history and progress charts.

### Hybrid AI

`CoachRouter` picks the coach. Local Gemma is the default and works offline; a
cloud provider is used when you save an API key for it and prefer it. A
rule-based coach is always available as a fallback. API keys are kept in the
device's secure storage and never leave it except to call the provider.

### Data and sync

Everything is stored in SQLite (`lib/core/db/app_database.dart`). Every
syncable row carries `updated_at`, `sync_state` and a soft-delete flag, and the
sync engine talks to a `RemoteStore` interface, so a Firebase backend can be
added without changing the schema or the UI. `AuthRepository` is an interface
for the same reason.

## Project layout

```
lib/
  main.dart, app.dart
  core/
    auth/      accounts, password hashing, auth state
    db/        SQLite schema
    sessions/  Session model and repository
    pose/      landmarks, extraction pipeline
    metrics/   phase detection and technique metrics
    coach/     coach providers, router, prompt and parser
    theme/     colours, type, shared decoration
    util/      ids, validators, formatters
  features/    one folder per screen
  widgets/     shared widgets
test/          unit and widget tests
```

## Getting started

Requires Flutter 3.47 or newer.

```sh
flutter pub get
flutter test
flutter run
```

Database tests use `sqflite_common_ffi`, which needs the SQLite library on the
machine running the tests (`libsqlite3-dev` on Debian/Ubuntu; already present
on macOS).

Commit `pubspec.lock` after your first `flutter pub get` so builds are
repeatable.

## Milestones

| #  | Deliverable | Status |
|----|-------------|--------|
| M0 | Repo, scaffold, CI | Done |
| M1 | Foundation: design system, login, SQLite, platform folders | Done |
| M2 | Video capture/import, pose extraction, skeleton overlay | Done |
| M3 | Batting metrics and phase detection | Done |
| M4 | Cloud coach: Claude, OpenAI, Gemini; built-in coach; API key settings | Done |
| M5 | Local Gemma 4: model download and auto-routing | Done |
| M6 | Session review (rename, notes, delete), progress charts, drills, sync engine | Done |
| M7 | Bowling analysis, discipline picker, release and iOS build workflows | Done |
| M8 | Fielding: catching analysis | Done |
| M9 | Wicketkeeping analysis | Done |

## Known limits

- Pose tracking sees the body only: the app coaches body mechanics, not bat
  path, ball contact or line and length.
- Metric guide ranges are sensible starting points from coaching literature,
  not validated biomechanics. Treat feedback as a prompt for practice, not a
  verdict.
- At 30 fps a fast bowling arm blurs; film in good light, and in slow motion
  where the phone allows it.
- Gemma 4 is a multi-gigabyte download, fetched on demand.

## Fonts

Headlines and numerals use Barlow Condensed, licensed under the SIL Open Font
License (`assets/fonts/OFL.txt`).
