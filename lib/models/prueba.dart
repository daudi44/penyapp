// lib/models/prueba.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Prueba {
  final String id;
  final String nombre;
  final String descripcion;
  final String categoria;
  final int puntuacionMaxima;
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
    required this.puntuacionMaxima,
    required this.valoracion,
    required this.unidadMedida,
    required this.orden,
    this.lugar,
    this.horario,
  });

  factory Prueba.fromFirestore(Map<String, dynamic> data, String id) {
    final rawHorario = data['horario']; // asegúrate que se llama 'horari'

    DateTime? parsedHorario;
    if (rawHorario is Timestamp) {
      parsedHorario = rawHorario.toDate();
    } else if (rawHorario is String) {
      try {
        parsedHorario = DateTime.parse(rawHorario);
      } catch (_) {
        parsedHorario = null;
      }
    }

    return Prueba(
      id: id,
      nombre: data['nombre'] ?? 'Sense nom',
      descripcion: data['descripcio'] ?? '',
      categoria: data['categoria'] ?? 'Sense categoria',
      puntuacionMaxima: data['puntuacionMaxima'] ?? 0,
      valoracion: data['valoracion'] ?? '',
      unidadMedida: data['unidadMedida'] ?? '',
      orden: data['orden'] ?? 0,
      lugar: data['lugar'],
      horario: parsedHorario,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nom': nombre,
      'descripcio': descripcion,
      'categoria': categoria,
      'puntuacioMaxima': puntuacionMaxima,
      'valoracio': valoracion,
      'unitatMesura': unidadMedida,
      'ordre': orden,
      'lloc': lugar,
      'horari': horario != null ? Timestamp.fromDate(horario!) : null,
    };
  }
}
