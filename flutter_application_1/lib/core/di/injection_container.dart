import 'package:get_it/get_it.dart';
import '../network/dio_client.dart';
import '../services/token_storage.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/i_auth_repository.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // ── Presentation ──────────────────────────────────────────────
  sl.registerFactory(() => AuthProvider(sl(), sl()));

  // ── Use Cases ─────────────────────────────────────────────────
  sl.registerLazySingleton(() => LoginUseCase(sl()));

  // ── Repositories ──────────────────────────────────────────────
  sl.registerLazySingleton<IAuthRepository>(
    () => AuthRepositoryImpl(sl()),
  );

  // ── Data Sources ──────────────────────────────────────────────
  sl.registerLazySingleton<IAuthRemoteDataSource>(
    () => AuthRemoteDataSource(sl()),
  );

  // ── Core ──────────────────────────────────────────────────────
  sl.registerLazySingleton(() => DioClient(sl()).dio);
  sl.registerLazySingleton(() => TokenStorage());
}
