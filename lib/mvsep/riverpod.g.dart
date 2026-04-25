// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'riverpod.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SeparateJob)
@JsonPersist()
final separateJobProvider = SeparateJobFamily._();

@JsonPersist()
final class SeparateJobProvider
    extends $AsyncNotifierProvider<SeparateJob, MvsepJob> {
  SeparateJobProvider._({
    required SeparateJobFamily super.from,
    required String super.argument,
  }) : super(
         retry: _separateJobCreatingRetry,
         name: r'separateJobProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$separateJobHash();

  @override
  String toString() {
    return r'separateJobProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  SeparateJob create() => SeparateJob();

  @override
  bool operator ==(Object other) {
    return other is SeparateJobProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$separateJobHash() => r'0c944cd633e960b3855f0237bad9ddde74f1c653';

@JsonPersist()
final class SeparateJobFamily extends $Family
    with
        $ClassFamilyOverride<
          SeparateJob,
          AsyncValue<MvsepJob>,
          MvsepJob,
          FutureOr<MvsepJob>,
          String
        > {
  SeparateJobFamily._()
    : super(
        retry: _separateJobCreatingRetry,
        name: r'separateJobProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  @JsonPersist()
  SeparateJobProvider call(String audioPath) =>
      SeparateJobProvider._(argument: audioPath, from: this);

  @override
  String toString() => r'separateJobProvider';
}

@JsonPersist()
abstract class _$SeparateJobBase extends $AsyncNotifier<MvsepJob> {
  late final _$args = ref.$arg as String;
  String get audioPath => _$args;

  FutureOr<MvsepJob> build(String audioPath);
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
    element.handleCreate(ref, () => build(_$args));
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
         retry: _separatePathFetchingRetry,
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

String _$separationPathHash() => r'19c9d337540cd47ef5f7babd6494a99303ebc268';

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
        retry: _separatePathFetchingRetry,
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

// **************************************************************************
// JsonGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
abstract class _$SeparateJob extends _$SeparateJobBase {
  /// The default key used by [persist].
  String get key {
    late final args = audioPath;
    late final resolvedKey = 'SeparateJob($args)';

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
