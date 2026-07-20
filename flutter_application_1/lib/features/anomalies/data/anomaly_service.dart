import 'package:dio/dio.dart';
import '../../../core/constants/app_config.dart';

class AnomalyResult {
  final String id;
  final String tipo;
  final bool esAnomalia;
  final double score;
  final String nivelRiesgo;
  final DateTime createdAt;
  final Map<String, dynamic>? outputJson;
  // Campos clínicos — solo presentes en tipo 'completa' con extraccion completa
  final String? categoriaSintoma;
  final double? temperatura;
  final num? presionSistolica;
  final num? glucosa;
  final int? edad;
  final String? sexo;

  const AnomalyResult({
    required this.id,
    required this.tipo,
    required this.esAnomalia,
    required this.score,
    required this.nivelRiesgo,
    required this.createdAt,
    this.outputJson,
    this.categoriaSintoma,
    this.temperatura,
    this.presionSistolica,
    this.glucosa,
    this.edad,
    this.sexo,
  });

  factory AnomalyResult.fromJson(Map<String, dynamic> json) {
    final output = json['output_json'] as Map<String, dynamic>?;
    // tipo 'completa' anida los datos de anomalía dentro de 'anomalia'
    final anomaliaObj = output?['anomalia'] as Map<String, dynamic>?;
    final extraccion = output?['extraccion'] as Map<String, dynamic>?;

    final nivelRiesgo = (output?['nivel_riesgo']    // tipo 'anomalia': nivel a raíz de output_json
        ?? anomaliaObj?['nivel_riesgo']             // tipo 'completa': nivel dentro de anomalia{}
        ?? 'normal').toString();

    return AnomalyResult(
      id: (json['id'] ?? '').toString(),
      tipo: (json['tipo'] ?? 'anomalia').toString(),
      esAnomalia: json['es_anomalia'] == true,
      score: (json['score'] as num? ?? 0).toDouble(),
      nivelRiesgo: nivelRiesgo,
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      outputJson: output,
      categoriaSintoma: extraccion?['categoria_sintoma'] as String?,
      temperatura: (extraccion?['temperatura_c'] as num?)?.toDouble(),
      presionSistolica: extraccion?['presion_sistolica'] as num?,
      glucosa: extraccion?['glucosa_mg_dl'] as num?,
      edad: (extraccion?['edad'] as num?)?.toInt(),
      sexo: extraccion?['sexo'] as String?,
    );
  }

  // Isolation Forest: score negativo = anómalo. Normaliza [-0.5, 0.5] → [100%, 0%].
  double get confianza => ((0.5 - score) * 100).clamp(0.0, 100.0);
}

class AnomalyService {
  final Dio _dio;
  const AnomalyService(this._dio);

  Future<List<AnomalyResult>> getHistorial({int limit = 50}) async {
    final response = await _dio.get(
      '$kBaseUrlML/inferencias',
      queryParameters: {'limit': limit},
    );
    final data = response.data as Map<String, dynamic>;
    final list = data['inferencias'] as List<dynamic>? ?? [];
    return list
        .map((e) => AnomalyResult.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
