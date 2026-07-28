import 'package:flutter/material.dart';

/// Clave global para MaterialApp.scaffoldMessengerKey. Permite mostrar un
/// SnackBar desde un sync fire-and-forget (patient_registration_page,
/// audio_confirmation_page, el listener de conectividad en main.dart) sin
/// depender de un BuildContext que puede haber quedado atrás tras una
/// navegación mientras la petición HTTP seguía en curso.
final rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
