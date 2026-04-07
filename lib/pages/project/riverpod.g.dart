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

String _$playControllerHash() => r'44b998866de4dabc090b9d923f6572356799a6d7';

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

String _$lyricControllerHash() => r'2c435ea63e6f8c7dc898856f2ffc8f04429106b2';

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
