import 'package:flutter/material.dart';
import '../../core/colors.dart';
import '../home/home_screen.dart';
import '../busca/busca_screen.dart';
import '../perfil/perfil_screen.dart';
import '../../widgets/custom_bottom_nav.dart';

class ParceirosScreen extends StatelessWidget {
  const ParceirosScreen({super.key});

  // Lista de exemplo (Matches)
  final List<Map<String, dynamic>> matches = const [
    {"name": "Mariana", "image": "https://pravatar.cc", "status": "Online"},
    {"name": "Beatriz", "image": "https://pravatar.cc", "status": "Visto há 5m"},
    {"name": "Fernanda", "image": "https://pravatar.cc", "status": "Online"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Seus Parceiros 🔥", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: matches.isEmpty
          ? const Center(child: Text("Nenhum match ainda... 💔"))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: matches.length,
        itemBuilder: (context, index) {
          final match = matches[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: AppColors.backgroundSoft,
              border: Border.all(color: Colors.white10),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              leading: CircleAvatar(
                radius: 30,
                backgroundImage: NetworkImage(match["image"]),
              ),
              title: Text(
                match["name"],
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              subtitle: Text(
                match["status"],
                style: const TextStyle(color: AppColors.primaryPink, fontSize: 12),
              ),
              trailing: const Icon(Icons.chat_bubble_outline, color: Colors.white70),
              onTap: () {
                // Aqui futuramente chamaremos a conversa
              },
            ),
          );
        },
      ),

      // 🧭 NAVEGAÇÃO (Índice 1 - Curtidas/Parceiros)
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 1,
        onTap: (index) {
          if (index == 1) return;
          switch (index) {
            case 0:
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
              break;
            case 1:
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
