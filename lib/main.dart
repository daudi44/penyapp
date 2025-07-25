// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:penyapp/firebase_options.dart'; // Ajusta la ruta si es diferente
import 'package:penyapp/screens/puntuaciones_screen.dart'; // <--- ¡Importa tu nueva pantalla!
import 'dart:developer'; // Mantén el import de log

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    log('Firebase inicializado correctamente!');
  } catch (e) {
    log('Error al inicializar Firebase: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PenyApp',
      theme: ThemeData(
        primarySwatch: Colors.green,
        secondaryHeaderColor: Colors.white,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const PuntuacionesScreen(),
    );
  }
}
