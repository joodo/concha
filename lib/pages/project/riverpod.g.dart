// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'riverpod.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(playController)
final playControllerProvider = PlayControllerFamily._();

final class PlayControllerProvider
    extends
        $FunctionalProvider<
          AsyncValue<PlayController>,
          PlayController,
          FutureOr<PlayController>
        >
    with $FutureModifier<PlayController>, $FutureProvider<PlayController> {
  PlayControllerProvider._({
    required PlayControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'playControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$playControllerHash();

  @override
  String toString() {
    return r'playControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<PlayController> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<PlayController> create(Ref ref) {
    final argument = this.argument as String;
    return playController(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PlayControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$playControllerHash() => r'953f6b483b136844c955bc2aae092bfe803a51c4';

final class PlayControllerFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<PlayController>, String> {
  PlayControllerFamily._()
    : super(
        retry: null,
        name: r'playControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  PlayControllerProvider call(String id) =>
      PlayControllerProvider._(argument: id, from: this);

  @override
  String toString() => r'playControllerProvider';
}

@ProviderFor(waveformController)
final waveformControllerProvider = WaveformControllerProvider._();

final class WaveformControllerProvider
    extends
        $FunctionalProvider<
          Raw<WaveformController>,
          Raw<WaveformController>,
          Raw<WaveformController>
        >
    with $Provider<Raw<WaveformController>> {
  WaveformControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'waveformControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$waveformControllerHash();

  @$internal
  @override
  $ProviderElement<Raw<WaveformController>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Raw<WaveformController> create(Ref ref) {
    return waveformController(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Raw<WaveformController> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Raw<WaveformController>>(value),
    );
  }
}

String _$waveformControllerHash() =>
    r'04f989eb28dac4dff081956127acea2ae452b09a';

@ProviderFor(LyricController)
final lyricControllerProvider = LyricControllerFamily._();

final class LyricControllerProvider
    extends $AsyncNotifierProvider<LyricController, fl.LyricController> {
  LyricControllerProvider._({
    required LyricControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'lyricControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$lyricControllerHash();

  @override
  String toString() {
    return r'lyricControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  LyricController create() => LyricController();

  @override
  bool operator ==(Object other) {
    return other is LyricControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$lyricControllerHash() => r'95125b9fbf723148ef475b9e5d84b77bf74b9cdd';

final class LyricControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          LyricController,
          AsyncValue<fl.LyricController>,
          fl.LyricController,
          FutureOr<fl.LyricController>,
          String
        > {
  LyricControllerFamily._()
    : super(
        retry: null,
        name: r'lyricControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  LyricControllerProvider call(String id) =>
      LyricControllerProvider._(argument: id, from: this);

  @override
  String toString() => r'lyricControllerProvider';
}

abstract class _$LyricController extends $AsyncNotifier<fl.LyricController> {
  late final _$args = ref.$arg as String;
  String get id => _$args;

  FutureOr<fl.LyricController> build(String id);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<fl.LyricController>, fl.LyricController>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<fl.LyricController>, fl.LyricController>,
              AsyncValue<fl.LyricController>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}

@ProviderFor(sepAudioEvent)
final sepAudioEventProvider = SepAudioEventFamily._();

final class SepAudioEventProvider
    extends
        $FunctionalProvider<
          AsyncValue<MvsepTaskEvent>,
          MvsepTaskEvent,
          Stream<MvsepTaskEvent>
        >
    with $FutureModifier<MvsepTaskEvent>, $StreamProvider<MvsepTaskEvent> {
  SepAudioEventProvider._({
    required SepAudioEventFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'sepAudioEventProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$sepAudioEventHash();

  @override
  String toString() {
    return r'sepAudioEventProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<MvsepTaskEvent> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<MvsepTaskEvent> create(Ref ref) {
    final argument = this.argument as String;
    return sepAudioEvent(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is SepAudioEventProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$sepAudioEventHash() => r'a4347f5ebdd79a0dd7b112623ba6941f97abc9c7';

final class SepAudioEventFamily extends $Family
    with $FunctionalFamilyOverride<Stream<MvsepTaskEvent>, String> {
  SepAudioEventFamily._()
    : super(
        retry: null,
        name: r'sepAudioEventProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SepAudioEventProvider call(String id) =>
      SepAudioEventProvider._(argument: id, from: this);

  @override
  String toString() => r'sepAudioEventProvider';
}

@ProviderFor(ReadAloudPending)
final readAloudPendingProvider = ReadAloudPendingProvider._();

final class ReadAloudPendingProvider
    extends $NotifierProvider<ReadAloudPending, bool> {
  ReadAloudPendingProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'readAloudPendingProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$readAloudPendingHash();

  @$internal
  @override
  ReadAloudPending create() => ReadAloudPending();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$readAloudPendingHash() => r'237c49fcea8d603e4dd8fd5a1e4cef63c6262575';

abstract class _$ReadAloudPending extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(AttachToLyric)
final attachToLyricProvider = AttachToLyricProvider._();

final class AttachToLyricProvider
    extends $NotifierProvider<AttachToLyric, bool> {
  AttachToLyricProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'attachToLyricProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$attachToLyricHash();

  @$internal
  @override
  AttachToLyric create() => AttachToLyric();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$attachToLyricHash() => r'7776b2bd1b3f83997347bae9511a9288bd0f13c1';

abstract class _$AttachToLyric extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(Loop)
final loopProvider = LoopProvider._();

final class LoopProvider extends $NotifierProvider<Loop, bool> {
  LoopProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'loopProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$loopHash();

  @$internal
  @override
  Loop create() => Loop();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$loopHash() => r'16f68d24d18f1866de32ed4d780a876dcd9d2630';

abstract class _$Loop extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
