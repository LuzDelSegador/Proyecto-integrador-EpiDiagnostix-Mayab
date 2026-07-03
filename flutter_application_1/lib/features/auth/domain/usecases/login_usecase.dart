import '../entities/auth_entity.dart';
import '../repositories/i_auth_repository.dart';

class LoginUseCase {
  final IAuthRepository _repository;

  const LoginUseCase(this._repository);

  Future<AuthEntity> call({
    required String identifier,
    required String password,
  }) =>
      _repository.login(
        identifier: identifier,
        password:   password,
      );
}
