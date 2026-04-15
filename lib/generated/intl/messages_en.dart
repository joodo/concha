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

  static String m0(bytes) => "(${bytes} downloaded)";

  static String m1(phase, reason) => "Failed at: ${phase}\\nReason: ${reason}";

  static String m2(project) => "Deleted \$${project}";

  static String m3(count) => "In queue (${count} remaining)";

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
    "apply": MessageLookupByLibrary.simpleMessage("Apply"),
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
    "continuePracticing": MessageLookupByLibrary.simpleMessage("Continue"),
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
    "downloadedBytes": m0,
    "downloadingStatus": MessageLookupByLibrary.simpleMessage("Downloading"),
    "failed": MessageLookupByLibrary.simpleMessage("Failed"),
    "failedToLoad": MessageLookupByLibrary.simpleMessage("Failed to load"),
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
    "initiatingService": MessageLookupByLibrary.simpleMessage(
      "Initializing service",
    ),
    "interface": MessageLookupByLibrary.simpleMessage("Interface"),
    "language": MessageLookupByLibrary.simpleMessage("Language"),
    "light": MessageLookupByLibrary.simpleMessage("Light"),
    "llmModelExample": MessageLookupByLibrary.simpleMessage(
      "e.g., \"gemini-3-flash-preview\"",
    ),
    "loadingAfterSeparatedStatus": MessageLookupByLibrary.simpleMessage(
      "Generated successfully! Loading",
    ),
    "localStorageDir": MessageLookupByLibrary.simpleMessage(
      "Local Storage Directory",
    ),
    "lyricFile": MessageLookupByLibrary.simpleMessage("Lyric File"),
    "modelName": MessageLookupByLibrary.simpleMessage("Model Name"),
    "myLibrary": MessageLookupByLibrary.simpleMessage("My Library"),
    "network": MessageLookupByLibrary.simpleMessage("Network"),
    "networkProxy": MessageLookupByLibrary.simpleMessage("Network Proxy"),
    "noProject": MessageLookupByLibrary.simpleMessage("No projects"),
    "openLocal": MessageLookupByLibrary.simpleMessage("Open Local"),
    "optionalServiceUrl": MessageLookupByLibrary.simpleMessage(
      "Service URL (Optional)",
    ),
    "pause": MessageLookupByLibrary.simpleMessage("Pause"),
    "phaseFailedStatus": m1,
    "pitch": MessageLookupByLibrary.simpleMessage("Pitch"),
    "play": MessageLookupByLibrary.simpleMessage("Play"),
    "playFromStartPoint": MessageLookupByLibrary.simpleMessage(
      "Play from Start",
    ),
    "playbackRate": MessageLookupByLibrary.simpleMessage("Speed"),
    "processing": MessageLookupByLibrary.simpleMessage("Processing"),
    "projectDeletedHint": m2,
    "queueStatus": m3,
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
    "searchOnline": MessageLookupByLibrary.simpleMessage("Search Online"),
    "selectAudioFile": MessageLookupByLibrary.simpleMessage(
      "Select Audio File",
    ),
    "selectService": MessageLookupByLibrary.simpleMessage("Select Service"),
    "separatingStatus": MessageLookupByLibrary.simpleMessage(
      "Separating vocals and accompaniment",
    ),
    "settings": MessageLookupByLibrary.simpleMessage("Settings"),
    "startingProgress": MessageLookupByLibrary.simpleMessage("In progress"),
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
    "translate": MessageLookupByLibrary.simpleMessage("Translate"),
    "translateLyric": MessageLookupByLibrary.simpleMessage("Translate Lyrics"),
    "translateTo": MessageLookupByLibrary.simpleMessage("Translate to: "),
    "ttsModelExample": MessageLookupByLibrary.simpleMessage(
      "e.g., \"gemini-2.5-flash-preview-tts\"",
    ),
    "undo": MessageLookupByLibrary.simpleMessage("Undo"),
    "uploading": MessageLookupByLibrary.simpleMessage("Uploading"),
    "version": MessageLookupByLibrary.simpleMessage("version"),
    "vocalIsolation": MessageLookupByLibrary.simpleMessage(
      "Vocal Isolation Mode",
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
  };
}
