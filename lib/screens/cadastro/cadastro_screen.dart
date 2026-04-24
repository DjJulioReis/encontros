import 'package:encontros/screens/cadastro/cadastro_screen_pt2.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // 🔐 Essencial para segurança
import 'package:geolocator/geolocator.dart';

class CadastroScreen extends StatefulWidget {
  const CadastroScreen({super.key});

  @override
  State<CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends State<CadastroScreen> {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool loading = false;

  // 🔥 A MÁGICA ACONTECE AQUI: Cria no Auth e depois no Firestore
  Future<String> createAccount() async {
    // 1. Cria a credencial de segurança (Gera o UID e criptografa a senha)
    UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
    );

    final String uid = userCredential.user!.uid;

    // 2. Pega a localização para o Radar
    Position position;
    try {
      position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: const Duration(seconds: 5),
      );
    } catch (e) {
      // Coordenada padrão (SP) se o GPS falhar no emulador
      position = Position(
          latitude: -23.5505, longitude: -46.6333,
          timestamp: DateTime.now(), accuracy: 0.0, altitude: 0.0,
          heading: 0.0, speed: 0.0, speedAccuracy: 0.0,
          altitudeAccuracy: 0.0, headingAccuracy: 0.0
      );
    }

    // 3. GRAVAÇÃO DEFINITIVA NO FIRESTORE
    // Usamos .doc(uid).set para o ID do documento ser IGUAL ao UID do login
    await FirebaseFirestore.instance.collection('usuarios').doc(uid).set({
      "uid": uid, // Agora o campo vai aparecer no banco!
      "nome": nameController.text.trim(),
      "telefone": phoneController.text.trim(),
      "email": emailController.text.trim(),

      // Status para o Radar
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
        phoneController.text.isEmpty ||
        passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Preencha todos os campos obrigatórios")),
      );
      return;
    }

    setState(() => loading = true);

    try {
      final userId = await createAccount();

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CadastroScreenStep2(userId: userId),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      // Erros específicos de Autenticação
      String msg = "Erro ao criar conta";
      if (e.code == 'email-already-in-use') msg = "Este e-mail já está cadastrado";
      if (e.code == 'weak-password') msg = "Senha muito curta (mínimo 6 caracteres)";

      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro técnico: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 60),
          height: MediaQuery.of(context).size.height,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Criar conta 🔥",
                style: TextStyle(color: Colors.pinkAccent, fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),
              _input("Nome", nameController, Icons.person),
              _input("Telefone", phoneController, Icons.phone, keyboard: TextInputType.phone),
              _input("Email", emailController, Icons.email, keyboard: TextInputType.emailAddress),
              _input("Senha", passwordController, Icons.lock, isPassword: true),

              const Spacer(),

              GestureDetector(
                onTap: loading ? null : next,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      gradient: const LinearGradient(colors: [Color(0xFFFF2D8D), Color(0xFFFF6A00)]),
                      boxShadow: [
                        BoxShadow(color: Colors.pinkAccent.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))
                      ]
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
      ),
    );
  }

  Widget _input(String label, TextEditingController controller, IconData icon,
      {bool isPassword = false, TextInputType keyboard = TextInputType.text}) {
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