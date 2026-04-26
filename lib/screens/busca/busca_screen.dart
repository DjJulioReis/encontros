import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/custom_bottom_nav.dart';
import '../../core/colors.dart';
import '../../core/location_controller.dart';
import '../../core/distance_service.dart';
import '../../core/utils.dart';
import '../perfil/edit_profile_screen.dart';
import '../home/home_screen.dart';

class BuscaScreen extends StatefulWidget {
  const BuscaScreen({super.key});

  @override
  State<BuscaScreen> createState() => _BuscaScreenState();
}

class _BuscaScreenState extends State<BuscaScreen> {
  Offset position = Offset.zero;
  double angle = 0;
  int currentPhoto = 0;
  final String _myUid = FirebaseAuth.instance.currentUser?.uid ?? "";

  // 🔥 REGISTRA INTERAÇÃO E VERIFICA MATCH
  Future<void> _registrarInteracao(String targetId, String tipo, String targetName, String targetPhoto) async {
    await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(_myUid)
        .collection('interacoes')
        .doc(targetId)
        .set({
      'tipo': tipo,
      'timestamp': FieldValue.serverTimestamp(),
    });

    if (tipo == 'like') {
      DocumentSnapshot checkMatch = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(targetId)
          .collection('interacoes')
          .doc(_myUid)
          .get();

      if (checkMatch.exists && checkMatch['tipo'] == 'like') {
        _exibirTelaDeMatch(targetName, targetPhoto);
      }
    }

    setState(() {
      position = Offset.zero;
      angle = 0;
      currentPhoto = 0;
    });
  }

  // ✨ SEGUNDA CHANCE: Apaga descartes para voltarem ao deck
  Future<void> _segundaChance() async {
    final batch = FirebaseFirestore.instance.batch();
    var descartes = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(_myUid)
        .collection('interacoes')
        .where('tipo', isEqualTo: 'descarte')
        .get();

    if (descartes.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nenhum descarte para restaurar.")),
      );
      return;
    }

    for (var doc in descartes.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
    setState(() => currentPhoto = 0);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Perfis restaurados!"), backgroundColor: Colors.green),
    );
  }

  void _exibirTelaDeMatch(String nome, String foto) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Scaffold(
        backgroundColor: Colors.black.withOpacity(0.95),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("ITS A MATCH!",
                  style: TextStyle(color: Colors.pinkAccent, fontSize: 45, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic)),
              const SizedBox(height: 40),
              CircleAvatar(radius: 85, backgroundImage: NetworkImage(foto), backgroundColor: Colors.white10),
              const SizedBox(height: 25),
              Text("Você e $nome se curtiram!", style: const TextStyle(color: Colors.white, fontSize: 20)),
              const SizedBox(height: 60),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pinkAccent,
                    minimumSize: const Size(250, 55),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text("CONTINUAR BUSCANDO", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final myLocation = context.watch<LocationController>();

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('usuarios').doc(_myUid).snapshots(),
        builder: (context, meuPerfilSnapshot) {
          if (meuPerfilSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.pinkAccent));
          }

          if (!meuPerfilSnapshot.hasData || !meuPerfilSnapshot.data!.exists) {
            return const Center(child: Text("Sincronizando...", style: TextStyle(color: Colors.white)));
          }

          final meusDados = meuPerfilSnapshot.data!.data() as Map<String, dynamic>?;
          if (meusDados == null) return const SizedBox();

          final meuRaio = (meusDados['distancia_maxima'] ?? 50).toDouble();
          List<String> minhasPreps = (meusDados['preferencia'] is List)
              ? List<String>.from(meusDados['preferencia'])
              : [];

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('usuarios').where('ativo', isEqualTo: true).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Colors.pinkAccent));
              }

              return FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance.collection('usuarios').doc(_myUid).collection('interacoes').get(),
                builder: (context, interSnapshot) {
                  if (interSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Colors.pinkAccent));
                  }

                  if (!interSnapshot.hasData || snapshot.data == null) return const SizedBox();

                  List<String> vistos = interSnapshot.data!.docs.map((d) => d.id).toList();
                  vistos.add(_myUid);

                  final filtrados = snapshot.data!.docs.where((doc) {
                    final d = doc.data() as Map<String, dynamic>;
                    if (vistos.contains(doc.id)) return false;

                    if (minhasPreps.isNotEmpty && !minhasPreps.contains("Todos")) {
                      if (!minhasPreps.contains(d['genero'])) return false;
                    }

                    if (myLocation.lat != null && d['lat'] != null) {
                      double dist = DistanceService.calculateDistance(myLocation.lat!, myLocation.lng!, d['lat'], d['lng']);
                      return dist <= meuRaio;
                    }
                    return true;
                  }).toList();

                  if (filtrados.isEmpty) return _buildEmptyState();

                  final target = filtrados[0];
                  final targetData = target.data() as Map<String, dynamic>;

                  // 🔥 Tratamento de imagens seguro
                  List<String> imgs = [];
                  if (targetData['fotos'] != null && (targetData['fotos'] as List).isNotEmpty) {
                    imgs = List<String>.from(targetData['fotos']);
                  } else if (targetData['foto_principal'] != null) {
                    imgs = [targetData['foto_principal']];
                  }

                  return _buildSwiperUI(target.id, targetData, imgs, myLocation);
                },
              );
            },
          );
        },
      ),
      bottomNavigationBar: const CustomBottomNav(currentIndex: 0),
    );
  }

  Widget _buildSwiperUI(String id, Map<String, dynamic> data, List<String> imgs, LocationController myLocation) {
    // 🔥 Proteção contra lista de imagens vazia
    List<String> imagensSeguras = imgs.isNotEmpty ? imgs : ["https://via.placeholder.com/500"];
    String fotoParaMatch = imagensSeguras[0];

    double lat = data['lat']?.toDouble() ?? 0.0;
    double lng = data['lng']?.toDouble() ?? 0.0;
    double d = DistanceService.calculateDistance(myLocation.lat ?? 0.0, myLocation.lng ?? 0.0, lat, lng);
    int idade = UserUtils.calcularIdade(data['data_nascimento']);

    return Stack(
      children: [
        Center(
          child: GestureDetector(
            onPanUpdate: (details) => setState(() { position += details.delta; angle = position.dx * 0.001; }),
            onPanEnd: (_) {
              if (position.dx > 120) _registrarInteracao(id, 'like', data['nikname'] ?? 'Alguém', fotoParaMatch);
              else if (position.dx < -120) _registrarInteracao(id, 'descarte', '', '');
              else setState(() { position = Offset.zero; angle = 0; });
            },
            onTapUp: (details) {
              final w = MediaQuery.of(context).size.width;
              if (details.localPosition.dx > w / 2) {
                if (currentPhoto < imagensSeguras.length - 1) setState(() => currentPhoto++);
              } else {
                if (currentPhoto > 0) setState(() => currentPhoto--);
              }
            },
            child: Transform.translate(
              offset: position,
              child: Transform.rotate(angle: angle, child: _card(data, imagensSeguras, d, idade)),
            ),
          ),
        ),
        Positioned(
          bottom: 30, left: 0, right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _circleBtn(Icons.close, Colors.redAccent, () => _registrarInteracao(id, 'descarte', '', '')),
              _circleBtn(Icons.favorite, Colors.pinkAccent, () => _registrarInteracao(id, 'like', data['nikname'] ?? 'Alguém', fotoParaMatch), isMain: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _card(Map<String, dynamic> data, List<String> imgs, double d, int idade) {
    // 🔥 Garante que o index da foto nunca quebre o card
    int safeIndex = (currentPhoto < imgs.length) ? currentPhoto : 0;

    return Container(
      width: MediaQuery.of(context).size.width * 0.92,
      height: MediaQuery.of(context).size.height * 0.68,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 10)]),
      child: Stack(
        children: [
          ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                imgs[safeIndex],
                fit: BoxFit.cover,
                height: double.infinity,
                width: double.infinity,
                errorBuilder: (ctx, err, stack) => Container(color: Colors.black, child: const Icon(Icons.broken_image, color: Colors.white24)),
              )
          ),
          Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.center, colors: [Colors.black.withOpacity(0.95), Colors.transparent]))),
          Positioned(
              bottom: 25, left: 20, right: 20,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text("${data['nikname'] ?? 'Usuário'}, $idade", style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.pinkAccent, size: 16),
                    const SizedBox(width: 5),
                    Text("a ${d.toStringAsFixed(1)} km", style: const TextStyle(color: Colors.white70, fontSize: 16)),
                  ],
                ),
              ])
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person_search, size: 80, color: Colors.white12),
            const SizedBox(height: 20),
            const Text("Acabaram as opções!", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _segundaChance,
              icon: const Icon(Icons.undo, color: Colors.orangeAccent),
              label: const Text("SEGUNDA CHANCE", style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white10, minimumSize: const Size(double.infinity, 55)),
            ),
            const SizedBox(height: 15),
            ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen())),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent, minimumSize: const Size(double.infinity, 55), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
              child: const Text("AUMENTAR ALCANCE", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _circleBtn(IconData icon, Color color, VoidCallback onTap, {bool isMain = false}) {
    return GestureDetector(
        onTap: onTap,
        child: Container(
          width: isMain ? 75 : 60, height: isMain ? 75 : 60,
          decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF1A1A2E), border: Border.all(color: color.withOpacity(0.6), width: 2)),
          child: Icon(icon, color: Colors.white, size: isMain ? 32 : 24),
        )
    );
  }
}