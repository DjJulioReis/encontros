import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/colors.dart';

class ChatScreen extends StatefulWidget {
  final String peerId;
  final String peerName;

  const ChatScreen({super.key, required this.peerId, required this.peerName});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final String _myUid = FirebaseAuth.instance.currentUser?.uid ?? "";
  late String _chatId;
  String? _peerImageUrl; // 🔥 Variável para guardar a foto da pessoa

  @override
  void initState() {
    super.initState();
    // Cria ID único da conversa
    if (_myUid.hashCode <= widget.peerId.hashCode) {
      _chatId = '${_myUid}_${widget.peerId}';
    } else {
      _chatId = '${widget.peerId}_$_myUid';
    }
    _getPeerProfile(); // 🔥 Busca a foto ao iniciar
  }

  // 🔥 Busca os dados da pessoa uma única vez para pegar a foto
  void _getPeerProfile() async {
    var doc = await FirebaseFirestore.instance.collection('usuarios').doc(widget.peerId).get();
    if (doc.exists) {
      setState(() {
        _peerImageUrl = doc.data()?['foto_principal'];
      });
    }
  }

  void sendMessage() async {
    if (controller.text.trim().isEmpty) return;
    String msg = controller.text.trim();
    controller.clear();

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(_chatId)
        .collection('mensagens')
        .add({
      "senderId": _myUid,
      "receiverId": widget.peerId,
      "text": msg,
      "timestamp": FieldValue.serverTimestamp(),
    });

    await FirebaseFirestore.instance.collection('chats').doc(_chatId).set({
      "lastMessage": msg,
      "lastUpdate": FieldValue.serverTimestamp(),
      "users": [_myUid, widget.peerId],
    }, SetOptions(merge: true));

    _scrollToBottom();
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
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(
        title: Row(
          children: [
            // 🔥 Miniatura no AppBar também fica top
            CircleAvatar(
              radius: 16,
              backgroundImage: _peerImageUrl != null ? NetworkImage(_peerImageUrl!) : null,
              child: _peerImageUrl == null ? const Icon(Icons.person, size: 16) : null,
            ),
            const SizedBox(width: 10),
            Text(widget.peerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(_chatId)
                  .collection('mensagens')
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator(color: Colors.pinkAccent));
                }

                var docs = snapshot.data!.docs;

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var data = docs[index].data() as Map<String, dynamic>;
                    bool isMe = data["senderId"] == _myUid;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.end, // Alinha foto na base da mensagem
                        children: [
                          // 🔥 FOTO DA OUTRA PESSOA (Só aparece se não for eu)
                          if (!isMe)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: CircleAvatar(
                                radius: 14,
                                backgroundImage: _peerImageUrl != null ? NetworkImage(_peerImageUrl!) : null,
                                child: _peerImageUrl == null ? const Icon(Icons.person, size: 14) : null,
                              ),
                            ),

                          // Bolha da Mensagem
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isMe ? AppColors.primaryPink : AppColors.backgroundSoft,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(15),
                                  topRight: const Radius.circular(15),
                                  bottomLeft: Radius.circular(isMe ? 15 : 0),
                                  bottomRight: Radius.circular(isMe ? 0 : 15),
                                ),
                              ),
                              child: Text(
                                data["text"] ?? "",
                                style: const TextStyle(color: Colors.white, fontSize: 15),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.backgroundSoft,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: "Digite uma mensagem...",
                  hintStyle: TextStyle(color: Colors.white54),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => sendMessage(),
              ),
            ),
            CircleAvatar(
              backgroundColor: Colors.pinkAccent,
              child: IconButton(
                onPressed: sendMessage,
                icon: const Icon(Icons.send, color: Colors.white, size: 20),
              ),
            )
          ],
        ),
      ),
    );
  }
}