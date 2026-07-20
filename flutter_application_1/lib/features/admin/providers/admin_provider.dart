import 'package:flutter/foundation.dart';
import '../data/admin_datasource.dart';
import '../data/admin_models.dart';
import '../../../core/services/token_storage.dart';

class AdminProvider extends ChangeNotifier {
  final AdminDataSource _ds;
  final TokenStorage _tokenStorage;

  AdminProvider(this._ds, this._tokenStorage);

  // ── Admin identity ──────────────────────────────────────────────
  String adminName = 'Administrador';

  Future<void> loadAdminName() async {
    final stored = await _tokenStorage.getNombre();
    if (stored != null && stored.isNotEmpty) {
      adminName = stored;
      notifyListeners();
    }
  }

  // ── Stats ────────────────────────────────────────────────────────
  StatsModel? stats;
  bool loadingStats = false;
  String? statsError;

  Future<void> loadStats() async {
    loadingStats = true;
    statsError = null;
    notifyListeners();
    try {
      stats = await _ds.getEstadisticas();
    } catch (_) {
      statsError = 'Error al cargar estadísticas. Verifica la conexión.';
    } finally {
      loadingStats = false;
      notifyListeners();
    }
  }

  // ── Solicitudes ──────────────────────────────────────────────────
  List<SolicitudAdminModel> solicitudes = [];
  bool loadingSolicitudes = false;
  String? solicitudesError;

  Future<void> loadSolicitudes(String estado) async {
    loadingSolicitudes = true;
    solicitudesError = null;
    notifyListeners();
    try {
      solicitudes = await _ds.getSolicitudes(estado);
    } catch (_) {
      solicitudesError = 'Error al cargar solicitudes.';
    } finally {
      loadingSolicitudes = false;
      notifyListeners();
    }
  }

  // Throws on API error so the UI can show a snackbar.
  Future<void> aprobarSolicitud(String id, String estadoActual) async {
    await _ds.aprobarSolicitud(id);
    await loadSolicitudes(estadoActual);
    await loadStats();
  }

  Future<void> rechazarSolicitud(
      String id, String motivo, String estadoActual) async {
    await _ds.rechazarSolicitud(id, motivo);
    await loadSolicitudes(estadoActual);
    await loadStats();
  }

  // ── Usuarios ─────────────────────────────────────────────────────
  List<UsuarioAdminModel> usuarios = [];
  bool loadingUsuarios = false;
  String? usuariosError;
  String? tipoFilter;

  Future<void> loadUsuarios([String? tipo]) async {
    tipoFilter = tipo;
    loadingUsuarios = true;
    usuariosError = null;
    notifyListeners();
    try {
      usuarios = await _ds.getUsuarios(tipo);
    } catch (_) {
      usuariosError = 'Error al cargar usuarios.';
    } finally {
      loadingUsuarios = false;
      notifyListeners();
    }
  }

  // ── Logout ───────────────────────────────────────────────────────
  Future<void> logout() async {
    await _tokenStorage.clearToken();
    adminName = 'Administrador';
    stats = null;
    solicitudes = [];
    usuarios = [];
    notifyListeners();
  }
}
