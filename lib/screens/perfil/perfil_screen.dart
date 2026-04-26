import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:video_player/video_player.dart';
import '../../core/colors.dart';
import '../../core/utils.dart';
import '../../widgets/custom_bottom_nav.dart';
import '../home/home_screen.dart';
import '../parceiros/parceiros_screen.dart';
import 'edit_profile_screen.dart';

class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key});

  // Garante que listas do Firebase não quebrem o app
  List<String> _tratarLista(dynamic data) {
    if (data is List) return List<String>.from(data);
    if (data != null && data.toString().isNotEmpty) return [data.toString()];
    return [];
  }

  // Lógica de exclusão rápida de fotos ou vídeos
  Future<void> _excluirFotoRapido(BuildContext context, String uid, List<String> fotosAtuais, int index) async {
    bool? confirmar = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text("Remover Mídia?", style: TextStyle(color: Colors.white)),
        content: const Text("Deseja apagar este item da sua galeria?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("CANCELAR")),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("EXCLUIR", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      List<String> novaLista = List.from(fotosAtuais);
      novaLista.removeAt(index);
      await FirebaseFirestore.instance.collection('usuarios').doc(uid).update({'fotos': novaLista});
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Mídia removida!"), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? "";

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('usuarios').doc(uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.pinkAccent));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Usuário não encontrado", style: TextStyle(color: Colors.white)));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final String fotoPrincipal = data['foto_principal'] ?? "";
          final List<String> fotosGaleria = _tratarLista(data['fotos']);
          final int idadeCalculada = UserUtils.calcularIdade(data['data_nascimento']);

          final List<String> interesses = _tratarLista(data['interesses']);
          final List<String> busca = _tratarLista(data['tipo_relacao']);
          final List<String> preferencias = _tratarLista(data['preferencia']);

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // HEADER COM FOTO E NOME
                Stack(
                  children: [
                    Image.network(fotoPrincipal, width: double.infinity, height: 400, fit: BoxFit.cover),
                    Container(
                      height: 400,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Colors.black.withOpacity(0.9), Colors.transparent],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 30, left: 20, right: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  "${data['nikname'] ?? 'Usuário'}, $idadeCalculada",
                                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          Text("@${data['nikname']}", style: const TextStyle(color: Colors.pinkAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                    ),
                  ],
                ),

                // GALERIA HORIZONTAL COMPACTA
                if (fotosGaleria.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.only(left: 20, top: 15, bottom: 8),
                    child: Text("Galeria", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white70)),
                  ),
                  SizedBox(
                    height: 70,
                    child: ListView.builder(
                      padding: const EdgeInsets.only(left: 20, right: 10),
                      scrollDirection: Axis.horizontal,
                      itemCount: fotosGaleria.length,
                      itemBuilder: (context, index) {
                        String url = fotosGaleria[index];
                        bool eVideo = url.contains("/video/") || url.contains(".mp4");
                        String urlExibicao = eVideo ? url.replaceAll(RegExp(r'\.(mp4|mov|avi|wmv)$'), '.jpg') : url;

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MediaViewScreen(
                                  url: url,
                                  isVideo: eVideo,
                                  onDelete: () => _excluirFotoRapido(context, uid, fotosGaleria, index),
                                ),
                              ),
                            );
                          },
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: 55, height: 55,
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  color: Colors.black26,
                                  borderRadius: BorderRadius.circular(8),
                                  image: DecorationImage(image: NetworkImage(urlExibicao), fit: BoxFit.cover),
                                ),
                                child: eVideo ? const Center(child: Icon(Icons.play_arrow, color: Colors.white, size: 18)) : null,
                              ),
                              Positioned(
                                top: -5, right: 5,
                                child: GestureDetector(
                                  onTap: () => _excluirFotoRapido(context, uid, fotosGaleria, index),
                                  child: Container(
                                    decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                                    padding: const EdgeInsets.all(3),
                                    child: const Icon(Icons.close, size: 10, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],

                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Sobre mim", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 8),
                      Text(data['bio'] ?? "Sem bio definida", style: const TextStyle(color: Colors.white70, fontSize: 15)),

                      const SizedBox(height: 25),
                      // CHIPS DE INFORMAÇÃO
                      Wrap(
                        spacing: 10, runSpacing: 10,
                        children: [
                          _buildInfoChip(Icons.height, "${(data['altura'] ?? 1.70).toStringAsFixed(2)}m"),
                          _buildInfoChip(Icons.radar, "${data['distancia_maxima']?.toInt() ?? 50}km"),
                        ],
                      ),

                      if (busca.isNotEmpty) ...[
                        const SizedBox(height: 25),
                        const Text("O que busca?", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 10),
                        Wrap(spacing: 8, children: busca.map((b) => _buildTag(b, Colors.greenAccent)).toList()),
                      ],

                      if (interesses.isNotEmpty) ...[
                        const SizedBox(height: 25),
                        const Text("Interesses", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 10),
                        Wrap(spacing: 8, children: interesses.map((i) => _buildTag(i, Colors.pinkAccent)).toList()),
                      ],

                      const SizedBox(height: 40),
                      ElevatedButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen())),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.backgroundSoft,
                          minimumSize: const Size(double.infinity, 55),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        child: const Text("EDITAR PERFIL", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: const CustomBottomNav(currentIndex: 5),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(15)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.pinkAccent),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildTag(String label, Color color) {
    return Chip(
      label: Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500)),
      backgroundColor: color.withOpacity(0.15),
      side: BorderSide(color: color.withOpacity(0.3)),
    );
  }
}

// VISUALIZADOR DE MÍDIA (FOTO E VÍDEO)
class MediaViewScreen extends StatefulWidget {
  final String url;
  final bool isVideo;
  final VoidCallback onDelete;

  const MediaViewScreen({super.key, required this.url, required this.isVideo, required this.onDelete});

  @override
  State<MediaViewScreen> createState() => _MediaViewScreenState();
}

class _MediaViewScreenState extends State<MediaViewScreen> {
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    if (widget.isVideo) {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
        ..initialize().then((_) {
          if (mounted) setState(() { _controller!.play(); _controller!.setLooping(true); });
        });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.redAccent),
            onPressed: () { Navigator.pop(context); widget.onDelete(); },
          ),
        ],
      ),
      body: Center(
        child: widget.isVideo
            ? (_controller != null && _controller!.value.isInitialized
            ? AspectRatio(aspectRatio: _controller!.value.aspectRatio, child: VideoPlayer(_controller!))
            : const CircularProgressIndicator(color: Colors.pinkAccent))
            : InteractiveViewer(child: Image.network(widget.url, fit: BoxFit.contain)),
      ),
      floatingActionButton: widget.isVideo ? FloatingActionButton(
        backgroundColor: Colors.pinkAccent,
        onPressed: () => setState(() => _controller!.value.isPlaying ? _controller!.pause() : _controller!.play()),
        child: Icon(_controller!.value.isPlaying ? Icons.pause : Icons.play_arrow),
      ) : null,
    );
  }
}