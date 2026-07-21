import '../models/atencion_model.dart';
import '../models/medicamento.dart';

/// Traduce `camposExtraidos` (salida del BiLSTM local, ver tflite_extractor.dart)
/// más los campos manuales nuevos al payload que espera MS2 (`/atenciones`,
/// `/atenciones/sync`). Las claves del BiLSTM (peso_kg, talla_cm, temperatura_c,
/// frecuencia_cardiaca_bpm, duracion_sintomas_dias, glucosa_mg_dl) NO se tocan
/// en ningún otro lugar del código — el mapeo vive solo aquí.
class AtencionPayloadMapper {
  static AtencionCreatePayload fromCamposExtraidos({
    required Map<String, dynamic> campos,
    required String pacienteId,
    required String personalId,
    required String comunidad,
    required String municipio,
    required String deviceGeneratedId,
    required DateTime fechaAtencion,
    String? motivoConsulta,
    String? diagnosticoDescripcion,
    int? diasEvolucionSintomasOverride,
    int? saturacionOxigeno,
    List<Medicamento> medicamentos = const [],
    String? evidenciaRecetaBase64,
  }) {
    return AtencionCreatePayload(
      pacienteId: pacienteId,
      personalId: personalId,
      motivoConsulta: motivoConsulta,
      fechaAtencion: _isoSinTimezone(fechaAtencion),
      comunidad: comunidad,
      municipio: municipio,
      diagnosticoDescripcion: diagnosticoDescripcion,
      diasEvolucionSintomas:
          diasEvolucionSintomasOverride ?? _asInt(campos['duracion_sintomas_dias']),
      presionSistolica:   _asInt(campos['presion_sistolica']),
      presionDiastolica:  _asInt(campos['presion_diastolica']),
      temperatura:        _asDouble(campos['temperatura_c']),
      peso:               _asDouble(campos['peso_kg']),
      estatura:           _asDouble(campos['talla_cm']),
      glucosa:            _asDouble(campos['glucosa_mg_dl']),
      frecuenciaCardiaca: _asInt(campos['frecuencia_cardiaca_bpm']),
      saturacionOxigeno:  saturacionOxigeno,
      medicamentos:       medicamentos,
      evidenciaRecetaBase64: evidenciaRecetaBase64,
      deviceGeneratedId: deviceGeneratedId,
    );
  }

  static String _isoSinTimezone(DateTime dt) {
    final local = dt.toLocal();
    String p2(int v) => v.toString().padLeft(2, '0');
    return '${local.year.toString().padLeft(4, '0')}-${p2(local.month)}-${p2(local.day)}'
        'T${p2(local.hour)}:${p2(local.minute)}:${p2(local.second)}';
  }

  static int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  static double? _asDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }
}
