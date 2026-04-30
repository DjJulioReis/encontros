import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_screen.dart';
import '../../core/colors.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String myUid = FirebaseAuth.instance.currentUser?.uid ?? "";

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(
        title: const Text("Conversas 💬", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // 🔥 BUSCA CONVERSAS ONDE VOCÊ É UM DOS PARTICIPANTES
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('users', arrayContains: myUid)
            .orderBy('lastUpdate', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Erro ao carregar conversas"));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.pinkAccent));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
                child: Text("Nenhuma conversa iniciada ainda...",
                    style: TextStyle(color: Colors.white54))
            );
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var chatDoc = snapshot.data!.docs[index];
              var chatData = chatDoc.data() as Map<String, dynamic>;

              // Descobrir quem é a OUTRA pessoa (não sou eu)
              List users = chatData['users'] ?? [];
              String peerId = users.firstWhere((id) => id != myUid, orElse: () => "");

              // Precisamos buscar o nome e foto da outra pessoa no Firestore
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('usuarios').doc(peerId).get(),
                builder: (context, userSnap) {
                  String peerName = "Usuário";
                  String? peerFoto;

                  if (userSnap.hasData && userSnap.data!.exists) {
                    var userData = userSnap.data!.data() as Map<String, dynamic>;
                    peerName = userData['nome'] ?? "Usuário";
                    peerFoto = userData['foto_principal'];
                  }

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                    leading: CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white10,
                      backgroundImage: (peerFoto != null && peerFoto.isNotEmpty)
                          ? NetworkImage(peerFoto)
                          : null,
                      child: (peerFoto == null || peerFoto.isEmpty)
                          ? const Icon(Icons.person, color: Colors.white)
                          : null,
                    ),
                    title: Text(peerName, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    subtitle: Text(
                      chatData['lastMessage'] ?? "Clique para conversar",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white54),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white24),
                    onTap: () {
                      // 🔥 AGORA COM OS PARÂMETROS CORRETOS
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            peerId: peerId,
                            peerName: peerName,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}