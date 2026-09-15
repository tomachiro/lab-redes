class AppUser {
  final String id;
  final String username;
  final String? avatarUrl;

  AppUser({required this.id, required this.username, this.avatarUrl});
}

class ChatMessage {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.timestamp,
  });
}
