// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'riverpod.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

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

String _$lyricControllerHash() => r'd6821f251c9828ae76af9d956799bc2a2c526107';

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

@ProviderFor(Lyric)
final lyricProvider = LyricFamily._();

final class LyricProvider extends $AsyncNotifierProvider<Lyric, String?> {
  LyricProvider._({
    required LyricFamily super.from,
    required (String, {bool isTranslate}) super.argument,
  }) : super(
         retry: null,
         name: r'lyricProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$lyricHash();

  @override
  String toString() {
    return r'lyricProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  Lyric create() => Lyric();

  @override
  bool operator ==(Object other) {
    return other is LyricProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$lyricHash() => r'6d47e175d1814275a1e86ef6734b9b2efe0a99a6';

final class LyricFamily extends $Family
    with
        $ClassFamilyOverride<
          Lyric,
          AsyncValue<String?>,
          String?,
          FutureOr<String?>,
          (String, {bool isTranslate})
        > {
  LyricFamily._()
    : super(
        retry: null,
        name: r'lyricProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  LyricProvider call(String id, {required bool isTranslate}) =>
      LyricProvider._(argument: (id, isTranslate: isTranslate), from: this);

  @override
  String toString() => r'lyricProvider';
}

abstract class _$Lyric extends $AsyncNotifier<String?> {
  late final _$args = ref.$arg as (String, {bool isTranslate});
  String get id => _$args.$1;
  bool get isTranslate => _$args.isTranslate;

  FutureOr<String?> build(String id, {required bool isTranslate});
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<String?>, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<String?>, String?>,
              AsyncValue<String?>,
              Object?,
              Object?
            >;
    element.handleCreate(
      ref,
      () => build(_$args.$1, isTranslate: _$args.isTranslate),
    );
  }
}
