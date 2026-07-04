import 'package:dio/dio.dart';
import 'admin_models.dart';

class AdminDataSource {
  final Dio _dio;

  const AdminDataSource(this._dio);

  Future<StatsModel> getEstadisticas() async {
    final res = await _dio.get('/admin/estadisticas');
    return StatsModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<SolicitudAdminModel>> getSolicitudes(String estado) async {
    final res = await _dio.get(
      '/admin/solicitudes',
      queryParameters: {'estado': estado},
    );
    return (res.data as List)
        .map((e) => SolicitudAdminModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> aprobarSolicitud(String id) async {
    await _dio.patch('/admin/solicitudes/$id/aprobar');
  }

  Future<void> rechazarSolicitud(String id, String motivo) async {
    await _dio.patch(
      '/admin/solicitudes/$id/rechazar',
      data: {'motivo_rechazo': motivo},
    );
  }

  Future<List<UsuarioAdminModel>> getUsuarios(String? tipo) async {
    final res = await _dio.get(
      '/admin/usuarios',
      queryParameters: tipo != null ? {'tipo': tipo} : null,
    );
    return (res.data as List)
        .map((e) => UsuarioAdminModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
