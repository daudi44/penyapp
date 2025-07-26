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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F3F8), // Fondo claro moderno
      body: SafeArea(
        child: Column(
          children: [
            // APP BAR moderno personalizado
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
                'Pruebas',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // CONTENIDO PRINCIPAL
            Expanded(
              child: FutureBuilder<List<Prueba>>(
                future: _cargarPruebas(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error cargando pruebas: ${snapshot.error}'));
                  }

                  final pruebas = snapshot.data ?? [];
                  final pruebasOrdenadas = [...pruebas]..sort((a, b) => a.orden.compareTo(b.orden));

                  if (pruebasOrdenadas.isEmpty) {
                    return const Center(child: Text('No hay pruebas aún.'));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    itemCount: pruebasOrdenadas.length,
                    itemBuilder: (context, index) {
                      final prueba = pruebasOrdenadas[index];
                      final horaFormateada = DateFormat('dd/MM - HH:mm').format(prueba.horario);

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
                            gradient: const LinearGradient(
                              colors: [Color(0xFFD1C4E9), Color(0xFF9575CD)],
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
                                    child: Text(prueba.lugar,
                                        style: const TextStyle(color: Colors.white70),
                                        overflow: TextOverflow.ellipsis),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.deepPurple.shade400,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'Categoría: ${prueba.categoria}',
                                      style: const TextStyle(color: Colors.white, fontSize: 12),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.deepPurple.shade200,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'Máx: ${prueba.puntosMaximos} pts',
                                      style: const TextStyle(color: Colors.white, fontSize: 12),
                                    ),
                                  ),
                                ],
                              )
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
