import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/prueba.dart'; // Ajusta el path a donde esté tu modelo Prueba
import 'pruebas_screen.dart';
import 'puntuaciones_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  late Future<List<Prueba>> _futurePruebas;

  @override
  void initState() {
    super.initState();
    _futurePruebas = _cargarPruebasDesdeFirestore();
  }

  Future<List<Prueba>> _cargarPruebasDesdeFirestore() async {
    final snapshot = await FirebaseFirestore.instance.collection('pruebas').get();

    return snapshot.docs.map((doc) {
      // Asumiendo que tu modelo Prueba tiene un método fromFirestore que acepta Map y id
      return Prueba.fromFirestore(doc.data(), doc.id);
    }).toList();
  }

  void _onTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Prueba>>(
      future: _futurePruebas,
      builder: (context, snapshot) {

        final screens = [
          PruebasScreen(),
          PuntuacionesScreen(),
        ];

        return Scaffold(
          body: screens[_currentIndex],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            selectedItemColor: Colors.deepPurple,
            onTap: _onTap,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.list_alt),
                label: 'Pruebas',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.emoji_events),
                label: 'Puntuaciones',
              ),
            ],
          ),
        );
      },
    );
  }
}
