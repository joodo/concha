import 'package:flutter_riverpod/experimental/persist.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:riverpod_annotation/experimental/json_persist.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '/persistence/persistence.dart';
import '/preferences/preferences.dart';
import '/utils/utils.dart';

import 'word_for_word.dart';

part 'riverpod.g.dart';

@JsonSerializable()
class TranslationResult {
  @JsonKey(name: 'source_lang')
  final String sourceLang;

  final String sentence;
  final String translate;
  final List<TranslationDetail> detail;

  TranslationResult({
    required this.sourceLang,
    required this.sentence,
    required this.translate,
    required this.detail,
  });

  factory TranslationResult.fromJson(Map<String, dynamic> json) =>
      _$TranslationResultFromJson(json);

  Map<String, dynamic> toJson() => _$TranslationResultToJson(this);
}

@JsonSerializable()
class TranslationDetail {
  final String word;
  final String translate;
  final String? explanation;

  TranslationDetail({
    required this.word,
    required this.translate,
    this.explanation,
  });

  factory TranslationDetail.fromJson(Map<String, dynamic> json) =>
      _$TranslationDetailFromJson(json);

  Map<String, dynamic> toJson() => _$TranslationDetailToJson(this);
}

@riverpod
@JsonPersist()
class WordForWord extends _$WordForWord with LoadPersistOrFetch {
  @override
  Future<TranslationResult> build(String sentence) async {
    return loadPersistOrFetch(
      persist: persist(
        ref.watch(persistStorageProvider.future),
        options: const StorageOptions(
          cacheTime: StorageCacheTime.unsafe_forever,
        ),
      ),
      fetch: _fetch,
    );
  }

  Future<TranslationResult> _fetch() async {
    final json = await createSentenceTranslation(
      sentence,
      ref.read(translateLangProvider),
    );
    final result = TranslationResult.fromJson(json);
    return result;
  }
}
