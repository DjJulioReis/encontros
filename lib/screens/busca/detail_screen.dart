import 'package:flutter/material.dart';
import '../../core/colors.dart';

class DetailScreen extends StatelessWidget {
  final Map<String, dynamic> user;

  const DetailScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(user["name"]),
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // 📸 FOTOS
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: user["images"].length,
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.network(
                      user["images"][i],
                      width: 150,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 🧾 BIO
            const Text("Bio", style: TextStyle(fontSize: 18)),
            Text(user["bio"]),

            const SizedBox(height: 20),

            // 🎯 PREFERÊNCIAS
            const Text("Preferências", style: TextStyle(fontSize: 18)),
            Text(user["preferences"]),

            const SizedBox(height: 20),

            // 🎥 VÍDEO (placeholder)
            const Text("Vídeos", style: TextStyle(fontSize: 18)),
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: AppColors.backgroundSoft,
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Center(
                child: Icon(Icons.play_circle, size: 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}