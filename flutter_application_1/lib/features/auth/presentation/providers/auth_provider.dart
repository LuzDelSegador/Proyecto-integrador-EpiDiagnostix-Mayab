import 'package:flutter/foundation.dart';
import '../../../../core/constants/user_roles.dart';
import '../../../../core/errors/app_exceptions.dart';
import '../../../../core/services/token_storage.dart';
import '../../domain/entities/auth_entity.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/register_usecase.dart';

enum AuthStatus { initial, loading, success, error }

class AuthProvider extends ChangeNotifier {
  final LoginUseCase _loginUseCase;
  final TokenStorage _tokenStorage;
  final RegisterUseCase _registerUseCase;

  AuthProvider(this._loginUseCase, this._tokenStorage, this._registerUseCase);

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
      await _tokenStorage.setCorreo(identifier);
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

  Future<void> register({
    required String nombre,
    required String correo,
    required String password,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _registerUseCase(
        nombreCompleto: nombre,
        correo:         correo,
        contrasena:     password,
      );
      await _tokenStorage.setToken(_currentUser.token);
      await _tokenStorage.setUserData(
        personalId:     _currentUser.userId,
        nombreCompleto: _currentUser.name,
        tipo:           _currentUser.role,
      );
      await _tokenStorage.setCorreo(correo);
      _status = AuthStatus.success;
    } on ConflictException catch (e) {
      _errorMessage = e.toString();
      _status = AuthStatus.error;
    } on ValidationException catch (e) {
      _errorMessage = e.toString();
      _status = AuthStatus.error;
    } on NetworkException {
      _errorMessage = 'No hay conexión. Verifica tu internet e intenta de nuevo.';
      _status = AuthStatus.error;
    } catch (_) {
      _errorMessage = 'Error al crear la cuenta. Intenta de nuevo.';
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
