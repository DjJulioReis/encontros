import 'dart:math' as math;
import 'package:encontros/screens/cadastro/cadastro_screen_pt2.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

class CadastroScreen extends StatefulWidget {
  const CadastroScreen({super.key});

  @override
  State<CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends State<CadastroScreen> {
  // 📝 Controles de texto
  final nameController = TextEditingController();
  final nicknameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // 📅 Variáveis de estado
  DateTime? dataNascimento;
  bool loading = false;

  // 💡 GERADOR DE SUGESTÕES (A função que estava faltando)
  List<String> _gerarSugestoes(String original) {
    String base = original.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    if (base.isEmpty) base = "user";
    return [
      "${base}${math.Random().nextInt(99)}",
      "${base}_2026",
      "oficial_$base",
    ];
  }

  // 📅 SELETOR DE DATA
  Future<void> _selecionarData() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.pinkAccent,
              onPrimary: Colors.white,
              surface: Color(0xFF1A1A2E),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => dataNascimento = picked);
  }

  // 🔍 VALIDAÇÃO DE NICKNAME ÚNICO
  Future<bool> _isNicknameUnique(String nick) async {
    final result = await FirebaseFirestore.instance
        .collection('usuarios')
        .where('nikname', isEqualTo: nick.toLowerCase().trim())
        .get();
    return result.docs.isEmpty;
  }

  // 🔥 CRIAÇÃO DE CONTA NO AUTH E FIRESTORE
  Future<String> createAccount() async {
    UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
    );

    final String uid = userCredential.user!.uid;

    // Pegar localização para o Radar
    Position position;
    try {
      position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: const Duration(seconds: 5),
      );
    } catch (e) {
      position = Position(
          latitude: -23.5505, longitude: -46.6333,
          timestamp: DateTime.now(), accuracy: 0.0, altitude: 0.0,
          heading: 0.0, speed: 0.0, speedAccuracy: 0.0,
          altitudeAccuracy: 0.0, headingAccuracy: 0.0
      );
    }

    await FirebaseFirestore.instance.collection('usuarios').doc(uid).set({
      "uid": uid,
      "nome": nameController.text.trim(),
      "nikname": nicknameController.text.trim().toLowerCase(),
      "data_nascimento": dataNascimento != null ? Timestamp.fromDate(dataNascimento!) : null,
      "telefone": phoneController.text.trim(),
      "email": emailController.text.trim(),
      "ativo": true,
      "online": true,
      "lat": position.latitude,
      "lng": position.longitude,
      "etapa": 1,
      "perfil_completo": false,
      "criado_em": FieldValue.serverTimestamp(),
      "atualizado_em": FieldValue.serverTimestamp(),
    });

    return uid;
  }

  void next() async {
    if (nameController.text.isEmpty ||
        nicknameController.text.isEmpty ||
        dataNascimento == null ||
        emailController.text.isEmpty ||
        passwordController.text.isEmpty) {
      _showSnack("Preencha todos os campos e a data de nascimento");
      return;
    }

    setState(() => loading = true);

    try {
      bool unico = await _isNicknameUnique(nicknameController.text);

      if (!unico) {
        setState(() => loading = false);
        _mostrarSugestoes();
        return;
      }

      final userId = await createAccount();
      if (mounted) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => CadastroScreenStep2(userId: userId)));
      }
    } on FirebaseAuthException catch (e) {
      String msg = "Erro ao criar conta";
      if (e.code == 'email-already-in-use') msg = "Este e-mail já está em uso";
      _showSnack(msg);
    } catch (e) {
      _showSnack("Erro técnico: $e");
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _mostrarSugestoes() {
    final sugeridos = _gerarSugestoes(nicknameController.text);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text("Nickname em uso 🚫", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: sugeridos.map((s) => ListTile(
            title: Text("@$s", style: const TextStyle(color: Colors.pinkAccent)),
            onTap: () {
              nicknameController.text = s;
              Navigator.pop(ctx);
            },
          )).toList(),
        ),
      ),
    );
  }

  void _showSnack(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 60),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Criar conta 🔥", style: TextStyle(color: Colors.pinkAccent, fontSize: 26, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            _input("Nome Real", nameController, Icons.person),
            _input("Nickname (Único)", nicknameController, Icons.alternate_email),

            // 🔥 CAMPO VISUAL DA DATA
            GestureDetector(
              onTap: _selecionarData,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
                margin: const EdgeInsets.only(bottom: 15),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month, color: Colors.pinkAccent),
                    const SizedBox(width: 12),
                    Text(
                      dataNascimento == null
                          ? "Data de Nascimento"
                          : "${dataNascimento!.day}/${dataNascimento!.month}/${dataNascimento!.year}",
                      style: TextStyle(
                          color: dataNascimento == null ? Colors.white38 : Colors.white,
                          fontSize: 16
                      ),
                    ),
                  ],
                ),
              ),
            ),

            _input("Telefone", phoneController, Icons.phone, keyboard: TextInputType.phone),
            _input("Email", emailController, Icons.email, keyboard: TextInputType.emailAddress),
            _input("Senha", passwordController, Icons.lock, isPassword: true),

            const SizedBox(height: 40),

            GestureDetector(
              onTap: loading ? null : next,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  gradient: const LinearGradient(colors: [Color(0xFFFF2D8D), Color(0xFFFF6A00)]),
                ),
                child: Center(
                  child: loading
                      ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text("Continuar", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _input(String label, TextEditingController controller, IconData icon, {bool isPassword = false, TextInputType keyboard = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: keyboard,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white38),
          prefixIcon: Icon(icon, color: Colors.pinkAccent),
          filled: true,
          fillColor: Colors.white.withOpacity(0.05),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        ),
      ),
    );
  }
}