import 'dart:convert';

class PatientRecord {
  final String textoOriginal;
  final Map<String, dynamic> camposExtraidos;
  final DateTime fechaCaptura;
  final bool sincronizado;
  final DateTime? fechaSincronizado;
  final double? latitud;
  final double? longitud;

  const PatientRecord({
    required this.textoOriginal,
    required this.camposExtraidos,
    required this.fechaCaptura,
    this.sincronizado = false,
    this.fechaSincronizado,
    this.latitud,
    this.longitud,
  });

  Map<String, Object?> toMap() => {
    'fecha_captura':      fechaCaptura.toIso8601String(),
    'texto_original':     textoOriginal,
    'campos_extraidos':   jsonEncode(camposExtraidos),
    'sincronizado':       sincronizado ? 1 : 0,
    'fecha_sincronizado': fechaSincronizado?.toIso8601String(),
    'latitud':            latitud,
    'longitud':           longitud,
  };
}
