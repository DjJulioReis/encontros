import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../chat/chat_screen.dart';

class PerfilUserScreen extends StatefulWidget {
  final String peerId;

  const PerfilUserScreen({super.key, required this.peerId});

  @override
  State<PerfilUserScreen> createState() => _PerfilUserScreenState();
}

class _PerfilUserScreenState extends State<PerfilUserScreen> {
  int _currentPhotoIndex = 0;

  // Função para tratar listas vindas do Firebase e evitar erros de tipo
  List<String> _tratarLista(dynamic data) {
    if (data is List) return List<String>.from(data);
    if (data != null && data.toString().isNotEmpty) return [data.toString()];
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      // 🔥 Buscando os dados específicos do peerId (Perfil selecionado)
      stream: FirebaseFirestore.instance.collection('usuarios').doc(widget.peerId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            backgroundColor: Color(0xFF0F0F1E),
            body: Center(child: CircularProgressIndicator(color: Colors.pinkAccent)),
          );
        }

        if (!snapshot.data!.exists) {
          return const Scaffold(
            backgroundColor: Color(0xFF0F0F1E),
            body: Center(child: Text("Usuário não encontrado", style: TextStyle(color: Colors.white))),
          );
        }

        var data = snapshot.data!.data() as Map<String, dynamic>;

        // 🔥 Lógica para unificar fotos SEM REPETIÇÃO
        String fotoPrincipal = data['foto_principal'] ?? "";
        List<String> fotosGaleria = _tratarLista(data['fotos']);

        // Usamos um Set para limpar duplicatas (mesma URL no campo principal e na lista)
        final todasAsFotos = <String>{};
        if (fotoPrincipal.isNotEmpty) todasAsFotos.add(fotoPrincipal);
        todasAsFotos.addAll(fotosGaleria.where((f) => f.isNotEmpty));

        final listaFotosFinal = todasAsFotos.toList();

        String nome = data['nikname'] ?? data['nome'] ?? "Usuário";
        String bio = data['bio'] ?? "Sem descrição disponível.";
        double altura = (data['altura'] ?? 1.70).toDouble();
        List interesses = _tratarLista(data['interesses']);

        return Scaffold(
          backgroundColor: const Color(0xFF0F0F1E),
          bottomNavigationBar: _buildBottomButtons(context, nome),
          body: Stack(
            children: [
              CustomScrollView(
                slivers: [
                  // 📸 Header com Carrossel de Fotos
                  SliverAppBar(
                    expandedHeight: 480,
                    pinned: true,
                    automaticallyImplyLeading: false,
                    backgroundColor: const Color(0xFF0F0F1E),
                    flexibleSpace: FlexibleSpaceBar(
                      background: GestureDetector(
                        onTapUp: (details) {
                          final w = MediaQuery.of(context).size.width;
                          if (details.localPosition.dx > w / 2) {
                            if (_currentPhotoIndex < listaFotosFinal.length - 1) {
                              setState(() => _currentPhotoIndex++);
                            }
                          } else {
                            if (_currentPhotoIndex > 0) {
                              setState(() => _currentPhotoIndex--);
                            }
                          }
                        },
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            listaFotosFinal.isNotEmpty
                                ? Image.network(listaFotosFinal[_currentPhotoIndex], fit: BoxFit.cover)
                                : Container(color: Colors.white10, child: const Icon(Icons.person, size: 100, color: Colors.white24)),

                            // Indicadores de fotos (Barrinhas brancas)
                            if (listaFotosFinal.length > 1)
                              Positioned(
                                top: 60, left: 15, right: 15,
                                child: Row(
                                  children: List.generate(listaFotosFinal.length, (index) => Expanded(
                                    child: Container(
                                      height: 3,
                                      margin: const EdgeInsets.symmetric(horizontal: 2),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        color: index == _currentPhotoIndex ? Colors.white : Colors.white24,
                                      ),
                                    ),
                                  )),
                                ),
                              ),

                            // Gradiente para ver o nome
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.center,
                                  colors: [Colors.black.withOpacity(0.85), Colors.transparent],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildProfileHeader(nome),
                          const SizedBox(height: 25),
                          _buildSectionTitle("Sobre mim"),
                          Text(bio, style: const TextStyle(color: Colors.white70, fontSize: 16, height: 1.5)),
                          const SizedBox(height: 25),
                          _buildSectionTitle("Informações"),
                          _buildInfoRow(Icons.height, "Altura", "${altura.toStringAsFixed(2)}m"),
                          _buildInfoRow(Icons.child_care, "Filhos", data['filhos'] ?? "Não informado"),

                          const SizedBox(height: 25),
                          _buildSectionTitle("Interesses"),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: interesses.map((item) => _buildChip(item.toString(), Colors.pinkAccent)).toList(),
                          ),
                          const SizedBox(height: 120),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Botão Voltar Superior
              Positioned(
                top: 50,
                left: 20,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: const CircleAvatar(
                    backgroundColor: Colors.black45,
                    child: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader(String nome) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(nome, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 4),
              const Row(
                children: [
                  CircleAvatar(radius: 4, backgroundColor: Colors.greenAccent),
                  SizedBox(width: 6),
                  Text("Online agora", style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(peerId: widget.peerId, peerName: nome))),
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: const BoxDecoration(color: Colors.pinkAccent, shape: BoxShape.circle),
            child: const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 28),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButtons(BuildContext context, String nome) {
    return Container(
      padding: const EdgeInsets.only(bottom: 30, top: 10),
      decoration: const BoxDecoration(color: Color(0xFF0F0F1E)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildMatchButton(icon: Icons.close, color: Colors.redAccent, onTap: () => Navigator.pop(context)),
          _buildMatchButton(icon: Icons.favorite, color: Colors.pinkAccent, isBig: true, onTap: () => _registrarLike(context, widget.peerId, nome)),
          _buildMatchButton(icon: Icons.star, color: Colors.amber, onTap: () {}),
        ],
      ),
    );
  }

  Future<void> _registrarLike(BuildContext context, String targetId, String targetName) async {
    final String myUid = FirebaseAuth.instance.currentUser?.uid ?? "";
    try {
      await FirebaseFirestore.instance.collection('usuarios').doc(myUid).collection('likes_enviados').doc(targetId).set({
        'nome': targetName,
        'timestamp': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Você curtiu $targetName! ❤️"), backgroundColor: Colors.pinkAccent));
      Future.delayed(const Duration(milliseconds: 500), () => Navigator.pop(context));
    } catch (e) { debugPrint("Erro: $e"); }
  }

  Widget _buildSectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
  );

  Widget _buildChip(String label, Color color) => Chip(
    label: Text(label, style: const TextStyle(color: Colors.white, fontSize: 13)),
    backgroundColor: color.withOpacity(0.1),
    side: BorderSide(color: color.withOpacity(0.4)),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
  );

  Widget _buildInfoRow(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Icon(icon, color: Colors.white38, size: 20),
        const SizedBox(width: 12),
        Text("$label: ", style: const TextStyle(color: Colors.white38, fontSize: 15)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
      ],
    ),
  );

  Widget _buildMatchButton({required IconData icon, required Color color, required VoidCallback onTap, bool isBig = false}) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: EdgeInsets.all(isBig ? 20 : 15),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF1A1A2E),
        border: Border.all(color: color.withOpacity(0.5), width: 2),
      ),
      child: Icon(icon, color: color, size: isBig ? 35 : 28),
    ),
  );
}