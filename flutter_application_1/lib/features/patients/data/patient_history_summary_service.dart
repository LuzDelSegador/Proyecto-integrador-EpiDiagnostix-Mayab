import '../../../core/services/groq_client.dart';
import 'models/paciente.dart';

const String _kSystemPrompt = '''
Eres un asistente clínico que redacta resúmenes narrativos breves del
historial de un paciente para personal de salud comunitaria en México.

Instrucciones:
- Redacta en español, con tono clínico-profesional, en 2 a 4 párrafos.
- Basa el resumen ÚNICAMENTE en los datos de consultas proporcionados — no inventes información.
- Si hay patrones (síntomas recurrentes, tendencias en signos vitales), menciónalos explícitamente.
- No repitas mecánicamente cada consulta como una lista: narra el panorama general.
- No incluyas recomendaciones de tratamiento ni diagnósticos nuevos, solo resume lo ya registrado.
''';

/// Genera un resumen narrativo del historial de un paciente vía LLM (Groq/Qwen)
/// a partir de las consultas ya cargadas localmente (SQLite) — no pide nada
/// nuevo al backend. Bajo demanda, sin caché: se regenera en cada llamada.
///
/// A diferencia de LlmNormalizationService, este servicio SÍ propaga errores
/// (timeout, sin conexión, respuesta vacía) para que la UI muestre el mensaje
/// amigable correspondiente en vez de fallar en silencio.
class PatientHistorySummaryService {
  final GroqClient _client;

  PatientHistorySummaryService([GroqClient? client]) : _client = client ?? GroqClient();

  Future<String> summarize({
    required String pacienteNombre,
    required List<ConsultaResumen> consultas,
  }) async {
    if (consultas.isEmpty) {
      throw StateError('Sin consultas para resumir');
    }

    final ordenadas = [...consultas]
      ..sort((a, b) => a.fechaCaptura.compareTo(b.fechaCaptura));

    final buffer = StringBuffer();
    for (final c in ordenadas) {
      final motivo = c.camposExtraidos['motivo_consulta']?.toString().trim();
      final diagnostico =
          c.camposExtraidos['diagnostico_descripcion']?.toString().trim();

      buffer.writeln('- Fecha: ${_formatFecha(c.fechaCaptura)}');
      if (motivo != null && motivo.isNotEmpty) {
        buffer.writeln('  Motivo de consulta: $motivo');
      }
      if (diagnostico != null && diagnostico.isNotEmpty) {
        buffer.writeln('  Diagnóstico: $diagnostico');
      }
      if (c.categoriaSintoma != null) {
        buffer.writeln('  Categoría de síntoma: ${c.categoriaSintoma}');
      }
      if (c.temperaturaC != null) {
        buffer.writeln('  Temperatura: ${c.temperaturaC} °C');
      }
      if (c.presionSistolica != null && c.presionDiastolica != null) {
        buffer.writeln(
            '  Presión arterial: ${c.presionSistolica}/${c.presionDiastolica} mmHg');
      }
      if (c.glucosaMgDl != null) {
        buffer.writeln('  Glucosa: ${c.glucosaMgDl} mg/dL');
      }
      buffer.writeln();
    }

    final userPrompt = 'Paciente: $pacienteNombre\n\n'
        'Historial de consultas (de más antigua a más reciente):\n$buffer';

    final resumen = await _client
        .chatCompletion(
          systemPrompt: _kSystemPrompt,
          userPrompt: userPrompt,
          temperature: 0.3,
          maxTokens: 600,
        )
        .timeout(const Duration(seconds: 15));

    if (resumen.trim().isEmpty) {
      throw StateError('El LLM devolvió una respuesta vacía');
    }
    return resumen.trim();
  }

  static String _formatFecha(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    return '$d/$m/${dt.year}';
  }
}
