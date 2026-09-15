import 'package:flutter/material.dart';

import '../models/app_models.dart';
import '../utils/app_strings.dart';
import 'chat_screen.dart';

class DirectChatsScreen extends StatefulWidget {
  final String currentUserId;

  const DirectChatsScreen({super.key, required this.currentUserId});

  @override
  State<DirectChatsScreen> createState() => _DirectChatsScreenState();
}

class _DirectChatsScreenState extends State<DirectChatsScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<AppUser> _recentChats = [];
  List<AppUser> _followedUsers = [];
  List<AppUser> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadChatsAndFollowedData();
  }

  void _loadChatsAndFollowedData() {
    setState(() {
      _recentChats = [];
      _followedUsers = [];
    });
  }

  void _onSearchChanged(String query) {
    if (query.trim().isEmpty) {
      setState(() => _isSearching = false);
      return;
    }

    setState(() {
      _isSearching = true;
      _searchResults = _followedUsers
          .where((u) => u.username.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  void _openChatWith(AppUser user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DirectChatScreen(
          currentUserId: widget.currentUserId,
          peerUser: user,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.directMessagesTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: AppStrings.searchUserHint,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          Expanded(
            child: _isSearching
                ? _buildUserList(_searchResults, AppStrings.noUsersFound)
                : ListView(
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Text(
                          AppStrings.recentChatsHeader,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      if (_recentChats.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            AppStrings.noRecentChats,
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      else
                        ..._buildUserListWidgets(_recentChats),
                      const Divider(),
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Text(
                          AppStrings.followedUsersHeader,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      if (_followedUsers.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            AppStrings.noFollowedUsers,
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      else
                        ..._buildUserListWidgets(_followedUsers),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserList(List<AppUser> users, String emptyMessage) {
    if (users.isEmpty) {
      return Center(
        child: Text(emptyMessage, style: const TextStyle(color: Colors.grey)),
      );
    }
    return ListView(children: _buildUserListWidgets(users));
  }

  List<Widget> _buildUserListWidgets(List<AppUser> users) {
    return users
        .map(
          (user) => ListTile(
            leading: CircleAvatar(child: Text(user.username[0].toUpperCase())),
            title: Text(user.username),
            onTap: () => _openChatWith(user),
          ),
        )
        .toList();
  }
}
