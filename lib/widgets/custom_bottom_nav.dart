import 'package:encontros/screens/chat/chat_global_screen.dart';
import 'package:encontros/screens/radar/radar_screen.dart';
import 'package:flutter/material.dart';
// 🔥 Importe todas as suas telas aqui para o componente enxergá-las
import '../screens/home/home_screen.dart';
import '../screens/busca/busca_screen.dart';
import '../screens/favoritos/favoritos_screen.dart';
import '../screens/chat/matches_screen.dart';
import '../screens/perfil/perfil_screen.dart';
import '../screens/chat/chat_global_screen.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
  });

  // 🔥 LÓGICA CENTRALIZADA DE NAVEGAÇÃO
  void _navegar(BuildContext context, int index) {
    if (index == currentIndex) return;

    Widget nextScreen;
    switch (index) {
      case 0: nextScreen = const BuscaScreen(); break;
      case 1: nextScreen = const RadarScreen(); break;
      case 2: nextScreen = const FavoritosScreen(); break;
      case 3: nextScreen = const ChatGlobalScreen(); break;
      case 4: nextScreen = const MatchesScreen(); break;
      case 5: nextScreen = const PerfilScreen(); break;
      default: return;
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, anim1, anim2) => nextScreen,
        transitionDuration: Duration.zero, // Troca instantânea estilo App real
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) => _navegar(context, index), // Chama a lógica interna
      type: BottomNavigationBarType.fixed,
      backgroundColor: const Color(0xFF0F0F1E),
      selectedItemColor: Colors.pinkAccent,
      unselectedItemColor: Colors.white38,
      selectedFontSize: 12,
      unselectedFontSize: 10,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.style), label: "Busca"),
        BottomNavigationBarItem(icon: Icon(Icons.radar), label: "Radar"),
        BottomNavigationBarItem(icon: Icon(Icons.star), label: "Favoritos"),
        BottomNavigationBarItem(icon: Icon(Icons.chat_bubble), label: "Chat"),
        BottomNavigationBarItem(icon: Icon(Icons.local_fire_department), label: "Match"),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: "Perfil"),
      ],
    );
  }
}