import 'package:flutter/material.dart';
import '../core/colors.dart';

import '../screens/radar/radar_screen.dart';
import '../screens/chat/chat_list_screen.dart';
import '../screens/busca/busca_screen.dart';
import '../screens/perfil/perfil_screen.dart';

import 'custom_bottom_nav.dart';

class BottomNav extends StatefulWidget {
  const BottomNav({super.key});

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {

  int currentIndex = 2; // 👈 começa na busca (Tinder vibe)

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
            )
          ],
        ),
        child: CustomBottomNav(
          currentIndex: currentIndex,
          //onTap: (index) {
          //  setState(() => currentIndex = index);
        //  },
        ),
      ),
    );
  }
}