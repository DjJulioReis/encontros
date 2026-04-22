import 'package:encontros/screens/home/home_screen.dart';
import 'package:flutter/material.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_input.dart';
import '../../core/colors.dart';
import '../../widgets/bottom_nav.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.background,
              AppColors.backgroundSoft,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 🔥 LOGO
              Image.asset(
                'assets/images/logo.png',
                width: 260,
              ),

              const SizedBox(height: 40),

              // 🔹 INPUTS
              const CustomInput(hint: "Email"),
              const SizedBox(height: 16),
              const CustomInput(hint: "Senha"),

              const SizedBox(height: 30),

              // 🚀 BOTÃO ENTRAR
              CustomButton(
                text: "Entrar",
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const HomeScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 25), // Espaço entre o botão e o texto
              const Text(
                "ou continue com",
                style: TextStyle(color: Colors.white60, fontSize: 13),
              ),

              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween, // Deixa um em cada lado
                children: [
                  // Botão Google
                  Expanded(
                    child: socialButton(
                      child: Image.asset(
                        'assets/images/google.png',
                        height: 24,
                      ),
                    ),
                  ),

                  const SizedBox(width: 20), // Espaço entre os dois

                  // Botão Apple
                  Expanded(
                    child: socialButton(
                      child: const Icon(Icons.apple, color: Colors.white, size: 28),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center, // Centraliza na tela
                children: [
                  const Text(
                    "Não tem conta? ",
                    style: TextStyle(color: Colors.white60, fontSize: 16),
                  ),
                  GestureDetector(
                    onTap: () {
                      // 🚀 ABRE A PÁGINA DE CADASTRO

                    },
                    child: const Text(
                      "Criar conta",
                      style: TextStyle(
                        color: Color(0xFFFF006E), // Cor Rosa igual da imagem
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
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
        color: const Color(0xFF1A1A1A), // Cinza bem escuro
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white10), // Borda quase invisível
      ),
      child: InkWell(
        onTap: () {}, // Ação ao clicar
        borderRadius: BorderRadius.circular(15),
        child: Center(child: child),
      ),
    );
  }
}