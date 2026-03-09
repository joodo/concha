# Concha

Concha is a singing practice app built with Flutter.

The idea is simple: load a song, inspect its waveform, set a start point, and
repeat difficult phrases until they feel natural.

`Concha - hear it again. sing it better.`

## What Concha Does

- Creates practice projects from local audio files.
- Saves project data locally so your practice list persists across launches.
- Shows music metadata (title + cover art when available).
- Provides a waveform overview and a detailed timeline view.
- Lets you set a custom start point from the timeline.
- Supports play, pause, stop, seek, and "play from start point" actions.
- Supports quick play/pause with the `Space` key.
- Supports timeline zooming with mouse wheel in the overview panel.

## Supported Audio Import Types

When creating a project, the file picker accepts:

- `mp3`
- `m4a`
- `wav`
- `flac`
- `aac`
- `ogg`

## Tech Stack

- Flutter + Dart
- `flutter_soloud` for audio playback and sample reading
- `audio_metadata_reader` for title/cover extraction
- `provider` / `ChangeNotifier` style state updates
- `json_serializable` for project model persistence

## Quick Start

### Prerequisites

- Flutter SDK (latest stable recommended)
- Dart SDK compatible with `sdk: ^3.10.8`
- A desktop or mobile Flutter target device

### Install Dependencies

```bash
flutter pub get
```

### Run (macOS example)

```bash
flutter run -d macos
```

Use `flutter devices` to list all available targets.

## Practice Workflow

1. Open Concha.
2. Tap `+` to create a new project.
3. Pick a local song file.
4. Open the project from the grid.
5. Click the timeline to set your phrase start point.
6. Press the main play button to start from that point.
7. Repeat, adjust, and practice.

## Project Structure

- `lib/pages/start/`: project list and "new project" dialog
- `lib/pages/project/`: playback page and toolbar
- `lib/waveform/`: waveform rendering, timeline, overview, chunk loading
- `lib/play_controller.dart`: audio playback, seek, position tracking
- `lib/models/`: persistent `Project` model and JSON serialization

## Current Status

Concha is in active prototype stage.

Core loop for audio-based singing practice is available, while advanced
training features (for example lyric alignment, pitch analysis, and scoring)
are not fully implemented yet.

## Roadmap Ideas

- Lyric import and synchronized lyric display
- A/B loop range practice (start + end markers)
- Speed control without pitch shift
- Pitch tracking and visual feedback
- Session history and progress metrics

## License

No license file is included yet. Add a `LICENSE` file before public release.
