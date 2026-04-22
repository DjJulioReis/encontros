import 'package:encontros/screens/busca/busca_screen.dart';
import 'package:encontros/screens/perfil/perfil_screen.dart';
import 'package:flutter/material.dart';
import '../../widgets/home_card.dart';
import '../splash/bottom_navigation.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0; // Para controlar qual ícone está ativo

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            const CircleAvatar(
              radius: 26,
              backgroundImage: NetworkImage("https://i.pravatar.cc/600?img=5"),
              backgroundColor: Colors.white10,
            ),
            const SizedBox(width: 12),
            const Text(
              "Olá, Julio 🔥",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 26),
            ),
          ],
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                children: const [
                  Text(
                    "O que voce pretende fazer hoje?",
                    style: TextStyle(color: Colors.white60, fontSize: 13),
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
            SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
              ),
              delegate: SliverChildListDelegate([
                HomeCard(imagePath: "assets/images/radar.png", onTap: () {}),
                HomeCard(imagePath: "assets/images/parceiros.png", onTap: () {}),
                HomeCard(imagePath: "assets/images/buscar.png", onTap: () {}),
                HomeCard(imagePath: "assets/images/fotos-lista.png", onTap: () {}),
              ]),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 140,
                child: HomeCard(
                  imagePath: "assets/images/chat.png",
                  onTap: () {},
                ),
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar: CustomBottomNav(
        currentIndex: 0, // 0 porque estamos na Home
        onTap: (index) {
          if (index == _selectedIndex) return; // Não faz nada se clicar na mesma aba

          // Lógica de navegação baseada no índice clicado
          switch (index) {
            case 0:
            // Já estamos na Home, não faz nada
              break;
            case 1:
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const BuscaScreen()));
              break;
            case 2:
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const BuscaScreen()));
              break;
            case 3:
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PerfilScreen()));
              break;
          }
        },
      ),

    );
  }
}
