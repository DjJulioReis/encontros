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
  // 🔥 Transformado em listas para múltipla escolha
  List<String> bebidasSelecionadas = [];
  List<String> fumaSelecionados = [];
  List<String> relacaoSelecionados = [];
  String? filhos; // Escolha única (opcional)
  double altura = 1.70;

  bool loading = false;

  final List<String> opcoesBebida = ["Não bebo", "Socialmente", "Frequentemente"];
  final List<String> opcoesFuma = ["Não", "Às vezes", "Sim"];
  final List<String> opcoesFilhos = ["Não tenho", "Tenho", "Quero ter"];
  final List<String> opcoesRelacao = ["Casual", "Algo Sério", "Novos Amigos", "Apenas papo"];

  // Função genérica para gerenciar as listas (toggle)
  void _toggleItem(List<String> lista, String item) {
    setState(() {
      if (lista.contains(item)) {
        lista.remove(item);
      } else {
        lista.add(item);
      }
    });
  }

  Future<void> saveAndNext() async {
    setState(() => loading = true);

    try {
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(widget.userId)
          .update({
        "bebida": bebidasSelecionadas, // 🔥 Salva como Array
        "fuma": fumaSelecionados,       // 🔥 Salva como Array
        "filhos": filhos,
        "tipo_relacao": relacaoSelecionados, // 🔥 Salva como Array
        "altura": altura,
        "etapa": 4,
        "atualizado_em": FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CadastroStep5(userId: widget.userId),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro: $e")));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      body: SingleChildScrollView( // Adicionado scroll para telas menores
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
                "Seu estilo de vida",
                style: TextStyle(color: Colors.pinkAccent, fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),

              // Seções com múltipla escolha
              _sectionMulti("Você bebe?", opcoesBebida, bebidasSelecionadas),
              _sectionMulti("Você fuma?", opcoesFuma, fumaSelecionados),
              _sectionMulti("O que busca?", opcoesRelacao, relacaoSelecionados),

              // Seção com escolha única (Filhos)
              _sectionSingle("Filhos", opcoesFilhos, filhos, (v) => filhos = v),

              const SizedBox(height: 20),
              const Text("Altura", style: TextStyle(color: Colors.white70)),
              Slider(
                value: altura,
                min: 1.40,
                max: 2.10,
                divisions: 70,
                label: "${altura.toStringAsFixed(2)} m",
                activeColor: Colors.pinkAccent,
                onChanged: (value) => setState(() => altura = value),
              ),
              Text("${altura.toStringAsFixed(2)} m", style: const TextStyle(color: Colors.white38)),

              const SizedBox(height: 40),

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
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
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

  // 🔥 COMPONENTE MÚLTIPLA ESCOLHA
  Widget _sectionMulti(String title, List<String> options, List<String> selectedList) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: options.map((item) {
            final isSelected = selectedList.contains(item);
            return GestureDetector(
              onTap: () => _toggleItem(selectedList, item),
              child: _chip(item, isSelected),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // 🔥 COMPONENTE ESCOLHA ÚNICA
  Widget _sectionSingle(String title, List<String> options, String? selected, Function(String) onSelect) {
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
              child: _chip(item, isSelected),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _chip(String text, bool selected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        gradient: selected ? const LinearGradient(colors: [Color(0xFFFF2D8D), Color(0xFFFF6A00)]) : null,
        color: selected ? null : Colors.white10,
      ),
      child: Text(text, style: const TextStyle(color: Colors.white)),
    );
  }
}