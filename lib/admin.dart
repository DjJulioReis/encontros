import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class AdminFakesScreen extends StatefulWidget {
  const AdminFakesScreen({super.key});

  @override
  State<AdminFakesScreen> createState() => _AdminFakesScreenState();
}

class _AdminFakesScreenState extends State<AdminFakesScreen> {
  bool _isCreating = false;

  // Lista de dados fakes para o teste
  final List<Map<String, dynamic>> _fakes = [
    {
      "nome": "Carla Oliveira",
      "nikname": "carla_vibe",
      "bio": "Amo viajar e conhecer novos lugares. ✈️",
      "foto": "https://images.unsplash.com/photo-1494790108377-be9c29b29330",
    },
    {
      "nome": "Marcos Silva",
      "nikname": "marcos_dev",
      "bio": "Café, código e rock n roll. 🎸",
      "foto": "https://images.unsplash.com/photo-1500648767791-00dcc994a43e",
    },
    {
      "nome": "Beatriz Santos",
      "nikname": "bia_fitness",
      "bio": "Treino sério e pizza no fds. 🍕",
      "foto": "https://images.unsplash.com/photo-1438761681033-6461ffad8d80",
    },
    {
      "nome": "Ricardo Lima",
      "nikname": "rick_surf",
      "bio": "O mar acalma a alma. 🌊",
      "foto": "https://images.unsplash.com/photo-1472099645785-5658abf4ff4e",
    },
  ];

  Future<void> _gerarFakesProximos() async {
    setState(() => _isCreating = true);

    try {
      // 1. Pega sua localização atual como base
      Position myPos = await Geolocator.getCurrentPosition();

      WriteBatch batch = FirebaseFirestore.instance.batch();

      for (var fake in _fakes) {
        // 2. Gera um deslocamento aleatório de ~500m a 2km
        double offsetLat = (math.Random().nextDouble() - 0.5) / 50;
        double offsetLng = (math.Random().nextDouble() - 0.5) / 50;

        String fakeUid = "fake_${math.Random().nextInt(999999)}";
        DocumentReference ref = FirebaseFirestore.instance.collection('usuarios').doc(fakeUid);

        batch.set(ref, {
          "uid": fakeUid,
          "nome": fake['nome'],
          "nikname": fake['nikname'],
          "bio": fake['bio'],
          "fotos": [fake['foto']],
          "foto_principal": fake['foto'],
          "lat": myPos.latitude + offsetLat,
          "lng": myPos.longitude + offsetLng,
          "altura": 1.60 + (math.Random().nextDouble() * 0.3),
          "distancia_maxima": 50.0,
          "tipo_relacao": ["Amizade", "Conversar"],
          "preferencia": ["Ambos"],
          "bebida": ["Bebo socialmente"],
          "fuma": ["Não fumo"],
          "online": true,
          "ativo": true,
          "criado_em": FieldValue.serverTimestamp(),
          "is_fake": true, // Para facilitar deletar depois
        });
      }

      await batch.commit();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("4 Fakes criados próximos a você!")));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro: $e")));
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  Future<void> _limparFakes() async {
    final query = await FirebaseFirestore.instance
        .collection('usuarios')
        .where('is_fake', isEqualTo: true)
        .get();

    WriteBatch batch = FirebaseFirestore.instance.batch();
    for (var doc in query.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Fakes removidos!")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(title: const Text("Gerador de Fakes (Testes)"), backgroundColor: Colors.transparent),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people_outline, size: 100, color: Colors.pinkAccent),
            const SizedBox(height: 30),
            if (_isCreating)
              const CircularProgressIndicator(color: Colors.pinkAccent)
            else ...[
              ElevatedButton(
                onPressed: _gerarFakesProximos,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent, padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15)),
                child: const Text("CRIAR 4 FAKES PERTO DE MIM"),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: _limparFakes,
                child: const Text("Limpar fakes da DB", style: TextStyle(color: Colors.white38)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}