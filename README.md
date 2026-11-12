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
2. **Choose a discipline** - batting, bowling, fielding (catching) or
   wicketkeeping.
3. **Capture** - record or import a short clip of one ball. A guided tour
   for each discipline shows where to put the camera, how to frame the
   player and what the clip must contain. It opens by itself the first time
   you record a discipline and can be replayed from the new-session screen
   or from Settings.
4. **Pose** - 33 body landmarks are extracted per sampled frame, on the device
   (Google ML Kit pose detection).
5. **Measure** - pure Dart analyzers find the key moments of the movement and
   compute seven measurements per discipline, each scored against a guide
   range. The technique score is the mean of those scores.
6. **Coach** - the measurements (never the video) go to a coach, which returns
   a summary, strengths, improvements and drills.
7. **Review** - skeleton overlay playback with jump-to-moment, measurement
   bars, feedback, your own notes, history and progress charts.

### What each discipline measures

| Discipline | Moments found | Measurements |
|------------|---------------|--------------|
| Batting | Stance, backlift, impact, finish | Front knee, front elbow, head over front foot, stride, backlift height, head movement, balance at finish |
| Bowling | Front foot lands, release, follow-through | Arm straightness, release height, front knee, trunk lean, stride, head movement, follow-through |
| Fielding | Ready, catch, give | Hands together, knee bend, stance width, head in line, elbow bend, give, head movement |
| Wicketkeeping | Set, take, give | Crouch depth, stance width, rise before the take, gloves together, head in line, elbow bend, give |

### Who writes the feedback

`CoachService` picks the coach. In automatic mode the order is:

1. **Gemma 4 on the phone** (`flutter_edge_ai`, LiteRT-LM) once its model has
   been downloaded from Settings. Works offline; nothing leaves the device.
2. **A cloud coach** - Claude, ChatGPT (OpenAI) or Gemini - when you have saved
   your own API key for it. Model names are editable in Settings.
3. **The built-in coach**, which writes feedback straight from the
   measurements with no AI model. Always available.

You can also pick one coach in Settings. If the chosen coach fails, the
built-in coach answers and the feedback says why. API keys are kept in the
phone's secure storage (Keychain / Keystore), never in the database.

### Data and sync

Everything is stored in SQLite (`lib/core/db/app_database.dart`). Every session
row carries `updated_at`, `sync_state` and a soft-delete flag. `SyncService`
pushes pending changes, pulls remote ones and resolves conflicts by
last-edit-wins, against a `CloudBackend` interface.

The app ships with `NoCloudBackend`, so sync is **not active yet**. To turn it
on, implement `CloudBackend` (for example with Cloud Firestore) and pass it to
`SyncService` in `lib/core/services.dart`; implement `AuthRepository` with
Firebase Auth in the same way. Session records sync; video clips and pose data
stay on the phone.

## Project layout

```
lib/
  main.dart, app.dart
  core/
    analysis/  analyzers for each discipline, metrics, body helpers
    auth/      accounts, password hashing, auth state
    capture/   clip picker
    coach/     coach providers (cloud/, local/), prompt, parser, drills
    db/        SQLite schema
    guide/     filming tours for each discipline
    pose/      landmarks, frame extraction, pose estimation
    progress/  progress summaries
    sessions/  Session model, repository, analysis pipeline, video store
    settings/  per-user settings and secret storage
    sync/      sync engine and cloud backend interface
    theme/     colours, type, shared decoration
    util/      ids, validators, formatters
  features/    one folder per screen
  widgets/     shared widgets
test/          unit and widget tests
```

Everything that touches a plugin sits behind an interface in a `plugins/`
folder, so the logic is unit-tested with fakes.

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

### Platform requirements

- **Android**: Android 11 (API 30) or newer, 64-bit ARM. The on-device model
  runtime sets this floor.
- **iOS**: iOS 15.5 or newer. For the on-device model on a real iPhone, add the
  extended-virtual-addressing and increased-memory-limit entitlements to the
  Runner target (see the `flutter_edge_ai` documentation); they need a paid
  Apple developer account.

### Workflows

| Workflow | When | What |
|----------|------|------|
| CI | every push | `flutter analyze` and `flutter test` |
| Android build | every push | debug APK compiles |
| iOS build | manual, or push to `ci/ios*` | unsigned iOS build compiles |
| Release build | manual | release APK as a downloadable artifact |

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
  path, ball contact, line and length, or whether a catch was held.
- Guide ranges are general coaching starting points, not validated
  biomechanics, and have not been tuned against real footage yet. Treat
  feedback as a prompt for practice, not a verdict. The ranges live at the top
  of each analyzer.
- A single camera cannot judge whether a bowling action is legal.
- Clips are sampled at 15 frames per second, so a fast bowling arm is caught
  in only a few frames; film in good light, and in slow motion where the
  phone allows it.
- Gemma 4 E2B is a 2.4 GB download and suits recent phones with 8 GB of
  memory or more.
- Cloud sync and cloud accounts are not connected yet (see Data and sync).

## Fonts

Headlines and numerals use Barlow Condensed, licensed under the SIL Open Font
License (`assets/fonts/OFL.txt`).
