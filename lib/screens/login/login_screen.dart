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
                width: 200,
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
                      builder: (_) => const BottomNav(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}