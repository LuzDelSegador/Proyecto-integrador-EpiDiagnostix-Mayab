import '../../domain/entities/auth_entity.dart';

class AuthModel extends AuthEntity {
  const AuthModel({
    required super.token,
    required super.userId,
    required super.name,
    required super.role,
  });

  factory AuthModel.fromJson(Map<String, dynamic> json) {
    return AuthModel(
      token:  json['access_token']   as String,
      userId: json['personal_id']    as String,
      name:   json['nombre_completo'] as String,
      role:   json['tipo']           as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'access_token':    token,
        'personal_id':     userId,
        'nombre_completo': name,
        'tipo':            role,
      };
}
