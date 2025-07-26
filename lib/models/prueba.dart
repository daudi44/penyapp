// lib/models/prueba.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Prueba {
  final String id;
  final String nombre;
  final DateTime horario;
  final String lugar;
  final int puntosMaximos;
  final int orden;
  final String categoria;

  Prueba({
    required this.id,
    required this.nombre,
    required this.horario,
    required this.lugar,
    required this.puntosMaximos,
    required this.orden,
    required this.categoria,
  });

  factory Prueba.fromFirestore(Map<String, dynamic> data, String id) {
    return Prueba(
      id: id,
      nombre: data['nombre'] ?? 'Prova sense nom',
      horario: (data['horario'] as Timestamp).toDate(),
      lugar: data['lugar'] ?? 'Lloc desconegut',
      puntosMaximos: (data['puntosMaximos'] as num?)?.toInt() ?? 0,
      orden: (data['orden'] as num?)?.toInt() ?? 999,
      categoria: data['categoria'] ?? 'azul',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nombre': nombre,
      'horario': Timestamp.fromDate(horario),
      'lugar': lugar,
      'puntosMaximos': puntosMaximos,
      'orden': orden,
      'categoria': categoria,
    };
  }
}
