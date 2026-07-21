import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_theme.dart';
import 'core/di/injection_container_admin.dart' as di;
import 'core/services/token_storage.dart';
import 'features/admin/providers/admin_provider.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/admin/pages/admin_login_page.dart';
import 'features/admin/pages/admin_shell_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.initAdmin();

  // Check for an existing admin session.
  final tokenStorage = di.sl<TokenStorage>();
  final hasToken = await tokenStorage.hasToken();
  final tipo = hasToken ? await tokenStorage.getTipo() : null;
  final startAsAdmin = hasToken && tipo == 'admin';

  runApp(AdminApp(startAsAdmin: startAsAdmin));
}

class AdminApp extends StatelessWidget {
  final bool startAsAdmin;

  const AdminApp({super.key, required this.startAsAdmin});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => di.sl<AuthProvider>()),
        ChangeNotifierProvider(create: (_) => di.sl<AdminProvider>()),
      ],
      child: MaterialApp(
        title: 'EpiDiagnostix Admin',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        home: startAsAdmin
            ? AdminShellPage()
            : AdminLoginPage(),
      ),
    );
  }
}
