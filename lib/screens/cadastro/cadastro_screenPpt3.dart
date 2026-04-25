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

  // 🔥 Lista para armazenar as múltiplas escolhas
  List<String> selecionados = [];
  bool loading = false;

  void toggleInteresse(String item) {
    setState(() {
      if (selecionados.contains(item)) {
        selecionados.remove(item);
      } else {
        // Opcional: Limitar a 5 ou 10 interesses para não poluir o card
        if (selecionados.length < 10) {
          selecionados.add(item);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Limite de 10 interesses atingido")),
          );
        }
      }
    });
  }

  Future<void> saveAndNext() async {
    if (selecionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Escolha pelo menos 1 interesse para continuar")),
      );
      return;
    }

    setState(() => loading = true);

    try {
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(widget.userId)
          .update({
        "interesses": selecionados, // 🔥 Salva como Array no Firestore
        "etapa": 3,
        "atualizado_em": FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CadastroStep4(userId: widget.userId),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao salvar interesses: $e")),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
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
              "Escolha o que faz seu coração bater mais forte 🔥",
              style: TextStyle(color: Colors.white54),
            ),

            const SizedBox(height: 30),

            // 🔥 GRID DE INTERESSES
            Expanded(
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: allInteresses.map((item) {
                    final isSelected = selecionados.contains(item);

                    return GestureDetector(
                      onTap: () => toggleInteresse(item),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(25),
                          gradient: isSelected
                              ? const LinearGradient(
                            colors: [Color(0xFFFF2D8D), Color(0xFFFF6A00)],
                          )
                              : null,
                          color: isSelected ? null : Colors.white10,
                          border: Border.all(
                            color: isSelected ? Colors.transparent : Colors.white24,
                          ),
                        ),
                        child: Text(
                          item,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white70,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 🔢 CONTADOR DINÂMICO
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${selecionados.length} selecionados",
                  style: const TextStyle(color: Colors.white38),
                ),
                if (selecionados.length >= 3)
                  const Text("Boa escolha! ✅", style: TextStyle(color: Colors.greenAccent, fontSize: 12)),
              ],
            ),

            const SizedBox(height: 20),

            // 🔘 BOTÃO CONTINUAR
            GestureDetector(
              onTap: loading ? null : saveAndNext,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF2D8D), Color(0xFFFF6A00)],
                  ),
                  boxShadow: selecionados.isNotEmpty
                      ? [BoxShadow(color: Colors.pinkAccent.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))]
                      : [],
                ),
                child: Center(
                  child: loading
                      ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text(
                    "Continuar",
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
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