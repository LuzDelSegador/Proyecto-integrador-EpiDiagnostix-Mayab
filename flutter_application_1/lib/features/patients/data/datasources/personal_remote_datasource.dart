import 'package:dio/dio.dart';
import '../../../../core/constants/app_config.dart';
import '../../../../core/errors/app_exceptions.dart';
import '../models/personal_model.dart';

/// Service layer para POST/GET /personal. Sin pantalla propia todavía
/// (decisión de producto: vivirá en el futuro panel de administrador).
class PersonalRemoteDataSource {
  final Dio _dio;

  const PersonalRemoteDataSource(this._dio);

  Future<PersonalModel> crear(PersonalCreatePayload payload) async {
    try {
      final response = await _dio.post(
        '$kBaseUrlAuth/personal',
        data: payload.toJson(),
      );
      return PersonalModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<PersonalModel> obtener(String personalId) async {
    try {
      final response = await _dio.get('$kBaseUrlAuth/personal/$personalId');
      return PersonalModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Exception _mapError(DioException e) {
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return const NetworkException();
    }
    if (e.response?.statusCode == 401) return const UnauthorizedException();
    if (e.response?.statusCode == 409) return const ConflictException();
    if (e.response?.statusCode == 422) return const ValidationException();
    final message = e.response?.data is Map ? e.response?.data['message'] as String? : null;
    return ServerException(message ?? 'Error al registrar personal médico.');
  }
}
