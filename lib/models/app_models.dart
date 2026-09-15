import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String id;
  final String author;
  final String content;
  final String? mediaUrl;
  final String? mediaType; // 'image' o 'video'
  final List<String> likes;
  final DateTime? createdAt;

  PostModel({
    required this.id,
    required this.author,
    required this.content,
    this.mediaUrl,
    this.mediaType,
    required this.likes,
    this.createdAt,
  });

  factory PostModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return PostModel(
      id: doc.id,
      author: data['author'] ?? 'Anónimo',
      content: data['content'] ?? '',
      mediaUrl: data['mediaUrl'],
      mediaType: data['mediaType'],
      likes: List<String>.from(data['likes'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
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
      author: data['author'] ?? 'Anónimo',
      text: data['text'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
