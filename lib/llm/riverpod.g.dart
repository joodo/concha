// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'riverpod.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TranslationResult _$TranslationResultFromJson(Map<String, dynamic> json) =>
    TranslationResult(
      sourceLang: json['source_lang'] as String,
      sentence: json['sentence'] as String,
      translate: json['translate'] as String,
      detail: (json['detail'] as List<dynamic>)
          .map((e) => TranslationDetail.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$TranslationResultToJson(TranslationResult instance) =>
    <String, dynamic>{
      'source_lang': instance.sourceLang,
      'sentence': instance.sentence,
      'translate': instance.translate,
      'detail': instance.detail,
    };

TranslationDetail _$TranslationDetailFromJson(Map<String, dynamic> json) =>
    TranslationDetail(
      word: json['word'] as String,
      translate: json['translate'] as String,
      explanation: json['explanation'] as String?,
    );

Map<String, dynamic> _$TranslationDetailToJson(TranslationDetail instance) =>
    <String, dynamic>{
      'word': instance.word,
      'translate': instance.translate,
      'explanation': instance.explanation,
    };

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(wordForWord)
final wordForWordProvider = WordForWordFamily._();

final class WordForWordProvider
    extends
        $FunctionalProvider<
          AsyncValue<TranslationResult>,
          TranslationResult,
          FutureOr<TranslationResult>
        >
    with
        $FutureModifier<TranslationResult>,
        $FutureProvider<TranslationResult> {
  WordForWordProvider._({
    required WordForWordFamily super.from,
    required String super.argument,
  }) : super(
         retry: disableRetry,
         name: r'wordForWordProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$wordForWordHash();

  @override
  String toString() {
    return r'wordForWordProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<TranslationResult> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<TranslationResult> create(Ref ref) {
    final argument = this.argument as String;
    return wordForWord(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is WordForWordProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$wordForWordHash() => r'055b99cbb7b20d005753d79a3724789c9c1c7a15';

final class WordForWordFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<TranslationResult>, String> {
  WordForWordFamily._()
    : super(
        retry: disableRetry,
        name: r'wordForWordProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  WordForWordProvider call(String sentence) =>
      WordForWordProvider._(argument: sentence, from: this);

  @override
  String toString() => r'wordForWordProvider';
}
