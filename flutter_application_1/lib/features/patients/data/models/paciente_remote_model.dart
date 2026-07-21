class PacienteRemoteModel {
  final String id;
  final String curp;
  final String nombreCompleto;
  final String fechaNacimiento;
  final String sexo;
  final String? comunidad;
  final String municipio;
  final String? lenguaMaterna;
  final String? contactoEmergencia;
  final int? edad;
  final bool fueCreadoAhora;

  const PacienteRemoteModel({
    required this.id,
    required this.curp,
    required this.nombreCompleto,
    required this.fechaNacimiento,
    required this.sexo,
    this.comunidad,
    required this.municipio,
    this.lenguaMaterna,
    this.contactoEmergencia,
    this.edad,
    this.fueCreadoAhora = false,
  });

  factory PacienteRemoteModel.fromJson(Map<String, dynamic> json) {
    return PacienteRemoteModel(
      id:                 json['id'] as String,
      curp:               json['curp'] as String,
      nombreCompleto:     json['nombre_completo'] as String,
      fechaNacimiento:    json['fecha_nacimiento'] as String,
      sexo:               json['sexo'] as String,
      comunidad:          json['comunidad'] as String?,
      municipio:          json['municipio'] as String,
      lenguaMaterna:      json['lengua_materna'] as String?,
      contactoEmergencia: json['contacto_emergencia'] as String?,
      edad:               json['edad'] as int?,
      fueCreadoAhora:     json['fue_creado_ahora'] as bool? ?? false,
    );
  }
}

/// Payload de entrada para POST /pacientes y para cada item de POST /pacientes/sync.
class PacienteCreatePayload {
  final String curp;
  final String nombreCompleto;
  final String fechaNacimiento; // 'YYYY-MM-DD'
  final String sexo;            // 'H' | 'M' — ver sexo_mapper.dart
  final String comunidad;
  final String municipio;
  final String? lenguaMaterna;
  final String? contactoEmergencia;
  final String deviceGeneratedId;

  const PacienteCreatePayload({
    required this.curp,
    required this.nombreCompleto,
    required this.fechaNacimiento,
    required this.sexo,
    required this.comunidad,
    required this.municipio,
    this.lenguaMaterna,
    this.contactoEmergencia,
    required this.deviceGeneratedId,
  });

  Map<String, dynamic> toJson() => {
        'curp':                 curp,
        'nombre_completo':      nombreCompleto,
        'fecha_nacimiento':     fechaNacimiento,
        'sexo':                 sexo,
        'comunidad':            comunidad,
        'municipio':            municipio,
        'lengua_materna':       lenguaMaterna,
        'contacto_emergencia':  contactoEmergencia,
        'device_generated_id':  deviceGeneratedId,
      };
}

/// Un resultado individual dentro de la respuesta de POST /pacientes/sync:
/// {"resultados":[{"device_generated_id","id_servidor","curp","estado"}]}
class SyncResultado {
  final String deviceGeneratedId;
  final String idServidor;
  final String estado;

  const SyncResultado({
    required this.deviceGeneratedId,
    required this.idServidor,
    required this.estado,
  });

  factory SyncResultado.fromJson(Map<String, dynamic> json) {
    return SyncResultado(
      deviceGeneratedId: json['device_generated_id'] as String,
      idServidor:        json['id_servidor'] as String,
      estado:            json['estado'] as String? ?? '',
    );
  }
}
