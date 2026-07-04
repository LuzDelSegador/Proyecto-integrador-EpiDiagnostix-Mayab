import '../entities/auth_entity.dart';
import '../repositories/i_auth_repository.dart';

class RegisterUseCase {
  final IAuthRepository _repository;

  const RegisterUseCase(this._repository);

  Future<AuthEntity> call({
    required String nombreCompleto,
    required String correo,
    required String contrasena,
  }) =>
      _repository.register(
        nombreCompleto: nombreCompleto,
        correo:         correo,
        contrasena:     contrasena,
      );
}
