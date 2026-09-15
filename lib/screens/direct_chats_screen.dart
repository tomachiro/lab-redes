import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/app_strings.dart';
import 'chat_screen.dart';

class DirectChatsScreen extends StatelessWidget {
  final String currentUserId;

  const DirectChatsScreen({super.key, required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.directMessagesTitle)),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('users', arrayContains: currentUserId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final chatDocs = snapshot.data?.docs.toList() ?? [];

          if (chatDocs.isEmpty) {
            return const Center(child: Text(AppStrings.noActiveChats));
          }

          // Ordenar chats por última actualización en memoria
          chatDocs.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aTime = aData['updatedAt'] as Timestamp?;
            final bTime = bData['updatedAt'] as Timestamp?;

            if (aTime == null) return 1;
            if (bTime == null) return -1;
            return bTime.compareTo(aTime);
          });

          return ListView.builder(
            itemCount: chatDocs.length,
            itemBuilder: (context, index) {
              final data = chatDocs[index].data() as Map<String, dynamic>;
              final users = List<String>.from(data['users'] ?? []);
              final partnerId = users.firstWhere(
                (id) => id != currentUserId,
                orElse: () => '',
              );

              if (partnerId.isEmpty) return const SizedBox.shrink();

              return ListTile(
                leading: CircleAvatar(child: Text(partnerId[0].toUpperCase())),
                title: Text(
                  partnerId,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  data['lastMessage'] ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(
                      currentUserId: currentUserId,
                      chatPartnerId: partnerId,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
