import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static String getChatId(String user1, String user2) {
    List<String> ids = [user1, user2]..sort();
    return ids.join('_');
  }

  static Future<void> sendMessage({
    required String senderId,
    required String receiverId,
    required String message,
  }) async {
    final chatId = getChatId(senderId, receiverId);
    final timestamp = FieldValue.serverTimestamp();

    // Crear/actualizar metadatos del chat para listar rápido en la pantalla de mensajes
    await _db.collection('chats').doc(chatId).set({
      'users': [senderId, receiverId],
      'lastMessage': message,
      'lastSender': senderId,
      'updatedAt': timestamp,
    }, SetOptions(merge: true));

    // Agregar el mensaje a la subcolección
    await _db.collection('chats').doc(chatId).collection('messages').add({
      'senderId': senderId,
      'receiverId': receiverId,
      'message': message,
      'timestamp': timestamp,
    });
  }
}
