import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/prueba.dart';
import 'detalle_prueba_screen.dart';

class PruebasScreen extends StatelessWidget {
  const PruebasScreen({super.key});

  Future<List<Prueba>> _cargarPruebas() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('pruebas')
        .get();
    return snapshot.docs
        .map((doc) => Prueba.fromFirestore(doc.data(), doc.id))
        .toList();
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

  Widget _buildModernAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              // change colors to dark purple gradient
              Color(0xFF6D28D9), // Purple 800
              Color(0xFF7C3AED), // Purple 700
              Color(0xFF8B5CF6), // Purple 600
              Color(0xFFA78BFA), // Purple 500
              
            ],
          ),
        ),
        child: FlexibleSpaceBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.emoji_flags,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Proves',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          centerTitle: false,
          titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F3F8),
      body: FutureBuilder<List<Prueba>>(
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
          final pruebasOrdenadas = [...pruebas]
            ..sort((a, b) => a.orden.compareTo(b.orden));

          return CustomScrollView(
            slivers: [
              _buildModernAppBar(),
              SliverToBoxAdapter(child: const SizedBox(height: 16)),

              if (pruebasOrdenadas.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: Text('Encara no hi ha proves.')),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
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
                        margin: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
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
                                const Icon(
                                  Icons.schedule,
                                  size: 18,
                                  color: Colors.white70,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  horaFormateada,
                                  style: const TextStyle(color: Colors.white70),
                                ),
                                const SizedBox(width: 16),
                                const Icon(
                                  Icons.place,
                                  size: 18,
                                  color: Colors.white70,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    prueba.lugar ?? 'Lloc per determinar',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }, childCount: pruebasOrdenadas.length),
                ),
            ],
          );
        },
      ),
    );
  }
}
