# Dating Radar MVP - Tech Architecture & Design

## 1. Modern Tech Stack
Para um MVP ágil, escalável e com suporte nativo a geolocalização e tempo real:

*   **Frontend:** Flutter (Desenvolvimento rápido, UI fluida para o Radar).
*   **Backend:** Firebase.
    *   **Firestore:** Armazenamento de perfis e preferências.
    *   **Realtime Database:** Ideal para sincronização de coordenadas e status "online" devido à baixa latência e custo por atualização.
    *   **Firebase Auth:** Autenticação simplificada.
*   **Geolocalização:** `geoflutterfire2` para consultas geoespaciais eficientes no Firestore/Realtime DB.

---

## 2. Estrutura do Banco de Dados (Firestore)

### Coleção `users`
```json
{
  "uid": "ID_UNICO",
  "name": "João Silva",
  "phone": "+5511999998888",
  "phoneVerified": true,
  "birthday": "1995-05-20",
  "isAdult": true,
  "gender": "male",
  "photos": [
    "https://...",
    "https://..."
  ],
  "bio": "Adoro viajar e café.",
  "preferences": {
    "interestedIn": "female",
    "relationshipType": "serious",
    "ageRange": {"min": 20, "max": 35},
    "maxDistance": 50
  },
  "lastSeen": "TIMESTAMP"
}
```

### Coleção `locations` (Atualizada frequentemente)
*Nota: Para alta frequência, o Realtime Database é preferível, mas usaremos a lógica de GeoHash.*
```json
{
  "uid": "ID_UNICO",
  "position": {
    "geohash": "v2u6p",
    "geopoint": [lat, lng]
  },
  "isOnline": true
}
```

### Coleção `chats`
```json
{
  "chatId": "ID_CONVERSA",
  "participants": ["UID_1", "UID_2"],
  "lastMessage": "Olá, tudo bem?",
  "lastUpdate": "TIMESTAMP"
}
```

### Sub-coleção `messages` (dentro de um chat)
```json
{
  "senderId": "UID_1",
  "text": "Dá uma olhada nessa foto!",
  "imageUrl": "https://firebasestorage...",
  "timestamp": "TIMESTAMP",
  "type": "text" // ou "image"
}
```

---

## 3. Lógica de "Quem está online"
Para evitar mostrar perfis inativos:
1.  **Presence System:** Usamos o Firebase Realtime Database com o hook `.onDisconnect()`. Quando o app é fechado, o Firebase marca automaticamente `isOnline: false`.
2.  **Heartbeat:** O app atualiza o campo `lastSeen` a cada 5 minutos enquanto estiver em primeiro plano.
3.  **Filtro na Query:** O Radar só busca documentos onde `isOnline == true` e `lastSeen > (Agora - 10 minutos)`.

---

## 4. Privacidade: Fuzzy Logic (Offset)
Para proteger a residência do usuário, nunca enviamos a coordenada exata para outros clientes:
*   **No Backend/Escrita:** O usuário envia a posição real.
*   **Na Visualização:** O app aplica um deslocamento aleatório:
    ```dart
    newLat = lat + (Random().nextDouble() * 0.004 - 0.002); // ~200-500m
    ```
