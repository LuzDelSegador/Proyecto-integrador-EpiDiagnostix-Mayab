import '../entities/auth_entity.dart';

abstract class IAuthRepository {
  Future<AuthEntity> login({
    required String identifier,
    required String password,
    required bool rememberSession,
  });
}
