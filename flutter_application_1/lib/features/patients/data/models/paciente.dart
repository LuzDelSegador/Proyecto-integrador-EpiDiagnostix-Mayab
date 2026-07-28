class Paciente {
  final String id;
  final String nombreCompleto;
  final String? sexo;
  final String? comunidad;
  final DateTime primeraVisita;
  final DateTime ultimaVisita;
  final int totalVisitas;
  final bool sincronizado;

  // Identidad MS1 — requeridos por POST /pacientes, capturados en el alta.
  final String? curp;
  final String? fechaNacimiento; // 'YYYY-MM-DD'
  final String? municipio;
  final String? lenguaMaterna;
  final String? contactoEmergencia;
  final String? remoteId; // id devuelto por MS1 una vez sincronizado
  final String? ultimoErrorSync; // motivo del último rechazo de POST /pacientes/sync, si lo hubo

  const Paciente({
    required this.id,
    required this.nombreCompleto,
    this.sexo,
    this.comunidad,
    required this.primeraVisita,
    required this.ultimaVisita,
    required this.totalVisitas,
    this.sincronizado = false,
    this.curp,
    this.fechaNacimiento,
    this.municipio,
    this.lenguaMaterna,
    this.contactoEmergencia,
    this.remoteId,
    this.ultimoErrorSync,
  });
}

class PacienteConResumen {
  final Paciente paciente;
  final int visitasEstaSemana;
  final int visitasEsteMes;

  const PacienteConResumen({
    required this.paciente,
    required this.visitasEstaSemana,
    required this.visitasEsteMes,
  });
}

/// Una consulta con coordenadas GPS reales (capturadas por Geolocator en el
/// momento de guardar la consulta, no geocodificadas). Solo existen instancias
/// de esto para consultas donde el permiso de ubicación estuvo disponible —
/// no todas las consultas tienen coordenadas.
class ConsultaConUbicacion {
  final String id;
  final DateTime fechaCaptura;
  final String nombrePaciente;
  final String? comunidad;
  final String? municipio;
  final String? categoriaSintoma;
  final double latitud;
  final double longitud;

  const ConsultaConUbicacion({
    required this.id,
    required this.fechaCaptura,
    required this.nombrePaciente,
    this.comunidad,
    this.municipio,
    this.categoriaSintoma,
    required this.latitud,
    required this.longitud,
  });
}

/// Agregación real (SQL local, sin geocodificación ni backend nuevo) de
/// pacientes/consultas por comunidad — o municipio si el paciente no tiene
/// comunidad capturada.
class ResumenComunidad {
  final String zona;
  final int totalPacientes;
  final int totalConsultas;
  final DateTime ultimaVisita;

  const ResumenComunidad({
    required this.zona,
    required this.totalPacientes,
    required this.totalConsultas,
    required this.ultimaVisita,
  });
}

class ConsultaResumen {
  final String id;
  final String pacienteId;
  final DateTime fechaCaptura;
  final String textoOriginal;
  final double? temperaturaC;
  final int? presionSistolica;
  final int? presionDiastolica;
  final double? glucosaMgDl;
  final String? categoriaSintoma;
  final Map<String, dynamic> camposExtraidos;
  final bool sincronizado;
  final double? latitud;
  final double? longitud;

  const ConsultaResumen({
    required this.id,
    required this.pacienteId,
    required this.fechaCaptura,
    required this.textoOriginal,
    this.temperaturaC,
    this.presionSistolica,
    this.presionDiastolica,
    this.glucosaMgDl,
    this.categoriaSintoma,
    required this.camposExtraidos,
    this.sincronizado = false,
    this.latitud,
    this.longitud,
  });
}
