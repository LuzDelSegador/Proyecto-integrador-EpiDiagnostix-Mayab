// DI container for the admin web panel.
// Intentionally does NOT import tflite_flutter or sqflite — those packages
// don't compile for web. Only registers services needed by the admin UI.
import 'package:get_it/get_it.dart';

import '../network/dio_client.dart';
import '../services/token_storage.dart';
import '../../features/admin/data/admin_datasource.dart';
import '../../features/admin/providers/admin_provider.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/i_auth_repository.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/register_usecase.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

final sl = GetIt.instance;

Future<void> initAdmin() async {
  // ── Core ──────────────────────────────────────────────────────────
  sl.registerLazySingleton(() => TokenStorage());
  sl.registerLazySingleton(() => DioClient(sl()).dio);

  // ── Data Sources ──────────────────────────────────────────────────
  sl.registerLazySingleton<IAuthRemoteDataSource>(
    () => AuthRemoteDataSource(sl()),
  );

  // ── Repositories ──────────────────────────────────────────────────
  sl.registerLazySingleton<IAuthRepository>(
    () => AuthRepositoryImpl(sl()),
  );

  // ── Use Cases ─────────────────────────────────────────────────────
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => RegisterUseCase(sl()));

  // ── Admin Data Source ─────────────────────────────────────────────
  sl.registerLazySingleton(() => AdminDataSource(sl()));

  // ── Providers (factory = new instance per request) ─────────────────
  sl.registerFactory(() => AuthProvider(sl(), sl(), sl()));
  sl.registerFactory(() => AdminProvider(sl(), sl()));
}
