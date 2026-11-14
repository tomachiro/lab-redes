import '../utils/app_strings.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FitnessCalorieHelper {
static const Map<String, double> kcalPerMinute = {
AppStrings.routineWeights: 6.0,
AppStrings.routineCardio: 10.5,
AppStrings.routineHiit: 12.0,
AppStrings.routineCycling: 8.5,
AppStrings.routineWalking: 4.5,
AppStrings.routineYoga: 3.5,
};

static int estimateBurnedCalories(String routineType, int minutes) {
final rate = kcalPerMinute[routineType] ?? 6.5;
return (rate * minutes).round();
}
}

class PostModel {
final String id;
final String author;
final String content;
final String category; // 'workout' o 'food'
final String? routineType;
final int? durationMinutes;
final int? calories;
final bool? isHealthyDiet;
final String? mediaUrl;
final String? mediaType;
final List<String> likes;
final DateTime? createdAt;
final DateTime? expiresAt;

PostModel({
required this.id,
required this.author,
required this.content,
this.category = 'workout',
this.routineType,
this.durationMinutes,
this.calories,
this.isHealthyDiet,
this.mediaUrl,
this.mediaType,
required this.likes,
this.createdAt,
this.expiresAt,
});

bool get isExpired =>
expiresAt != null && expiresAt!.isBefore(DateTime.now());

static String? formatRemainingTime(DateTime? expiresAt) {
if (expiresAt == null) return null;
final diff = expiresAt.difference(DateTime.now());
if (diff.isNegative) return AppStrings.postExpired;
if (diff.inHours >= 1) {
final mins = diff.inMinutes % 60;
return AppStrings.remainingHoursMins(diff.inHours, mins);
}
if (diff.inMinutes >= 1) {
return 'Quedan ${diff.inMinutes} min';
}
return AppStrings.lessThanOneMin;
}

factory PostModel.fromFirestore(DocumentSnapshot doc) {
final data = doc.data() as Map<String, dynamic>? ?? {};
return PostModel(
id: doc.id,
author: data['author'] ?? AppStrings.anonymousUser,
content: data['content'] ?? '',
category: data['category'] ?? 'workout',
routineType: data['routineType'],
durationMinutes: data['durationMinutes'],
calories: data['calories'],
isHealthyDiet: data['isHealthyDiet'],
mediaUrl: data['mediaUrl'],
mediaType: data['mediaType'],
likes: List<String>.from(data['likes'] ?? []),
createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
expiresAt: (data['expiresAt'] as Timestamp?)?.toDate(),
);
}
}

class CommentModel {
final String id;
final String author;
final String text;
final DateTime? createdAt;

CommentModel({
required this.id,
required this.author,
required this.text,
this.createdAt,
});

factory CommentModel.fromFirestore(DocumentSnapshot doc) {
final data = doc.data() as Map<String, dynamic>? ?? {};
return CommentModel(
id: doc.id,
author: data['author'] ?? AppStrings.anonymousUser,
text: data['text'] ?? '',
createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
);
}
}
