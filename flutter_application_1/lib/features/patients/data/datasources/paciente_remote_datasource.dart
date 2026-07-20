import 'package:dio/dio.dart';
import '../../../../core/constants/app_config.dart';
import '../../../../core/errors/app_exceptions.dart';
import '../models/paciente_remote_model.dart';

class PacienteRemoteDataSource {
  final Dio _dio;

  const PacienteRemoteDataSource(this._dio);

  Future<PacienteRemoteModel> crear(PacienteCreatePayload payload) async {
    try {
      final response = await _dio.post(
        '$kBaseUrlAuth/pacientes',
        data: payload.toJson(),
      );
      return PacienteRemoteModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<PacienteRemoteModel> obtener(String pacienteId) async {
    try {
      final response = await _dio.get('$kBaseUrlAuth/pacientes/$pacienteId');
      return PacienteRemoteModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<List<PacienteRemoteModel>> catalogo({
    required DateTime desde,
    String? comunidad,
  }) async {
    try {
      final response = await _dio.get(
        '$kBaseUrlAuth/pacientes/catalogo',
        queryParameters: {
          'desde': desde.toIso8601String(),
          if (comunidad != null && comunidad.isNotEmpty) 'comunidad': comunidad,
        },
      );
      return (response.data as List<dynamic>)
          .map((e) => PacienteRemoteModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  /// POST /pacientes/sync — OJO: el backend valida el body completo antes de
  /// procesar nada, así que un solo item mal formado devuelve 422 para todo
  /// el lote (no es tolerante a fallos individuales pese a lo documentado).
  /// Por eso hay que validar cada [PacienteCreatePayload] del lado del
  /// cliente antes de agregarlo al outbox local.
  Future<List<SyncResultado>> sync({
    required String dispositivoId,
    required List<PacienteCreatePayload> pacientes,
  }) async {
    try {
      final response = await _dio.post(
        '$kBaseUrlAuth/pacientes/sync',
        data: {
          'dispositivo_id': dispositivoId,
          'pacientes': pacientes.map((p) => p.toJson()).toList(),
        },
      );
      final resultados = (response.data as Map<String, dynamic>)['resultados'] as List<dynamic>;
      return resultados
          .map((e) => SyncResultado.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<void> agregarHistorial(
    String pacienteId, {
    required String descripcion,
    required String tipo,
    String? origenAtencionId,
  }) async {
    try {
      await _dio.post(
        '$kBaseUrlAuth/pacientes/$pacienteId/historial',
        data: {
          'descripcion': descripcion,
          'tipo': tipo,
          'origen_atencion_id': origenAtencionId,
        },
      );
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<PacienteRemoteModel> actualizarDatos(
    String pacienteId, {
    String? nombreCompleto,
    String? comunidad,
    String? municipio,
    String? lenguaMaterna,
    String? contactoEmergencia,
  }) async {
    try {
      final response = await _dio.patch(
        '$kBaseUrlAuth/pacientes/$pacienteId/datos',
        data: {
          if (nombreCompleto != null) 'nombre_completo': nombreCompleto,
          if (comunidad != null) 'comunidad': comunidad,
          if (municipio != null) 'municipio': municipio,
          if (lenguaMaterna != null) 'lengua_materna': lenguaMaterna,
          if (contactoEmergencia != null) 'contacto_emergencia': contactoEmergencia,
        },
      );
      return PacienteRemoteModel.fromJson(response.data as Map<String, dynamic>);
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
    return ServerException(message ?? 'Error al conectar con el servicio de pacientes.');
  }
}
