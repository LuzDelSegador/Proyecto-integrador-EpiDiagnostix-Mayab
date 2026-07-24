import 'package:connectivity_plus/connectivity_plus.dart';

import 'groq_client.dart';

const String _kSystemPrompt = '''
Eres un asistente clínico que normaliza vocabulario coloquial en notas de
consulta médica en español, para que un extractor NER especializado pueda
reconocer los términos técnicos correctos.

Reglas estrictas:
- Reescribe ÚNICAMENTE el vocabulario coloquial a su equivalente técnico.
- NO agregues información, síntomas, cifras ni diagnósticos que no estén ya en el texto.
- NO inventes ni asumas valores.
- NO resumas ni elimines contenido: conserva intacta la estructura del resto de la oración.
- Responde solo con el texto normalizado, sin explicaciones, comillas ni comentarios.

Ejemplos de normalización:
- "fiebre" -> "temperatura elevada"
- "le dolía la panza" -> "dolor abdominal"
- "presión alta" -> "hipertensión"
- "le dio gripa" -> "cuadro gripal"
- "se sentía mareado" -> "mareo"
- "le faltaba el aire" -> "dificultad respiratoria"
''';

/// Resultado de un intento de normalización: el texto a usar (normalizado si
/// tuvo éxito, original si no) y si efectivamente pasó por el LLM.
class NormalizationResult {
  final String text;
  final bool normalizado;
  const NormalizationResult({required this.text, required this.normalizado});
}

/// Normaliza vocabulario clínico coloquial vía LLM antes del extractor BiLSTM.
///
/// Nunca bloquea el flujo ni lanza excepciones hacia el caller: sin conexión,
/// sin API key, timeout o cualquier error del LLM devuelven el texto original
/// intacto con `normalizado: false` — la captura offline nunca depende de este paso.
class LlmNormalizationService {
  final GroqClient _client;

  LlmNormalizationService([GroqClient? client]) : _client = client ?? GroqClient();

  Future<NormalizationResult> normalize(String text) async {
    if (text.trim().isEmpty) {
      return NormalizationResult(text: text, normalizado: false);
    }

    final connectivity = await Connectivity().checkConnectivity();
    final online = connectivity.any((r) => r != ConnectivityResult.none);
    if (!online) {
      return NormalizationResult(text: text, normalizado: false);
    }

    try {
      final normalized = await _client
          .chatCompletion(
            systemPrompt: _kSystemPrompt,
            userPrompt: text,
            temperature: 0.15,
            maxTokens: 400,
          )
          .timeout(const Duration(seconds: 15));

      if (normalized.trim().isEmpty) {
        return NormalizationResult(text: text, normalizado: false);
      }
      return NormalizationResult(text: normalized.trim(), normalizado: true);
    } catch (_) {
      return NormalizationResult(text: text, normalizado: false);
    }
  }
}
