// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a en locale. All the
// messages from the main program should be duplicated here with the same
// function name.

// Ignore issues from commonly used lints in this file.
// ignore_for_file:unnecessary_brace_in_string_interps, unnecessary_new
// ignore_for_file:prefer_single_quotes,comment_references, directives_ordering
// ignore_for_file:annotate_overrides,prefer_generic_function_type_aliases
// ignore_for_file:unused_import, file_names, avoid_escaping_inner_quotes
// ignore_for_file:unnecessary_string_interpolations, unnecessary_string_escapes

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';

final messages = new MessageLookup();

typedef String MessageIfAbsent(String messageStr, List<dynamic> args);

class MessageLookup extends MessageLookupByLibrary {
  String get localeName => 'en';

  static String m0(project) => "Deleted ${project}";

  static String m1(count) => "Selected ${count} timepoints: ";

  static String m2(usingLocal, version) =>
      "Using ${Intl.select(usingLocal, {'true': 'local', 'false': 'system', 'other': 'unknown'})} yt-dlp, version ${version}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "about": MessageLookupByLibrary.simpleMessage("About"),
    "add": MessageLookupByLibrary.simpleMessage("Add"),
    "addAudio": MessageLookupByLibrary.simpleMessage("Add Track"),
    "addLanguage": MessageLookupByLibrary.simpleMessage("Add Language"),
    "addLanguageHint": MessageLookupByLibrary.simpleMessage(
      "Add auxiliary content, such as phonetics, Romaji, or Pinyin",
    ),
    "adjustLyricOffset": MessageLookupByLibrary.simpleMessage(
      "Adjust Lyric Offset",
    ),
    "aiTranscribe": MessageLookupByLibrary.simpleMessage("AI Transcribe"),
    "album": MessageLookupByLibrary.simpleMessage("Album"),
    "apply": MessageLookupByLibrary.simpleMessage("Apply"),
    "artist": MessageLookupByLibrary.simpleMessage("Artist"),
    "attachToLyric": MessageLookupByLibrary.simpleMessage("Snap to Lyrics"),
    "audioPathInvalidHint": MessageLookupByLibrary.simpleMessage(
      "Please enter a local file path or a valid YouTube link",
    ),
    "autoFillMetadata": MessageLookupByLibrary.simpleMessage(
      "Auto-fill music info",
    ),
    "cancel": MessageLookupByLibrary.simpleMessage("Cancel"),
    "clearLyric": MessageLookupByLibrary.simpleMessage("Clear Lyrics"),
    "confirm": MessageLookupByLibrary.simpleMessage("Confirm"),
    "confirmTrackInfo": MessageLookupByLibrary.simpleMessage(
      "Confirm track info",
    ),
    "continuePracticing": MessageLookupByLibrary.simpleMessage("Continue"),
    "contribute": MessageLookupByLibrary.simpleMessage("Contribute!"),
    "copy": MessageLookupByLibrary.simpleMessage("Copy"),
    "copyCurrentLyric": MessageLookupByLibrary.simpleMessage(
      "Copy Current Lyric",
    ),
    "copyWholeLyric": MessageLookupByLibrary.simpleMessage("Copy All Lyrics"),
    "copyright2026": MessageLookupByLibrary.simpleMessage(
      "Copyright 2026 Joodo. Licensed under GPLv3 License.",
    ),
    "createNewProject": MessageLookupByLibrary.simpleMessage("New Project"),
    "currentLyricCopyed": MessageLookupByLibrary.simpleMessage(
      "Current lyric copied",
    ),
    "dark": MessageLookupByLibrary.simpleMessage("Dark"),
    "delete": MessageLookupByLibrary.simpleMessage("Delete"),
    "discard": MessageLookupByLibrary.simpleMessage("Discard"),
    "discardChanges": MessageLookupByLibrary.simpleMessage("Discard changes?"),
    "download": MessageLookupByLibrary.simpleMessage("Download"),
    "downloading": MessageLookupByLibrary.simpleMessage("Downloading..."),
    "edit": MessageLookupByLibrary.simpleMessage("Edit"),
    "editLyric": MessageLookupByLibrary.simpleMessage("Edit lyric"),
    "editMetadata": MessageLookupByLibrary.simpleMessage("Edit metadata"),
    "editTranslateLyric": MessageLookupByLibrary.simpleMessage(
      "Edit translate lyric",
    ),
    "expertMode": MessageLookupByLibrary.simpleMessage("Expert Mode"),
    "expertModeHint": MessageLookupByLibrary.simpleMessage(
      "Locate songs by waveform and allow playback from a fixed position.",
    ),
    "extraArgs": MessageLookupByLibrary.simpleMessage("Extra args"),
    "failed": MessageLookupByLibrary.simpleMessage("Failed"),
    "failedToLoad": MessageLookupByLibrary.simpleMessage("Failed to load"),
    "failedToLoadSeparationAudio": MessageLookupByLibrary.simpleMessage(
      "Failed to load separation audio",
    ),
    "failedToReadAloudPleaseRetry": MessageLookupByLibrary.simpleMessage(
      "Failed to get audio, please retry",
    ),
    "failureOfTest": MessageLookupByLibrary.simpleMessage(" Failure:"),
    "followSystem": MessageLookupByLibrary.simpleMessage("Follow System"),
    "functionOfAcoustID": MessageLookupByLibrary.simpleMessage(
      "Used for completing music information",
    ),
    "functionOfLlm": MessageLookupByLibrary.simpleMessage(
      "Used for understanding and translating lyrics",
    ),
    "functionOfMvsep": MessageLookupByLibrary.simpleMessage(
      "Used for generating accompaniments",
    ),
    "general": MessageLookupByLibrary.simpleMessage("General"),
    "imageFile": MessageLookupByLibrary.simpleMessage("Image file"),
    "interface": MessageLookupByLibrary.simpleMessage("Interface"),
    "language": MessageLookupByLibrary.simpleMessage("Language"),
    "leaveYourNameOptional": MessageLookupByLibrary.simpleMessage(
      "Leave your name (optional)",
    ),
    "light": MessageLookupByLibrary.simpleMessage("Light"),
    "llmModelExample": MessageLookupByLibrary.simpleMessage(
      "e.g., \"gemini-3-flash-preview\"",
    ),
    "localStorageDir": MessageLookupByLibrary.simpleMessage(
      "Local Storage Directory",
    ),
    "lyricFile": MessageLookupByLibrary.simpleMessage("Lyric File"),
    "metadataWillBeRestoredToTheStateBeforeModification":
        MessageLookupByLibrary.simpleMessage(
          "Metadata will be restored to the state before modification.",
        ),
    "mixTable": MessageLookupByLibrary.simpleMessage("Mix Table"),
    "modelName": MessageLookupByLibrary.simpleMessage("Model Name"),
    "modified": MessageLookupByLibrary.simpleMessage("(Modified)"),
    "myLibrary": MessageLookupByLibrary.simpleMessage("My Library"),
    "network": MessageLookupByLibrary.simpleMessage("Network"),
    "networkProxy": MessageLookupByLibrary.simpleMessage("Network Proxy"),
    "next": MessageLookupByLibrary.simpleMessage("Next"),
    "noExecutableFound": MessageLookupByLibrary.simpleMessage(
      "No executable found.",
    ),
    "noMediaInformationFound": MessageLookupByLibrary.simpleMessage(
      "No media information found",
    ),
    "noProject": MessageLookupByLibrary.simpleMessage("No projects"),
    "oneForAllAllForOne": MessageLookupByLibrary.simpleMessage(
      "One for all, all for one!",
    ),
    "openLocal": MessageLookupByLibrary.simpleMessage("Open Local"),
    "openProjectDirectory": MessageLookupByLibrary.simpleMessage(
      "Open project directory",
    ),
    "optionalServiceUrl": MessageLookupByLibrary.simpleMessage(
      "Service URL (Optional)",
    ),
    "pasteLyricsHere": MessageLookupByLibrary.simpleMessage(
      "Paste lyrics here",
    ),
    "pause": MessageLookupByLibrary.simpleMessage("Pause"),
    "pitch": MessageLookupByLibrary.simpleMessage("Pitch"),
    "play": MessageLookupByLibrary.simpleMessage("Play"),
    "playFromStartPoint": MessageLookupByLibrary.simpleMessage(
      "Play from Start",
    ),
    "playbackRate": MessageLookupByLibrary.simpleMessage("Speed"),
    "previous": MessageLookupByLibrary.simpleMessage("Previous"),
    "processing": MessageLookupByLibrary.simpleMessage("Processing"),
    "projectDeletedHint": m0,
    "proofread": MessageLookupByLibrary.simpleMessage("Proofread"),
    "proofreadHint": MessageLookupByLibrary.simpleMessage(
      "The LRC lyrics will be calibrated and supplemented according to the provided lyric text.",
    ),
    "proofreading": MessageLookupByLibrary.simpleMessage("Proofreading..."),
    "readAloudCurrentLyric": MessageLookupByLibrary.simpleMessage(
      "Read Current Lyric Aloud",
    ),
    "readAloudLyric": MessageLookupByLibrary.simpleMessage("Read Lyrics Aloud"),
    "regenerateExplanation": MessageLookupByLibrary.simpleMessage(
      "Regenerate Explanation",
    ),
    "regenerateSubtitle": MessageLookupByLibrary.simpleMessage(
      "Regenerate Subtitles",
    ),
    "retry": MessageLookupByLibrary.simpleMessage("Retry"),
    "save": MessageLookupByLibrary.simpleMessage("Save"),
    "searchOnline": MessageLookupByLibrary.simpleMessage("Search Online"),
    "searchTitleArtistOrAlbum": MessageLookupByLibrary.simpleMessage(
      "Search Title, Artist or Album...",
    ),
    "seekToTimepoint": MessageLookupByLibrary.simpleMessage(
      "Seek to timepoint",
    ),
    "selectAudioFile": MessageLookupByLibrary.simpleMessage(
      "Select Audio File",
    ),
    "selectService": MessageLookupByLibrary.simpleMessage("Select Service"),
    "selectedTimepoints": m1,
    "separateWithSpace": MessageLookupByLibrary.simpleMessage(
      "Separate with space",
    ),
    "settings": MessageLookupByLibrary.simpleMessage("Settings"),
    "showLicense": MessageLookupByLibrary.simpleMessage("Show License"),
    "stop": MessageLookupByLibrary.simpleMessage("Stop"),
    "successOfTest": MessageLookupByLibrary.simpleMessage(" Success"),
    "supportAudioInputsHint": MessageLookupByLibrary.simpleMessage(
      "Supports YouTube links or local files",
    ),
    "targetLanguage": MessageLookupByLibrary.simpleMessage("Target Language"),
    "test": MessageLookupByLibrary.simpleMessage("Test"),
    "testing": MessageLookupByLibrary.simpleMessage("Testing"),
    "textProcessing": MessageLookupByLibrary.simpleMessage("Text Processing"),
    "textProcessingTest": MessageLookupByLibrary.simpleMessage(
      "Text Processing Test",
    ),
    "theme": MessageLookupByLibrary.simpleMessage("Theme"),
    "title": MessageLookupByLibrary.simpleMessage("Title"),
    "tools": MessageLookupByLibrary.simpleMessage("Tools"),
    "transcribing": MessageLookupByLibrary.simpleMessage("Transcribing"),
    "translate": MessageLookupByLibrary.simpleMessage("Translate"),
    "translateLyric": MessageLookupByLibrary.simpleMessage("Translate Lyrics"),
    "translateTo": MessageLookupByLibrary.simpleMessage("Translate to: "),
    "ttsModelExample": MessageLookupByLibrary.simpleMessage(
      "e.g., \"gemini-2.5-flash-preview-tts\"",
    ),
    "undo": MessageLookupByLibrary.simpleMessage("Undo"),
    "upgrade": MessageLookupByLibrary.simpleMessage("Upgrade"),
    "upgrading": MessageLookupByLibrary.simpleMessage("Upgrading..."),
    "upload": MessageLookupByLibrary.simpleMessage("Upload"),
    "uploadLyricsHint": MessageLookupByLibrary.simpleMessage(
      "Upload lyrics to lrclib.net and share your contributions with the world.",
    ),
    "version": MessageLookupByLibrary.simpleMessage("version"),
    "vocalIsolation": MessageLookupByLibrary.simpleMessage("Vocal Isolation"),
    "vocalIsolationIsRequired": MessageLookupByLibrary.simpleMessage(
      "Vocal isolation is required",
    ),
    "voiceGeneration": MessageLookupByLibrary.simpleMessage("Voice Generation"),
    "voiceTest": MessageLookupByLibrary.simpleMessage("Voice Test"),
    "volume": MessageLookupByLibrary.simpleMessage("Volume"),
    "wholeLyricCopyed": MessageLookupByLibrary.simpleMessage(
      "All lyrics copied",
    ),
    "wordByWordExplanation": MessageLookupByLibrary.simpleMessage(
      "Word-by-word Breakdown",
    ),
    "ytDlpInfo": m2,
    "ytDlpUpgradingHint": MessageLookupByLibrary.simpleMessage(
      "Try updating your version if YouTube audio downloads fail.",
    ),
    "ytDlpUseHint": MessageLookupByLibrary.simpleMessage(
      "Used to download audio from YouTube",
    ),
  };
}
