import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

class UserPoint {
  final String id;
  final String name;
  final double lat;
  final double lng;
  final String photoUrl;
  final String genero;

  UserPoint({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
    this.photoUrl = 'https://via.placeholder.com/150',
    required this.genero,
  });
}

class RadarScreen extends StatefulWidget {
  const RadarScreen({super.key});

  @override
  State<RadarScreen> createState() => _RadarScreenState();
}

class _RadarScreenState extends State<RadarScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  double centerLat = 0.0;
  double centerLng = 0.0;
  bool _localizacaoObtida = false;
  List<UserPoint> nearbyUsers = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _determinarPosicao();
  }

  // Captura a posição real (Sensor GPS)
  Future<void> _determinarPosicao() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    Position position = await Geolocator.getCurrentPosition();

    if (mounted) {
      setState(() {
        centerLat = position.latitude;
        centerLng = position.longitude;
        _localizacaoObtida = true;
      });
      _conectarAoFirestore();
    }
  }

  // Escuta o banco de dados em tempo real
  void _conectarAoFirestore() {
    final currentUser = FirebaseAuth.instance.currentUser;

    FirebaseFirestore.instance
        .collection('usuarios')
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        setState(() {
          nearbyUsers = snapshot.docs.map((doc) {
            var data = doc.data();
            return UserPoint(
              id: doc.id,
              name: data['nome'] ?? 'Anônimo',
              lat: (data['lat'] as num?)?.toDouble() ?? 0.0,
              lng: (data['lng'] as num?)?.toDouble() ?? 0.0,
              photoUrl: data['foto_principal'] ?? 'https://via.placeholder.com/150',
              genero: data['genero'] ?? '',
            );
          }).where((u) => u.id != currentUser?.uid && u.lat != 0.0).toList();
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // --- FUNÇÕES DE DESENHO (O que estava faltando) ---

  List<Widget> _buildRadarCircles() {
    return [1, 2, 3].map((i) {
      return Container(
        width: i * 200,
        height: i * 200,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.pink.withOpacity(0.1), width: 1),
        ),
      );
    }).toList();
  }

  Widget _buildUserMarker(UserPoint user) {
    // Zoom do radar (Ganho do sinal)
    const double zoom = 15000;
    double xOffset = (user.lng - centerLng) * zoom;
    double yOffset = -(user.lat - centerLat) * zoom;

    return Transform.translate(
      offset: Offset(xOffset, yOffset),
      child: GestureDetector(
        onTap: () => _showUserCard(user),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: Colors.pinkAccent,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.pink.withOpacity(0.5), blurRadius: 10, spreadRadius: 2),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(user.name, style: const TextStyle(color: Colors.white70, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  void _showUserCard(UserPoint user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF16213E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.pink.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                CircleAvatar(radius: 30, backgroundImage: NetworkImage(user.photoUrl)),
                const SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(user.genero, style: const TextStyle(color: Colors.pinkAccent, fontSize: 14)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.pink, minimumSize: const Size(double.infinity, 45)),
              child: const Text("VER PERFIL COMPLETO"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_localizacaoObtida) {
      return const Scaffold(
        backgroundColor: Color(0xFF1A1A2E),
        body: Center(child: CircularProgressIndicator(color: Colors.pink)),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
            center: Alignment.center,
            radius: 1.0,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            ..._buildRadarCircles(),

            // Sweep Animation
            RotationTransition(
              turns: _controller,
              child: Container(
                decoration: BoxDecoration(
                  gradient: SweepGradient(
                    center: Alignment.center,
                    colors: [Colors.pink.withOpacity(0.0), Colors.pink.withOpacity(0.2)],
                    stops: const [0.75, 1.0],
                  ),
                ),
              ),
            ),

            // Centro (Você)
            const Icon(Icons.my_location, color: Colors.white, size: 20),

            // Pontos Reais
            ...nearbyUsers.map((user) => _buildUserMarker(user)).toList(),

            // Botão de Filtros
            Positioned(
              top: 50,
              child: ActionChip(
                backgroundColor: Colors.black54,
                label: const Text("Ajustar Preferências", style: TextStyle(color: Colors.white)),
                onPressed: () => Navigator.pushNamed(context, '/detalhes'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}