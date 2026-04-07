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
