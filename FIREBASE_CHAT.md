# Integração Real-Time com Firebase (Chat & Status)

Para transformar este protótipo em um chat funcional, utilizamos o **Cloud Firestore** e o **Realtime Database**.

### 1. Mensagens em Tempo Real (Firestore)
No Flutter, usamos `Streams` para ouvir mudanças na coleção de mensagens.
```dart
StreamBuilder<QuerySnapshot>(
  stream: FirebaseFirestore.instance
      .collection('chats')
      .doc(chatId)
      .collection('messages')
      .orderBy('timestamp')
      .snapshots(),
  builder: (context, snapshot) {
    // Retorna o ListView.builder com os dados reais
  },
)
```

### 2. Indicador "Digitando..." (Realtime Database)
Para evitar custos excessivos de leitura/escrita no Firestore, o status de digitação é feito no **Firebase Realtime Database**, que é mais eficiente para dados efêmeros.
```dart
// Ao mudar o texto:
database.ref("typing/$chatId/$myId").set(true);

// Listener para o outro usuário:
database.ref("typing/$chatId/$otherId").onValue.listen((event) {
  setState(() => isTyping = event.snapshot.value ?? false);
});
```

### 3. Envio de Imagens (Firebase Storage)
1. O usuário seleciona a imagem com `image_picker`.
2. A imagem é enviada para o **Firebase Storage**.
3. A URL pública gerada é salva no documento da mensagem no Firestore com `type: "image"`.

### 4. Status Online/Offline
Utilizamos o sistema de presença já documentado em `ONLINE_LOGIC.md`, integrando-o ao cabeçalho do chat para exibir a bolinha verde ou o "visto por último".
