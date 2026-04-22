import 'package:flutter/material.dart';

class HomeCard extends StatelessWidget {
  final String imagePath;
  final VoidCallback onTap;

  const HomeCard({
    super.key,
    required this.imagePath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Center(
        child: Image.asset(
          imagePath,
          fit: BoxFit.contain, // Mantém a imagem sem cortar
          errorBuilder: (context, error, stackTrace) =>
          const Icon(Icons.broken_image, size: 50, color: Colors.white24),
        ),
      ),
    );
  }
}
