import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/colors.dart';
import '../../core/location_controller.dart';
import '../../core/distance_service.dart';

class ChatGlobalScreen extends StatefulWidget {
  final String name;
  const ChatGlobalScreen({super.key, required this.name});

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

    // Se o GPS falhar, avisamos o usuário
    if (lat == null || lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("GPS não localizado. Verifique sua conexão.")),
      );
      return;
    }

    String text = _messageController.text.trim();
    _messageController.clear();

    try {
      await FirebaseFirestore.instance.collection('chat_global').add({
        "user": widget.name,
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
    // Escuta a localização em tempo real via Provider
    final myLocation = context.watch<LocationController>();

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context), // 🔥 Agora volta corretamente
        ),
        title: const Text(
          "Radar Chat 📍",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 🎚️ WIDGET DO SLIDER DE ALCANCE
          _buildRaioSlider(),

          // 💬 LISTA DE MENSAGENS (FIREBASE)
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chat_global')
                  .orderBy('timestamp', descending: false)
                  .limitToLast(50)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text("Erro ao carregar chat", style: TextStyle(color: Colors.white38)));
                }

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

                    // Cálculo de distância
                    double distance = 0;
                    if (myLocation.lat != null && myLocation.lng != null) {
                      distance = DistanceService.calculateDistance(
                        myLocation.lat!,
                        myLocation.lng!,
                        (data["lat"] ?? 0).toDouble(),
                        (data["lng"] ?? 0).toDouble(),
                      );
                    }

                    // 🔥 FILTRO DINÂMICO PELO SLIDER
                    if (distance > _raioAjustado) return const SizedBox.shrink();

                    return _buildChatBubble(data, isMe, distance);
                  },
                );
              },
            ),
          ),

          // ⌨️ CAMPO DE INPUT
          _buildInputArea(myLocation),
        ],
      ),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.pinkAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              "${_raioAjustado.round()}km",
              style: const TextStyle(color: Colors.pinkAccent, fontSize: 12, fontWeight: FontWeight.bold),
            ),
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
          boxShadow: [
            if (isMe) BoxShadow(color: Colors.pinkAccent.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  "${data["user"]} • ${distance.toStringAsFixed(1)} km",
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.pinkAccent, fontSize: 11),
                ),
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
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A2E),
        borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(25),
                ),
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
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: Colors.pinkAccent,
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white, size: 20),
                onPressed: () => sendMessage(myLocation.lat, myLocation.lng),
              ),
            ),
          ],
        ),
      ),
    );
  }
}