class Paciente {
  final String id;
  final String nombreCompleto;
  final String? sexo;
  final String? comunidad;
  final DateTime primeraVisita;
  final DateTime ultimaVisita;
  final int totalVisitas;
  final bool sincronizado;

  const Paciente({
    required this.id,
    required this.nombreCompleto,
    this.sexo,
    this.comunidad,
    required this.primeraVisita,
    required this.ultimaVisita,
    required this.totalVisitas,
    this.sincronizado = false,
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
  });
}
