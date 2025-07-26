// lib/models/resultado.dart
class Resultado {
  final String id;
  final String idGrupo;
  final String idPrueba;
  final int posicion; // <--- ¡CAMBIADO de puntosObtenidos a posicion!

  Resultado({
    required this.id,
    required this.idGrupo,
    required this.idPrueba,
    required this.posicion,
  });

  factory Resultado.fromFirestore(Map<String, dynamic> data, String id) {
    return Resultado(
      id: id,
      idGrupo: data['idGrupo'] ?? '',
      idPrueba: data['idPrueba'] ?? '',
      posicion: (data['posicion'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {'idGrupo': idGrupo, 'idPrueba': idPrueba, 'posicion': posicion};
  }

  int calcularPuntos(String categoriaPrueba) {
    if (posicion == 0) return 0; // Si no hay posición (ej. no participó)

    switch (categoriaPrueba) {
      case 'negra':
        if (posicion == 1) return 10;
        if (posicion == 2) return 8;
        if (posicion == 3) return 6;
        if (posicion == 4) return 4;
        if (posicion == 5) return 2;
        return 1; // 6ta en adelante por participar
      case 'roja':
        if (posicion == 1) return 6;
        if (posicion == 2) return 4;
        if (posicion == 3) return 2;
        return 1; // 4ta en adelante por participar
      case 'azul':
        if (posicion == 1) return 3;
        if (posicion == 2) return 2;
        return 1; // 3er en adelante por participar
      default:
        return 0; // Categoría desconocida o por defecto 0 puntos
    }
  }
}
