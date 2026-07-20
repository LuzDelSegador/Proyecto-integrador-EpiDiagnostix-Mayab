import 'dart:convert';

import '../../../core/services/device_id_service.dart';
import '../../attentions/data/datasources/atencion_remote_datasource.dart';
import '../../attentions/data/mappers/atencion_payload_mapper.dart';
import '../../attentions/data/models/atencion_model.dart';
import '../../attentions/data/models/medicamento.dart';
import '../../patients/data/datasources/paciente_remote_datasource.dart';
import '../../patients/data/mappers/sexo_mapper.dart';
import '../../patients/data/models/paciente.dart';
import '../../patients/data/models/paciente_remote_model.dart';
import '../../patients/data/repositories/patient_local_repository.dart';

class SyncResumen {
  final int pacientesSincronizados;
  final int atencionesSincronizadas;
  final bool huboError;

  const SyncResumen({
    this.pacientesSincronizados = 0,
    this.atencionesSincronizadas = 0,
    this.huboError = false,
  });
}

/// Outbox pusher: SQLite sigue siendo la fuente de verdad inmediata; este
/// servicio solo empuja lo pendiente (sincronizado = 0) a MS1/MS2 en segundo
/// plano. Los pacientes se sincronizan primero porque MS2 necesita el
/// paciente_id real del backend para poder crear sus atenciones.
class SyncService {
  final PatientLocalRepository _localRepo;
  final PacienteRemoteDataSource _pacienteDs;
  final AtencionRemoteDataSource _atencionDs;
  final DeviceIdService _deviceId;

  SyncService(this._localRepo, this._pacienteDs, this._atencionDs, this._deviceId);

  bool _syncing = false;

  Future<SyncResumen> syncAll() async {
    if (_syncing) return const SyncResumen();
    _syncing = true;
    try {
      final pacientesOk = await _syncPacientesPendientes();
      final atencionesOk = await _syncAtencionesPendientes();
      return SyncResumen(
        pacientesSincronizados: pacientesOk.cantidad,
        atencionesSincronizadas: atencionesOk.cantidad,
        huboError: pacientesOk.huboError || atencionesOk.huboError,
      );
    } finally {
      _syncing = false;
    }
  }

  Future<_Resultado> _syncPacientesPendientes() async {
    final pendientes = await _localRepo.getPacientesPendientesSync();
    if (pendientes.isEmpty) return const _Resultado(0, false);

    // El backend valida el body completo antes de procesar nada: un solo
    // registro incompleto invalida el lote entero, así que se filtran aquí.
    final listos = pendientes.where(_pacienteListoParaSync).toList();
    if (listos.isEmpty) return const _Resultado(0, false);

    final dispositivoId = await _deviceId.getDeviceId();
    final payloads = listos
        .map((p) => PacienteCreatePayload(
              curp: p.curp!,
              nombreCompleto: p.nombreCompleto,
              fechaNacimiento: p.fechaNacimiento!,
              sexo: p.sexo ?? kSexoHombre,
              comunidad: (p.comunidad == null || p.comunidad!.isEmpty) ? p.municipio! : p.comunidad!,
              municipio: p.municipio!,
              lenguaMaterna: p.lenguaMaterna,
              contactoEmergencia: p.contactoEmergencia,
              deviceGeneratedId: p.id,
            ))
        .toList();

    try {
      final resultados = await _pacienteDs.sync(
        dispositivoId: dispositivoId,
        pacientes: payloads,
      );
      for (final r in resultados) {
        await _localRepo.marcarPacienteSincronizado(r.deviceGeneratedId, r.idServidor);
      }
      return _Resultado(resultados.length, false);
    } catch (_) {
      // Sin red, cold-start, o 422 de validación — se reintenta en el
      // próximo trigger (conexión recuperada / botón manual / próximo guardado).
      return const _Resultado(0, true);
    }
  }

  bool _pacienteListoParaSync(Paciente p) =>
      p.curp != null &&
      p.curp!.length >= 18 &&
      p.fechaNacimiento != null &&
      p.municipio != null &&
      p.municipio!.isNotEmpty;

  Future<_Resultado> _syncAtencionesPendientes() async {
    final rows = await _localRepo.getConsultasPendientesSync();
    if (rows.isEmpty) return const _Resultado(0, false);

    final dispositivoId = await _deviceId.getDeviceId();
    final payloads = <AtencionCreatePayload>[];

    for (final r in rows) {
      Map<String, dynamic> campos;
      try {
        campos = jsonDecode(r['campos_extraidos'] as String) as Map<String, dynamic>;
      } catch (_) {
        campos = {};
      }
      final personalId = campos['personal_id'] as String? ?? '';
      final municipio = campos['municipio'] as String? ?? campos['comunidad'] as String? ?? '';
      final comunidad = campos['comunidad'] as String? ?? municipio;
      // Requeridos por MS2 — si faltan, se omite este registro (el resto del
      // lote no debe bloquearse por uno incompleto).
      if (personalId.isEmpty || municipio.isEmpty) continue;

      final medicamentosRaw = campos['medicamentos'] as List<dynamic>? ?? [];
      final medicamentos = medicamentosRaw
          .map((m) => Medicamento.fromJson(m as Map<String, dynamic>))
          .toList();

      payloads.add(AtencionPayloadMapper.fromCamposExtraidos(
        campos: campos,
        pacienteId: r['paciente_remote_id'] as String,
        personalId: personalId,
        comunidad: comunidad,
        municipio: municipio,
        deviceGeneratedId: r['id'] as String,
        fechaAtencion: DateTime.parse(r['fecha_captura'] as String),
        motivoConsulta: campos['motivo_consulta'] as String?,
        diagnosticoDescripcion: campos['diagnostico_descripcion'] as String?,
        saturacionOxigeno: campos['saturacion_oxigeno'] as int?,
        medicamentos: medicamentos,
        evidenciaRecetaBase64: campos['evidencia_receta_base64'] as String?,
      ));
    }
    if (payloads.isEmpty) return const _Resultado(0, false);

    try {
      final resultados = await _atencionDs.sync(
        dispositivoId: dispositivoId,
        atenciones: payloads,
      );
      for (final res in resultados) {
        await _localRepo.marcarConsultaSincronizada(res.deviceGeneratedId, res.idServidor);
      }
      return _Resultado(resultados.length, false);
    } catch (_) {
      return const _Resultado(0, true);
    }
  }
}

class _Resultado {
  final int cantidad;
  final bool huboError;
  const _Resultado(this.cantidad, this.huboError);
}
