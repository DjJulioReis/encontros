import 'package:encontros/screens/cadastro/cadastro_screenPpt5.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CadastroStep4 extends StatefulWidget {
  final String userId;

  const CadastroStep4({super.key, required this.userId});

  @override
  State<CadastroStep4> createState() => _CadastroStep4State();
}

class _CadastroStep4State extends State<CadastroStep4> {

  String? bebida;
  String? fuma;
  String? filhos;
  String? relacao;
  double altura = 1.70;

  bool loading = false;

  final List<String> opcoesBebida = ["Não bebo", "Socialmente", "Frequentemente"];
  final List<String> opcoesFuma = ["Não", "Às vezes", "Sim"];
  final List<String> opcoesFilhos = ["Não tenho", "Tenho", "Quero ter"];
  final List<String> opcoesRelacao = ["Casual", "Sério", "Amizade"];

  Future<void> saveAndNext() async {

    setState(() => loading = true);

    await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(widget.userId)
        .update({
      "bebida": bebida,
      "fuma": fuma,
      "filhos": filhos,
      "tipo_relacao": relacao,
      "altura": altura,
      "etapa": 4,
      "atualizado_em": FieldValue.serverTimestamp(),
    });

    setState(() => loading = false);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CadastroStep5(userId: widget.userId),
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

            // 🔙 voltar
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Icon(Icons.arrow_back, color: Colors.white),
            ),

            const SizedBox(height: 20),

            const Text(
              "Seu estilo de vida",
              style: TextStyle(
                color: Colors.pinkAccent,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 30),

            _section("Você bebe?", opcoesBebida, bebida, (v) => bebida = v),
            _section("Você fuma?", opcoesFuma, fuma, (v) => fuma = v),
            _section("Filhos", opcoesFilhos, filhos, (v) => filhos = v),
            _section("O que busca?", opcoesRelacao, relacao, (v) => relacao = v),

            const SizedBox(height: 20),

            const Text("Altura", style: TextStyle(color: Colors.white70)),

            Slider(
              value: altura,
              min: 1.40,
              max: 2.10,
              divisions: 70,
              label: "${altura.toStringAsFixed(2)} m",
              onChanged: (value) {
                setState(() => altura = value);
              },
            ),

            Text(
              "${altura.toStringAsFixed(2)} m",
              style: const TextStyle(color: Colors.white38),
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

  // 🔥 COMPONENTE REUTILIZÁVEL (CHIPS)
  Widget _section(
      String title,
      List<String> options,
      String? selected,
      Function(String) onSelect,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Text(title, style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 10),

        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: options.map((item) {

            final isSelected = selected == item;

            return GestureDetector(
              onTap: () => setState(() => onSelect(item)),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  gradient: isSelected
                      ? const LinearGradient(
                    colors: [
                      Color(0xFFFF2D8D),
                      Color(0xFFFF6A00),
                    ],
                  )
                      : null,
                  color: isSelected ? null : Colors.white10,
                ),
                child: Text(
                  item,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 20),
      ],
    );
  }
}