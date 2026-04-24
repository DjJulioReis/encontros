import 'package:encontros/screens/busca/busca_screen.dart';
import 'package:encontros/screens/home/home_screen.dart';
import 'package:encontros/screens/parceiros/parceiros_screen.dart';
import 'package:flutter/material.dart';
import '../../core/colors.dart';
import '../navigation/bottom_navigation.dart'; // Seu menu global

class ChatScreen extends StatefulWidget {
  final String name;

  const ChatScreen({super.key, required this.name});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController controller = TextEditingController();

  List<Map<String, dynamic>> messages = [
    {"text": "Oi 😏", "isMe": false},
    {"text": "Tudo bem?", "isMe": true},
  ];

  void sendMessage() {
    if (controller.text.isEmpty) return;

    setState(() {
      messages.add({
        "text": controller.text,
        "isMe": true,
      });
    });

    controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.name),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // mensagens
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];

                return Align(
                  alignment: msg["isMe"]
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: msg["isMe"]
                          ? AppColors.primaryPink
                          : AppColors.backgroundSoft,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(msg["text"]),
                  ),
                );
              },
            ),
          ),

          // input
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            color: AppColors.backgroundSoft,
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
                  ),
                ),
                IconButton(
                  onPressed: sendMessage,
                  icon: const Icon(Icons.send, color: Colors.white),
                )
              ],
            ),
          )
        ],
      ),

    );
  }
}