import 'package:json_annotation/json_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

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

@Riverpod(keepAlive: true, retry: disableRetry)
Future<TranslationResult> wordForWord(Ref ref, String sentence) async {
  try {
    final json = await createWordTranslation(sentence);
    return TranslationResult.fromJson(json);
  } catch (e) {
    Future.microtask(ref.invalidateSelf);
    rethrow;
  }
}
