// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'riverpod.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(textVoice)
final textVoiceProvider = TextVoiceFamily._();

final class TextVoiceProvider
    extends
        $FunctionalProvider<
          AsyncValue<Uint8List>,
          Uint8List,
          FutureOr<Uint8List>
        >
    with $FutureModifier<Uint8List>, $FutureProvider<Uint8List> {
  TextVoiceProvider._({
    required TextVoiceFamily super.from,
    required String super.argument,
  }) : super(
         retry: noRetry,
         name: r'textVoiceProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$textVoiceHash();

  @override
  String toString() {
    return r'textVoiceProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Uint8List> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Uint8List> create(Ref ref) {
    final argument = this.argument as String;
    return textVoice(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TextVoiceProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$textVoiceHash() => r'8a3339b2290d06f7bdafd5bc7238a265a0f644ff';

final class TextVoiceFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Uint8List>, String> {
  TextVoiceFamily._()
    : super(
        retry: noRetry,
        name: r'textVoiceProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  TextVoiceProvider call(String text) =>
      TextVoiceProvider._(argument: text, from: this);

  @override
  String toString() => r'textVoiceProvider';
}
