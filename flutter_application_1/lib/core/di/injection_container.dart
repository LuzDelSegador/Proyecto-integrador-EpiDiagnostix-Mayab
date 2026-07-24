import 'package:get_it/get_it.dart';
import '../network/dio_client.dart';
import '../services/token_storage.dart';
import '../services/tflite_extractor.dart';
import '../services/device_id_service.dart';
import '../services/llm_normalization_service.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/i_auth_repository.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/register_usecase.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/patients/data/datasources/paciente_remote_datasource.dart';
import '../../features/patients/data/datasources/personal_remote_datasource.dart';
import '../../features/patients/data/repositories/patient_local_repository.dart';
import '../../features/attentions/data/datasources/atencion_remote_datasource.dart';
import '../../features/anomalies/data/anomaly_service.dart';
import '../../features/patients/data/patient_history_summary_service.dart';
import '../../features/plans/data/plan_service.dart';
import '../../features/sync/data/sync_service.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // ── Presentation ──────────────────────────────────────────────
  sl.registerFactory(() => AuthProvider(sl(), sl(), sl()));

  // ── Use Cases ─────────────────────────────────────────────────
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => RegisterUseCase(sl()));

  // ── Repositories ──────────────────────────────────────────────
  sl.registerLazySingleton<IAuthRepository>(
    () => AuthRepositoryImpl(sl()),
  );
  sl.registerLazySingleton(() => PatientLocalRepository());
  sl.registerLazySingleton(() => AnomalyService(sl()));
  sl.registerLazySingleton(() => PlanService(sl()));
  sl.registerLazySingleton(() => SyncService(sl(), sl(), sl(), sl()));

  // ── Data Sources ──────────────────────────────────────────────
  sl.registerLazySingleton<IAuthRemoteDataSource>(
    () => AuthRemoteDataSource(sl()),
  );
  sl.registerLazySingleton(() => PacienteRemoteDataSource(sl()));
  sl.registerLazySingleton(() => PersonalRemoteDataSource(sl()));
  sl.registerLazySingleton(() => AtencionRemoteDataSource(sl()));

  // ── Core ──────────────────────────────────────────────────────
  sl.registerLazySingleton(() => DioClient(sl()).dio);
  sl.registerLazySingleton(() => TokenStorage());
  sl.registerLazySingleton(() => DeviceIdService());

  // ── AI Services ───────────────────────────────────────────────
  sl.registerSingletonAsync<NerExtractor>(
    () => NerExtractor.fromAssets(
      modelAsset:  'assets/model/ner_tflite_v2.tflite',
      vocabAsset:  'assets/model/tflite_vocab_v2.json',
      labelsAsset: 'assets/model/tflite_labels_v2.json',
    ),
  );
  sl.registerLazySingleton(() => LlmNormalizationService());
  sl.registerLazySingleton(() => PatientHistorySummaryService());
}
