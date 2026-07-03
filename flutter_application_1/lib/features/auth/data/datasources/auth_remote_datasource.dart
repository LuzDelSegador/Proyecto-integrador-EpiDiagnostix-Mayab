import 'package:dio/dio.dart';
import '../../../../core/errors/app_exceptions.dart';
import '../models/auth_model.dart';

abstract class IAuthRemoteDataSource {
  Future<AuthModel> login({
    required String identifier,
    required String password,
  });
}

class AuthRemoteDataSource implements IAuthRemoteDataSource {
  final Dio _dio;

  const AuthRemoteDataSource(this._dio);

  @override
  Future<AuthModel> login({
    required String identifier,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {
          'correo':     identifier,
          'contrasena': password,
        },
      );
      return AuthModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        throw const NetworkException();
      }
      if (e.response?.statusCode == 401) {
        throw const UnauthorizedException();
      }
      final message = e.response?.data?['message'] as String?;
      throw ServerException(message ?? 'Error al conectar con el servidor.');
    }
  }
}
