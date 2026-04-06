import '/utils/utils.dart';

abstract class LlmService {
  Future<String> generate(
    String prompt, {
    dynamic apiKey,
    String? systemPrompt,
    String? proxy,
  });

  Future<JsonMap> generateJson(
    String prompt, {
    required JsonMap format,
    dynamic apiKey,
    String? systemPrompt,
    String? proxy,
  });
}
