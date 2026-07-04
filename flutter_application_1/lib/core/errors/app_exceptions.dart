class ServerException implements Exception {
  final String message;
  const ServerException(this.message);

  @override
  String toString() => message;
}

class NetworkException implements Exception {
  const NetworkException();

  @override
  String toString() => 'Sin conexión a internet. Verifique su red.';
}

class UnauthorizedException implements Exception {
  const UnauthorizedException();

  @override
  String toString() => 'Credenciales incorrectas. Verifique su identificación y contraseña.';
}

class ConflictException implements Exception {
  const ConflictException();

  @override
  String toString() => 'Este correo ya está registrado. Intenta con otro.';
}

class ValidationException implements Exception {
  const ValidationException();

  @override
  String toString() => 'Datos inválidos. Verifica los campos.';
}
