import 'package:encontros/screens/perfil/perfil_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/colors.dart';
import '../../core/location_controller.dart';
import '../../core/distance_service.dart';
import '../../widgets/like_button.dart';
import '../splash/bottom_navigation.dart'; // Certifique-se que o CustomBottomNav está aqui
import '../home/home_screen.dart'; // Importe a Home

class BuscaScreen extends StatelessWidget {
  const BuscaScreen({super.key});

  final List<Map<String, dynamic>> users = const [
    {
      "name": "Ana",
      "age": 22,
      "lat": -25.57,
      "lng": -48.62,
      "image": "https://i.pravatar.cc/300?img=1"
    },
    {
      "name": "Julia",
      "age": 25,
      "lat": -25.60,
      "lng": -48.65,
      "image": "https://i.pravatar.cc/300?img=2"
    },
    {
      "name": "Carla",
      "age": 28,
      "lat": -25.58,
      "lng": -48.63,
      "image": "https://i.pravatar.cc/300?img=3"
    },
  ];

  @override
  Widget build(BuildContext context) {
    final myLocation = context.watch<LocationController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Buscar 🔥"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          double distance = 0;

          if (myLocation.lat != null && myLocation.lng != null) {
            distance = DistanceService.calculateDistance(
              myLocation.lat!,
              myLocation.lng!,
              user["lat"],
              user["lng"],
            );
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: AppColors.backgroundSoft,
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.network(
                    user["image"],
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${user["name"]}, ${user["age"]}",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        myLocation.lat == null
                            ? "Calculando..."
                            : "${distance.toStringAsFixed(1)} km de você",
                        style: const TextStyle(color: Colors.white54),
                      ),
                    ],
                  ),
                ),
                const LikeButton(),
              ],
            ),
          );
        },
      ),

      // 🧭 NAVEGAÇÃO AJUSTADA
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 2, // 2 é o índice da Busca
        onTap: (index) {
          if (index == 2) return; // Se já estiver na busca, não faz nada

          switch (index) {
            case 0:
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
              break;
            case 1:
            // Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const CurtidasScreen()));
              break;
            case 2:
            // Já estamos aqui
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
