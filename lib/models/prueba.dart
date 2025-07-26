// lib/models/prueba.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Prueba {
  final String id;
  final String nombre;
  final String descripcion;
  final String categoria;
  final int puntosMaximos;
  final String valoracion;
  final String unidadMedida;
  final int orden;

  final String? lugar;
  final DateTime? horario;

  Prueba({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.categoria,
    required this.puntosMaximos,
    required this.valoracion,
    required this.unidadMedida,
    required this.orden,
    this.lugar,
    this.horario,
  });

  factory Prueba.fromFirestore(Map<String, dynamic> data, String id) {
    return Prueba(
      id: id,
      nombre: data['nombre'] ?? 'Sense nom',
      lugar: data['lugar'] ?? 'Sense lloc',
      categoria: data['categoria'] ?? 'Sense categoria',
      puntosMaximos: data['puntosMaximos'] ?? 0,
      orden: data['orden'] ?? 0,
      descripcion: data['descripcion'] ?? '',
      valoracion: data['valoracion'] ?? 'Sense valoració',
      unidadMedida: data['unidadMedida'] ?? 'Sense unitat',
      horario: data['horario'] != null ? (data['horario'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nombre': nombre,
      'descripcion': descripcion,
      'categoria': categoria,
      'puntosMaximos': puntosMaximos,
      'valoracion': valoracion,
      'unidadMedida': unidadMedida,
      'orden': orden,
      'lugar': lugar,
      'horario': null,
    };
  }
}
