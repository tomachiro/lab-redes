import 'package:flutter/material.dart';

import 'profile_screen.dart';

class UserListScreen extends StatelessWidget {
  final String title;
  final List<String> userIds;
  final String currentUserId;

  const UserListScreen({
    super.key,
    required this.title,
    required this.userIds,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: userIds.isEmpty
          ? const Center(child: Text('Lista vacía'))
          : ListView.builder(
              itemCount: userIds.length,
              itemBuilder: (context, index) {
                final username = userIds[index];
                return ListTile(
                  leading: CircleAvatar(child: Text(username[0].toUpperCase())),
                  title: Text(
                    username,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfileScreen(
                        currentUserId: currentUserId,
                        profileUserId: username,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
