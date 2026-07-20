class PersonalModel {
  final String id;
  final String nombreCompleto;
  final String tipo;
  final String? comunidad;
  final String? municipio;
  final String correo;
  final String? cedulaProfesional;
  final bool activo;

  const PersonalModel({
    required this.id,
    required this.nombreCompleto,
    required this.tipo,
    this.comunidad,
    this.municipio,
    required this.correo,
    this.cedulaProfesional,
    this.activo = true,
  });

  factory PersonalModel.fromJson(Map<String, dynamic> json) => PersonalModel(
        id:                 json['id'] as String,
        nombreCompleto:     json['nombre_completo'] as String,
        tipo:               json['tipo'] as String,
        comunidad:          json['comunidad'] as String?,
        municipio:          json['municipio'] as String?,
        correo:             json['correo'] as String,
        cedulaProfesional:  json['cedula_profesional'] as String?,
        activo:             json['activo'] as bool? ?? true,
      );
}

/// Payload de POST /personal — requiere estar ya autenticado (distinto del
/// registro público /auth/register). Sin UI todavía: vivirá en el futuro
/// panel de administrador junto con /admin/*.
class PersonalCreatePayload {
  final String nombreCompleto;
  final String tipo; // 'enfermera' | 'medico'
  final String comunidad;
  final String municipio;
  final String correo;
  final String contrasena;
  final String confirmarContrasena;
  final String? cedulaProfesional;

  const PersonalCreatePayload({
    required this.nombreCompleto,
    required this.tipo,
    required this.comunidad,
    required this.municipio,
    required this.correo,
    required this.contrasena,
    required this.confirmarContrasena,
    this.cedulaProfesional,
  });

  Map<String, dynamic> toJson() => {
        'nombre_completo':       nombreCompleto,
        'tipo':                  tipo,
        'comunidad':             comunidad,
        'municipio':             municipio,
        'correo':                correo,
        'contrasena':            contrasena,
        'confirmar_contrasena':  confirmarContrasena,
        'cedula_profesional':    cedulaProfesional,
      };
}
