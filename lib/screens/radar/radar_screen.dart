import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';
import '../perfil/perfil_user_screen.dart';

class RadarScreen extends StatefulWidget {
  const RadarScreen({super.key});

  @override
  State<RadarScreen> createState() => _RadarScreenState();
}

class _RadarScreenState extends State<RadarScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  GoogleMapController? _mapController;
  Position? _currentPosition;
  LatLngBounds? _mapBounds;
  final String _myUid = FirebaseAuth.instance.currentUser?.uid ?? "";

  Set<Marker> _markers = {};
  // Cache para não processar a mesma imagem várias vezes
  final Map<String, BitmapDescriptor> _customIcons = {};

  @override
  void initState() {
    super.initState();
    _determinePosition();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  // 🔥 GERADOR DE MARCADOR CUSTOMIZADO (Foto + Nome)
  Future<BitmapDescriptor> _getClusterMarker({required String imageUrl, required String name}) async {
    if (_customIcons.containsKey(imageUrl)) return _customIcons[imageUrl]!;

    const double size = 150.0; // Tamanho total do widget do marcador
    const double imageSize = 100.0;

    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint = Paint()..color = Colors.pinkAccent;

    // 1. Desenhar fundo do nome (Retângulo arredondado embaixo)
    final RRect nameRect = RRect.fromLTRBR(10, size - 40, size - 10, size, const Radius.circular(10));
    canvas.drawRRect(nameRect, paint);

    // 2. Desenhar o Nome
    TextPainter textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: name.length > 10 ? "${name.substring(0, 8)}.." : name,
      style: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset((size - textPainter.width) / 2, size - 35));

    // 3. Desenhar Borda Rosa para a Foto
    canvas.drawCircle(const Offset(size / 2, imageSize / 2), (imageSize / 2) + 4, paint);

    // 4. Carregar e Cortar a Imagem em Círculo
    try {
      final Uint8List imageBytes = await _fetchImage(imageUrl);
      final ui.Codec codec = await ui.instantiateImageCodec(imageBytes, targetWidth: imageSize.toInt(), targetHeight: imageSize.toInt());
      final ui.FrameInfo fi = await codec.getNextFrame();

      final ui.Image image = fi.image;
      final Path clipPath = Path()..addOval(Rect.fromLTWH((size - imageSize) / 2, 0, imageSize, imageSize));
      canvas.clipPath(clipPath);
      canvas.drawImage(image, Offset((size - imageSize) / 2, 0), Paint());
    } catch (e) {
      // Se falhar, desenha um círculo cinza com ícone de pessoa
      canvas.drawCircle(const Offset(size / 2, imageSize / 2), imageSize / 2, Paint()..color = Colors.grey);
    }

    final ui.Image markerImage = await pictureRecorder.endRecording().toImage(size.toInt(), size.toInt());
    final ByteData? byteData = await markerImage.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List pngBytes = byteData!.buffer.asUint8List();

    BitmapDescriptor icon = BitmapDescriptor.fromBytes(pngBytes);
    _customIcons[imageUrl] = icon;
    return icon;
  }

  Future<Uint8List> _fetchImage(String url) async {
    final HttpClientRequest request = await HttpClient().getUrl(Uri.parse(url));
    final HttpClientResponse response = await request.close();
    final Uint8List bytes = await consolidateHttpClientResponseBytes(response);
    return bytes;
  }

  Future<void> _determinePosition() async {
    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() => _currentPosition = position);
      _mapController?.animateCamera(CameraUpdate.newLatLng(LatLng(position.latitude, position.longitude)));
    } catch (e) {
      debugPrint("Erro GPS: $e");
    }
  }

  Future<void> _updateVisibleRegion() async {
    if (_mapController == null) return;
    LatLngBounds bounds = await _mapController!.getVisibleRegion();
    setState(() => _mapBounds = bounds);
  }

  void _updateMarkers(List<QueryDocumentSnapshot> docs) async {
    Set<Marker> newMarkers = {};
    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final String userId = doc.id;
      if (userId == _myUid) continue;

      final double lat = (data['lat'] ?? 0).toDouble();
      final double lng = (data['lng'] ?? 0).toDouble();
      final String nome = data['nome'] ?? "Usuário";
      final String foto = data['foto_principal'] ?? "";

      if (lat != 0 && lng != 0) {
        // 🔥 Gera o ícone customizado com foto e nome
        BitmapDescriptor customIcon = await _getClusterMarker(
            imageUrl: foto.isNotEmpty ? foto : "https://via.placeholder.com/100",
            name: nome
        );

        newMarkers.add(
          Marker(
            markerId: MarkerId(userId),
            position: LatLng(lat, lng),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => PerfilUserScreen(peerId: userId)));
            },
            icon: customIcon,
          ),
        );
      }
    }
    setState(() => _markers = newMarkers);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      body: Stack(
        alignment: Alignment.center,
        children: [
          _currentPosition == null
              ? const Center(child: CircularProgressIndicator(color: Colors.pinkAccent))
              : GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
              zoom: 15,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
              _updateVisibleRegion();
            },
            onCameraIdle: () => _updateVisibleRegion(),
            myLocationEnabled: false,
            zoomControlsEnabled: false,
            markers: _markers,
            mapType: MapType.normal,
          ),

          // Efeito de Radar
          IgnorePointer(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Container(
                  width: MediaQuery.of(context).size.width * _controller.value * 2.5,
                  height: MediaQuery.of(context).size.width * _controller.value * 2.5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.pinkAccent.withOpacity(1 - _controller.value), width: 1.5),
                  ),
                );
              },
            ),
          ),

          _buildCentralAvatar(),

          // Stream de Usuários
          StreamBuilder<QuerySnapshot>(
            stream: (_mapBounds == null)
                ? FirebaseFirestore.instance.collection('usuarios').where('ativo', isEqualTo: true).snapshots()
                : FirebaseFirestore.instance.collection('usuarios')
                .where('ativo', isEqualTo: true)
                .where('lat', isGreaterThanOrEqualTo: _mapBounds!.southwest.latitude)
                .where('lat', isLessThanOrEqualTo: _mapBounds!.northeast.latitude)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final filteredDocs = snapshot.data!.docs.where((doc) {
                  final d = doc.data() as Map<String, dynamic>;
                  double lng = (d['lng'] ?? 0).toDouble();
                  if (_mapBounds == null) return true;
                  return lng >= _mapBounds!.southwest.longitude && lng <= _mapBounds!.northeast.longitude;
                }).toList();

                _updateMarkers(filteredDocs);
              }
              return const SizedBox.shrink();
            },
          ),

          _buildHeader(),
        ],
      ),
    );
  }

  Widget _buildCentralAvatar() {
    return IgnorePointer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.pinkAccent,
              boxShadow: [BoxShadow(color: Colors.pinkAccent.withOpacity(0.6), blurRadius: 15, spreadRadius: 2)],
            ),
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('usuarios').doc(_myUid).snapshots(),
              builder: (context, userSnapshot) {
                String? fotoUrl;
                if (userSnapshot.hasData && userSnapshot.data!.exists) {
                  fotoUrl = (userSnapshot.data!.data() as Map<String, dynamic>)['foto_principal'];
                }
                return CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFF1A1A2E),
                  backgroundImage: (fotoUrl != null && fotoUrl.isNotEmpty) ? NetworkImage(fotoUrl) : null,
                  child: (fotoUrl == null || fotoUrl.isEmpty) ? const Icon(Icons.person, color: Colors.white) : null,
                );
              },
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(color: Colors.pinkAccent, borderRadius: BorderRadius.circular(10)),
            child: const Text("VOCÊ", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Positioned(
      top: 50,
      left: 15,
      right: 15,
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), shape: BoxShape.circle),
              child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(20)),
            child: const Row(
              children: [
                Icon(Icons.radar, color: Colors.pinkAccent, size: 18),
                SizedBox(width: 8),
                Text("Radar Ativo", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const Spacer(),
          FloatingActionButton.small(
            heroTag: "btn_gps",
            backgroundColor: Colors.pinkAccent,
            onPressed: _determinePosition,
            child: const Icon(Icons.my_location, color: Colors.white),
          ),
        ],
      ),
    );
  }
}