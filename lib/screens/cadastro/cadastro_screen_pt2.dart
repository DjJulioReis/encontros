import 'package:encontros/screens/cadastro/cadastro_screenPpt3.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CadastroScreenStep2 extends StatefulWidget {
  final String userId;

  const CadastroScreenStep2({super.key, required this.userId});

  @override
  State<CadastroScreenStep2> createState() => _CadastroScreenStep2State();
}

class _CadastroScreenStep2State extends State<CadastroScreenStep2> {

  String? genero;
  String? preferencia;

  bool loading = false;

  final List<String> generos = [
    "Homem",
    "Mulher",
    "Homem Trans",
    "Mulher Trans",
    "Casal"
  ];

  final List<String> preferencias = [
    "Homens",
    "Mulheres",
    "Ambos"
  ];

  Future<void> saveAndNext() async {

    if (genero == null || preferencia == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Selecione as opções")),
      );
      return;
    }

    setState(() => loading = true);

    await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(widget.userId)
        .update({
      "genero": genero,
      "preferencia": preferencia,
      "etapa": 2,
      "atualizado_em": FieldValue.serverTimestamp(),
    });

    setState(() => loading = false);

    // 👉 próxima tela
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CadastroStep3(userId: widget.userId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 60),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // 🔙 VOLTAR
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Icon(Icons.arrow_back, color: Colors.white),
            ),

            const SizedBox(height: 20),

            const Text(
              "Sobre você",
              style: TextStyle(
                color: Colors.pinkAccent,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 40),

            const Text("Seu gênero",
                style: TextStyle(color: Colors.white70)),

            const SizedBox(height: 10),

            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: generos.map((g) {
                final selected = genero == g;

                return GestureDetector(
                  onTap: () => setState(() => genero = g),
                  child: _chip(g, selected),
                );
              }).toList(),
            ),

            const SizedBox(height: 40),

            const Text("Você quer conhecer",
                style: TextStyle(color: Colors.white70)),

            const SizedBox(height: 10),

            Wrap(
              spacing: 10,
              children: preferencias.map((p) {
                final selected = preferencia == p;

                return GestureDetector(
                  onTap: () => setState(() => preferencia = p),
                  child: _chip(p, selected),
                );
              }).toList(),
            ),

            const Spacer(),

            GestureDetector(
              onTap: loading ? null : saveAndNext,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFFF2D8D),
                      Color(0xFFFF6A00),
                    ],
                  ),
                ),
                child: Center(
                  child: loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                    "Continuar",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String text, bool selected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        gradient: selected
            ? const LinearGradient(
          colors: [
            Color(0xFFFF2D8D),
            Color(0xFFFF6A00),
          ],
        )
            : null,
        color: selected ? null : Colors.white10,
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white),
      ),
    );
  }
}