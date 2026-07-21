import 'package:dio/dio.dart';
import '../../../core/constants/app_config.dart';
import '../../auth/data/models/auth_model.dart';

class SolicitudResult {
  final String solicitudId;
  final String estado; // 'pendiente' | 'aprobado' | 'rechazado'
  final String mensaje;

  const SolicitudResult({
    required this.solicitudId,
    required this.estado,
    required this.mensaje,
  });

  factory SolicitudResult.fromJson(Map<String, dynamic> json) {
    return SolicitudResult(
      solicitudId: (json['solicitudId'] ?? json['solicitud_id'] ?? '').toString(),
      estado: (json['estado'] ?? 'pendiente').toString(),
      mensaje: (json['mensaje'] ?? '').toString(),
    );
  }
}

class SolicitudDuplicadaException implements Exception {
  const SolicitudDuplicadaException();
}

class PlanService {
  final Dio _dio;
  const PlanService(this._dio);

  /// POST /auth/solicitar-premium — requiere JWT (lo agrega DioClient automáticamente).
  /// Lanza [SolicitudDuplicadaException] si el backend responde 409.
  Future<SolicitudResult> solicitarPremium({
    required String numeroCedula,
    required String nombreEnCedula,
    String? especialidad,
  }) async {
    try {
      final response = await _dio.post(
        '$kBaseUrlAuth/auth/solicitar-premium',
        data: {
          'numero_cedula': numeroCedula,
          'nombre_en_cedula': nombreEnCedula,
          if (especialidad != null && especialidad.isNotEmpty)
            'especialidad': especialidad,
        },
      );
      return SolicitudResult.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) throw const SolicitudDuplicadaException();
      rethrow;
    }
  }

  /// GET /auth/mi-solicitud — devuelve null si el backend responde 404.
  Future<SolicitudResult?> getMiSolicitud() async {
    try {
      final response = await _dio.get('$kBaseUrlAuth/auth/mi-solicitud');
      return SolicitudResult.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  /// PATCH /auth/upgrade-plan — sube de plan (usuario -> enfermera -> medico,
  /// nunca baja), devuelve un JWT nuevo con el tipo actualizado. Sin trigger
  /// de UI todavía: ningún flujo actual lo dispara, queda listo para cuando
  /// se defina dónde debe vivir (ej. tras aprobación de la solicitud premium).
  Future<AuthModel> upgradePlan({
    required String nuevoTipo,
    bool cedulaVerificada = false,
  }) async {
    final response = await _dio.patch(
      '$kBaseUrlAuth/auth/upgrade-plan',
      data: {
        'nuevo_tipo': nuevoTipo,
        'cedula_verificada': cedulaVerificada,
      },
    );
    return AuthModel.fromJson(response.data as Map<String, dynamic>);
  }
}
