// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'intl/messages_all.dart';

// **************************************************************************
// Generator: Flutter Intl IDE plugin
// Made by Localizely
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars
// ignore_for_file: join_return_with_assignment, prefer_final_in_for_each
// ignore_for_file: avoid_redundant_argument_values, avoid_escaping_inner_quotes

class S {
  S();

  static S? _current;

  static S get current {
    assert(
      _current != null,
      'No instance of S was loaded. Try to initialize the S delegate before accessing S.current.',
    );
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<S> load(Locale locale) {
    final name = (locale.countryCode?.isEmpty ?? false)
        ? locale.languageCode
        : locale.toString();
    final localeName = Intl.canonicalizedLocale(name);
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      final instance = S();
      S._current = instance;

      return instance;
    });
  }

  static S of(BuildContext context) {
    final instance = S.maybeOf(context);
    assert(
      instance != null,
      'No instance of S present in the widget tree. Did you add S.delegate in localizationsDelegates?',
    );
    return instance!;
  }

  static S? maybeOf(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  /// `Settings`
  String get settings {
    return Intl.message('Settings', name: 'settings', desc: '', args: []);
  }

  /// `Interface`
  String get interface {
    return Intl.message('Interface', name: 'interface', desc: '', args: []);
  }

  /// `Theme`
  String get theme {
    return Intl.message('Theme', name: 'theme', desc: '', args: []);
  }

  /// `Follow System`
  String get followSystem {
    return Intl.message(
      'Follow System',
      name: 'followSystem',
      desc: '',
      args: [],
    );
  }

  /// `Light`
  String get light {
    return Intl.message('Light', name: 'light', desc: '', args: []);
  }

  /// `Dark`
  String get dark {
    return Intl.message('Dark', name: 'dark', desc: '', args: []);
  }

  /// `Language`
  String get language {
    return Intl.message('Language', name: 'language', desc: '', args: []);
  }

  /// `Network`
  String get network {
    return Intl.message('Network', name: 'network', desc: '', args: []);
  }

  /// `Network Proxy`
  String get networkProxy {
    return Intl.message(
      'Network Proxy',
      name: 'networkProxy',
      desc: '',
      args: [],
    );
  }

  /// `Used for completing music information`
  String get functionOfAcoustID {
    return Intl.message(
      'Used for completing music information',
      name: 'functionOfAcoustID',
      desc: '',
      args: [],
    );
  }

  /// `Apply`
  String get apply {
    return Intl.message('Apply', name: 'apply', desc: '', args: []);
  }

  /// `Used for generating accompaniments`
  String get functionOfMvsep {
    return Intl.message(
      'Used for generating accompaniments',
      name: 'functionOfMvsep',
      desc: '',
      args: [],
    );
  }

  /// `Text Processing`
  String get textProcessing {
    return Intl.message(
      'Text Processing',
      name: 'textProcessing',
      desc: '',
      args: [],
    );
  }

  /// `Select Service`
  String get selectService {
    return Intl.message(
      'Select Service',
      name: 'selectService',
      desc: '',
      args: [],
    );
  }

  /// `Used for understanding and translating lyrics`
  String get functionOfLlm {
    return Intl.message(
      'Used for understanding and translating lyrics',
      name: 'functionOfLlm',
      desc: '',
      args: [],
    );
  }

  /// `Target Language`
  String get targetLanguage {
    return Intl.message(
      'Target Language',
      name: 'targetLanguage',
      desc: '',
      args: [],
    );
  }

  /// `Translate to: `
  String get translateTo {
    return Intl.message(
      'Translate to: ',
      name: 'translateTo',
      desc: '',
      args: [],
    );
  }

  /// `Service URL (Optional)`
  String get optionalServiceUrl {
    return Intl.message(
      'Service URL (Optional)',
      name: 'optionalServiceUrl',
      desc: '',
      args: [],
    );
  }

  /// `Model Name`
  String get modelName {
    return Intl.message('Model Name', name: 'modelName', desc: '', args: []);
  }

  /// `e.g., "gemini-3-flash-preview"`
  String get llmModelExample {
    return Intl.message(
      'e.g., "gemini-3-flash-preview"',
      name: 'llmModelExample',
      desc: '',
      args: [],
    );
  }

  /// `Text Processing Test`
  String get textProcessingTest {
    return Intl.message(
      'Text Processing Test',
      name: 'textProcessingTest',
      desc: '',
      args: [],
    );
  }

  /// `Voice Generation`
  String get voiceGeneration {
    return Intl.message(
      'Voice Generation',
      name: 'voiceGeneration',
      desc: '',
      args: [],
    );
  }

  /// `e.g., "gemini-2.5-flash-preview-tts"`
  String get ttsModelExample {
    return Intl.message(
      'e.g., "gemini-2.5-flash-preview-tts"',
      name: 'ttsModelExample',
      desc: '',
      args: [],
    );
  }

  /// `Voice Test`
  String get voiceTest {
    return Intl.message('Voice Test', name: 'voiceTest', desc: '', args: []);
  }

  /// `About`
  String get about {
    return Intl.message('About', name: 'about', desc: '', args: []);
  }

  /// `Local Storage Directory`
  String get localStorageDir {
    return Intl.message(
      'Local Storage Directory',
      name: 'localStorageDir',
      desc: '',
      args: [],
    );
  }

  /// `Test`
  String get test {
    return Intl.message('Test', name: 'test', desc: '', args: []);
  }

  /// ` Success`
  String get successOfTest {
    return Intl.message(' Success', name: 'successOfTest', desc: '', args: []);
  }

  /// ` Failure:`
  String get failureOfTest {
    return Intl.message(' Failure:', name: 'failureOfTest', desc: '', args: []);
  }

  /// `Testing`
  String get testing {
    return Intl.message('Testing', name: 'testing', desc: '', args: []);
  }

  /// `Confirm`
  String get confirm {
    return Intl.message('Confirm', name: 'confirm', desc: '', args: []);
  }

  /// `version`
  String get version {
    return Intl.message('version', name: 'version', desc: '', args: []);
  }

  /// `Copyright 2026 Joodo. Licensed under GPLv3 License.`
  String get copyright2026 {
    return Intl.message(
      'Copyright 2026 Joodo. Licensed under GPLv3 License.',
      name: 'copyright2026',
      desc: '',
      args: [],
    );
  }

  /// `Word-by-word Breakdown`
  String get wordByWordExplanation {
    return Intl.message(
      'Word-by-word Breakdown',
      name: 'wordByWordExplanation',
      desc: '',
      args: [],
    );
  }

  /// `Current lyric copied`
  String get currentLyricCopyed {
    return Intl.message(
      'Current lyric copied',
      name: 'currentLyricCopyed',
      desc: '',
      args: [],
    );
  }

  /// `All lyrics copied`
  String get wholeLyricCopyed {
    return Intl.message(
      'All lyrics copied',
      name: 'wholeLyricCopyed',
      desc: '',
      args: [],
    );
  }

  /// `Copy Current Lyric`
  String get copyCurrentLyric {
    return Intl.message(
      'Copy Current Lyric',
      name: 'copyCurrentLyric',
      desc: '',
      args: [],
    );
  }

  /// `Copy All Lyrics`
  String get copyWholeLyric {
    return Intl.message(
      'Copy All Lyrics',
      name: 'copyWholeLyric',
      desc: '',
      args: [],
    );
  }

  /// `Translate`
  String get translate {
    return Intl.message('Translate', name: 'translate', desc: '', args: []);
  }

  /// `Cancel`
  String get cancel {
    return Intl.message('Cancel', name: 'cancel', desc: '', args: []);
  }

  /// `Add Language`
  String get addLanguage {
    return Intl.message(
      'Add Language',
      name: 'addLanguage',
      desc: '',
      args: [],
    );
  }

  /// `Add auxiliary content, such as phonetics, Romaji, or Pinyin`
  String get addLanguageHint {
    return Intl.message(
      'Add auxiliary content, such as phonetics, Romaji, or Pinyin',
      name: 'addLanguageHint',
      desc: '',
      args: [],
    );
  }

  /// `Regenerate Explanation`
  String get regenerateExplanation {
    return Intl.message(
      'Regenerate Explanation',
      name: 'regenerateExplanation',
      desc: '',
      args: [],
    );
  }

  /// `Read Lyrics Aloud`
  String get readAloudLyric {
    return Intl.message(
      'Read Lyrics Aloud',
      name: 'readAloudLyric',
      desc: '',
      args: [],
    );
  }

  /// `Clear Lyrics`
  String get clearLyric {
    return Intl.message('Clear Lyrics', name: 'clearLyric', desc: '', args: []);
  }

  /// `Read Current Lyric Aloud`
  String get readAloudCurrentLyric {
    return Intl.message(
      'Read Current Lyric Aloud',
      name: 'readAloudCurrentLyric',
      desc: '',
      args: [],
    );
  }

  /// `Translate Lyrics`
  String get translateLyric {
    return Intl.message(
      'Translate Lyrics',
      name: 'translateLyric',
      desc: '',
      args: [],
    );
  }

  /// `Failed`
  String get failed {
    return Intl.message('Failed', name: 'failed', desc: '', args: []);
  }

  /// `Open Local`
  String get openLocal {
    return Intl.message('Open Local', name: 'openLocal', desc: '', args: []);
  }

  /// `Search Online`
  String get searchOnline {
    return Intl.message(
      'Search Online',
      name: 'searchOnline',
      desc: '',
      args: [],
    );
  }

  /// `Lyric File`
  String get lyricFile {
    return Intl.message('Lyric File', name: 'lyricFile', desc: '', args: []);
  }

  /// `Adjust Lyric Offset`
  String get adjustLyricOffset {
    return Intl.message(
      'Adjust Lyric Offset',
      name: 'adjustLyricOffset',
      desc: '',
      args: [],
    );
  }

  /// `Pause`
  String get pause {
    return Intl.message('Pause', name: 'pause', desc: '', args: []);
  }

  /// `Play from Start`
  String get playFromStartPoint {
    return Intl.message(
      'Play from Start',
      name: 'playFromStartPoint',
      desc: '',
      args: [],
    );
  }

  /// `Play`
  String get play {
    return Intl.message('Play', name: 'play', desc: '', args: []);
  }

  /// `Snap to Lyrics`
  String get attachToLyric {
    return Intl.message(
      'Snap to Lyrics',
      name: 'attachToLyric',
      desc: '',
      args: [],
    );
  }

  /// `Stop`
  String get stop {
    return Intl.message('Stop', name: 'stop', desc: '', args: []);
  }

  /// `Volume`
  String get volume {
    return Intl.message('Volume', name: 'volume', desc: '', args: []);
  }

  /// `Speed`
  String get playbackRate {
    return Intl.message('Speed', name: 'playbackRate', desc: '', args: []);
  }

  /// `Pitch`
  String get pitch {
    return Intl.message('Pitch', name: 'pitch', desc: '', args: []);
  }

  /// `Vocal Isolation`
  String get vocalIsolation {
    return Intl.message(
      'Vocal Isolation',
      name: 'vocalIsolation',
      desc: '',
      args: [],
    );
  }

  /// `Initializing service`
  String get initiatingService {
    return Intl.message(
      'Initializing service',
      name: 'initiatingService',
      desc: '',
      args: [],
    );
  }

  /// `In progress`
  String get startingProgress {
    return Intl.message(
      'In progress',
      name: 'startingProgress',
      desc: '',
      args: [],
    );
  }

  /// `Uploading`
  String get uploading {
    return Intl.message('Uploading', name: 'uploading', desc: '', args: []);
  }

  /// `In queue ({count} remaining)`
  String queueStatus(num count) {
    final NumberFormat countNumberFormat = NumberFormat.compact(
      locale: Intl.getCurrentLocale(),
    );
    final String countString = countNumberFormat.format(count);

    return Intl.message(
      'In queue ($countString remaining)',
      name: 'queueStatus',
      desc: '',
      args: [countString],
    );
  }

  /// `Separating vocals and accompaniment`
  String get separatingStatus {
    return Intl.message(
      'Separating vocals and accompaniment',
      name: 'separatingStatus',
      desc: '',
      args: [],
    );
  }

  /// `Downloading`
  String get downloadingStatus {
    return Intl.message(
      'Downloading',
      name: 'downloadingStatus',
      desc: '',
      args: [],
    );
  }

  /// `({bytes} downloaded)`
  String downloadedBytes(String bytes) {
    return Intl.message(
      '($bytes downloaded)',
      name: 'downloadedBytes',
      desc: '',
      args: [bytes],
    );
  }

  /// `Generated successfully! Loading`
  String get loadingAfterSeparatedStatus {
    return Intl.message(
      'Generated successfully! Loading',
      name: 'loadingAfterSeparatedStatus',
      desc: '',
      args: [],
    );
  }

  /// `Failed at: {phase}\nReason: {reason}`
  String phaseFailedStatus(String phase, String reason) {
    return Intl.message(
      'Failed at: $phase\\nReason: $reason',
      name: 'phaseFailedStatus',
      desc: '',
      args: [phase, reason],
    );
  }

  /// `Processing`
  String get processing {
    return Intl.message('Processing', name: 'processing', desc: '', args: []);
  }

  /// `Delete`
  String get delete {
    return Intl.message('Delete', name: 'delete', desc: '', args: []);
  }

  /// `Failed to get audio, please retry`
  String get failedToReadAloudPleaseRetry {
    return Intl.message(
      'Failed to get audio, please retry',
      name: 'failedToReadAloudPleaseRetry',
      desc: '',
      args: [],
    );
  }

  /// `Select Audio File`
  String get selectAudioFile {
    return Intl.message(
      'Select Audio File',
      name: 'selectAudioFile',
      desc: '',
      args: [],
    );
  }

  /// `Supports YouTube links or local files`
  String get supportAudioInputsHint {
    return Intl.message(
      'Supports YouTube links or local files',
      name: 'supportAudioInputsHint',
      desc: '',
      args: [],
    );
  }

  /// `Auto-fill music info`
  String get autoFillMetadata {
    return Intl.message(
      'Auto-fill music info',
      name: 'autoFillMetadata',
      desc: '',
      args: [],
    );
  }

  /// `New Project`
  String get createNewProject {
    return Intl.message(
      'New Project',
      name: 'createNewProject',
      desc: '',
      args: [],
    );
  }

  /// `Add`
  String get add {
    return Intl.message('Add', name: 'add', desc: '', args: []);
  }

  /// `Please enter a local file path or a valid YouTube link`
  String get audioPathInvalidHint {
    return Intl.message(
      'Please enter a local file path or a valid YouTube link',
      name: 'audioPathInvalidHint',
      desc: '',
      args: [],
    );
  }

  /// `Failed to load`
  String get failedToLoad {
    return Intl.message(
      'Failed to load',
      name: 'failedToLoad',
      desc: '',
      args: [],
    );
  }

  /// `No projects`
  String get noProject {
    return Intl.message('No projects', name: 'noProject', desc: '', args: []);
  }

  /// `Deleted {project}`
  String projectDeletedHint(String project) {
    return Intl.message(
      'Deleted $project',
      name: 'projectDeletedHint',
      desc: '',
      args: [project],
    );
  }

  /// `Undo`
  String get undo {
    return Intl.message('Undo', name: 'undo', desc: '', args: []);
  }

  /// `Add Track`
  String get addAudio {
    return Intl.message('Add Track', name: 'addAudio', desc: '', args: []);
  }

  /// `My Library`
  String get myLibrary {
    return Intl.message('My Library', name: 'myLibrary', desc: '', args: []);
  }

  /// `Continue`
  String get continuePracticing {
    return Intl.message(
      'Continue',
      name: 'continuePracticing',
      desc: '',
      args: [],
    );
  }

  /// `Regenerate Subtitles`
  String get regenerateSubtitle {
    return Intl.message(
      'Regenerate Subtitles',
      name: 'regenerateSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Mix Table`
  String get mixTable {
    return Intl.message('Mix Table', name: 'mixTable', desc: '', args: []);
  }

  /// `Edit lyric`
  String get editLyric {
    return Intl.message('Edit lyric', name: 'editLyric', desc: '', args: []);
  }

  /// `Edit translate lyric`
  String get editTranslateLyric {
    return Intl.message(
      'Edit translate lyric',
      name: 'editTranslateLyric',
      desc: '',
      args: [],
    );
  }

  /// `Edit metadata`
  String get editMetadata {
    return Intl.message(
      'Edit metadata',
      name: 'editMetadata',
      desc: '',
      args: [],
    );
  }

  /// `Title`
  String get title {
    return Intl.message('Title', name: 'title', desc: '', args: []);
  }

  /// `Album`
  String get album {
    return Intl.message('Album', name: 'album', desc: '', args: []);
  }

  /// `Artist`
  String get artist {
    return Intl.message('Artist', name: 'artist', desc: '', args: []);
  }

  /// `Save`
  String get save {
    return Intl.message('Save', name: 'save', desc: '', args: []);
  }

  /// `Search Title, Artist or Album...`
  String get searchTitleArtistOrAlbum {
    return Intl.message(
      'Search Title, Artist or Album...',
      name: 'searchTitleArtistOrAlbum',
      desc: '',
      args: [],
    );
  }

  /// `Discard changes?`
  String get discardChanges {
    return Intl.message(
      'Discard changes?',
      name: 'discardChanges',
      desc: '',
      args: [],
    );
  }

  /// `Metadata will be restored to the state before modification.`
  String get metadataWillBeRestoredToTheStateBeforeModification {
    return Intl.message(
      'Metadata will be restored to the state before modification.',
      name: 'metadataWillBeRestoredToTheStateBeforeModification',
      desc: '',
      args: [],
    );
  }

  /// `Discard`
  String get discard {
    return Intl.message('Discard', name: 'discard', desc: '', args: []);
  }

  /// `Image file`
  String get imageFile {
    return Intl.message('Image file', name: 'imageFile', desc: '', args: []);
  }

  /// `No media information found`
  String get noMediaInformationFound {
    return Intl.message(
      'No media information found',
      name: 'noMediaInformationFound',
      desc: '',
      args: [],
    );
  }

  /// `Show License`
  String get showLicense {
    return Intl.message(
      'Show License',
      name: 'showLicense',
      desc: '',
      args: [],
    );
  }

  /// `Tools`
  String get tools {
    return Intl.message('Tools', name: 'tools', desc: '', args: []);
  }

  /// `General`
  String get general {
    return Intl.message('General', name: 'general', desc: '', args: []);
  }

  /// `Using {usingLocal, select, true{local} false{system} other{unknown}} yt-dlp, version {version}`
  String ytDlpInfo(String usingLocal, String version) {
    return Intl.message(
      'Using ${Intl.select(usingLocal, {'true': 'local', 'false': 'system', 'other': 'unknown'})} yt-dlp, version $version',
      name: 'ytDlpInfo',
      desc: '',
      args: [usingLocal, version],
    );
  }

  /// `Upgrading...`
  String get upgrading {
    return Intl.message('Upgrading...', name: 'upgrading', desc: '', args: []);
  }

  /// `Upgrade`
  String get upgrade {
    return Intl.message('Upgrade', name: 'upgrade', desc: '', args: []);
  }

  /// `Try updating your version if YouTube audio downloads fail.`
  String get ytDlpUpgradingHint {
    return Intl.message(
      'Try updating your version if YouTube audio downloads fail.',
      name: 'ytDlpUpgradingHint',
      desc: '',
      args: [],
    );
  }

  /// `Extra args`
  String get extraArgs {
    return Intl.message('Extra args', name: 'extraArgs', desc: '', args: []);
  }

  /// `Separate with space`
  String get separateWithSpace {
    return Intl.message(
      'Separate with space',
      name: 'separateWithSpace',
      desc: '',
      args: [],
    );
  }

  /// `Used to download audio from YouTube`
  String get ytDlpUseHint {
    return Intl.message(
      'Used to download audio from YouTube',
      name: 'ytDlpUseHint',
      desc: '',
      args: [],
    );
  }

  /// `Downloading...`
  String get downloading {
    return Intl.message(
      'Downloading...',
      name: 'downloading',
      desc: '',
      args: [],
    );
  }

  /// `Download`
  String get download {
    return Intl.message('Download', name: 'download', desc: '', args: []);
  }

  /// `No executable found.`
  String get noExecutableFound {
    return Intl.message(
      'No executable found.',
      name: 'noExecutableFound',
      desc: '',
      args: [],
    );
  }

  /// `Open project directory`
  String get openProjectDirectory {
    return Intl.message(
      'Open project directory',
      name: 'openProjectDirectory',
      desc: '',
      args: [],
    );
  }

  /// `Expert Mode`
  String get expertMode {
    return Intl.message('Expert Mode', name: 'expertMode', desc: '', args: []);
  }

  /// `Locate songs by waveform and allow playback from a fixed position.`
  String get expertModeHint {
    return Intl.message(
      'Locate songs by waveform and allow playback from a fixed position.',
      name: 'expertModeHint',
      desc: '',
      args: [],
    );
  }

  /// `(Modified)`
  String get modified {
    return Intl.message('(Modified)', name: 'modified', desc: '', args: []);
  }

  /// `Proofread`
  String get proofread {
    return Intl.message('Proofread', name: 'proofread', desc: '', args: []);
  }

  /// `The LRC lyrics will be calibrated and supplemented according to the provided lyric text.`
  String get proofreadHint {
    return Intl.message(
      'The LRC lyrics will be calibrated and supplemented according to the provided lyric text.',
      name: 'proofreadHint',
      desc: '',
      args: [],
    );
  }

  /// `Paste lyrics here`
  String get pasteLyricsHere {
    return Intl.message(
      'Paste lyrics here',
      name: 'pasteLyricsHere',
      desc: '',
      args: [],
    );
  }

  /// `Proofreading...`
  String get proofreading {
    return Intl.message(
      'Proofreading...',
      name: 'proofreading',
      desc: '',
      args: [],
    );
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<S> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
      Locale.fromSubtags(languageCode: 'en'),
      Locale.fromSubtags(languageCode: 'zh', countryCode: 'CN'),
    ];
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale);
  @override
  Future<S> load(Locale locale) => S.load(locale);
  @override
  bool shouldReload(AppLocalizationDelegate old) => false;

  bool _isSupported(Locale locale) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }
}
