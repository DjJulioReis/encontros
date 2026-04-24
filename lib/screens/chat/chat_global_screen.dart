import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

  // 🔥 Lista simulada com localização
  List<Map<String, dynamic>> messages = [
    {
      "user": "Ana",
      "text": "Alguém por perto?",
      "time": "14:00",
      "lat": -25.57,
      "lng": -48.62,
    },
    {
      "user": "Julio",
      "text": "Opa, estou aqui no centro!",
      "time": "14:05",
      "lat": -25.58,
      "lng": -48.63,
    },
    {
      "user": "Carla",
      "text": "Bora marcar algo?",
      "time": "14:06",
      "lat": -25.70, // mais longe
      "lng": -48.80,
    },
  ];

  void sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    setState(() {
      messages.add({
        "user": widget.name,
        "text": _messageController.text,
        "time": "${TimeOfDay.now().hour}:${TimeOfDay.now().minute}",
        "lat": 0.0, // depois vem do GPS
        "lng": 0.0,
      });
    });

    _messageController.clear();

    Future.delayed(const Duration(milliseconds: 200), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final myLocation = context.watch<LocationController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Chat Global (até 40km) 📍"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [

          // 💬 MENSAGENS
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];

                bool isMe = msg["user"] == widget.name;

                double distance = 0;

                if (myLocation.lat != null && myLocation.lng != null) {
                  distance = DistanceService.calculateDistance(
                    myLocation.lat!,
                    myLocation.lng!,
                    msg["lat"],
                    msg["lng"],
                  );
                }

                // 🔥 FILTRO 40KM
                if (distance > 40) {
                  return const SizedBox.shrink();
                }

                return Align(
                  alignment:
                  isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isMe
                          ? AppColors.primaryPink
                          : AppColors.backgroundSoft,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      crossAxisAlignment: isMe
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [

                        if (!isMe)
                          Text(
                            "${msg["user"]} • ${distance.toStringAsFixed(1)} km",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.pinkAccent,
                              fontSize: 12,
                            ),
                          ),

                        Text(
                          msg["text"],
                          style: const TextStyle(color: Colors.white),
                        ),

                        Text(
                          msg["time"],
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // ⌨️ INPUT
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.backgroundSoft),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: "Diga algo para quem está perto...",
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: AppColors.primaryPink),
                  onPressed: sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}