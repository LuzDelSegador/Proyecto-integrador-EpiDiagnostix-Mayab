import '../../../../core/constants/user_roles.dart';

class AuthEntity {
  final String token;
  final String userId;
  final String name;
  final String role;

  UserRole get userRole => UserRoleExtension.fromString(role);

  // Constructor normal
  const AuthEntity({
    required this.token,
    required this.userId,
    required this.name,
    required this.role,
  });

  // Constructor nombrado — estado vacío / no autenticado
  const AuthEntity.empty()
      : token = '',
        userId = '',
        name = '',
        role = '';

  // copyWith — crea una copia modificando solo los campos indicados
  AuthEntity copyWith({
    String? token,
    String? userId,
    String? name,
    String? role,
  }) {
    return AuthEntity(
      token: token ?? this.token,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      role: role ?? this.role,
    );
  }
}
