import 'package:cloud_firestore/cloud_firestore.dart';

class StreakService {
static final FirebaseFirestore _db = FirebaseFirestore.instance;

static Future<DocumentReference> _getUserDocRef(String username) async {
final query = await _db
.collection('users')
.where('username', isEqualTo: username)
.limit(1)
.get();

if (query.docs.isNotEmpty) {
return query.docs.first.reference;
}
return _db.collection('users').doc(username);
}

static Future<void> registerActivity({
required String username,
required String category,
bool isHealthyDiet = true,
}) async {
if (category == 'food' && !isHealthyDiet) return;

final userRef = await _getUserDocRef(username);
final doc = await userRef.get();
final data = (doc.data() as Map<String, dynamic>?) ?? {};

final now = DateTime.now().toUtc();
final today = DateTime.utc(now.year, now.month, now.day);
final yesterday = today.subtract(const Duration(days: 1));

final String streakField =
category == 'workout' ? 'workoutStreak' : 'dietStreak';
final String lastDateField =
category == 'workout' ? 'lastWorkoutDate' : 'lastDietDate';

int currentStreak = data[streakField] ?? 0;
final Timestamp? lastTimestamp = data[lastDateField] as Timestamp?;

if (lastTimestamp != null) {
final lastDt = lastTimestamp.toDate().toUtc();
final lastDay = DateTime.utc(lastDt.year, lastDt.month, lastDt.day);

if (lastDay.isAtSameMomentAs(today)) {
return;
} else if (lastDay.isAtSameMomentAs(yesterday)) {
currentStreak += 1;
} else {
currentStreak = 1;
}
} else {
currentStreak = 1;
}

await userRef.set({
'username': username,
streakField: currentStreak,
lastDateField: Timestamp.fromDate(now),
}, SetOptions(merge: true));
}

static int getEffectiveStreak(Map<String, dynamic> userData, String type) {
final String streakField =
type == 'workout' ? 'workoutStreak' : 'dietStreak';
final String lastDateField =
type == 'workout' ? 'lastWorkoutDate' : 'lastDietDate';

final int savedStreak = userData[streakField] ?? 0;
final Timestamp? lastTimestamp = userData[lastDateField] as Timestamp?;

if (savedStreak == 0 || lastTimestamp == null) return 0;

final now = DateTime.now().toUtc();
final today = DateTime.utc(now.year, now.month, now.day);
final yesterday = today.subtract(const Duration(days: 1));

final lastDt = lastTimestamp.toDate().toUtc();
final lastDay = DateTime.utc(lastDt.year, lastDt.month, lastDt.day);

if (lastDay.isAtSameMomentAs(today) ||
lastDay.isAtSameMomentAs(yesterday)) {
return savedStreak;
}
return 0;
}
}
