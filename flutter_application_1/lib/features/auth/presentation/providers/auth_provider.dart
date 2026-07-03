import 'package:flutter/foundation.dart';
import '../../../../core/constants/user_roles.dart';
import '../../../../core/errors/app_exceptions.dart';
import '../../../../core/services/token_storage.dart';
import '../../domain/entities/auth_entity.dart';
import '../../domain/usecases/login_usecase.dart';

enum AuthStatus { initial, loading, success, error }

class AuthProvider extends ChangeNotifier {
  final LoginUseCase _loginUseCase;
  final TokenStorage _tokenStorage;

  AuthProvider(this._loginUseCase, this._tokenStorage);

  AuthStatus _status = AuthStatus.initial;
  AuthEntity _currentUser = const AuthEntity.empty();
  String? _errorMessage;

  AuthStatus get status      => _status;
  AuthEntity get currentUser => _currentUser;
  String?    get errorMessage => _errorMessage;
  UserRole   get currentRole => _currentUser.userRole;

  Future<void> login({
    required String identifier,
    required String password,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _loginUseCase(
        identifier: identifier,
        password:   password,
      );
      await _tokenStorage.setToken(_currentUser.token);
      await _tokenStorage.setUserData(
        personalId:     _currentUser.userId,
        nombreCompleto: _currentUser.name,
        tipo:           _currentUser.role,
      );
      _status = AuthStatus.success;
    } on UnauthorizedException catch (e) {
      _errorMessage = e.toString();
      _status = AuthStatus.error;
    } on NetworkException catch (e) {
      _errorMessage = e.toString();
      _status = AuthStatus.error;
    } on ServerException catch (e) {
      _errorMessage = e.toString();
      _status = AuthStatus.error;
    } catch (_) {
      _errorMessage = 'Error inesperado. Intente nuevamente.';
      _status = AuthStatus.error;
    }

    notifyListeners();
  }

  // TODO: cuando el backend exponga POST /auth/register (público, sin token),
  // crear RegisterUseCase → AuthRepositoryImpl.register() → AuthRemoteDataSource.register()
  // con body { "nombre_completo": nombre, "correo": correo, "contrasena": password, "tipo": "usuario" }
  // y respuesta { access_token, personal_id, nombre_completo, tipo }.
  // Reemplazar el bloque local de abajo por: _currentUser = await _registerUseCase(...);
  Future<void> register({
    required String nombre,
    required String correo,
    required String password,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = 'local_${DateTime.now().millisecondsSinceEpoch}';
      _currentUser = AuthEntity(
        token: token,
        userId: correo,
        name: nombre,
        role: 'usuario',
      );
      await _tokenStorage.setToken(token);
      await _tokenStorage.setUserData(
        personalId: correo,
        nombreCompleto: nombre,
        tipo: 'usuario',
      );
      _status = AuthStatus.success;
    } catch (_) {
      _errorMessage = 'Error al crear la cuenta. Intente nuevamente.';
      _status = AuthStatus.error;
    }

    notifyListeners();
  }

  Future<void> logout() async {
    await _tokenStorage.clearToken();
    _currentUser = const AuthEntity.empty();
    _status = AuthStatus.initial;
    _errorMessage = null;
    notifyListeners();
  }

  void resetStatus() {
    _status = AuthStatus.initial;
    _errorMessage = null;
    notifyListeners();
  }
}
