import 'package:encontros/screens/cadastro/cadastro_screenPpt4.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CadastroStep3 extends StatefulWidget {
  final String userId;

  const CadastroStep3({super.key, required this.userId});

  @override
  State<CadastroStep3> createState() => _CadastroStep3State();
}

class _CadastroStep3State extends State<CadastroStep3> {

  final List<String> allInteresses = [
    "🎵 Música",
    "🎬 Filmes",
    "🍻 Festa",
    "✈️ Viagem",
    "🏋️ Academia",
    "🎮 Games",
    "📚 Leitura",
    "🍔 Gastronomia",
    "🐶 Pets",
    "🏖️ Praia",
    "🌄 Natureza",
    "🚗 Carros",
    "💻 Tecnologia",
    "🎨 Arte",
    "⚽ Esportes",
  ];

  List<String> selecionados = [];

  bool loading = false;

  void toggleInteresse(String item) {
    setState(() {
      if (selecionados.contains(item)) {
        selecionados.remove(item);
      } else {
        selecionados.add(item);
      }
    });
  }

  Future<void> saveAndNext() async {

    if (selecionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Escolha pelo menos 1 interesse")),
      );
      return;
    }

    setState(() => loading = true);

    await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(widget.userId)
        .update({
      "interesses": selecionados,
      "etapa": 3,
      "atualizado_em": FieldValue.serverTimestamp(),
    });

    setState(() => loading = false);

    // 👉 próxima etapa
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CadastroStep4(userId: widget.userId),
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
              "Seus interesses",
              style: TextStyle(
                color: Colors.pinkAccent,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              "Escolha o que você curte 🔥",
              style: TextStyle(color: Colors.white54),
            ),

            const SizedBox(height: 30),

            Expanded(
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: allInteresses.map((item) {
                  final selected = selecionados.contains(item);

                  return GestureDetector(
                    onTap: () => toggleInteresse(item),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                        item,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 10),

            // 🔢 CONTADOR
            Text(
              "${selecionados.length} selecionados",
              style: const TextStyle(color: Colors.white38),
            ),

            const SizedBox(height: 20),

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
}