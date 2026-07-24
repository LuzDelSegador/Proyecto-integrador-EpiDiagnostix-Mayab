import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

const String _kGroqEndpoint = 'https://api.groq.com/openai/v1/chat/completions';
const String _kGroqModel = 'qwen/qwen3.6-27b';

/// Cliente delgado para chat completions de Groq (API compatible con OpenAI).
///
/// Usa un [Dio] propio y sin interceptores — a diferencia de [DioClient], esta
/// llamada no debe llevar el JWT del backend propio ni pasar por su
/// LogInterceptor. La API key se lee de GROQ_API_KEY (ver .env / flutter_dotenv),
/// nunca hardcodeada.
class GroqClient {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
  ));

  bool get hasApiKey => (dotenv.env['GROQ_API_KEY'] ?? '').isNotEmpty;

  Future<String> chatCompletion({
    required String systemPrompt,
    required String userPrompt,
    double temperature = 0.2,
    int maxTokens = 512,
  }) async {
    final apiKey = dotenv.env['GROQ_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      throw StateError('GROQ_API_KEY no configurada');
    }

    final response = await _dio.post(
      _kGroqEndpoint,
      options: Options(
        contentType: Headers.jsonContentType,
        headers: {'Authorization': 'Bearer $apiKey'},
      ),
      data: {
        'model': _kGroqModel,
        'reasoning_effort': 'none',
        'temperature': temperature,
        'max_tokens': maxTokens,
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': userPrompt},
        ],
      },
    );

    final choices = response.data['choices'] as List;
    final content = choices.first['message']['content'] as String;
    return content.trim();
  }
}
