import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/colors.dart';
import '../../core/location_controller.dart';
import '../../core/distance_service.dart';
import '../../widgets/custom_bottom_nav.dart';

class ChatGlobalScreen extends StatefulWidget {
  // 🔥 Removi o 'required name'. Agora ela busca sozinha!
  const ChatGlobalScreen({super.key});

  @override
  State<ChatGlobalScreen> createState() => _ChatGlobalScreenState();
}

class _ChatGlobalScreenState extends State<ChatGlobalScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final String _myUid = FirebaseAuth.instance.currentUser?.uid ?? "";

  // 🔥 ESTADO DO ALCANCE (RAIO)
  double _raioAjustado = 20.0;

  // 🚀 FUNÇÃO DE ENVIO PARA O FIREBASE
  Future<void> sendMessage(double? lat, double? lng) async {
    if (_messageController.text.trim().isEmpty) return;

    if (lat == null || lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("GPS não localizado.")),
      );
      return;
    }

    String text = _messageController.text.trim();
    _messageController.clear();

    try {
      // Buscamos o nikname atualizado do usuário no Firestore para a mensagem
      final userDoc = await FirebaseFirestore.instance.collection('usuarios').doc(_myUid).get();
      final String myName = userDoc.data()?['nikname'] ?? "Usuário";

      await FirebaseFirestore.instance.collection('chat_global').add({
        "user": myName, // 🔥 Nome pego direto do banco
        "uid": _myUid,
        "text": text,
        "lat": lat,
        "lng": lng,
        "timestamp": FieldValue.serverTimestamp(),
      });

      _scrollToBottom();
    } catch (e) {
      debugPrint("Erro ao enviar: $e");
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final myLocation = context.watch<LocationController>();

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Radar Chat 📍",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false, // Tiramos a seta manual para usar o BottomNav
      ),
      body: Column(
        children: [
          _buildRaioSlider(),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chat_global')
                  .orderBy('timestamp', descending: false)
                  .limitToLast(50)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator(color: Colors.pinkAccent));
                }

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    bool isMe = data["uid"] == _myUid;

                    double distance = 0;
                    if (myLocation.lat != null && myLocation.lng != null) {
                      distance = DistanceService.calculateDistance(
                        myLocation.lat!,
                        myLocation.lng!,
                        (data["lat"] ?? 0).toDouble(),
                        (data["lng"] ?? 0).toDouble(),
                      );
                    }

                    // Filtro pelo slider de alcance
                    if (distance > _raioAjustado) return const SizedBox.shrink();

                    return _buildChatBubble(data, isMe, distance);
                  },
                );
              },
            ),
          ),

          _buildInputArea(myLocation),
        ],
      ),
      // 🔥 Rodapé Padronizado (Chat é o índice 3)
      bottomNavigationBar: const CustomBottomNav(currentIndex: 3),
    );
  }

  Widget _buildRaioSlider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          const Icon(Icons.radar, color: Colors.pinkAccent, size: 20),
          Expanded(
            child: Slider(
              value: _raioAjustado,
              min: 1.0,
              max: 40.0,
              divisions: 39,
              activeColor: Colors.pinkAccent,
              inactiveColor: Colors.white10,
              label: "${_raioAjustado.round()} km",
              onChanged: (val) => setState(() => _raioAjustado = val),
            ),
          ),
          Text(
            "${_raioAjustado.round()}km",
            style: const TextStyle(color: Colors.pinkAccent, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(Map<String, dynamic> data, bool isMe, double distance) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe ? Colors.pinkAccent : const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(15),
            topRight: const Radius.circular(15),
            bottomLeft: Radius.circular(isMe ? 15 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 15),
          ),
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Text(
                "${data["user"]} • ${distance.toStringAsFixed(1)} km",
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.pinkAccent, fontSize: 11),
              ),
            Text(
              data["text"] ?? "",
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea(LocationController myLocation) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(color: Color(0xFF1A1A2E)),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: "Diga algo para quem está perto...",
                  hintStyle: TextStyle(color: Colors.white24, fontSize: 14),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => sendMessage(myLocation.lat, myLocation.lng),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send, color: Colors.pinkAccent),
              onPressed: () => sendMessage(myLocation.lat, myLocation.lng),
            ),
          ],
        ),
      ),
    );
  }
}