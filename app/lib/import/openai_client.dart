/// Minimal OpenAI Chat Completions client with JSON-schema structured output.
/// The API key never leaves the device except in this request.
library;

import 'dart:convert';

import 'package:http/http.dart' as http;

class OpenAiException implements Exception {
  OpenAiException(this.message, {this.status});
  final String message;
  final int? status;
  @override
  String toString() => message;
}

class OpenAiClient {
  OpenAiClient({required this.apiKey, required this.model, http.Client? http_, this.baseUrl = 'https://api.openai.com/v1'})
      : _http = http_ ?? http.Client();

  final String apiKey;
  final String model;
  final String baseUrl;
  final http.Client _http;

  /// Returns the parsed JSON object the model produced for [schema].
  Future<Map<String, dynamic>> completeJson({
    required String system,
    required String user,
    required Map<String, dynamic> schema,
    String schemaName = 'result',
    double temperature = 0,
  }) async {
    final body = {
      'model': model,
      'temperature': temperature,
      'messages': [
        {'role': 'system', 'content': system},
        {'role': 'user', 'content': user},
      ],
      'response_format': {
        'type': 'json_schema',
        'json_schema': {'name': schemaName, 'strict': true, 'schema': schema},
      },
    };
    final http.Response res;
    try {
      res = await _http
          .post(
            Uri.parse('$baseUrl/chat/completions'),
            headers: {'Authorization': 'Bearer $apiKey', 'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 120));
    } catch (e) {
      throw OpenAiException('OpenAI request failed: $e');
    }
    if (res.statusCode != 200) {
      String detail = res.body;
      try {
        detail = (jsonDecode(res.body)['error']['message'] as String?) ?? res.body;
      } catch (_) {}
      throw OpenAiException('OpenAI ${res.statusCode}: $detail', status: res.statusCode);
    }
    final json = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final choices = json['choices'] as List<dynamic>?;
    if (choices == null || choices.isEmpty) throw OpenAiException('OpenAI returned no choices');
    final message = choices.first['message'] as Map<String, dynamic>;
    if (message['refusal'] != null) throw OpenAiException('OpenAI refused: ${message['refusal']}');
    final content = message['content'];
    if (content is! String) throw OpenAiException('OpenAI returned no content');
    try {
      return jsonDecode(content) as Map<String, dynamic>;
    } catch (e) {
      throw OpenAiException('OpenAI returned invalid JSON: $e');
    }
  }
}
