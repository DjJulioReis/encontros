import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/custom_bottom_nav.dart';
import '../home/home_screen.dart';
import '../chat/chat_screen.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  final String _myUid = FirebaseAuth.instance.currentUser?.uid ?? "";

  // 🔥 ACEITAR: Quando você clica no card, você dá o like de volta e abre o chat
  Future<void> _aceitarMatch(String targetId, String nome) async {
    try {
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(_myUid)
          .collection('interacoes')
          .doc(targetId)
          .set({
        'tipo': 'like',
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.push(context, MaterialPageRoute(
            builder: (_) => ChatScreen(peerId: targetId, peerName: nome)
        ));
      }
    } catch (e) {
      debugPrint("Erro ao aceitar match: $e");
    }
  }

  // 🔥 RECUSAR/EXCLUIR: Remove a interação da lista
  Future<void> _excluirInteracao(String targetId) async {
    await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(_myUid)
        .collection('interacoes')
        .doc(targetId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0F0F1E),
        appBar: AppBar(
          title: const Text("Matches e Mensagens", style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.transparent,
          centerTitle: true,
          automaticallyImplyLeading: false,
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🌟 SEÇÃO 1: QUEM TE DEU LIKE (CARDS RETANGULARES)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                child: Text(
                  "Pessoas que te curtiram",
                  style: TextStyle(color: Colors.pinkAccent.shade100, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              _buildLikesRecebidosList(),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Divider(color: Colors.white10, height: 40),
              ),

              // 💬 SEÇÃO 2: CONVERSAS ATIVAS (LISTA VERTICAL)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Text(
                  "Conversas",
                  style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              _buildChatList(),
            ],
          ),
        ),
        bottomNavigationBar: const CustomBottomNav(currentIndex: 4),
      ),
    );
  }

  Widget _buildLikesRecebidosList() {
    return SizedBox(
      height: 160, // Altura para os cards retangulares
      child: StreamBuilder<QuerySnapshot>(
        // 🔥 IMPORTANTE: Aqui você deve buscar na coleção que armazena quem DEU like em você
        // Se você seguiu a lógica de 'likes_recebidos', mude o caminho abaixo:
        stream: FirebaseFirestore.instance
            .collection('usuarios')
            .doc(_myUid)
            .collection('likes_recebidos') // Ajuste conforme seu banco
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox();
          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Padding(
              padding: EdgeInsets.only(left: 20),
              child: Text("Nenhum novo like por enquanto.", style: TextStyle(color: Colors.white24)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            scrollDirection: Axis.horizontal,
            itemCount: docs.length,
            itemBuilder: (context, index) => _buildCardPendente(docs[index].id),
          );
        },
      ),
    );
  }

  Widget _buildCardPendente(String id) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('usuarios').doc(id).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        var data = snapshot.data!.data() as Map<String, dynamic>;
        String nome = data['nikname'] ?? "Usuário";
        String foto = data['foto_principal'] ?? "";

        return GestureDetector(
          onTap: () => _aceitarMatch(id, nome),
          child: Container(
            width: 110,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              image: DecorationImage(image: NetworkImage(foto), fit: BoxFit.cover),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                ),
              ),
              padding: const EdgeInsets.all(8),
              alignment: Alignment.bottomCenter,
              child: Text(
                nome,
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildChatList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .where('users', arrayContains: _myUid)
          .orderBy('lastUpdate', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.only(top: 50),
              child: Text("Nenhuma conversa ativa ainda.", style: TextStyle(color: Colors.white24)),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            var chatData = docs[index].data() as Map<String, dynamic>;
            String targetId = (chatData['users'] as List).firstWhere((id) => id != _myUid);
            return _buildChatItem(targetId, chatData['lastMessage'] ?? "Clique para conversar", docs[index].id);
          },
        );
      },
    );
  }

  Widget _buildChatItem(String id, String lastMsg, String chatId) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('usuarios').doc(id).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        var data = snapshot.data!.data() as Map<String, dynamic>;
        String nome = data['nikname'] ?? "Usuário";

        return ListTile(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(peerId: id, peerName: nome))),
          leading: CircleAvatar(
            radius: 28,
            backgroundImage: NetworkImage(data['foto_principal'] ?? ""),
          ),
          title: Text(nome, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          subtitle: Text(lastMsg, style: const TextStyle(color: Colors.white38), maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white24),
            onPressed: () => _excluirInteracao(id),
          ),
        );
      },
    );
  }
}