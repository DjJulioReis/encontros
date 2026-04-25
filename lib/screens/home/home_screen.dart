import 'package:encontros/screens/busca/busca_screen.dart';
import 'package:encontros/screens/chat/chat_global_screen.dart';
import 'package:encontros/screens/parceiros/parceiros_screen.dart';
import 'package:encontros/screens/perfil/perfil_screen.dart';
import 'package:encontros/screens/radar/radar_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart'; // 🔥 Importante para o GPS
import '../../widgets/home_card.dart';
import '../../widgets/custom_bottom_nav.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final String _uid = FirebaseAuth.instance.currentUser?.uid ?? "";

  @override
  void initState() {
    super.initState();
    // 🔥 Assim que o app abre, ele atualiza sua posição no banco
    _atualizarMinhaLocalizacaoNoBanco();
  }

  // 📍 FUNÇÃO PARA SINCRONIZAR GPS COM FIREBASE
  Future<void> _atualizarMinhaLocalizacaoNoBanco() async {
    try {
      // 1. Pede permissão e pega a posição atual
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      // 2. Grava no documento do usuário logado
      if (_uid.isNotEmpty) {
        await FirebaseFirestore.instance.collection('usuarios').doc(_uid).update({
          'lat': position.latitude,
          'lng': position.longitude,
          'atualizado_em': FieldValue.serverTimestamp(),
          'online': true, // Aproveitamos para setar como online
        });
        debugPrint("✅ GPS Sincronizado: ${position.latitude}, ${position.longitude}");
      }
    } catch (e) {
      debugPrint("❌ Erro ao atualizar localização: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('usuarios').doc(_uid).snapshots(),
      builder: (context, userSnapshot) {
        String nomeUsuario = "Usuário";
        String? fotoPerfil;

        if (userSnapshot.hasData && userSnapshot.data!.exists) {
          var data = userSnapshot.data!.data() as Map<String, dynamic>;
          nomeUsuario = data['nome'] ?? "Usuário";
          fotoPerfil = data['foto_principal'];
        }

        return Scaffold(
          backgroundColor: const Color(0xFF0F0F1E),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            toolbarHeight: 80,
            title: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white10,
                  backgroundImage: (fotoPerfil != null && fotoPerfil.isNotEmpty)
                      ? NetworkImage(fotoPerfil)
                      : null,
                  child: (fotoPerfil == null || fotoPerfil.isEmpty)
                      ? const Icon(Icons.person, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Olá, $nomeUsuario 🔥",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.white)),
                    const Text("O seu Radar está ativo.",
                        style: TextStyle(color: Colors.white60, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: CustomScrollView(
              slivers: [
                SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                  ),
                  delegate: SliverChildListDelegate([
                    HomeCard(imagePath: "assets/images/radar.png", onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RadarScreen()))),
                    HomeCard(imagePath: "assets/images/parceiros.png", onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ParceirosScreen()))),
                    HomeCard(imagePath: "assets/images/buscar.png", onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BuscaScreen()))),
                    HomeCard(imagePath: "assets/images/fotos-lista.png", onTap: () {}),
                    HomeCard(imagePath: "assets/images/chat.png", onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatGlobalScreen(name: nomeUsuario)))),

                    // BATE PAPO COM CONTADOR
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        HomeCard(imagePath: "assets/images/bate_papo.png", onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatGlobalScreen(name: nomeUsuario)))),
                        Positioned(
                          top: -5,
                          right: -5,
                          child: StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance.collection('usuarios').where('online', isEqualTo: true).snapshots(),
                            builder: (context, onlineSnapshot) {
                              if (!onlineSnapshot.hasData) return const SizedBox.shrink();
                              int count = onlineSnapshot.data!.docs.length;
                              return count > 0 ? Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle),
                                constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                                child: Center(child: Text("$count", style: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold))),
                              ) : const SizedBox.shrink();
                            },
                          ),
                        ),
                      ],
                    ),
                  ]),
                ),
              ],
            ),
          ),
          bottomNavigationBar: CustomBottomNav(
            currentIndex: 0,
            onTap: (index) {
              switch (index) {
                case 1: Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const BuscaScreen())); break;
                case 2: Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ChatGlobalScreen(name: nomeUsuario))); break;
                case 3: Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PerfilScreen())); break;
              }
            },
          ),
        );
      },
    );
  }
}