enum UserRole { usuario, enfermera, medico }

extension UserRoleExtension on UserRole {
  static UserRole fromString(String s) {
    switch (s) {
      case 'medico':
        return UserRole.medico;
      case 'enfermera':
        return UserRole.enfermera;
      default:
        return UserRole.usuario;
    }
  }

  bool get puedeVerMapa      => this == UserRole.medico;
  bool get puedeVerAnomaliasML => this != UserRole.usuario;
  bool get tieneIA           => this != UserRole.usuario;
  bool get esIlimitado       => this != UserRole.usuario;
  bool get mostrarPlanes     => this != UserRole.medico;
}
