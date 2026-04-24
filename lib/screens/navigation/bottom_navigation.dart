import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../widgets/custom_bottom_nav.dart';

import '../radar/radar_screen.dart';
import '../chat/chat_list_screen.dart';
import '../busca/busca_screen.dart';
import '../perfil/perfil_screen.dart';

class BottomNavigation extends StatefulWidget {
  const BottomNavigation({super.key});

  @override
  State<BottomNavigation> createState() => _BottomNavigationState();
}

class _BottomNavigationState extends State<BottomNavigation> {
  int currentIndex = 2; // 🔥 começa na busca

  final List<Widget> screens = const [
    RadarScreen(),
    ChatListScreen(),
    BuscaScreen(),
    PerfilScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: screens,
      ),

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.backgroundSoft,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 12,
            ),
          ],
        ),
        child: CustomBottomNav(
          currentIndex: currentIndex,
          onTap: (index) {
            setState(() => currentIndex = index);
          },
        ),
      ),
    );
  }
}