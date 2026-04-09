import 'dart:convert';

import 'package:llm_dart/llm_dart.dart';

import '/preferences/preferences.dart';
import '/utils/utils.dart';

import 'service.dart';

class LlmServiceImpl implements LlmService {
  LlmServiceImpl.fromPref()
    : apiKey = Pref.get(.llmKey)!,
      service = Pref.get(.llmService),
      model = Pref.get(.llmModel),
      url = Pref.get(.llmUrl),
      proxy = Pref.get(.proxy);

  LlmServiceImpl({
    required this.apiKey,
    required this.service,
    required this.model,
    this.url,
    this.proxy,
  });

  final String apiKey;
  final String service;
  final String model;
  final String? url;
  final String? proxy;

  late final _builder = ai()
      .provider(service)
      .applyIf(url?.isNotEmpty == true, (self) => self.baseUrl(url!))
      .apiKey(apiKey)
      .model(model)
      .applyIf(
        proxy?.isNotEmpty == true,
        (self) => self.http((config) => config.proxy(proxy!)),
      );

  @override
  Future<void> test() async {
    final provider = await _builder.maxTokens(1).build();
    await provider.chat([ChatMessage.user('Hello')]);
  }

  @override
  Future<String> generate(String prompt, {String? systemPrompt}) async {
    final provider = await _builder
        .applyIf(
          systemPrompt?.isNotEmpty == true,
          (self) => self.systemPrompt(systemPrompt!),
        )
        .build();

    final response = await provider.chat([ChatMessage.user(prompt)]);
    return response.text ?? '';
  }

  @override
  Future<JsonMap> generateJson(
    String prompt, {
    required JsonMap format,
    String? systemPrompt,
  }) async {
    final provider = await _builder
        .applyIf(
          systemPrompt?.isNotEmpty == true,
          (self) => self.systemPrompt(systemPrompt!),
        )
        .responseFormat('json_schema')
        .jsonSchema(StructuredOutputFormat.fromJson(format))
        .build();

    final response = await provider.chat([ChatMessage.user(prompt)]);
    final content = response.text!;
    return jsonDecode(content);
  }
}
