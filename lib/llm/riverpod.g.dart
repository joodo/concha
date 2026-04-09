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

@ProviderFor(WordForWord)
@JsonPersist()
final wordForWordProvider = WordForWordFamily._();

@JsonPersist()
final class WordForWordProvider
    extends $AsyncNotifierProvider<WordForWord, TranslationResult> {
  WordForWordProvider._({
    required WordForWordFamily super.from,
    required String super.argument,
  }) : super(
         retry: disableRetry,
         name: r'wordForWordProvider',
         isAutoDispose: true,
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
  WordForWord create() => WordForWord();

  @override
  bool operator ==(Object other) {
    return other is WordForWordProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$wordForWordHash() => r'275f3d03b080461f90c722d52c62a7dd37652f8d';

@JsonPersist()
final class WordForWordFamily extends $Family
    with
        $ClassFamilyOverride<
          WordForWord,
          AsyncValue<TranslationResult>,
          TranslationResult,
          FutureOr<TranslationResult>,
          String
        > {
  WordForWordFamily._()
    : super(
        retry: disableRetry,
        name: r'wordForWordProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  @JsonPersist()
  WordForWordProvider call(String sentence) =>
      WordForWordProvider._(argument: sentence, from: this);

  @override
  String toString() => r'wordForWordProvider';
}

@JsonPersist()
abstract class _$WordForWordBase extends $AsyncNotifier<TranslationResult> {
  late final _$args = ref.$arg as String;
  String get sentence => _$args;

  FutureOr<TranslationResult> build(String sentence);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<TranslationResult>, TranslationResult>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<TranslationResult>, TranslationResult>,
              AsyncValue<TranslationResult>,
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
abstract class _$WordForWord extends _$WordForWordBase {
  /// The default key used by [persist].
  String get key {
    late final args = sentence;
    late final resolvedKey = 'WordForWord($args)';

    return resolvedKey;
  }

  /// A variant of [persist], for JSON-specific encoding.
  ///
  /// You can override [key] to customize the key used for storage.
  PersistResult persist(
    FutureOr<Storage<String, String>> storage, {
    String? key,
    String Function(TranslationResult state)? encode,
    TranslationResult Function(String encoded)? decode,
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
            return TranslationResult.fromJson(e as Map<String, Object?>);
          },
      options: options,
    );
  }
}
