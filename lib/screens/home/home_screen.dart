import 'package:flutter/material.dart';
import '../../widgets/home_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Olá 🔥"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            HomeCard(
              title: "Radar",
              icon: Icons.radar,
              onTap: () {},
            ),
            HomeCard(
              title: "Parceiros",
              icon: Icons.favorite,
              onTap: () {},
            ),
            HomeCard(
              title: "Busca",
              icon: Icons.location_on,
              onTap: () {},
            ),
            HomeCard(
              title: "Fotos",
              icon: Icons.image,
              onTap: () {},
            ),
            HomeCard(
              title: "Chat",
              icon: Icons.chat,
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}