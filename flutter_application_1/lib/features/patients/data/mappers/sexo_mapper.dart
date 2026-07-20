/// Traduce el código de sexo del paciente (identidad, MS1) desde/hacia la UI.
///
/// MS1 usa 'H' (Hombre) según especificación del backend, explícitamente
/// distinto de 'M' de "Masculino". Se asume 'M' = Mujer por convención
/// estándar en español — el backend no valida el enum (confirmado con
/// curl: acepta cualquier string), así que esta es la única fuente de
/// verdad sobre el mapeo y el único lugar a corregir si el backend real
/// espera otra letra para "mujer".
const kSexoHombre = 'H';
const kSexoMujer  = 'M';

String sexoLabel(String? codigo) {
  switch (codigo) {
    case kSexoHombre:
      return 'Hombre';
    case kSexoMujer:
      return 'Mujer';
    default:
      return '';
  }
}
