import 'package:dio/dio.dart';
import '../services/token_storage.dart';

class DioClient {
  late final Dio dio;

  DioClient(TokenStorage tokenStorage) {
    dio = Dio(
      BaseOptions(
        // Render free tier duerme el servicio tras inactividad: el primer
        // request tras un cold-start puede tardar ~20-30s en responder.
        connectTimeout: const Duration(seconds: 40),
        receiveTimeout: const Duration(seconds: 40),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.addAll([
      _TokenInterceptor(tokenStorage),
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (o) => debugPrint(o.toString()),
      ),
    ]);
  }
}

class _TokenInterceptor extends Interceptor {
  final TokenStorage _tokenStorage;

  _TokenInterceptor(this._tokenStorage);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Lee el caché en memoria (síncrono) — se carga en app start via hasToken().
    final token = _tokenStorage.token;
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      // Fire-and-forget: _cachedToken se limpia sincrónicamente al inicio
      // de clearToken() antes del primer await.
      _tokenStorage.clearToken();
    }
    handler.next(err);
  }
}

void debugPrint(String message) {
  // ignore: avoid_print
  print('[DioClient] $message');
}
