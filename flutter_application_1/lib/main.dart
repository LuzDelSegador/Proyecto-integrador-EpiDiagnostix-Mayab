import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/di/injection_container.dart' as di;
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/providers/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init();
  runApp(const EpiSurveillanceApp());
}

class EpiSurveillanceApp extends StatelessWidget {
  const EpiSurveillanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => di.sl<AuthProvider>(),
      child: MaterialApp(
        title: 'EpiSurveillance',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1B6E52)),
          fontFamily: 'Roboto',
        ),
        home: const LoginPage(),
      ),
    );
  }
}
