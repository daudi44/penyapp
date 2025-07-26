import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/prueba.dart';
import '../models/resultado.dart';
import '../models/grupo.dart';

class DetallePruebaScreen extends StatefulWidget {
  final Prueba prueba;

  const DetallePruebaScreen({super.key, required this.prueba});

  @override
  State<DetallePruebaScreen> createState() => _DetallePruebaScreenState();
}

class _DetallePruebaScreenState extends State<DetallePruebaScreen> {
  late Future<List<_ResultadoConGrupo>> _futureResultados;

  @override
  void initState() {
    super.initState();
    _futureResultados = _cargarResultados();
  }

  Future<List<_ResultadoConGrupo>> _cargarResultados() async {
    final resultadosSnapshot = await FirebaseFirestore.instance
        .collection('resultados')
        .where('idPrueba', isEqualTo: widget.prueba.id)
        .get();

    final resultados = resultadosSnapshot.docs
        .map((doc) => Resultado.fromFirestore(doc.data(), doc.id))
        .toList();

    final gruposMap = <String, Grupo>{};

    for (var resultado in resultados) {
      if (!gruposMap.containsKey(resultado.idGrupo)) {
        final grupoSnap = await FirebaseFirestore.instance
            .collection('grupos')
            .doc(resultado.idGrupo)
            .get();
        if (grupoSnap.exists) {
          gruposMap[resultado.idGrupo] =
              Grupo.fromFirestore(grupoSnap.data()!, grupoSnap.id);
        }
      }
    }

    final listaConGrupo = resultados.map((resultado) {
      final grupo = gruposMap[resultado.idGrupo];
      final puntos = resultado.calcularPuntos(widget.prueba.categoria);
      return _ResultadoConGrupo(
        grupo: grupo!,
        resultado: resultado,
        puntos: puntos,
      );
    }).toList();

    listaConGrupo.sort((a, b) => a.resultado.posicion.compareTo(b.resultado.posicion));
    return listaConGrupo;
  }

  List<Color> _coloresPorCategoria(String categoria) {
    switch (categoria.toLowerCase()) {
      case 'negra':
        return [const Color(0xFF424242), const Color(0xFF212121)];
      case 'roja':
        return [const Color(0xFFEF5350), const Color(0xFFE53935)];
      case 'blava':
        return [const Color(0xFF64B5F6), const Color(0xFF1E88E5)];
      default:
        return [const Color(0xFFA5D6A7), const Color(0xFF43A047)];
    }
  }

  @override
  Widget build(BuildContext context) {
    final prueba = widget.prueba;
    final hora = prueba.horario != null
        ? DateFormat('dd/MM/yyyy – HH:mm').format(prueba.horario!)
        : 'Per determinar';

    final gradientColors = _coloresPorCategoria(prueba.categoria);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F3F8),
      body: FutureBuilder<List<_ResultadoConGrupo>>(
        future: _futureResultados,
        builder: (context, snapshot) {
          final resultados = snapshot.data ?? [];

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 160,
                backgroundColor: Colors.transparent,
                flexibleSpace: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: gradientColors,
                    ),
                  ),
                  child: FlexibleSpaceBar(
                    titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
                    title: Text(
                      prueba.nombre,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    background: Container(
                      padding: const EdgeInsets.all(20),
                      alignment: Alignment.bottomLeft,
                      child: const Icon(
                        Icons.flag,
                        color: Colors.white24,
                        size: 80,
                      ),
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _infoRow(Icons.place, 'Lloc', prueba.lugar ?? 'Per determinar'),
                      _infoRow(Icons.schedule, 'Hora', hora),
                      const SizedBox(height: 12),
                      if (prueba.descripcion.trim().isNotEmpty)
                        _sectionText('Descripció', prueba.descripcion),
                      if (prueba.valoracion.trim().isNotEmpty)
                        _sectionText('Valoració', prueba.valoracion),
                      const SizedBox(height: 24),
                      const Text(
                        'Resultats',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),

              if (snapshot.connectionState == ConnectionState.waiting)
                const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
              else if (resultados.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: Text('Encara no hi ha resultats.')),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final r = resultados[index];
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFD1C4E9), Color(0xFF9575CD)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        leading: CircleAvatar(
                          backgroundColor: Colors.deepPurple,
                          child: Text(
                            '${r.resultado.posicion}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          r.grupo.nombre,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        subtitle: Text(
                          'Punts: ${r.puntos}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        trailing: r.grupo.logoUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  r.grupo.logoUrl!,
                                  height: 40,
                                  width: 40,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : null,
                      ),
                    );
                  }, childCount: resultados.length),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.deepPurple, size: 20),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionText(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$title:',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          Text(content),
        ],
      ),
    );
  }
}

class _ResultadoConGrupo {
  final Grupo grupo;
  final Resultado resultado;
  final int puntos;

  _ResultadoConGrupo({
    required this.grupo,
    required this.resultado,
    required this.puntos,
  });
}
