import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/prueba.dart';
import 'detalle_prueba_screen.dart';

class PruebasScreen extends StatelessWidget {
  const PruebasScreen({super.key});

  Future<List<Prueba>> _cargarPruebas() async {
    final snapshot = await FirebaseFirestore.instance.collection('pruebas').get();
    return snapshot.docs.map((doc) => Prueba.fromFirestore(doc.data(), doc.id)).toList();
  }

  // Define los colores por categoría
  Map<String, List<Color>> _coloresPorCategoria(String categoria) {
    switch (categoria.toLowerCase()) {
      case 'negra':
        return {
          'gradient': [const Color(0xFF424242), const Color(0xFF212121)],
          'badge': [Colors.black],
        };
      case 'roja':
        return {
          'gradient': [const Color(0xFFEF5350), const Color(0xFFE53935)],
          'badge': [Colors.red.shade700],
        };
      case 'blava':
        return {
          'gradient': [const Color(0xFF64B5F6), const Color(0xFF1E88E5)],
          'badge': [Colors.blue.shade700],
        };
      default:
        return {
          'gradient': [const Color(0xFFA5D6A7), const Color(0xFF43A047)],
          'badge': [Colors.green.shade700],
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F3F8),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF8E24AA), Color(0xFF5E35B1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: const Text(
                'Llistat de Proves',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<List<Prueba>>(
                future: _cargarPruebas(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error carregant les proves, contacteu en @audidani: ${snapshot.error}',
                      ),
                    );
                  }

                  final pruebas = snapshot.data ?? [];
                  final pruebasOrdenadas = [...pruebas]..sort((a, b) => a.orden.compareTo(b.orden));

                  if (pruebasOrdenadas.isEmpty) {
                    return const Center(child: Text('Encara no hi ha proves.'));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    itemCount: pruebasOrdenadas.length,
                    itemBuilder: (context, index) {
                      final prueba = pruebasOrdenadas[index];
                      final colores = _coloresPorCategoria(prueba.categoria);
                      final gradient = colores['gradient']!;
                      final badgeColor = colores['badge']!.first;

                      final horaFormateada = prueba.horario != null
                          ? DateFormat('dd/MM - HH:mm').format(prueba.horario!)
                          : 'Hora per determinar';

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DetallePruebaScreen(prueba: prueba),
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: gradient,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                offset: const Offset(0, 4),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                prueba.nombre,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.schedule, size: 18, color: Colors.white70),
                                  const SizedBox(width: 6),
                                  Text(horaFormateada, style: const TextStyle(color: Colors.white70)),
                                  const SizedBox(width: 16),
                                  const Icon(Icons.place, size: 18, color: Colors.white70),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      prueba.lugar ?? 'Lloc per determinar',
                                      style: const TextStyle(color: Colors.white70),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
