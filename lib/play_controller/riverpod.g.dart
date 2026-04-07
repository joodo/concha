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
