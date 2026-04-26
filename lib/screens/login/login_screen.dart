import 'package:encontros/screens/busca/busca_screen.dart';
import 'package:encontros/screens/home/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // 🔥 Import fundamental
import '../../widgets/custom_button.dart';
import '../../widgets/custom_input.dart';
import '../../core/colors.dart';
import '../cadastro/cadastro_screen.dart';

// 🛠️ Mudamos para StatefulWidget para gerenciar os textos dos inputs
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // 🔹 Controllers para capturar os dados
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  // 🚀 FUNÇÃO DE LOGIN REAL (Conferindo na DB)
  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showError("Preencha todos os campos");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 🔥 Aqui o sinal vai para o Firebase conferir os dados
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Se der certo, vai para a Home
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const BuscaScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      // Tratamento de erros de "senha errada" ou "usuário não existe"
      String message = "Erro ao entrar";
      if (e.code == 'user-not-found') message = "Usuário não encontrado";
      else if (e.code == 'wrong-password') message = "Senha incorreta";
      else if (e.code == 'invalid-email') message = "E-mail inválido";

      _showError(message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.background, AppColors.backgroundSoft],
          ),
        ),
        child: SingleChildScrollView( // 🔹 Evita erro de teclado subindo
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/logo.png', width: 260),
              const SizedBox(height: 40),

              // 🔹 INPUTS (Passando os controllers)
              CustomInput(
                hint: "Email",
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              CustomInput(
                hint: "Senha",
                controller: _passwordController,
                obscureText: true,
              ),

              const SizedBox(height: 30),

              // 🚀 BOTÃO ENTRAR COM LÓGICA
              _isLoading
                  ? const CircularProgressIndicator(color: AppColors.primaryPink)
                  : CustomButton(
                text: "Entrar",
                onTap: _handleLogin, // 🔥 Agora chama a função de conferência
              ),

              const SizedBox(height: 25),
              const Text("ou continue com", style: TextStyle(color: Colors.white60, fontSize: 13)),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(child: socialButton(child: Image.asset('assets/images/google.png', height: 24))),
                  const SizedBox(width: 20),
                  Expanded(child: socialButton(child: const Icon(Icons.apple, color: Colors.white, size: 28))),
                ],
              ),

              const SizedBox(height: 40),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Não tem conta? ", style: TextStyle(color: Colors.white60, fontSize: 16)),
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CadastroScreen())),
                    child: const Text(
                      "Criar conta",
                      style: TextStyle(color: Color(0xFFFF006E), fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget socialButton({required Widget child}) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white10),
      ),
      child: InkWell(
        onTap: () {}, // Ação Google/Apple futuramente
        child: Center(child: child),
      ),
    );
  }
}