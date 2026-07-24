import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_config.dart';
import 'core/constants/app_theme.dart';
import 'core/di/injection_container.dart' as di;
import 'core/services/token_storage.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/dashboard/presentation/pages/dashboard_page.dart';
import 'features/sync/data/sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // .env no está presente (ej. instalación limpia sin claves de IA
    // configuradas) — las funciones de LLM quedan deshabilitadas, el resto
    // de la app sigue funcionando con normalidad.
  }
  Stripe.publishableKey = kStripePublishableKey;
  // applySettings() es opcional: Stripe aplica la clave de forma lazy en el
  // primer uso del PaymentSheet. No llamarla aquí evita bloquear el arranque
  // cuando la clave es un placeholder en desarrollo.
  await di.init();
  await di.sl.allReady();
  // Precarga el token en _cachedToken para que el interceptor Dio lo lea.
  final startWithDashboard = await di.sl<TokenStorage>().hasToken();
  runApp(EpiDiagnostixMayabApp(startWithDashboard: startWithDashboard));
}

class EpiDiagnostixMayabApp extends StatefulWidget {
  final bool startWithDashboard;

  const EpiDiagnostixMayabApp({super.key, required this.startWithDashboard});

  @override
  State<EpiDiagnostixMayabApp> createState() => _EpiDiagnostixMayabAppState();
}

class _EpiDiagnostixMayabAppState extends State<EpiDiagnostixMayabApp> {
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  @override
  void initState() {
    super.initState();
    // Al recuperar conexión, empuja lo pendiente del outbox local a MS1/MS2
    // en segundo plano — mismo patrón fire-and-forget que el resto del sync.
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) async {
      if (results.every((r) => r == ConnectivityResult.none)) return;
      if (!await di.sl<TokenStorage>().hasToken()) return;
      di.sl<SyncService>().syncAll().catchError((_) => const SyncResumen());
    });
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => di.sl<AuthProvider>(),
      child: MaterialApp(
        title: 'EpiDiagnostix-Mayab',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        home: widget.startWithDashboard ? DashboardPage() : LoginPage(),
      ),
    );
  }
}
