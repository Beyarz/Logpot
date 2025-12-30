import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

import 'config.dart';

class Hallucinate {
  late final String _model;
  late final String _systemPrompt;
  final Logger? _logger;

  Hallucinate({
    required String model,
    required String systemPrompt,
    Logger? logger,
  }) : _model = model,
       _systemPrompt = systemPrompt,
       _logger = logger;

  Future<String?> generate(String userPrompt) async {
    Uri endpoint = Uri.parse(openaiEndpoint);

    Map<String, String> headers = {
      'Authorization': 'Bearer $openaiApikey',
      'Content-Type': 'application/json',
    };

    Map<String, dynamic> body = {
      "model": _model,
      "max_tokens": 512,
      "temperature": 0.7,
      "top_p": 0.8,
      "stream": false,
      "messages": [
        {"role": "system", "content": _systemPrompt},
        {"role": "user", "content": userPrompt},
      ],
    };

    try {
      final response = await http.post(
        endpoint,
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode != 200) {
        _logger?.warning(
          'Hallucinate API returned status ${response.statusCode}: ${response.body}',
        );

        return null;
      }

      final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

      if (jsonResponse['choices'] != null &&
          jsonResponse['choices'] is List &&
          jsonResponse['choices'].isNotEmpty) {
        final firstChoice = jsonResponse['choices'][0];

        if (firstChoice['message'] != null &&
            firstChoice['message']['content'] != null) {
          final content = firstChoice['message']['content'] as String;
          _logger?.info('Generated hallucinated content for: $userPrompt');
          return content;
        }
      }

      _logger?.warning('Unexpected response structure: $jsonResponse');
      return null;
    } catch (e, stackTrace) {
      _logger?.severe('Failed to generate hallucination: $e', e, stackTrace);
      return null;
    }
  }
}
