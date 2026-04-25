// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'riverpod.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(MvsepJobNotifier)
@JsonPersist()
final mvsepJobProvider = MvsepJobNotifierFamily._();

@JsonPersist()
final class MvsepJobNotifierProvider
    extends $AsyncNotifierProvider<MvsepJobNotifier, MvsepJob> {
  MvsepJobNotifierProvider._({
    required MvsepJobNotifierFamily super.from,
    required (String, MvsepOperation) super.argument,
  }) : super(
         retry: _separateJobCreatingRetry,
         name: r'mvsepJobProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$mvsepJobNotifierHash();

  @override
  String toString() {
    return r'mvsepJobProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  MvsepJobNotifier create() => MvsepJobNotifier();

  @override
  bool operator ==(Object other) {
    return other is MvsepJobNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$mvsepJobNotifierHash() => r'de423419ed83b9f1450082ae45fc1a0908a12a29';

@JsonPersist()
final class MvsepJobNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          MvsepJobNotifier,
          AsyncValue<MvsepJob>,
          MvsepJob,
          FutureOr<MvsepJob>,
          (String, MvsepOperation)
        > {
  MvsepJobNotifierFamily._()
    : super(
        retry: _separateJobCreatingRetry,
        name: r'mvsepJobProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  @JsonPersist()
  MvsepJobNotifierProvider call(String audioPath, MvsepOperation operation) =>
      MvsepJobNotifierProvider._(argument: (audioPath, operation), from: this);

  @override
  String toString() => r'mvsepJobProvider';
}

@JsonPersist()
abstract class _$MvsepJobNotifierBase extends $AsyncNotifier<MvsepJob> {
  late final _$args = ref.$arg as (String, MvsepOperation);
  String get audioPath => _$args.$1;
  MvsepOperation get operation => _$args.$2;

  FutureOr<MvsepJob> build(String audioPath, MvsepOperation operation);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<MvsepJob>, MvsepJob>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<MvsepJob>, MvsepJob>,
              AsyncValue<MvsepJob>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args.$1, _$args.$2));
  }
}

@ProviderFor(SeparationPath)
final separationPathProvider = SeparationPathFamily._();

final class SeparationPathProvider
    extends
        $AsyncNotifierProvider<
          SeparationPath,
          ({String instrument, String vocal})
        > {
  SeparationPathProvider._({
    required SeparationPathFamily super.from,
    required String super.argument,
  }) : super(
         retry: _autoRecreateJobRetry,
         name: r'separationPathProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$separationPathHash();

  @override
  String toString() {
    return r'separationPathProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  SeparationPath create() => SeparationPath();

  @override
  bool operator ==(Object other) {
    return other is SeparationPathProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$separationPathHash() => r'e5908ea26dfd0a58e26572749e2671d3a0aa1181';

final class SeparationPathFamily extends $Family
    with
        $ClassFamilyOverride<
          SeparationPath,
          AsyncValue<({String instrument, String vocal})>,
          ({String instrument, String vocal}),
          FutureOr<({String instrument, String vocal})>,
          String
        > {
  SeparationPathFamily._()
    : super(
        retry: _autoRecreateJobRetry,
        name: r'separationPathProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SeparationPathProvider call(String id) =>
      SeparationPathProvider._(argument: id, from: this);

  @override
  String toString() => r'separationPathProvider';
}

abstract class _$SeparationPath
    extends $AsyncNotifier<({String instrument, String vocal})> {
  late final _$args = ref.$arg as String;
  String get id => _$args;

  FutureOr<({String instrument, String vocal})> build(String id);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<({String instrument, String vocal})>,
              ({String instrument, String vocal})
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<({String instrument, String vocal})>,
                ({String instrument, String vocal})
              >,
              AsyncValue<({String instrument, String vocal})>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}

@ProviderFor(TranscribedLyric)
final transcribedLyricProvider = TranscribedLyricFamily._();

final class TranscribedLyricProvider
    extends $AsyncNotifierProvider<TranscribedLyric, String> {
  TranscribedLyricProvider._({
    required TranscribedLyricFamily super.from,
    required String super.argument,
  }) : super(
         retry: _autoRecreateJobRetry,
         name: r'transcribedLyricProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$transcribedLyricHash();

  @override
  String toString() {
    return r'transcribedLyricProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  TranscribedLyric create() => TranscribedLyric();

  @override
  bool operator ==(Object other) {
    return other is TranscribedLyricProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$transcribedLyricHash() => r'8767688b131a49c7fc4088aa8de5fafae0818f14';

final class TranscribedLyricFamily extends $Family
    with
        $ClassFamilyOverride<
          TranscribedLyric,
          AsyncValue<String>,
          String,
          FutureOr<String>,
          String
        > {
  TranscribedLyricFamily._()
    : super(
        retry: _autoRecreateJobRetry,
        name: r'transcribedLyricProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  TranscribedLyricProvider call(String id) =>
      TranscribedLyricProvider._(argument: id, from: this);

  @override
  String toString() => r'transcribedLyricProvider';
}

abstract class _$TranscribedLyric extends $AsyncNotifier<String> {
  late final _$args = ref.$arg as String;
  String get id => _$args;

  FutureOr<String> build(String id);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<String>, String>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<String>, String>,
              AsyncValue<String>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}

// **************************************************************************
// JsonGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
abstract class _$MvsepJobNotifier extends _$MvsepJobNotifierBase {
  /// The default key used by [persist].
  String get key {
    late final args = (audioPath, operation);
    late final resolvedKey = 'MvsepJobNotifier($args)';

    return resolvedKey;
  }

  /// A variant of [persist], for JSON-specific encoding.
  ///
  /// You can override [key] to customize the key used for storage.
  PersistResult persist(
    FutureOr<Storage<String, String>> storage, {
    String? key,
    String Function(MvsepJob state)? encode,
    MvsepJob Function(String encoded)? decode,
    StorageOptions options = const StorageOptions(),
  }) {
    return NotifierPersistX(this).persist<String, String>(
      storage,
      key: key ?? this.key,
      encode: encode ?? $jsonCodex.encode,
      decode:
          decode ??
          (encoded) {
            final e = $jsonCodex.decode(encoded);
            return MvsepJob.fromJson(e as Map<String, Object?>);
          },
      options: options,
    );
  }
}
