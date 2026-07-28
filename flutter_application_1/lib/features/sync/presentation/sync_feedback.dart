import 'package:flutter/material.dart';
import '../data/sync_service.dart';

/// Muestra un SnackBar breve cuando un sync automático (fire-and-forget)
/// deja pacientes rechazados por el backend (ej. CURP inválido). No dice
/// nada si todo salió bien o si el único problema fue de red/timeout —
/// eso se reintenta solo y no necesita interrumpir al usuario.
void mostrarResultadoSyncSiHayError(
  SyncResumen resumen,
  GlobalKey<ScaffoldMessengerState> messengerKey,
) {
  if (resumen.pacientesConError <= 0) return;

  final detalle = resumen.primerErrorPaciente == null
      ? null
      : _acortarMensaje(resumen.primerErrorPaciente!);

  final texto = resumen.pacientesConError == 1
      ? 'No se pudo sincronizar 1 paciente${detalle != null ? ': $detalle' : ''} — revísalo en Casos.'
      : 'No se pudieron sincronizar ${resumen.pacientesConError} pacientes — revísalos en Casos.';

  messengerKey.currentState?.showSnackBar(
    SnackBar(
      content: Text(texto),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 4),
    ),
  );
}

String _acortarMensaje(String mensaje) {
  var m = mensaje.trim();
  if (m.toLowerCase().startsWith('error:')) m = m.substring(6).trim();
  return m.length > 80 ? '${m.substring(0, 80)}…' : m;
}
