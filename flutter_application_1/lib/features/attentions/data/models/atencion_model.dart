import 'medicamento.dart';

class AtencionModel {
  final String id;
  final String pacienteId;
  final String personalId;
  final String? motivoConsulta;
  final String? diagnosticoDescripcion;
  final int? diasEvolucionSintomas;
  final String fechaAtencion;
  final String? comunidad;
  final String? municipio;
  final String estado;
  final List<Medicamento> medicamentos;
  final String? evidenciaUrl;
  final int? presionSistolica;
  final int? presionDiastolica;
  final double? temperatura;
  final double? peso;
  final double? estatura;
  final double? glucosa;
  final int? frecuenciaCardiaca;
  final int? saturacionOxigeno;

  const AtencionModel({
    required this.id,
    required this.pacienteId,
    required this.personalId,
    this.motivoConsulta,
    this.diagnosticoDescripcion,
    this.diasEvolucionSintomas,
    required this.fechaAtencion,
    this.comunidad,
    this.municipio,
    required this.estado,
    this.medicamentos = const [],
    this.evidenciaUrl,
    this.presionSistolica,
    this.presionDiastolica,
    this.temperatura,
    this.peso,
    this.estatura,
    this.glucosa,
    this.frecuenciaCardiaca,
    this.saturacionOxigeno,
  });

  factory AtencionModel.fromJson(Map<String, dynamic> json) {
    return AtencionModel(
      id:                     json['id'] as String,
      pacienteId:             json['paciente_id'] as String,
      personalId:             json['personal_id'] as String,
      motivoConsulta:         json['motivo_consulta'] as String?,
      diagnosticoDescripcion: json['diagnostico_descripcion'] as String?,
      diasEvolucionSintomas:  json['dias_evolucion_sintomas'] as int?,
      fechaAtencion:          json['fecha_atencion'] as String,
      comunidad:              json['comunidad'] as String?,
      municipio:              json['municipio'] as String?,
      estado:                 json['estado'] as String? ?? 'pendiente_validacion',
      medicamentos: (json['medicamentos'] as List<dynamic>? ?? [])
          .map((m) => Medicamento.fromJson(m as Map<String, dynamic>))
          .toList(),
      evidenciaUrl:       json['evidencia_url'] as String?,
      presionSistolica:   json['presion_sistolica'] as int?,
      presionDiastolica:  json['presion_diastolica'] as int?,
      temperatura:        (json['temperatura'] as num?)?.toDouble(),
      peso:               (json['peso'] as num?)?.toDouble(),
      estatura:           (json['estatura'] as num?)?.toDouble(),
      glucosa:            (json['glucosa'] as num?)?.toDouble(),
      frecuenciaCardiaca: json['frecuencia_cardiaca'] as int?,
      saturacionOxigeno:  json['saturacion_oxigeno'] as int?,
    );
  }
}

/// Payload de entrada para POST /atenciones y cada item de POST /atenciones/sync.
class AtencionCreatePayload {
  final String pacienteId;
  final String personalId;
  final String? motivoConsulta;
  final String fechaAtencion; // ISO 8601 sin timezone, ej. '2026-07-19T10:00:00'
  final String comunidad;
  final String municipio;
  final String? diagnosticoDescripcion;
  final int? diasEvolucionSintomas;
  final int? presionSistolica;
  final int? presionDiastolica;
  final double? temperatura;
  final double? peso;
  final double? estatura;
  final double? glucosa;
  final int? frecuenciaCardiaca;
  final int? saturacionOxigeno;
  final List<Medicamento> medicamentos;
  final String? evidenciaRecetaBase64;
  final String deviceGeneratedId;

  const AtencionCreatePayload({
    required this.pacienteId,
    required this.personalId,
    this.motivoConsulta,
    required this.fechaAtencion,
    required this.comunidad,
    required this.municipio,
    this.diagnosticoDescripcion,
    this.diasEvolucionSintomas,
    this.presionSistolica,
    this.presionDiastolica,
    this.temperatura,
    this.peso,
    this.estatura,
    this.glucosa,
    this.frecuenciaCardiaca,
    this.saturacionOxigeno,
    this.medicamentos = const [],
    this.evidenciaRecetaBase64,
    required this.deviceGeneratedId,
  });

  Map<String, dynamic> toJson() => {
        'paciente_id':               pacienteId,
        'personal_id':               personalId,
        'motivo_consulta':           motivoConsulta,
        'fecha_atencion':            fechaAtencion,
        'comunidad':                 comunidad,
        'municipio':                 municipio,
        'diagnostico_descripcion':   diagnosticoDescripcion,
        'dias_evolucion_sintomas':   diasEvolucionSintomas,
        'presion_sistolica':         presionSistolica,
        'presion_diastolica':        presionDiastolica,
        'temperatura':               temperatura,
        'peso':                      peso,
        'estatura':                  estatura,
        'glucosa':                   glucosa,
        'frecuencia_cardiaca':       frecuenciaCardiaca,
        'saturacion_oxigeno':        saturacionOxigeno,
        if (medicamentos.isNotEmpty)
          'medicamentos': medicamentos.map((m) => m.toJson()).toList(),
        'evidencia_receta_base64':   evidenciaRecetaBase64,
        'device_generated_id':       deviceGeneratedId,
      };
}

/// Un resultado individual dentro de la respuesta de POST /atenciones/sync:
/// {"resultados":[{"device_generated_id","id_servidor","estado"}]}
class AtencionSyncResultado {
  final String deviceGeneratedId;
  final String idServidor;
  final String estado;

  const AtencionSyncResultado({
    required this.deviceGeneratedId,
    required this.idServidor,
    required this.estado,
  });

  factory AtencionSyncResultado.fromJson(Map<String, dynamic> json) {
    return AtencionSyncResultado(
      deviceGeneratedId: json['device_generated_id'] as String,
      idServidor:        json['id_servidor'] as String,
      estado:            json['estado'] as String? ?? '',
    );
  }
}
