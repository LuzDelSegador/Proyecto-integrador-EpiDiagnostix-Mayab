import 'package:flutter/foundation.dart';
// ignore: unused_import — se activa cuando el backend esté listo
import '../../../../core/errors/app_exceptions.dart';
import '../../../../core/services/token_storage.dart';
import '../../domain/entities/auth_entity.dart';
import '../../domain/usecases/login_usecase.dart';

enum AuthStatus { initial, loading, success, error }

class AuthProvider extends ChangeNotifier {
  // ignore: unused_field — se activa cuando el backend esté listo
  final LoginUseCase _loginUseCase;
  final TokenStorage _tokenStorage;

  AuthProvider(this._loginUseCase, this._tokenStorage);

  AuthStatus _status = AuthStatus.initial;
  // Constructor nombrado .empty() = estado no autenticado
  AuthEntity _currentUser = const AuthEntity.empty();
  String? _errorMessage;

  AuthStatus get status => _status;
  AuthEntity get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;

  Future<void> login({
    required String identifier,
    required String password,
    required bool rememberSession,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    // TODO: cuando el backend esté listo, reemplazar este bloque por la llamada real:
    //
    // try {
    //   _currentUser = await _loginUseCase(
    //     identifier: identifier,
    //     password: password,
    //     rememberSession: rememberSession,
    //   );
    //   _tokenStorage.setToken(_currentUser.token);
    //   _status = AuthStatus.success;
    // } on UnauthorizedException catch (e) {
    //   _errorMessage = e.toString();
    //   _status = AuthStatus.error;
    // } on NetworkException catch (e) {
    //   _errorMessage = e.toString();
    //   _status = AuthStatus.error;
    // } on ServerException catch (e) {
    //   _errorMessage = e.toString();
    //   _status = AuthStatus.error;
    // } catch (_) {
    //   _errorMessage = 'Error inesperado. Intente nuevamente.';
    //   _status = AuthStatus.error;
    // }

    await Future.delayed(const Duration(milliseconds: 600));
    // copyWith: partimos de empty() y solo modificamos los campos necesarios
    _currentUser = const AuthEntity.empty().copyWith(
      token: 'mock_token_dev',
      userId: 'USR-001',
      name: identifier.isNotEmpty ? identifier : 'Usuario',
      role: 'health_worker',
    );
    _tokenStorage.setToken(_currentUser.token);
    _status = AuthStatus.success;

    notifyListeners();
  }

  void resetStatus() {
    _status = AuthStatus.initial;
    _currentUser = const AuthEntity.empty();
    _errorMessage = null;
    notifyListeners();
  }
}
