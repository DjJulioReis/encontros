import 'package:flutter/material.dart';
import '../../core/colors.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  final List<Map<String, String>> chats = const [
    {"name": "Ana 🔥", "message": "Oi, tudo bem?", "time": "12:30"},
    {"name": "Julia 😈", "message": "Vamos sair hoje?", "time": "11:10"},
    {"name": "Carla 💋", "message": "Gostei de você", "time": "Ontem"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chat 💬"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView.builder(
        itemCount: chats.length,
        itemBuilder: (context, index) {
          final chat = chats[index];

          return ListTile(
            leading: const CircleAvatar(
              radius: 25,
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: Colors.black),
            ),
            title: Text(chat["name"]!),
            subtitle: Text(
              chat["message"]!,
              style: const TextStyle(color: Colors.white54),
            ),
            trailing: Text(
              chat["time"]!,
              style: const TextStyle(fontSize: 12),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatScreen(name: chat["name"]!),
                ),
              );
            },
          );
        },
      ),
    );
  }
}