import 'package:dio/dio.dart';
import '../../../../core/constants/app_config.dart';
import '../../../../core/errors/app_exceptions.dart';
import '../models/atencion_model.dart';

/// MS2 no tiene login propio: decodifica el mismo JWT que emite MS1 (mismo
/// JWT_SECRET_KEY/JWT_ALGORITHM), así que el token guardado al hacer login
/// contra MS1 se manda tal cual aquí (el DioClient ya lo inyecta vía
/// interceptor, igual que en las llamadas a MS1).
class AtencionRemoteDataSource {
  final Dio _dio;

  const AtencionRemoteDataSource(this._dio);

  Future<AtencionModel> crear(AtencionCreatePayload payload) async {
    try {
      final response = await _dio.post(
        '$kBaseUrlAtencion/atenciones',
        data: payload.toJson(),
      );
      return AtencionModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  /// POST /atenciones/sync — mismo caveat que /pacientes/sync: un item mal
  /// formado puede invalidar el lote completo, validar antes de encolar.
  Future<List<AtencionSyncResultado>> sync({
    required String dispositivoId,
    required List<AtencionCreatePayload> atenciones,
  }) async {
    try {
      final response = await _dio.post(
        '$kBaseUrlAtencion/atenciones/sync',
        data: {
          'dispositivo_id': dispositivoId,
          'atenciones': atenciones.map((a) => a.toJson()).toList(),
        },
      );
      final resultados = (response.data as Map<String, dynamic>)['resultados'] as List<dynamic>;
      return resultados
          .map((e) => AtencionSyncResultado.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  /// PATCH /atenciones/{id} — solo motivo/diagnóstico y/o evidencia. La
  /// evidencia SE REEMPLAZA (no se anexa, a diferencia del historial de MS1).
  Future<AtencionModel> actualizar(
    String atencionId, {
    String? motivoConsulta,
    String? diagnosticoDescripcion,
    String? evidenciaRecetaBase64,
  }) async {
    try {
      final response = await _dio.patch(
        '$kBaseUrlAtencion/atenciones/$atencionId',
        data: {
          if (motivoConsulta != null) 'motivo_consulta': motivoConsulta,
          if (diagnosticoDescripcion != null) 'diagnostico_descripcion': diagnosticoDescripcion,
          if (evidenciaRecetaBase64 != null) 'evidencia_receta_base64': evidenciaRecetaBase64,
        },
      );
      return AtencionModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  // Los siguientes 3 endpoints están "SIN auth todavía" del lado del backend
  // (según especificación). Quedan implementados y disponibles para uso
  // futuro pero no se conectan a ninguna pantalla en este cambio — fusionar
  // lecturas remotas con las locales de SQLite es un problema de
  // reconciliación aparte, fuera de alcance.

  Future<List<AtencionModel>> porPaciente(String pacienteId) async {
    try {
      final response = await _dio.get('$kBaseUrlAtencion/atenciones/paciente/$pacienteId');
      return (response.data as List<dynamic>)
          .map((e) => AtencionModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<AtencionModel> obtener(String atencionId) async {
    try {
      final response = await _dio.get('$kBaseUrlAtencion/atenciones/$atencionId');
      return AtencionModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<List<AtencionModel>> porPersonal(String personalId) async {
    try {
      final response = await _dio.get('$kBaseUrlAtencion/atenciones/personal/$personalId');
      return (response.data as List<dynamic>)
          .map((e) => AtencionModel.fromJson(e as Map<String, dynamic>))
          .toList();
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
    if (e.response?.statusCode == 422) return const ValidationException();
    final message = e.response?.data is Map ? e.response?.data['message'] as String? : null;
    return ServerException(message ?? 'Error al conectar con el servicio de atención médica.');
  }
}
