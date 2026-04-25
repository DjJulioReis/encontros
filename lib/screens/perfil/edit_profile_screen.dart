import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/colors.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final nicknameController = TextEditingController();
  final bioController = TextEditingController();

  String? nomeFixo, fotoPrincipal;
  double altura = 1.70;
  double distanciaBusca = 50.0; // 🔥 Nova variável para o Radar

  List<String> prefsSelecionadas = [];
  List<String> bebidasSelecionadas = [];
  List<String> fumaSelecionados = [];
  List<String> buscaSelecionados = [];
  String? filhos;

  bool isLoading = true;
  final String uid = FirebaseAuth.instance.currentUser!.uid;

  final List<String> opcoesPreferencia = ["Homem", "Mulher", "Homem Trans", "Mulher Trans", "Casal", "Todos"];
  final List<String> opcoesBebida = ["Não bebo", "Socialmente", "Frequentemente"];
  final List<String> opcoesFuma = ["Não", "Às vezes", "Sim"];
  final List<String> opcoesBusca = ["Casual", "Algo sério", "Novas amizades", "Apenas papo"];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final doc = await FirebaseFirestore.instance.collection('usuarios').doc(uid).get();
    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        nomeFixo = data['nome'] ?? "";
        nicknameController.text = data['nikname'] ?? "";
        bioController.text = data['bio'] ?? "";
        fotoPrincipal = data['foto_principal'];
        altura = (data['altura'] ?? 1.70).toDouble();
        distanciaBusca = (data['distancia_maxima'] ?? 50.0).toDouble(); // 🔥 Carrega a distância
        filhos = data['filhos'];

        prefsSelecionadas = List<String>.from(data['preferencia'] ?? []);
        bebidasSelecionadas = List<String>.from(data['bebida'] ?? []);
        fumaSelecionados = List<String>.from(data['fuma'] ?? []);
        buscaSelecionados = List<String>.from(data['tipo_relacao'] ?? []);

        isLoading = false;
      });
    }
  }

  void _toggleItem(List<String> lista, String item) {
    setState(() {
      if (lista.contains(item)) {
        lista.remove(item);
      } else {
        lista.add(item);
      }
    });
  }

  // 🔍 VALIDAÇÃO DE NICKNAME ÚNICO
  Future<void> _salvar() async {
    final novoNick = nicknameController.text.trim().toLowerCase();
    if (novoNick.isEmpty) return;

    setState(() => isLoading = true);

    try {
      final query = await FirebaseFirestore.instance
          .collection('usuarios')
          .where('nikname', isEqualTo: novoNick)
          .get();

      bool jaExiste = query.docs.any((doc) => doc.id != uid);

      if (jaExiste) {
        setState(() => isLoading = false);
        _mostrarSugestoes(novoNick);
        return;
      }

      await FirebaseFirestore.instance.collection('usuarios').doc(uid).update({
        'nikname': novoNick,
        'bio': bioController.text.trim(),
        'altura': altura,
        'distancia_maxima': distanciaBusca, // 🔥 Salva no Radar
        'preferencia': prefsSelecionadas,
        'bebida': bebidasSelecionadas,
        'fuma': fumaSelecionados,
        'tipo_relacao': buscaSelecionados,
        'filhos': filhos,
        'atualizado_em': FieldValue.serverTimestamp(),
      });

      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  void _mostrarSugestoes(String original) {
    List<String> sugestoes = ["${original}${math.Random().nextInt(99)}", "${original}_2026", "oficial_$original"];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text("Nickname em uso 🚫", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: sugestoes.map((s) => ListTile(
            title: Text("@$s", style: const TextStyle(color: Colors.pinkAccent)),
            onTap: () { nicknameController.text = s; Navigator.pop(ctx); },
          )).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Scaffold(backgroundColor: Color(0xFF0F0F1E), body: Center(child: CircularProgressIndicator(color: Colors.pinkAccent)));

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(title: const Text("Editar Perfil"), backgroundColor: Colors.transparent, centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            Center(
              child: CircleAvatar(
                radius: 55,
                backgroundImage: (fotoPrincipal != null) ? NetworkImage(fotoPrincipal!) : null,
                child: fotoPrincipal == null ? const Icon(Icons.person, size: 50) : null,
              ),
            ),

            _buildLabel("Nickname"),
            _buildTextField(nicknameController, "@seu_nick"),

            // 🔥 SEÇÕES DE MÚLTIPLA ESCOLHA (MEIO)
            _buildMultiSelectSection("O que você busca?", opcoesBusca, buscaSelecionados),
            _buildMultiSelectSection("Interesse em", opcoesPreferencia, prefsSelecionadas),
            _buildMultiSelectSection("Sobre bebida", opcoesBebida, bebidasSelecionadas),
            _buildMultiSelectSection("Sobre fumo", opcoesFuma, fumaSelecionados),

            const SizedBox(height: 10),

            // 🔥 DISTÂNCIA DE BUSCA (RADAR)
            _buildLabel("Raio de busca: ${distanciaBusca.toInt()} km"),
            Slider(
              value: distanciaBusca,
              min: 1, max: 300,
              divisions: 50,
              activeColor: Colors.orangeAccent,
              onChanged: (v) => setState(() => distanciaBusca = v),
            ),

            // 🔥 ALTURA
            _buildLabel("Altura: ${altura.toStringAsFixed(2)}m"),
            Slider(
              value: altura,
              min: 1.40, max: 2.20,
              activeColor: Colors.pinkAccent,
              onChanged: (v) => setState(() => altura = v),
            ),

            // 🔥 BIO NO FINAL
            _buildLabel("Sua Bio"),
            _buildTextField(bioController, "Escreva algo sobre você...", maxLines: 4),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: _salvar,
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pinkAccent,
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25))
              ),
              child: const Text("SALVAR ALTERAÇÕES", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildMultiSelectSection(String title, List<String> opcoes, List<String> selecionados) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(title),
        Wrap(
          spacing: 10, runSpacing: 10,
          children: opcoes.map((o) {
            final isSelected = selecionados.contains(o);
            return GestureDetector(
              onTap: () => _toggleItem(selecionados, o),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: isSelected ? const LinearGradient(colors: [Color(0xFFFF2D8D), Color(0xFFFF6A00)]) : null,
                  color: isSelected ? null : Colors.white10,
                ),
                child: Text(o, style: const TextStyle(color: Colors.white, fontSize: 13)),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildLabel(String t) => Padding(padding: const EdgeInsets.only(top: 20, bottom: 8), child: Text(t, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)));

  Widget _buildTextField(TextEditingController c, String h, {int maxLines = 1}) {
    return TextField(
      controller: c, maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(hintText: h, hintStyle: const TextStyle(color: Colors.white24), filled: true, fillColor: Colors.white10, border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none)),
    );
  }
}