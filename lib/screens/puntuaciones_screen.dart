// lib/screens/puntuaciones_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/grupo.dart';
import '../models/prueba.dart';
import '../models/resultado.dart';
import 'package:penyapp/app_theme.dart'; // Importa tu tema personalizado

class PuntuacionesScreen extends StatefulWidget {
  const PuntuacionesScreen({super.key});

  @override
  State<PuntuacionesScreen> createState() => _PuntuacionesScreenState();
}

class _PuntuacionesScreenState extends State<PuntuacionesScreen>
    with TickerProviderStateMixin {
  List<Prueba> _pruebas = [];
  bool _isTableView = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _loadPruebas();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadPruebas() async {
    final QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('pruebas')
        .orderBy('orden')
        .get();
    setState(() {
      _pruebas = querySnapshot.docs
          .map(
            (doc) => Prueba.fromFirestore(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ),
          )
          .toList();
    });
  }

  int _calcularPuntuacionTotalGrupo(
    Grupo grupo,
    List<Resultado> resultados,
    List<Prueba> pruebas,
  ) {
    int totalPuntos = 0;
    for (var resultado in resultados) {
      if (resultado.idGrupo == grupo.id) {
        final prueba = pruebas.firstWhereOrNull(
          (p) => p.id == resultado.idPrueba,
        );
        if (prueba != null) {
          totalPuntos += resultado.calcularPuntos(prueba.categoria);
        }
      }
    }
    return totalPuntos;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          _buildModernAppBar(),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: _buildContent(),
            ),
          ),
        ],
      ),
      floatingActionButton: _buildViewToggleFAB(),
    );
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
              Color(0xFF059669), // Emerald 600
              Color(0xFF10B981), // Emerald 500
              Color(0xFF34D399), // Emerald 400
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
                  Icons.emoji_events_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Classificació General',
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

  Widget _buildViewToggleFAB() {
    return FloatingActionButton.extended(
      onPressed: () {
        setState(() {
          _isTableView = !_isTableView;
        });
      },
      backgroundColor: const Color(0xFF059669),
      foregroundColor: Colors.white,
      elevation: 8,
      icon: Icon(
        _isTableView ? Icons.view_list_rounded : Icons.table_chart_rounded,
      ),
      label: Text(_isTableView ? 'Veure llistat' : 'Veure taula'),
    );
  }

  Widget _buildContent() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('grupos').snapshots(),
      builder: (context, gruposSnapshot) {
        if (gruposSnapshot.hasError) {
          return _buildErrorState(
            'Error en carregar grups: ${gruposSnapshot.error}',
          );
        }
        if (gruposSnapshot.connectionState == ConnectionState.waiting ||
            _pruebas.isEmpty) {
          return _buildLoadingState();
        }
        if (!gruposSnapshot.hasData || gruposSnapshot.data!.docs.isEmpty) {
          return _buildEmptyState();
        }

        final List<Grupo> grupos = gruposSnapshot.data!.docs.map((doc) {
          return Grupo.fromFirestore(
            doc.data() as Map<String, dynamic>,
            doc.id,
          );
        }).toList();

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('resultados')
              .snapshots(),
          builder: (context, resultadosSnapshot) {
            if (resultadosSnapshot.hasError) {
              return _buildErrorState(
                'Error en carregar resultats: ${resultadosSnapshot.error}',
              );
            }
            if (resultadosSnapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingState();
            }

            final List<Resultado> resultados = resultadosSnapshot.data!.docs
                .map((doc) {
                  return Resultado.fromFirestore(
                    doc.data() as Map<String, dynamic>,
                    doc.id,
                  );
                })
                .toList();

            // Calcular y ordenar grupos por puntuación total
            for (var grupo in grupos) {
              int total = _calcularPuntuacionTotalGrupo(
                grupo,
                resultados,
                _pruebas,
              );
              grupo.puntuacionTotal = total;
            }

            grupos.sort(
              (a, b) => b.puntuacionTotal.compareTo(a.puntuacionTotal),
            );

            return _isTableView
                ? _buildModernTable(grupos, _pruebas, resultados)
                : _buildCardsView(grupos, _pruebas, resultados);
          },
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return Container(
      height: 400,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF059669)),
              strokeWidth: 3,
            ),
            SizedBox(height: 16),
            Text(
              'Carregant classificació...',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFDC2626),
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'Error',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFFDC2626),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Color(0xFF7F1D1D)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Column(
        children: [
          Icon(Icons.groups_outlined, color: Color(0xFF9CA3AF), size: 64),
          SizedBox(height: 16),
          Text(
            'Encara no hi ha grups',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF374151),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Els grups registrats apareixeran aquí',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }

  Widget _buildCardsView(
    List<Grupo> grupos,
    List<Prueba> pruebas,
    List<Resultado> resultados,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildStatsHeader(grupos),
          const SizedBox(height: 24),
          ...grupos.asMap().entries.map((entry) {
            final int index = entry.key;
            final Grupo grupo = entry.value;
            return _buildGrupoCard(grupo, index, pruebas, resultados);
          }).toList(),
          const SizedBox(height: 80), // Espacio para el FAB
        ],
      ),
    );
  }

  Widget _buildStatsHeader(List<Grupo> grupos) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF0FDF4), // Green 50
            Color(0xFFDCFCE7), // Green 100
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              'Penyes Totals',
              grupos.length.toString(),
              Icons.groups_rounded,
              const Color(0xFF059669),
            ),
          ),
          Container(width: 1, height: 40, color: const Color(0xFFBBF7D0)),
          Expanded(
            child: _buildStatItem(
              'Proves',
              _pruebas.length.toString(),
              Icons.quiz_rounded,
              const Color(0xFF0891B2),
            ),
          ),
          Container(width: 1, height: 40, color: const Color(0xFFBBF7D0)),
          Expanded(
            child: _buildStatItem(
              'Líder',
              grupos.isNotEmpty ? grupos.first.nombre : '-',
              Icons.emoji_events_rounded,
              const Color(0xFFEA580C),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF6B7280),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildGrupoCard(
    Grupo grupo,
    int index,
    List<Prueba> pruebas,
    List<Resultado> resultados,
  ) {
    final bool isWinner = index == 0;
    final bool isPodium = index < 3;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        elevation: isPodium ? 8 : 4,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: isWinner
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFFEF3C7), // Yellow 100
                      Color(0xFFFDE68A), // Yellow 200
                    ],
                  )
                : isPodium
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFF3F4F6), // Gray 100
                      Color(0xFFE5E7EB), // Gray 200
                    ],
                  )
                : null,
            color: isPodium ? null : Colors.white,
            border: isWinner
                ? Border.all(color: const Color(0xFFF59E0B), width: 2)
                : isPodium
                ? Border.all(color: const Color(0xFFD1D5DB))
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildCardHeader(grupo, index, isWinner, isPodium),
                // const SizedBox(height: 16),
                // _buildPruebasGrid(grupo, pruebas, resultados),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardHeader(
    Grupo grupo,
    int index,
    bool isWinner,
    bool isPodium,
  ) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isWinner
                ? const Color(0xFFF59E0B)
                : isPodium
                ? const Color(0xFF6B7280)
                : const Color(0xFF059669),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                grupo.nombre,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isWinner
                      ? const Color(0xFFB45309)
                      : const Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.star_rounded,
                    size: 16,
                    color: isWinner
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFF6B7280),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${grupo.puntuacionTotal} punts',
                    style: TextStyle(
                      fontSize: 14,
                      color: isWinner
                          ? const Color(0xFFB45309)
                          : const Color(0xFF6B7280),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (isWinner)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.emoji_events_rounded, color: Colors.white, size: 16),
                SizedBox(width: 4),
                Text(
                  'Líder',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildPruebasGrid(
    Grupo grupo,
    List<Prueba> pruebas,
    List<Resultado> resultados,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Puntuació per prova',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: pruebas.map((prueba) {
              final Resultado? resultado = resultados.firstWhereOrNull(
                (r) => r.idGrupo == grupo.id && r.idPrueba == prueba.id,
              );
              final int puntos =
                  resultado?.calcularPuntos(prueba.categoria) ?? 0;

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: puntos > 0
                      ? const Color(0xFF10B981)
                      : const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      prueba.nombre,
                      style: TextStyle(
                        fontSize: 10,
                        color: puntos > 0
                            ? Colors.white
                            : const Color(0xFF6B7280),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      puntos.toString(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: puntos > 0
                            ? Colors.white
                            : const Color(0xFF374151),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildModernTable(
    List<Grupo> grupos,
    List<Prueba> pruebas,
    List<Resultado> resultados,
  ) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: DataTable(
              columns: _buildTableColumns(pruebas),
              rows: _buildTableRows(grupos, pruebas, resultados),
              headingRowHeight: 60,
              dataRowMinHeight: 56,
              dataRowMaxHeight: 56,
              columnSpacing: 16,
              horizontalMargin: 20,
              headingRowColor: MaterialStateProperty.all(
                const Color(0xFFF9FAFB),
              ),
              border: TableBorder(
                horizontalInside: BorderSide(
                  color: const Color(0xFFE5E7EB),
                  width: 1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<DataColumn> _buildTableColumns(List<Prueba> pruebas) {
    return [
      const DataColumn(
        label: Expanded(
          child: Row(
            children: [
              Icon(Icons.groups_rounded, size: 20, color: Color(0xFF374151)),
              SizedBox(width: 8),
              Text(
                'Penya',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF374151),
                ),
              ),
            ],
          ),
        ),
      ),
      ...pruebas.map(
        (prueba) => DataColumn(
          label: Expanded(
            child: Text(
              prueba.nombre,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Color(0xFF374151),
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
      const DataColumn(
        label: Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.emoji_events_rounded,
                size: 20,
                color: Color(0xFFF59E0B),
              ),
              SizedBox(width: 8),
              Text(
                'Total',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF374151),
                ),
              ),
            ],
          ),
        ),
      ),
    ];
  }

  List<DataRow> _buildTableRows(
    List<Grupo> grupos,
    List<Prueba> pruebas,
    List<Resultado> resultados,
  ) {
    return grupos.asMap().entries.map((entry) {
      final int index = entry.key;
      final Grupo grupo = entry.value;
      final bool isPodium = index < 3;

      return DataRow(
        color: MaterialStateProperty.all(
          isPodium ? const Color(0xFFFEF3C7).withOpacity(0.3) : null,
        ),
        cells: [
          DataCell(
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isPodium
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFF059669),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    grupo.nombre,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          ...pruebas.map((prueba) {
            final Resultado? resultado = resultados.firstWhereOrNull(
              (r) => r.idGrupo == grupo.id && r.idPrueba == prueba.id,
            );
            final int puntos = resultado?.calcularPuntos(prueba.categoria) ?? 0;

            return DataCell(
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: puntos > 0
                        ? const Color(0xFF10B981)
                        : const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    puntos.toString(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: puntos > 0
                          ? Colors.white
                          : const Color(0xFF6B7280),
                    ),
                  ),
                ),
              ),
            );
          }),
          DataCell(
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isPodium
                      ? const Color(0xFFF59E0B)
                      : const Color(0xFF059669),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  grupo.puntuacionTotal.toString(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }).toList();
  }
}

// Extensión para List para usar firstWhereOrNull
extension ListExtension<T> on List<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (var element in this) {
      if (test(element)) {
        return element;
      }
    }
    return null;
  }
}
