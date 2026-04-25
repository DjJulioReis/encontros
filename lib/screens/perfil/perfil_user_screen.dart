import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../chat/chat_screen.dart';

class PerfilUserScreen extends StatelessWidget {
  final String peerId;

  const PerfilUserScreen({super.key, required this.peerId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('usuarios').doc(peerId).snapshots(),
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

        String nome = data['nome'] ?? "Usuário";
        String foto = data['foto_principal'] ?? "";
        String bio = data['bio'] ?? "Sem descrição disponível.";
        double altura = (data['altura'] ?? 1.70).toDouble();
        List interesses = data['interesses'] ?? [];
        List tipoRelacao = data['tipo_relacao'] ?? [];
        String filhos = data['filhos'] ?? "Não informado";
        List bebida = data['bebida'] ?? ["Não informado"];
        List fuma = data['fuma'] ?? ["Não informado"];

        return Scaffold(
          backgroundColor: const Color(0xFF0F0F1E),
          body: CustomScrollView(
            slivers: [
              // 📸 FOTO DE CAPA
              SliverAppBar(
                expandedHeight: 450,
                pinned: true,
                backgroundColor: const Color(0xFF0F0F1E),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: foto.isNotEmpty
                      ? Image.network(foto, fit: BoxFit.cover)
                      : Container(color: Colors.white10, child: const Icon(Icons.person, size: 100, color: Colors.white24)),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🔥 NOME E O BOTÃO DO CHAT "ESTILO 1" (QUE VOCÊ GOSTOU)
                      Row(
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
                                    Text("Online agora", style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // BOTÃO FLUTUANTE ROSA (O VOLTOU!)
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChatScreen(peerId: peerId, peerName: nome),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(15),
                              decoration: const BoxDecoration(
                                color: Colors.pinkAccent,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(color: Colors.pinkAccent, blurRadius: 12, spreadRadius: -2)
                                ],
                              ),
                              child: const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 28),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 25),
                      _buildSectionTitle("Sobre mim"),
                      Text(bio, style: const TextStyle(color: Colors.white70, fontSize: 16, height: 1.5)),

                      const SizedBox(height: 25),
                      _buildSectionTitle("Informações"),
                      _buildInfoRow(Icons.height, "Altura", "${altura.toStringAsFixed(2)}m"),
                      _buildInfoRow(Icons.child_care, "Filhos", filhos),
                      _buildInfoRow(Icons.local_bar, "Bebida", bebida.join(", ")),
                      _buildInfoRow(Icons.smoke_free, "Fuma", fuma.join(", ")),

                      const SizedBox(height: 25),
                      _buildSectionTitle("Interesses"),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: interesses.map((item) => _buildChip(item, Colors.pinkAccent)).toList(),
                      ),

                      const SizedBox(height: 50),

                      // 🔥 BARRA DE MATCH CORRIGIDA (SEM REPETIÇÃO)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Botão Recusar (X)
                          _buildMatchButton(
                            icon: Icons.close,
                            color: Colors.redAccent,
                            onTap: () => Navigator.pop(context),
                          ),

                          // Botão Curtir (Coração Neon)
                          _buildMatchButton(
                            icon: Icons.favorite,
                            color: Colors.pinkAccent,
                            isBig: true,
                            onTap: () => _registrarLike(context, peerId, nome),
                          ),

                          // Botão Favoritos (Estrela)
                          _buildMatchButton(
                            icon: Icons.star,
                            color: Colors.amber,
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Adicionado aos favoritos! ⭐"))
                              );
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // LÓGICA DE LIKE
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

  // WIDGETS DE ESTILO
  Widget _buildSectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
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
        Text("$label:", style: const TextStyle(color: Colors.white38, fontSize: 15)),
        const SizedBox(width: 8),
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
        boxShadow: [BoxShadow(color: color.withOpacity(0.15), blurRadius: 10)],
      ),
      child: Icon(icon, color: color, size: isBig ? 35 : 28),
    ),
  );
}