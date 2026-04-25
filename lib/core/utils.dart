import 'package:cloud_firestore/cloud_firestore.dart';

class UserUtils {
  // 🔥 REGRA UNIVERSAL DE IDADE
  static int calcularIdade(dynamic dataNascimento) {
    if (dataNascimento == null) return 0;

    DateTime nascimento;

    // Converte se for Timestamp (Firebase) ou se já for DateTime
    if (dataNascimento is Timestamp) {
      nascimento = dataNascimento.toDate();
    } else if (dataNascimento is DateTime) {
      nascimento = dataNascimento;
    } else {
      return 0;
    }

    DateTime hoje = DateTime.now();
    int idade = hoje.year - nascimento.year;

    // Ajuste fino: Verifica se já passou o dia e mês do aniversário
    if (hoje.month < nascimento.month ||
        (hoje.month == nascimento.month && hoje.day < nascimento.day)) {
      idade--;
    }

    return idade;
  }
}