import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/app_strings.dart';
import 'profile_screen.dart';

class UserSearchScreen extends StatefulWidget {
  final String currentUserId;

  const UserSearchScreen({super.key, required this.currentUserId});

  @override
  State<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends State<UserSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<String> _searchHistory = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _searchHistory =
          prefs.getStringList('search_history_${widget.currentUserId}') ?? [];
    });
  }

  Future<void> _saveToHistory(String username) async {
    final prefs = await SharedPreferences.getInstance();
    _searchHistory.remove(username);
    _searchHistory.insert(0, username);
    if (_searchHistory.length > 10) {
      _searchHistory.removeLast();
    }
    await prefs.setStringList(
      'search_history_${widget.currentUserId}',
      _searchHistory,
    );
    setState(() {});
  }

  Future<void> _clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('search_history_${widget.currentUserId}');
    setState(() => _searchHistory.clear());
  }

  void _openProfile(String username) {
    _saveToHistory(username);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileScreen(
          currentUserId: widget.currentUserId,
          profileUserId: username,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: AppStrings.searchUserHint,
            border: InputBorder.none,
          ),
          onChanged: (val) =>
              setState(() => _searchQuery = val.trim().toLowerCase()),
        ),
      ),
      body: _searchQuery.isEmpty
          ? _buildHistoryView()
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final users =
                    snapshot.data?.docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final username = (data['username'] ?? '')
                          .toString()
                          .toLowerCase();
                      return username.contains(_searchQuery) &&
                          username != widget.currentUserId.toLowerCase();
                    }).toList() ??
                    [];

                if (users.isEmpty) {
                  return const Center(child: Text(AppStrings.noUsersFound));
                }

                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final userData =
                        users[index].data() as Map<String, dynamic>;
                    final username =
                        userData['username'] ?? AppStrings.anonymousUser;

                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(username[0].toUpperCase()),
                      ),
                      title: Text(
                        username,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onTap: () => _openProfile(username),
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _buildHistoryView() {
    if (_searchHistory.isEmpty) {
      return const Center(child: Text('Escribe para buscar usuarios'));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recientes',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: _clearHistory,
                child: const Text('Borrar todo'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _searchHistory.length,
            itemBuilder: (context, index) {
              final user = _searchHistory[index];
              return ListTile(
                leading: const Icon(Icons.history),
                title: Text(user),
                onTap: () => _openProfile(user),
              );
            },
          ),
        ),
      ],
    );
  }
}
