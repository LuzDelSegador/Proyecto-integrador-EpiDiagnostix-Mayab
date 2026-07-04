import '../entities/auth_entity.dart';

abstract class IAuthRepository {
  Future<AuthEntity> login({
    required String identifier,
    required String password,
  });

  Future<AuthEntity> register({
    required String nombreCompleto,
    required String correo,
    required String contrasena,
  });
}
