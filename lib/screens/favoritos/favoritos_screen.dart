import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../perfil/perfil_user_screen.dart';
import '../../widgets/custom_bottom_nav.dart';
import '../../core/colors.dart';

class FavoritosScreen extends StatelessWidget {
  const FavoritosScreen({super.key});

  // 🔥 Função para remover dos favoritos
  Future<void> _removerFavorito(BuildContext context, String myUid, String targetId) async {
    try {
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(myUid)
          .collection('interacoes')
          .doc(targetId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Removido dos favoritos"),
          backgroundColor: Colors.redAccent,
          duration: Duration(seconds: 1),
        ),
      );
    } catch (e) {
      debugPrint("Erro ao remover: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final String _myUid = FirebaseAuth.instance.currentUser?.uid ?? "";

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(
        title: const Text("Meus Favoritos",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('usuarios')
            .doc(_myUid)
            .collection('interacoes')
            .where('tipo', isEqualTo: 'like')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.pinkAccent));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          var docs = snapshot.data!.docs;

          return GridView.builder(
            padding: const EdgeInsets.all(15),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.75,
            ),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              String favId = docs[index].id;
              return _buildFavCard(context, _myUid, favId); // Passamos o myUid aqui
            },
          );
        },
      ),
      bottomNavigationBar: const CustomBottomNav(currentIndex: 2),
    );
  }

  Widget _buildFavCard(BuildContext context, String myUid, String targetId) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('usuarios').doc(targetId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Container(color: Colors.white10);

        var data = snapshot.data!.data() as Map<String, dynamic>?;
        if (data == null) return const SizedBox.shrink();

        String foto = data['foto_principal'] ?? "";
        String nome = data['nikname'] ?? "Usuário";

        return GestureDetector(
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => PerfilUserScreen(peerId: targetId))
            );
          },
          child: Stack(
            children: [
              // Imagem e Nome
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  image: DecorationImage(image: NetworkImage(foto), fit: BoxFit.cover),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                    ),
                  ),
                  padding: const EdgeInsets.all(12),
                  alignment: Alignment.bottomLeft,
                  child: Text(nome,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),

              // 🔥 Botão de Excluir (X) no topo do card
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => _removerFavorito(context, myUid, targetId),
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 18),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border, size: 70, color: Colors.white.withOpacity(0.1)),
          const SizedBox(height: 15),
          const Text("Ainda não tens favoritos.",
              style: TextStyle(color: Colors.white38, fontSize: 16)),
        ],
      ),
    );
  }
}