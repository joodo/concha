import '/utils/utils.dart';

import 'service.impl.dart';

abstract class LlmService {
  factory LlmService.fromPref() = LlmServiceImpl.fromPref;

  Future<String> generate(String prompt, {String? systemPrompt});
  Future<JsonMap> generateJson(
    String prompt, {
    required JsonMap format,
    String? systemPrompt,
  });
  Future<void> test();
}
