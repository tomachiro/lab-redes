import 'mention_service.dart';
import '../utils/app_strings.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService {
static final FirebaseFirestore _db = FirebaseFirestore.instance;

static String getChatId(String user1, String user2) {
List<String> ids = [user1, user2]..sort();
return ids.join('_');
}

static String _todayUtcKey([DateTime? dt]) {
final now = (dt ?? DateTime.now()).toUtc();
final m = now.month.toString().padLeft(2, '0');
final d = now.day.toString().padLeft(2, '0');
return '${now.year}-$m-$d';
}

static String _yesterdayUtcKey() {
final yesterday = DateTime.now().toUtc().subtract(const Duration(days: 1));
return _todayUtcKey(yesterday);
}

/// Crea un chat grupal y devuelve su chatId
static Future<String> createGroupChat({
required String creatorId,
required String groupName,
required List<String> memberIds,
}) async {
final uniqueMembers = <String>{creatorId, ...memberIds}.toList()..sort();
final docRef = _db.collection('chats').doc();
final timestamp = FieldValue.serverTimestamp();

await docRef.set({
'isGroup': true,
'groupName': groupName.trim(),
'users': uniqueMembers,
'createdBy': creatorId,
'lastMessage': '$creatorId creó el grupo "$groupName"',
'lastSender': creatorId,
'updatedAt': timestamp,
'workoutStreak': 0,
'dietStreak': 0,
});

await docRef.collection('messages').add({
'senderId': creatorId,
'message': '👋 Grupo "$groupName" creado. ¡Completen sus rutinas y dietas juntos para subir la racha!',
'type': 'system',
'timestamp': timestamp,
});

return docRef.id;
}

/// Envía un mensaje normal a un chat individual o grupal
static Future<void> sendMessage({
required String senderId,
String? receiverId,
String? chatId,
required String message,
String type = 'text',
String? activityCategory,
}) async {
final resolvedChatId =
chatId ?? getChatId(senderId, receiverId ?? '');
final timestamp = FieldValue.serverTimestamp();

final Map<String, dynamic> chatUpdate = {
'lastMessage': message,
'lastSender': senderId,
'updatedAt': timestamp,
};

if (chatId == null && receiverId != null) {
chatUpdate['users'] = [senderId, receiverId];
chatUpdate['isGroup'] = false;
}

await _db
.collection('chats')
.doc(resolvedChatId)
.set(chatUpdate, SetOptions(merge: true));

await _db
.collection('chats')
.doc(resolvedChatId)
.collection('messages')
.add({
'senderId': senderId,
'receiverId': ?receiverId,
'message': message,
'type': type,
'activityCategory': ?activityCategory,
'timestamp': timestamp,
});

await MentionService.notifyMentions(
fromUser: senderId,
text: message,
contextLabel: 'en un chat',
chatId: resolvedChatId,
);
}

/// Registra el cumplimiento diario de ejercicio o dieta en el chat
/// Cuando TODOS los miembros completan el mismo día, sube la racha compartida
static Future<void> logSharedActivity({
required String chatId,
required String senderId,
required String category, // 'workout' | 'diet'
String? detail,
String? partnerId,
}) async {
final chatRef = _db.collection('chats').doc(chatId);
final today = _todayUtcKey();
final yesterday = _yesterdayUtcKey();

await _db.runTransaction((tx) async {
final snap = await tx.get(chatRef);
final data = snap.data() ?? {};

List<String> users = List<String>.from(data['users'] ?? []);
if (users.isEmpty && partnerId != null) {
users = [senderId, partnerId];
}

final bool isWorkout = category == 'workout';
final String streakField = isWorkout ? 'workoutStreak' : 'dietStreak';
final String lastDateField =
isWorkout ? 'lastWorkoutStreakDate' : 'lastDietStreakDate';
final String dayListField =
isWorkout ? 'workoutCompletedList' : 'dietCompletedList';
final String dayKeyField =
isWorkout ? 'workoutCompletedDay' : 'dietCompletedDay';

int currentStreak = data[streakField] ?? 0;
final String? lastCompletedDay = data[lastDateField] as String?;
final String? recordedDay = data[dayKeyField] as String?;

// Si es un día nuevo, reiniciar el progreso diario
List<String> completedToday = recordedDay == today
? List<String>.from(data[dayListField] ?? [])
: <String>[];

if (!completedToday.contains(senderId)) {
completedToday.add(senderId);
}

// Verificar si todos los miembros del chat cumplieron hoy
final bool allCompleted =
users.isNotEmpty && users.every((u) => completedToday.contains(u));

String newLastDate = lastCompletedDay ?? '';
if (allCompleted && lastCompletedDay != today) {
if (lastCompletedDay == yesterday) {
currentStreak += 1;
} else {
currentStreak = 1;
}
newLastDate = today;
}

final String label = isWorkout
? AppStrings.workoutCheckinLog
: AppStrings.dietCheckinLog;
final bool isGroupChat = data['isGroup'] == true || users.length > 2;
final otherMembers = users.where((u) => u != senderId).toList();
final autoTags = (isGroupChat && otherMembers.isNotEmpty)
? ' ${otherMembers.map((u) => '@$u').join(' ')}'
: '';
final baseMsg = (detail != null && detail.trim().isNotEmpty)
? '$label: ${detail.trim()}'
: label;
final String fullMsg = '$baseMsg$autoTags';

tx.set(
chatRef,
{
if (users.isNotEmpty) 'users': users,
streakField: currentStreak,
if (newLastDate.isNotEmpty) lastDateField: newLastDate,
dayKeyField: today,
dayListField: completedToday,
'lastMessage': fullMsg,
'lastSender': senderId,
'updatedAt': FieldValue.serverTimestamp(),
},
SetOptions(merge: true),
);

final msgRef = chatRef.collection('messages').doc();
tx.set(msgRef, {
'senderId': senderId,
'receiverId': ?partnerId,
'message': fullMsg,
'type': 'checkin',
'activityCategory': category,
'timestamp': FieldValue.serverTimestamp(),
});
});

final updatedSnap = await chatRef.get();
final updatedData = updatedSnap.data() ?? {};
final lastMsg = (updatedData['lastMessage'] ?? '').toString();
if (lastMsg.contains('@')) {
await MentionService.notifyMentions(
fromUser: senderId,
text: lastMsg,
contextLabel: 'en un ejercicio grupal',
chatId: chatId,
);
}
}

/// Calcula la racha efectiva actual del chat (0 si se rompió ayer)
static int getEffectiveChatStreak(
Map<String, dynamic> chatData,
String category,
) {
final bool isWorkout = category == 'workout';
final String streakField = isWorkout ? 'workoutStreak' : 'dietStreak';
final String lastDateField =
isWorkout ? 'lastWorkoutStreakDate' : 'lastDietStreakDate';

final int saved = chatData[streakField] ?? 0;
final String? lastDay = chatData[lastDateField] as String?;
if (saved == 0 || lastDay == null) return 0;

final today = _todayUtcKey();
final yesterday = _yesterdayUtcKey();
if (lastDay == today || lastDay == yesterday) {
return saved;
}
return 0;
}

/// Devuelve cuántos usuarios han completado la actividad hoy
static List<String> getTodayCompletedUsers(
Map<String, dynamic> chatData,
String category,
) {
final bool isWorkout = category == 'workout';
final String dayListField =
isWorkout ? 'workoutCompletedList' : 'dietCompletedList';
final String dayKeyField =
isWorkout ? 'workoutCompletedDay' : 'dietCompletedDay';

if (chatData[dayKeyField] != _todayUtcKey()) return [];
return List<String>.from(chatData[dayListField] ?? []);
}
}
