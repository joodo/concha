# Concha

Concha is a Flutter-based singing practice app.

`Concha - hear it again. sing it better.`

## Implemented Features

### 1) Project Creation and Management

- Project list view with cover/title, sorted by latest modified time.
- Create project from:
  - Local audio file.
  - YouTube URL (audio extracted via `yt-dlp`).
- Optional settings in create dialog:
  - HTTP proxy.
  - AcoustID metadata completion toggle + API key.
- Delete project from the start page context menu.

### 2) Audio Playback and Waveform

- Playback engine based on `flutter_soloud`.
- Supports `play`, `pause`, `stop`, `seek`, and `play from start point`.
- Independent controls:
  - Volume: `0%` to `100%`.
  - Speed: `0.25x` to `2.0x`.
  - Pitch: `-7` to `+7` semitones.
- Speed/pitch compensation is implemented to keep musical pitch stable when
  speed changes.
- Dual waveform UI:
  - Overview waveform (tap/drag to jump).
  - Detailed timeline waveform (tap to seek).
- Timeline click sets start point for phrase replay.

### 3) Lyric Workflow

- Open local `.lrc` lyric file.
- Online lyric search via `lrclib.net`.
- Lyric translation via Gemini (`google_generative_ai`).
- Adjustable lyric offset (`-10s` to `+10s`) with persistent save.
- Lyric progress follows playback position in real time.

### 4) Metadata Matching Pipeline

- Local tag read (`audio_metadata_reader`) for title/artist/album/cover.
- Multi-source matching pipeline:
  - AcoustID fingerprint recognition.
  - MusicBrainz recording search.
  - Candidate ranking and best match selection.
- Cover fallback includes Cover Art Archive download when IDs are available.

### 5) Persistence

- Project files are stored under app support directory (`projects/<id>/`).
- Persisted per project:
  - Audio file.
  - Cover image.
  - Lyric and translated lyric.
  - Playback position.
  - Lyric offset.

## Supported Audio Import Types

- `mp3`
- `m4a`
- `wav`
- `flac`
- `aac`
- `ogg`

## Keyboard Shortcuts

- `Space`: toggle play/pause.
- `Arrow Left` / `Arrow Right`: seek backward/forward 10s.
- `Arrow Up` / `Arrow Down`: volume +10% / -10%.
- `,` / `.`: speed -0.25x / +0.25x.
- `[` / `]`: pitch -1 / +1 semitone.

## Environment and Dependencies

### Required

- Flutter SDK (latest stable recommended).
- Dart SDK compatible with `sdk: ^3.10.8`.

### Runtime Tooling (auto-handled when possible)

- `yt-dlp`: required for YouTube import.
- `fpcalc` (Chromaprint): required for AcoustID recognition.

Concha will try to use system tools first, then auto-download binaries into
app support directory when missing.

### Optional API Keys

- AcoustID API key: improves metadata matching quality.
- Gemini API key: enables lyric translation.

## Quick Start

```bash
flutter pub get
flutter run -d macos
```

Use `flutter devices` to list available targets.

## Project Structure

- `lib/pages/start/`: project list and new project flow.
- `lib/pages/project/`: playback screen, lyric section, toolbar.
- `lib/waveform/`: waveform rendering, loading, zoom/scroll bindings.
- `lib/services/`: metadata/lyric/matching/download integrations.
- `lib/play_controller.dart`: playback state + audio control.
- `lib/models/`: persistent project model (`json_serializable`).

## License

This project includes `LICENSE` and is licensed under **GNU GPL v3.0**.
