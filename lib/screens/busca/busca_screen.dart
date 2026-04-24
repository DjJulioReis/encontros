import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/colors.dart';
import '../../core/location_controller.dart';
import '../../core/distance_service.dart';

class BuscaScreen extends StatefulWidget {
  const BuscaScreen({super.key});

  @override
  State<BuscaScreen> createState() => _BuscaScreenState();
}

class _BuscaScreenState extends State<BuscaScreen> {

  Offset position = Offset.zero;
  double angle = 0;
  int currentPhoto = 0;

  List<Map<String, dynamic>> users = [
    {
      "name": "Ana",
      "age": 22,
      "lat": -25.57,
      "lng": -48.62,
      "images": [
        "https://i.pravatar.cc/500?img=1",
        "https://i.pravatar.cc/500?img=11",
        "https://i.pravatar.cc/500?img=12",
      ],
    },
    {
      "name": "Julia",
      "age": 25,
      "lat": -25.60,
      "lng": -48.65,
      "images": [
        "https://i.pravatar.cc/500?img=2",
        "https://i.pravatar.cc/500?img=21",
      ],
    },
  ];

  // 🔄 RESET LISTA
  void resetUsers() {
    setState(() {
      users = [
        {
          "name": "Ana",
          "age": 22,
          "lat": -25.57,
          "lng": -48.62,
          "images": [
            "https://i.pravatar.cc/500?img=1",
            "https://i.pravatar.cc/500?img=11",
            "https://i.pravatar.cc/500?img=12",
          ],
        },
        {
          "name": "Julia",
          "age": 25,
          "lat": -25.60,
          "lng": -48.65,
          "images": [
            "https://i.pravatar.cc/500?img=2",
            "https://i.pravatar.cc/500?img=21",
          ],
        },
      ];

      currentPhoto = 0;
      position = Offset.zero;
      angle = 0;
    });
  }

  void resetCard() {
    setState(() {
      position = Offset.zero;
      angle = 0;
    });
  }

  void removeUser() {
    setState(() {
      if (users.isNotEmpty) {
        users.removeAt(0);
        currentPhoto = 0;
        position = Offset.zero;
        angle = 0;
      }
    });
  }

  void onDragUpdate(DragUpdateDetails details) {
    setState(() {
      position += details.delta;
      angle = position.dx * 0.001;
    });
  }

  void onDragEnd() {
    final x = position.dx;
    final y = position.dy;

    if (x > 120 || x < -120 || y < -120) {
      removeUser();
    } else {
      resetCard();
    }
  }

  @override
  Widget build(BuildContext context) {

    final myLocation = context.watch<LocationController>();

    // 🔥 FIM DA LISTA
    if (users.isEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              const Icon(
                Icons.favorite_border,
                size: 80,
                color: Colors.white30,
              ),

              const SizedBox(height: 20),

              const Text(
                "Acabaram por enquanto 😢",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                "Volte mais tarde ou recarregue",
                style: TextStyle(color: Colors.white54),
              ),

              const SizedBox(height: 30),

              GestureDetector(
                onTap: resetUsers,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    gradient: const LinearGradient(
                      colors: [
                        AppColors.primaryPink,
                        AppColors.primaryOrange,
                      ],
                    ),
                  ),
                  child: const Text(
                    "Recarregar",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final user = users[0];
    final images = user["images"];

    double distance = 0;
    if (myLocation.lat != null && myLocation.lng != null) {
      distance = DistanceService.calculateDistance(
        myLocation.lat!,
        myLocation.lng!,
        user["lat"],
        user["lng"],
      );
    }

    return Scaffold(
      body: Stack(
        children: [

          // 🔙 BOTÃO VOLTAR
          Positioned(
            top: 50,
            left: 20,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back, size: 20),
              ),
            ),
          ),

          // 🔥 CARD
          Center(
            child: GestureDetector(
              onPanUpdate: onDragUpdate,
              onPanEnd: (_) => onDragEnd(),

              // 👉 TROCAR FOTO
              onTapUp: (details) {
                final width = MediaQuery.of(context).size.width;

                if (details.localPosition.dx > width / 2) {
                  if (currentPhoto < images.length - 1) {
                    setState(() => currentPhoto++);
                  }
                } else {
                  if (currentPhoto > 0) {
                    setState(() => currentPhoto--);
                  }
                }
              },

              child: Transform.translate(
                offset: position,
                child: Transform.rotate(
                  angle: angle,
                  child: _buildCard(user, images, distance, myLocation),
                ),
              ),
            ),
          ),

          // 🔘 BOTÕES
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [

                GestureDetector(
                  onTap: removeUser,
                  child: _circleButton(Icons.close, Colors.red),
                ),

                GestureDetector(
                  onTap: removeUser,
                  child: _circleButton(
                    Icons.favorite,
                    AppColors.primaryPink,
                    isMain: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(user, images, distance, myLocation) {
    return Stack(
      children: [

        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.network(
            images[currentPhoto],
            height: double.infinity,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),

        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.center,
              colors: [
                Colors.black.withOpacity(0.85),
                Colors.transparent,
              ],
            ),
          ),
        ),

        // 🔥 STORIES
        Positioned(
          top: 50,
          left: 10,
          right: 10,
          child: Row(
            children: List.generate(images.length, (index) {
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  height: 4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: index <= currentPhoto
                        ? const LinearGradient(
                      colors: [
                        AppColors.primaryPink,
                        AppColors.primaryOrange,
                      ],
                    )
                        : null,
                    color: index > currentPhoto
                        ? Colors.white24
                        : null,
                  ),
                ),
              );
            }),
          ),
        ),

        // 📍 INFO
        Positioned(
          bottom: 140,
          left: 20,
          right: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "${user["name"]}, ${user["age"]}",
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                myLocation.lat == null
                    ? "📡 Calculando..."
                    : "📍 ${distance.toStringAsFixed(1)} km",
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _circleButton(IconData icon, Color color, {bool isMain = false}) {
    return Container(
      width: isMain ? 80 : 65,
      height: isMain ? 80 : 65,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: isMain
            ? const LinearGradient(
          colors: [
            AppColors.primaryPink,
            AppColors.primaryOrange,
          ],
        )
            : null,
        color: isMain ? null : color.withOpacity(0.2),
        boxShadow: isMain
            ? [
          BoxShadow(
            color: AppColors.primaryPink.withOpacity(0.5),
            blurRadius: 15,
          )
        ]
            : [],
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: isMain ? 34 : 28,
      ),
    );
  }
}