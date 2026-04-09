// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'riverpod.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(TextVoice)
final textVoiceProvider = TextVoiceFamily._();

final class TextVoiceProvider
    extends $AsyncNotifierProvider<TextVoice, Uint8List> {
  TextVoiceProvider._({
    required TextVoiceFamily super.from,
    required String super.argument,
  }) : super(
         retry: disableRetry,
         name: r'textVoiceProvider',
         isAutoDispose: true,
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
  TextVoice create() => TextVoice();

  @override
  bool operator ==(Object other) {
    return other is TextVoiceProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$textVoiceHash() => r'210555460aef7adcfd64d9242f37e11e893da979';

final class TextVoiceFamily extends $Family
    with
        $ClassFamilyOverride<
          TextVoice,
          AsyncValue<Uint8List>,
          Uint8List,
          FutureOr<Uint8List>,
          String
        > {
  TextVoiceFamily._()
    : super(
        retry: disableRetry,
        name: r'textVoiceProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  TextVoiceProvider call(String text) =>
      TextVoiceProvider._(argument: text, from: this);

  @override
  String toString() => r'textVoiceProvider';
}

abstract class _$TextVoice extends $AsyncNotifier<Uint8List> {
  late final _$args = ref.$arg as String;
  String get text => _$args;

  FutureOr<Uint8List> build(String text);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<Uint8List>, Uint8List>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Uint8List>, Uint8List>,
              AsyncValue<Uint8List>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
