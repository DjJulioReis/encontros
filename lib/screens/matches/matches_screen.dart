import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/custom_bottom_nav.dart';
import '../chat/chat_screen.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  final String _myUid = FirebaseAuth.instance.currentUser?.uid ?? "";

  // 🔥 ACEITAR MATCH: Quando você clica no card do topo
  Future<void> _aceitarMatch(String targetId, String nome) async {
    try {
      List<String> ids = [_myUid, targetId];
      ids.sort();
      String chatId = ids.join('_');

      // 1. Cria o Chat
      await FirebaseFirestore.instance.collection('chats').doc(chatId).set({
        'users': [_myUid, targetId],
        'lastUpdate': FieldValue.serverTimestamp(),
        'lastMessage': "Novo Match! Comece a conversar...",
      }, SetOptions(merge: true));

      // 2. Remove da subcoleção 'interacoes' para sumir do carrossel
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(_myUid)
          .collection('interacoes')
          .doc(targetId)
          .delete();

      if (mounted) {
        Navigator.push(context, MaterialPageRoute(
            builder: (_) => ChatScreen(peerId: targetId, peerName: nome)
        ));
      }
    } catch (e) {
      debugPrint("Erro ao aceitar match: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(
        title: const Text("Matches e Mensagens", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Text("Pessoas que te curtiram", style: TextStyle(color: Colors.pinkAccent, fontWeight: FontWeight.bold, fontSize: 16)),
            ),

            // --- CARROSSEL DE LIKES RECEBIDOS ---
            SizedBox(
              height: 70,
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('usuarios')
                    .doc(_myUid)
                    .collection('interacoes')
                    .where('tipo', isEqualTo: 'like')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox();
                  final docs = snapshot.data!.docs;
                  if (docs.isEmpty) return const Padding(padding: EdgeInsets.only(left: 20), child: Text("Ninguém novo.", style: TextStyle(color: Colors.white24)));

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    scrollDirection: Axis.horizontal,
                    itemCount: docs.length,
                    itemBuilder: (context, index) => _buildCardPendente(docs[index].id),
                  );
                },
              ),
            ),

            const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Divider(color: Colors.white10, height: 40)),

            const Padding(padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10), child: Text("Conversas", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 16))),

            // --- LISTA DE CHATS ATIVOS ---
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .where('users', arrayContains: _myUid)
                  .orderBy('lastUpdate', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox();
                final docs = snapshot.data!.docs;
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var chatData = docs[index].data() as Map<String, dynamic>;
                    String targetId = (chatData['users'] as List).firstWhere((id) => id != _myUid);
                    return _buildChatItem(targetId, chatData['lastMessage'] ?? "Dê um oi!");
                  },
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNav(currentIndex: 4),
    );
  }

  // Widget para os Cards Pequenos de 70px
  Widget _buildCardPendente(String targetUid) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('usuarios').doc(targetUid).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        var data = snapshot.data!.data() as Map<String, dynamic>?;
        if (data == null) return const SizedBox();

        return GestureDetector(
          onTap: () => _aceitarMatch(targetUid, data['nikname'] ?? "Usuário"),
          child: Container(
            width: 70,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              image: DecorationImage(image: NetworkImage(data['foto_principal'] ?? ""), fit: BoxFit.cover),
            ),
          ),
        );
      },
    );
  }

  // Widget para a Lista de Conversas
  Widget _buildChatItem(String targetUid, String lastMsg) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('usuarios').doc(targetUid).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        var data = snapshot.data!.data() as Map<String, dynamic>;
        return ListTile(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(peerId: targetUid, peerName: data['nikname']))),
          leading: CircleAvatar(backgroundImage: NetworkImage(data['foto_principal'] ?? "")),
          title: Text(data['nikname'] ?? "Usuário", style: const TextStyle(color: Colors.white)),
          subtitle: Text(lastMsg, style: const TextStyle(color: Colors.white38), maxLines: 1),
        );
      },
    );
  }
}