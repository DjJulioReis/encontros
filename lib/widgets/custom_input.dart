import 'package:flutter/material.dart';
import '../core/colors.dart';

class CustomInput extends StatelessWidget {
  final String hint;
  final TextEditingController? controller; // 🔌 O pino de saída de dados
  final bool obscureText;                 // 🔒 Para esconder a senha
  final TextInputType keyboardType;       // ⌨️ Tipo de teclado (email, tel, etc)

  const CustomInput({
    super.key,
    required this.hint,
    this.controller,             // Adicionado no construtor
    this.obscureText = false,    // Padrão é mostrar o texto
    this.keyboardType = TextInputType.text, // Padrão é texto comum
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,     // 🔌 Conecta o controle ao campo real
      obscureText: obscureText,   // Aplica a máscara de senha
      keyboardType: keyboardType, // Aplica o tipo de teclado
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: AppColors.backgroundSoft,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        // Adicionado um preenchimento interno para ficar mais elegante
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),
    );
  }
}