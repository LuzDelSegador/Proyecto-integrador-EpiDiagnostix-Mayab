import '../../domain/entities/auth_entity.dart';
import '../../domain/repositories/i_auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements IAuthRepository {
  final IAuthRemoteDataSource _remoteDataSource;

  const AuthRepositoryImpl(this._remoteDataSource);

  @override
  Future<AuthEntity> login({
    required String identifier,
    required String password,
  }) =>
      _remoteDataSource.login(
        identifier: identifier,
        password:   password,
      );
}
