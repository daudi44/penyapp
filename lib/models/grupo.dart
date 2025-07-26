class Grupo {
  final String id;
  final String nombre;
  final String? descripcion;
  final String? logoUrl;
  int puntuacionTotal;

  Grupo({
    required this.id,
    required this.nombre,
    this.descripcion,
    this.logoUrl,
    this.puntuacionTotal = 0,
  });

  factory Grupo.fromFirestore(Map<String, dynamic> data, String id) {
    return Grupo(
      id: id,
      nombre: data['nombre'] ?? 'Sense nom',
      descripcion: data['descripcion'],
      logoUrl: data['logoUrl'],
      puntuacionTotal: (data['puntuacionTotal'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nombre': nombre,
      'descripcion': descripcion,
      'logoUrl': logoUrl,
      'puntuacionTotal': puntuacionTotal,
    };
  }
}
