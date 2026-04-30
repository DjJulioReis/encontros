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
  String? genero; // Gênero do usuário (escolha única)
  List<String> preferenciasSelecionadas = []; // 🔥 Agora é uma lista!

  bool loading = false;

  final List<String> generos = [
    "Homem",
    "Mulher",
    "Homem Trans",
    "Mulher Trans",
    "Casal"
  ];

  final List<String> preferencias = [
    "Homem",
    "Mulher",
    "Homem Trans",
    "Mulher Trans",
    "Casal",
    "Todos"
  ];

  // Lógica para marcar/desmarcar preferências
  void togglePreferencia(String p) {
    setState(() {
      if (p == "Todos") {
        // Se clicar em todos, seleciona tudo ou limpa tudo
        if (preferenciasSelecionadas.length == preferencias.length - 1) {
          preferenciasSelecionadas.clear();
        } else {
          preferenciasSelecionadas = preferencias.where((item) => item != "Todos").toList();
        }
      } else {
        if (preferenciasSelecionadas.contains(p)) {
          preferenciasSelecionadas.remove(p);
        } else {
          preferenciasSelecionadas.add(p);
        }
      }
    });
  }

  Future<void> saveAndNext() async {
    if (genero == null || preferenciasSelecionadas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Selecione seu gênero e pelo menos uma preferência")),
      );
      return;
    }

    setState(() => loading = true);

    await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(widget.userId)
        .update({
      "genero": genero,
      "preferencia": preferenciasSelecionadas, // 🔥 Salva como Array no Firestore
      "etapa": 2,
      "atualizado_em": FieldValue.serverTimestamp(),
    });

    setState(() => loading = false);

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CadastroStep3(userId: widget.userId),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 60),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              const SizedBox(height: 20),
              const Text(
                "Sobre você",
                style: TextStyle(color: Colors.pinkAccent, fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),

              // SEÇÃO GÊNERO (Único)
              const Text("Seu gênero", style: TextStyle(color: Colors.white70)),
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

              // SEÇÃO PREFERÊNCIA (Múltipla)
              const Text("Você quer conhecer (escolha uma ou mais)",
                  style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: preferencias.map((p) {
                  // Lógica visual para o "Todos"
                  final selected = (p == "Todos")
                      ? preferenciasSelecionadas.length == preferencias.length - 1
                      : preferenciasSelecionadas.contains(p);

                  return GestureDetector(
                    onTap: () => togglePreferencia(p),
                    child: _chip(p, selected),
                  );
                }).toList(),
              ),

              const SizedBox(height: 60),

              GestureDetector(
                onTap: loading ? null : saveAndNext,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    gradient: const LinearGradient(colors: [Color(0xFFFF2D8D), Color(0xFFFF6A00)]),
                  ),
                  child: Center(
                    child: loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Continuar", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String text, bool selected) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        gradient: selected ? const LinearGradient(colors: [Color(0xFFFF2D8D), Color(0xFFFF6A00)]) : null,
        color: selected ? null : Colors.white10,
        border: Border.all(color: selected ? Colors.transparent : Colors.white24),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 14)),
    );
  }
}