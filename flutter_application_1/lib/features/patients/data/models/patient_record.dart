import 'dart:convert';

class PatientRecord {
  final String nombrePaciente;
  final String localidad;
  final String textoOriginal;
  final Map<String, dynamic> camposExtraidos;
  final DateTime fechaCaptura;
  final bool sincronizado;
  final DateTime? fechaSincronizado;

  const PatientRecord({
    required this.nombrePaciente,
    required this.localidad,
    required this.textoOriginal,
    required this.camposExtraidos,
    required this.fechaCaptura,
    this.sincronizado = false,
    this.fechaSincronizado,
  });

  Map<String, Object?> toMap() => {
    'fecha_captura': fechaCaptura.toIso8601String(),
    'nombre_paciente': nombrePaciente,
    'localidad': localidad,
    'texto_original': textoOriginal,
    'campos_extraidos': jsonEncode(camposExtraidos),
    'sincronizado': sincronizado ? 1 : 0,
    'fecha_sincronizado': fechaSincronizado?.toIso8601String(),
  };
}
