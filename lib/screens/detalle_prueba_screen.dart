import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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

    final resultados = resultadosSnapshot.docs.map((doc) {
      return Resultado.fromFirestore(doc.data(), doc.id);
    }).toList();

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

  @override
  Widget build(BuildContext context) {
    final prueba = widget.prueba;
    final fechaHora = DateFormat('dd/MM/yyyy – HH:mm').format(prueba.horario);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F3F8),
      body: SafeArea(
        child: Column(
          children: [
            // HEADER con gradiente morado
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
              child: Text(
                prueba.nombre,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.1,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // DATOS DE LA PRUEBA
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _infoRow(Icons.place, 'Lugar', prueba.lugar),
                  _infoRow(Icons.schedule, 'Horario', fechaHora),
                  _infoRow(Icons.category, 'Categoría', prueba.categoria),
                  _infoRow(Icons.emoji_events, 'Puntos máx', '${prueba.puntosMaximos}'),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // TÍTULO RESULTADOS
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Icon(Icons.leaderboard, color: Colors.deepPurple),
                  SizedBox(width: 8),
                  Text(
                    'Resultados',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // LISTA DE RESULTADOS
            Expanded(
              child: FutureBuilder<List<_ResultadoConGrupo>>(
                future: _futureResultados,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final resultados = snapshot.data ?? [];

                  if (resultados.isEmpty) {
                    return const Center(child: Text('Sin resultados aún.'));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    itemCount: resultados.length,
                    itemBuilder: (context, index) {
                      final r = resultados[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
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
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(
                            r.grupo.nombre,
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          subtitle: Text(
                            'Puntos: ${r.puntos}',
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

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, color: Colors.deepPurple, size: 20),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 15),
              overflow: TextOverflow.ellipsis,
            ),
          ),
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
