import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/colors.dart';
import '../../core/utils.dart'; // 🔥 Importando a Regra Universal
import '../../widgets/custom_bottom_nav.dart';
import '../home/home_screen.dart';
import '../parceiros/parceiros_screen.dart';
import 'edit_profile_screen.dart';

class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key});

  // Helper para garantir que dados de lista não quebrem o app
  List<String> _tratarLista(dynamic data) {
    if (data is List) return List<String>.from(data);
    if (data != null && data.toString().isNotEmpty) return [data.toString()];
    return [];
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

          // 🔥 APLICANDO A REGRA UNIVERSAL DE IDADE
          final int idadeCalculada = UserUtils.calcularIdade(data['data_nascimento']);

          // Mapeamento das Listas
          final List<String> interesses = _tratarLista(data['interesses']);
          final List<String> preferencias = _tratarLista(data['preferencia']);
          final List<String> bebidas = _tratarLista(data['bebida']);
          final List<String> fuma = _tratarLista(data['fuma']);
          final List<String> busca = _tratarLista(data['tipo_relacao']);

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 📸 HEADER COM FOTO E INFO BÁSICA
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
                      bottom: 30,
                      left: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Exibe Nome Real + Idade dinâmica
                          Text("${data['nikname'] ?? 'Usuário'}, $idadeCalculada",
                              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                          // Nickname logo abaixo como identidade visual
                          Text("@${data['nikname']}", style: const TextStyle(color: Colors.pinkAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                    ),
                  ],
                ),

                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Sobre mim", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 8),
                      Text(data['bio'] ?? "Sem bio definida", style: const TextStyle(color: Colors.white70, fontSize: 15)),

                      const SizedBox(height: 25),

                      // 🏷️ CHIPS DE ATRIBUTOS
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _buildInfoChip(Icons.height, "${(data['altura'] ?? 1.70).toStringAsFixed(2)}m"),
                          if (bebidas.isNotEmpty) _buildInfoChip(Icons.local_bar, bebidas.join(", ")),
                          if (fuma.isNotEmpty) _buildInfoChip(Icons.smoking_rooms, fuma.join(", ")),
                          _buildInfoChip(Icons.child_care, "Filhos: ${data['filhos'] ?? 'N/A'}"),
                          _buildInfoChip(Icons.radar, "Busca: ${data['distancia_maxima']?.toInt() ?? 50}km"),
                        ],
                      ),

                      const SizedBox(height: 30),

                      // 🎯 SEÇÃO O QUE BUSCA
                      if (busca.isNotEmpty) ...[
                        const Text("O que busca?", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          children: busca.map((b) => _buildTag(b, Colors.greenAccent)).toList(),
                        ),
                        const SizedBox(height: 25),
                      ],

                      // 🔍 INTERESSE EM CONHECER (PREFERÊNCIAS)
                      const Text("Interesse em conhecer", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        children: preferencias.map((p) => _buildTag(p, Colors.blueAccent)).toList(),
                      ),

                      const SizedBox(height: 25),

                      // ✨ INTERESSES (HOBBIES)
                      const Text("Interesses", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        children: interesses.map((i) => _buildTag(i, Colors.pinkAccent)).toList(),
                      ),

                      const SizedBox(height: 40),

                      // 🔘 BOTÃO DE EDIÇÃO
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()));
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.backgroundSoft,
                            minimumSize: const Size(double.infinity, 55),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))
                        ),
                        child: const Text("EDITAR PERFIL", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 3,
        onTap: (index) {
          if (index == 3) return;
          switch (index) {
            case 0: Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen())); break;
            case 1: Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ParceirosScreen())); break;
          }
        },
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}