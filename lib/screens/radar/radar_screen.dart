import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/colors.dart';

class RadarScreen extends StatefulWidget {
  const RadarScreen({super.key});

  @override
  State<RadarScreen> createState() => _RadarScreenState();
}

class _RadarScreenState extends State<RadarScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  GoogleMapController? _mapController;
  Position? _currentPosition;
  final String _myUid = FirebaseAuth.instance.currentUser?.uid ?? "";

  // Conjunto de marcadores dos OUTROS usuários
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _determinePosition();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  Future<void> _determinePosition() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() => _currentPosition = position);

      // Move a câmera para manter você no centro do radar
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(LatLng(position.latitude, position.longitude)),
      );
    } catch (e) {
      debugPrint("Erro GPS: $e");
    }
  }

  void _updateMarkers(List<QueryDocumentSnapshot> docs) {
    Set<Marker> newMarkers = {};
    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final String userId = data['uid'] ?? "";

      if (userId == _myUid) continue; // Ignora você nos marcadores (sua foto é o widget central)

      final double lat = (data['lat'] ?? 0).toDouble();
      final double lng = (data['lng'] ?? 0).toDouble();

      if (lat != 0 && lng != 0) {
        newMarkers.add(
          Marker(
            markerId: MarkerId(userId),
            position: LatLng(lat, lng),
            infoWindow: InfoWindow(title: data['nome'] ?? "Usuário"),
            icon: BitmapDescriptor.defaultMarkerWithHue(330.0),
          ),
        );
      }
    }

    if (newMarkers.length != _markers.length) {
      setState(() => _markers = newMarkers);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      body: Stack(
        alignment: Alignment.center, // 🔥 Mantém tudo alinhado ao centro
        children: [
          // 1. MAPA (Fundo)
          _currentPosition == null
              ? const Center(child: CircularProgressIndicator(color: Colors.pinkAccent))
              : GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
              zoom: 15,
            ),
            onMapCreated: (controller) => _mapController = controller,
            myLocationEnabled: false, // ❌ Desativamos o ponto azul para usar sua FOTO
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            markers: _markers,
            mapType: MapType.normal,
          ),

          // 2. EFEITO DE PULSO
          IgnorePointer(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Container(
                  width: MediaQuery.of(context).size.width * _controller.value * 2,
                  height: MediaQuery.of(context).size.width * _controller.value * 2,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primaryPink.withOpacity(1 - _controller.value),
                      width: 2,
                    ),
                  ),
                );
              },
            ),
          ),

          // 3. SEU AVATAR CUSTOMIZADO (No "olho" do radar)
          IgnorePointer(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.pinkAccent,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.pinkAccent.withOpacity(0.6),
                        blurRadius: 15,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                  child: StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('usuarios')
                        .doc(_myUid)
                        .snapshots(),
                    builder: (context, userSnapshot) {
                      String? fotoUrl;
                      if (userSnapshot.hasData && userSnapshot.data!.exists) {
                        fotoUrl = (userSnapshot.data!.data() as Map<String, dynamic>)['foto_principal'];
                      }

                      return CircleAvatar(
                        radius: 16,
                        backgroundColor: const Color(0xFF1A1A2E),
                        backgroundImage: (fotoUrl != null && fotoUrl.isNotEmpty)
                            ? NetworkImage(fotoUrl)
                            : null,
                        child: (fotoUrl == null || fotoUrl.isEmpty)
                            ? const Icon(Icons.person, color: Colors.white, size: 30)
                            : null,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.pinkAccent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    "VOCÊ",
                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          // 4. LOGICA FIREBASE (Escutando em tempo real)
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('usuarios')
                .where('ativo', isEqualTo: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _updateMarkers(snapshot.data!.docs);
                });
              }
              return const SizedBox.shrink();
            },
          ),

          // 5. INTERFACE SUPERIOR
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    "Radar 🔥",
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                FloatingActionButton.small(
                  backgroundColor: Colors.pinkAccent,
                  child: const Icon(Icons.my_location, color: Colors.white),
                  onPressed: _determinePosition,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}