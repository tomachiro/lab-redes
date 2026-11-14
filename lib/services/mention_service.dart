import 'package:cloud_firestore/cloud_firestore.dart';

class MentionService {
static final FirebaseFirestore _db = FirebaseFirestore.instance;

/// Extrae todos los @usuarios únicos de un texto
static List<String> extractMentions(String text) {
final regex = RegExp(r'@([a-zA-Z0-9_.-]+)');
final matches = regex.allMatches(text);
return matches
.map((m) => m.group(1) ?? '')
.where((u) => u.isNotEmpty)
.toSet()
.toList();
}

/// Envía notificaciones en Firestore a cada usuario mencionado válido
static Future<void> notifyMentions({
required String fromUser,
required String text,
required String contextLabel, // ej: "en una publicación" o "en el chat"
String? postId,
String? chatId,
}) async {
if (fromUser.startsWith('Invitado_')) return;
final mentioned = extractMentions(text);
if (mentioned.isEmpty) return;

final usersSnap = await _db.collection('users').get();
final Map<String, String> validUserMap = {};
for (final doc in usersSnap.docs) {
final data = doc.data();
final uname = (data['username'] ?? doc.id).toString();
final isAnon =
data['isAnonymous'] == true || uname.startsWith('Invitado_');
if (!isAnon && uname.isNotEmpty) {
validUserMap[uname.toLowerCase()] = uname;
}
}

final preview = text.length > 70 ? '${text.substring(0, 70)}...' : text;

for (final raw in mentioned) {
final target = validUserMap[raw.toLowerCase()];
if (target == null || target == fromUser) continue;

await _db
.collection('users')
.doc(target)
.collection('notifications')
.add({
'type': 'mention',
'fromUser': fromUser,
'message': '@$fromUser te mencionó $contextLabel: "$preview"',
'postId': postId,
'chatId': chatId,
'read': false,
'createdAt': FieldValue.serverTimestamp(),
});
}
}
}
