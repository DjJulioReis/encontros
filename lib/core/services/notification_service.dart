import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class NotificationService {

  // 🔥 FUNÇÃO PARA ENVIAR NOTIFICAÇÃO
  // Ela busca o token do destinatário no banco e dispara o "bip"
  static Future<void> enviarNotificacao({
    required String remetenteNome,
    required String textoMensagem,
    required String destinatarioUid,
  }) async {
    try {
      // 1. Busca o fcmToken do destinatário no Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(destinatarioUid)
          .get();

      if (!userDoc.exists) return;

      String? tokenDestino = userDoc.get('fcmToken');

      if (tokenDestino == null || tokenDestino.isEmpty) {
        print("⚠️ Destinatário não tem token de notificação.");
        return;
      }

      // 2. Lógica de envio (AQUI VOCÊ USARÁ SUA CLOUD FUNCTION OU API)
      // Para testes rápidos, você pode usar o console do Firebase.
      // Em produção, o Flutter não deve enviar direto para o Google por segurança (vazamento de chaves).

      print("🚀 Tentando enviar bip para $tokenDestino");

      // NOTA: Para enviar direto do app, você precisaria da sua 'Server Key' (legado)
      // ou integrar com uma pequena Cloud Function (recomendado).

    } catch (e) {
      print("❌ Erro ao disparar notificação: $e");
    }
  }
}