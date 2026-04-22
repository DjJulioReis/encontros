import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/location_controller.dart';
import 'core/theme.dart'; // 👈 ADICIONA ISSO
import 'screens/login/login_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => LocationController()..initLocation(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      // 🔥 AQUI ESTÁ O QUE FALTAVA
      theme: AppTheme.darkTheme,

      home: const LoginScreen(),
    );
  }
}