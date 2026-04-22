import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileDetailsScreen extends StatefulWidget {
  const ProfileDetailsScreen({super.key});

  @override
  State<ProfileDetailsScreen> createState() => _ProfileDetailsScreenState();
}

class _ProfileDetailsScreenState extends State<ProfileDetailsScreen> {
  String? _meuGenero;
  List<String> _interesses = []; // Aqui guardamos as múltiplas escolhas
  double _altura = 1.70;
  final _bioController = TextEditingController();

  // Opções que você solicitou
  final List<String> _opcoesBusca = [
    'Mulheres', 'Homens', 'Mulheres Trans', 'Homens Trans', 'Casais'
  ];

  Future<void> _concluirCadastro() async {
    final user = FirebaseAuth.instance.currentUser;
    if (_meuGenero == null || _interesses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Selecione seu gênero e o que procura!")),
      );
      return;
    }

    // Salvando os dados técnicos para o Radar filtrar depois
    await FirebaseFirestore.instance.collection('usuarios').doc(user?.uid).update({
      'genero': _meuGenero,
      'procura_por': _interesses, // Salva a lista ["Mulheres", "Casais"]
      'altura': _altura,
      'bio': _bioController.text,
      'cadastro_completo': true,
    });

    // Após salvar, envia para o Mapa Real
    Navigator.pushReplacementNamed(context, '/radar');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Preferências do Radar")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Eu sou:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: ['Homem', 'Mulher', 'Trans', 'Casal'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
              onChanged: (val) => setState(() => _meuGenero = val),
            ),
            const SizedBox(height: 25),

            const Text("Quem você quer encontrar? (Múltipla escolha)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: _opcoesBusca.map((opcao) {
                final isSelected = _interesses.contains(opcao);
                return FilterChip(
                  label: Text(opcao),
                  selected: isSelected,
                  selectedColor: Colors.pinkAccent,
                  onSelected: (val) {
                    setState(() {
                      val ? _interesses.add(opcao) : _interesses.remove(opcao);
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 25),

            Text("Sua Altura: ${_altura.toStringAsFixed(2)}m", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Slider(
              value: _altura, min: 1.40, max: 2.20, divisions: 80,
              activeColor: Colors.pink,
              onChanged: (v) => setState(() => _altura = v),
            ),
            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: _concluirCadastro,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.pink, minimumSize: const Size(double.infinity, 50)),
              child: const Text("ENTRAR NO RADAR", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}