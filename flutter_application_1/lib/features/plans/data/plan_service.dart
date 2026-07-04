import 'package:dio/dio.dart';

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
        '/auth/solicitar-premium',
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
      final response = await _dio.get('/auth/mi-solicitud');
      return SolicitudResult.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }
}
