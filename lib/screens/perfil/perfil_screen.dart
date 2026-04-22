import 'package:encontros/screens/perfil/edit_profile_screen.dart';
import 'package:flutter/material.dart';
import '../../core/colors.dart';
import '../home/home_screen.dart'; // Import da Home
import '../busca/busca_screen.dart'; // Import da Busca
import '../splash/bottom_navigation.dart'; // Seu menu global

class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 🔥 FOTO GRANDE
            Stack(
              children: [
                Image.network(
                  "https://i.pravatar.cc/600?img=5",
                  width: double.infinity,
                  height: 350,
                  fit: BoxFit.cover,
                ),
                Container(
                  height: 350,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.8),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 20,
                  left: 20,
                  child: const Text(
                    "Julio, 25 🔥",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                )
              ],
            ),

            const SizedBox(height: 20),

            // 🧾 BIO
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "Sobre mim",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Curto sair, música, e conhecer pessoas interessantes 😏",
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // 🔘 BOTÕES
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EditProfileScreen(),
                        ),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
                        color: AppColors.backgroundSoft,
                      ),
                      child: const Center(
                        child: Text("Editar Perfil"),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      color: AppColors.backgroundSoft,
                    ),
                    child: const Center(
                      child: Text("Configurações"),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),

      // 🧭 MENU DE RODAPÉ CONFIGURADO
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 3, // Índice 3 é o Perfil
        onTap: (index) {
          if (index == 3) return; // Se já estiver no perfil, não faz nada

          switch (index) {
            case 0:
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
              break;
            case 1:
            // Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const CurtidasScreen()));
              break;
            case 2:
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const BuscaScreen()));
              break;
            case 3:
            // Já estamos aqui
              break;
          }
        },
      ),
    );
  }
}
