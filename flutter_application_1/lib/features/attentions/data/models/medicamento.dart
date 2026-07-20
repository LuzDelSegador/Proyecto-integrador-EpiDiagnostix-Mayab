class Medicamento {
  final String nombre;
  final String? dosis;
  final String? frecuencia;
  final String? duracion;

  const Medicamento({
    required this.nombre,
    this.dosis,
    this.frecuencia,
    this.duracion,
  });

  factory Medicamento.fromJson(Map<String, dynamic> json) => Medicamento(
        nombre:     json['nombre'] as String? ?? '',
        dosis:      json['dosis'] as String?,
        frecuencia: json['frecuencia'] as String?,
        duracion:   json['duracion'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'nombre':     nombre,
        'dosis':      dosis,
        'frecuencia': frecuencia,
        'duracion':   duracion,
      };
}
