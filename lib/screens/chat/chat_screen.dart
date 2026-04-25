import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/colors.dart';

class ChatScreen extends StatefulWidget {
  final String peerId; // ID da pessoa com quem você está falando
  final String peerName; // Nome da pessoa

  const ChatScreen({super.key, required this.peerId, required this.peerName});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final String _myUid = FirebaseAuth.instance.currentUser?.uid ?? "";
  late String _chatId;

  @override
  void initState() {
    super.initState();
    // 🔥 Cria um ID único para a conversa entre os dois
    // Ex: Julio_UID + Ana_UID sempre gera o mesmo túnel
    if (_myUid.hashCode <= widget.peerId.hashCode) {
      _chatId = '${_myUid}_${widget.peerId}';
    } else {
      _chatId = '${widget.peerId}_$_myUid';
    }
  }

  void sendMessage() async {
    if (controller.text.trim().isEmpty) return;

    String msg = controller.text.trim();
    controller.clear();

    // 🚀 Salva na coleção 'chats' -> 'ID_DA_CONVERSA' -> 'mensagens'
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

    // Atualiza a última mensagem para a lista de conversas (opcional futuro)
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
        title: Text(widget.peerName, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // 💬 MENSAGENS EM TEMPO REAL
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

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
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
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // ⌨️ INPUT AREA
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