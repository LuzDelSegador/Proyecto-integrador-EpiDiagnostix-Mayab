class StatsModel {
  final int totalUsuarios;
  final Map<String, int> porRol;
  final int solicitudesPendientes;
  final int solicitudesAprobadasHoy;

  const StatsModel({
    required this.totalUsuarios,
    required this.porRol,
    required this.solicitudesPendientes,
    required this.solicitudesAprobadasHoy,
  });

  factory StatsModel.fromJson(Map<String, dynamic> json) => StatsModel(
        totalUsuarios: json['total_usuarios'] as int,
        porRol: (json['por_rol'] as Map<String, dynamic>).map(
          (k, v) => MapEntry(k, (v as num).toInt()),
        ),
        solicitudesPendientes: json['solicitudes_pendientes'] as int,
        solicitudesAprobadasHoy: json['solicitudes_aprobadas_hoy'] as int,
      );
}

class PersonalResumenModel {
  final String personalId;
  final String nombreCompleto;
  final String correo;
  final String tipo;

  const PersonalResumenModel({
    required this.personalId,
    required this.nombreCompleto,
    required this.correo,
    required this.tipo,
  });

  factory PersonalResumenModel.fromJson(Map<String, dynamic> json) =>
      PersonalResumenModel(
        personalId: json['personal_id'] as String,
        nombreCompleto: json['nombre_completo'] as String,
        correo: json['correo'] as String,
        tipo: json['tipo'] as String,
      );
}

class SolicitudAdminModel {
  final String solicitudId;
  final String estado;
  final DateTime createdAt;
  final String numeroCedula;
  final String nombreEnCedula;
  final String? especialidad;
  final PersonalResumenModel personal;
  final String? motivoRechazo;

  const SolicitudAdminModel({
    required this.solicitudId,
    required this.estado,
    required this.createdAt,
    required this.numeroCedula,
    required this.nombreEnCedula,
    this.especialidad,
    required this.personal,
    this.motivoRechazo,
  });

  factory SolicitudAdminModel.fromJson(Map<String, dynamic> json) =>
      SolicitudAdminModel(
        solicitudId: json['solicitud_id'] as String,
        estado: json['estado'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        numeroCedula: json['numero_cedula'] as String,
        nombreEnCedula: json['nombre_en_cedula'] as String,
        especialidad: json['especialidad'] as String?,
        personal: PersonalResumenModel.fromJson(
            json['personal'] as Map<String, dynamic>),
        motivoRechazo: json['motivo_rechazo'] as String?,
      );
}

class UsuarioAdminModel {
  final String personalId;
  final String nombreCompleto;
  final String correo;
  final String tipo;
  final DateTime createdAt;

  const UsuarioAdminModel({
    required this.personalId,
    required this.nombreCompleto,
    required this.correo,
    required this.tipo,
    required this.createdAt,
  });

  factory UsuarioAdminModel.fromJson(Map<String, dynamic> json) =>
      UsuarioAdminModel(
        personalId: json['personal_id'] as String,
        nombreCompleto: json['nombre_completo'] as String,
        correo: json['correo'] as String,
        tipo: json['tipo'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
