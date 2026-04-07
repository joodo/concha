// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'riverpod.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

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

String _$sepAudioEventHash() => r'b939ef5f6dfb15eda18804f62abd794572054290';

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
