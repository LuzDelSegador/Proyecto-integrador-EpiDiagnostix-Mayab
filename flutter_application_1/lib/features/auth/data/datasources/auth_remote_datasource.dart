import 'package:dio/dio.dart';
import '../../../../core/constants/app_config.dart';
import '../../../../core/errors/app_exceptions.dart';
import '../models/auth_model.dart';

abstract class IAuthRemoteDataSource {
  Future<AuthModel> login({
    required String identifier,
    required String password,
  });

  Future<AuthModel> register({
    required String nombreCompleto,
    required String correo,
    required String contrasena,
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
        '$kBaseUrlAuth/auth/login',
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

  @override
  Future<AuthModel> register({
    required String nombreCompleto,
    required String correo,
    required String contrasena,
  }) async {
    try {
      final response = await _dio.post(
        '$kBaseUrlAuth/auth/register',
        data: {
          'nombre_completo': nombreCompleto,
          'correo':          correo,
          'contrasena':      contrasena,
        },
      );
      return AuthModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        throw const NetworkException();
      }
      if (e.response?.statusCode == 409) throw const ConflictException();
      if (e.response?.statusCode == 422) throw const ValidationException();
      final message = e.response?.data?['message'] as String?;
      throw ServerException(message ?? 'Error al crear la cuenta. Intenta de nuevo.');
    }
  }
}
