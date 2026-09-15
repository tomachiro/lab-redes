import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/app_strings.dart';
import '../main.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import 'chat_screen.dart';
import 'user_list_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String currentUserId;
  final String? profileUserId;

  const ProfileScreen({
    super.key,
    required this.currentUserId,
    this.profileUserId,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _bioController = TextEditingController();
  final _avatarUrlController = TextEditingController();

  final _convertUsernameController = TextEditingController();
  final _convertPasswordController = TextEditingController();

  bool get isMyProfile =>
      widget.profileUserId == null ||
      widget.profileUserId == widget.currentUserId;

  String get targetUser => widget.profileUserId ?? widget.currentUserId;

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  void _showConvertAnonDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(AppStrings.convertAnonTitle),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  AppStrings.convertAnonDesc,
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _convertUsernameController,
                  decoration: const InputDecoration(
                    labelText: AppStrings.usernameLabel,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _convertPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: AppStrings.passwordLabel,
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(AppStrings.cancel),
            ),
            ElevatedButton(
              onPressed: () async {
                final newUsername = _convertUsernameController.text.trim();
                final newPass = _convertPasswordController.text.trim();

                if (newUsername.isEmpty || newPass.length < 6) return;

                final email =
                    '${newUsername.toLowerCase().replaceAll(' ', '')}@labred.app';

                final nav = Navigator.of(dialogContext);

                try {
                  AuthCredential credential = EmailAuthProvider.credential(
                    email: email,
                    password: newPass,
                  );

                  UserCredential result = await FirebaseAuth
                      .instance
                      .currentUser!
                      .linkWithCredential(credential);

                  String uid = result.user!.uid;

                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(uid)
                      .set({
                        'username': newUsername,
                        'email': email,
                        'isAnonymous': false,
                      }, SetOptions(merge: true));

                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('current_user', newUsername);
                  await prefs.setBool('is_anonymous', false);

                  nav.pop();

                  if (!mounted) return;
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HomeScreen(
                        currentUserId: newUsername,
                        isAnonymous: false,
                      ),
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al vincular: $e')),
                  );
                }
              },
              child: const Text(AppStrings.save),
            ),
          ],
        );
      },
    );
  }

  void _showEditProfileDialog(String currentBio, String currentAvatar) {
    _bioController.text = currentBio;
    _avatarUrlController.text = currentAvatar;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(AppStrings.editBio),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _avatarUrlController,
                  decoration: const InputDecoration(
                    labelText: AppStrings.avatarUrlHint,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _bioController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: AppStrings.bioHint,
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(AppStrings.cancel),
            ),
            ElevatedButton(
              onPressed: () async {
                final uid = FirebaseAuth.instance.currentUser?.uid;
                final nav = Navigator.of(dialogContext);

                if (uid != null) {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(uid)
                      .set({
                        'bio': _bioController.text.trim(),
                        'avatarUrl': _avatarUrlController.text.trim(),
                      }, SetOptions(merge: true));
                }

                nav.pop();
              },
              child: const Text(AppStrings.save),
            ),
          ],
        );
      },
    );
  }

  void _showCommentsDialog(String postId) {
    final commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(modalContext).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                AppStrings.commentsTitle,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('posts')
                      .doc(postId)
                      .collection('comments')
                      .orderBy('createdAt', descending: false)
                      .snapshots(),
                  builder: (context, snapshot) {
                    final comments = snapshot.data?.docs ?? [];
                    if (comments.isEmpty) {
                      return const Center(
                        child: Text(AppStrings.noCommentsYet),
                      );
                    }
                    return ListView.builder(
                      itemCount: comments.length,
                      itemBuilder: (context, index) {
                        final c =
                            comments[index].data() as Map<String, dynamic>;
                        return ListTile(
                          title: Text(
                            c['author'] ?? AppStrings.anonymousUser,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(c['text'] ?? ''),
                        );
                      },
                    );
                  },
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: commentController,
                      decoration: const InputDecoration(
                        hintText: AppStrings.commentHint,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: () async {
                      final text = commentController.text.trim();
                      if (text.isEmpty) return;
                      commentController.clear();
                      await FirebaseFirestore.instance
                          .collection('posts')
                          .doc(postId)
                          .collection('comments')
                          .add({
                            'author': widget.currentUserId,
                            'text': text,
                            'createdAt': FieldValue.serverTimestamp(),
                          });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  void _showThemeSelector() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(AppStrings.themeTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text(AppStrings.themeLight),
                leading: const Icon(Icons.light_mode),
                onTap: () {
                  MyApp.of(context)?.changeTheme('light');
                  Navigator.pop(dialogContext);
                },
              ),
              ListTile(
                title: const Text(AppStrings.themeDark),
                leading: const Icon(Icons.dark_mode),
                onTap: () {
                  MyApp.of(context)?.changeTheme('dark');
                  Navigator.pop(dialogContext);
                },
              ),
              ListTile(
                title: const Text(AppStrings.themeWarm),
                leading: const Icon(
                  Icons.wb_sunny_outlined,
                  color: Colors.orange,
                ),
                onTap: () {
                  MyApp.of(context)?.changeTheme('warm');
                  Navigator.pop(dialogContext);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatColumn(String label, String count, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          children: [
            Text(
              count,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAnonUser = FirebaseAuth.instance.currentUser?.isAnonymous ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(targetUser),
        actions: [
          IconButton(
            icon: const Icon(Icons.palette_outlined),
            tooltip: AppStrings.themeTitle,
            onPressed: _showThemeSelector,
          ),
          if (isMyProfile)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'convert') _showConvertAnonDialog();
                if (value == 'logout') _logout();
              },
              itemBuilder: (context) => [
                if (isAnonUser)
                  const PopupMenuItem(
                    value: 'convert',
                    child: Row(
                      children: [
                        Icon(Icons.upgrade, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('Vincular Cuenta'),
                      ],
                    ),
                  ),
                const PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: Colors.red),
                      SizedBox(width: 8),
                      Text(
                        AppStrings.logout,
                        style: TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(targetUser)
            .snapshots(),
        builder: (context, userSnapshot) {
          final userData =
              userSnapshot.data?.data() as Map<String, dynamic>? ?? {};
          final bio = userData['bio'] ?? '';
          final avatarUrl = userData['avatarUrl'] ?? '';
          final followers = List<String>.from(userData['followers'] ?? []);
          final following = List<String>.from(userData['following'] ?? []);
          final isFollowing = followers.contains(widget.currentUserId);

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('posts')
                .where('author', isEqualTo: targetUser)
                .snapshots(),
            builder: (context, postsSnapshot) {
              final posts = postsSnapshot.data?.docs ?? [];

              return Column(
                children: [
                  const SizedBox(height: 16),
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: avatarUrl.isNotEmpty
                        ? NetworkImage(avatarUrl)
                        : null,
                    child: avatarUrl.isEmpty
                        ? Text(
                            targetUser.isNotEmpty
                                ? targetUser[0].toUpperCase()
                                : 'U',
                            style: const TextStyle(fontSize: 32),
                          )
                        : null,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    targetUser,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (bio.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 4,
                      ),
                      child: Text(
                        bio,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontStyle: FontStyle.italic),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatColumn('Posts', '${posts.length}', () {}),
                      _buildStatColumn('Seguidores', '${followers.length}', () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => UserListScreen(
                              title: 'Seguidores',
                              userIds: followers,
                              currentUserId: widget.currentUserId,
                            ),
                          ),
                        );
                      }),
                      _buildStatColumn('Seguidos', '${following.length}', () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => UserListScreen(
                              title: 'Seguidos',
                              userIds: following,
                              currentUserId: widget.currentUserId,
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (isMyProfile)
                    TextButton.icon(
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text(AppStrings.editBio),
                      onPressed: () => _showEditProfileDialog(bio, avatarUrl),
                    )
                  else if (!widget.currentUserId.startsWith('Invitado_'))
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isFollowing
                                ? Colors.grey[300]
                                : Colors.blue,
                            foregroundColor: isFollowing
                                ? Colors.black
                                : Colors.white,
                          ),
                          onPressed: () async {
                            if (isFollowing) {
                              followers.remove(widget.currentUserId);
                            } else {
                              followers.add(widget.currentUserId);
                            }
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(targetUser)
                                .set({
                                  'followers': followers,
                                }, SetOptions(merge: true));

                            final myDoc = await FirebaseFirestore.instance
                                .collection('users')
                                .doc(widget.currentUserId)
                                .get();
                            final myData = myDoc.data() ?? {};
                            final myFollowing = List<String>.from(
                              myData['following'] ?? [],
                            );

                            if (isFollowing) {
                              myFollowing.remove(targetUser);
                            } else {
                              myFollowing.add(targetUser);
                            }

                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(widget.currentUserId)
                                .set({
                                  'following': myFollowing,
                                }, SetOptions(merge: true));
                          },
                          icon: Icon(
                            isFollowing ? Icons.check : Icons.person_add,
                          ),
                          label: Text(
                            isFollowing
                                ? AppStrings.unfollow
                                : AppStrings.follow,
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatScreen(
                                  currentUserId: widget.currentUserId,
                                  chatPartnerId: targetUser,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.chat_bubble_outline),
                          label: const Text('Mensaje'),
                        ),
                      ],
                    ),
                  const Divider(height: 24),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        AppStrings.myPostsSection,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: posts.isEmpty
                        ? const Center(child: Text(AppStrings.noUserPosts))
                        : ListView.builder(
                            itemCount: posts.length,
                            itemBuilder: (context, index) {
                              final doc = posts[index];
                              final post = doc.data() as Map<String, dynamic>;
                              final likes = List<String>.from(
                                post['likes'] ?? [],
                              );
                              final isLiked = likes.contains(
                                widget.currentUserId,
                              );
                              final content = post['content'] ?? '';
                              final mediaUrl = post['mediaUrl'];
                              final mediaType = post['mediaType'];

                              return Card(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ListTile(
                                      leading: CircleAvatar(
                                        child: Text(
                                          targetUser[0].toUpperCase(),
                                        ),
                                      ),
                                      title: Text(
                                        targetUser,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    if (content.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 4,
                                        ),
                                        child: Text(content),
                                      ),
                                    if (mediaUrl != null && mediaUrl.isNotEmpty)
                                      Container(
                                        height: 180,
                                        margin: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.black12,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Center(
                                          child: mediaType == 'video'
                                              ? const Icon(
                                                  Icons.play_circle,
                                                  size: 50,
                                                )
                                              : Image.network(
                                                  mediaUrl,
                                                  errorBuilder: (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) => const Icon(Icons.image),
                                                ),
                                        ),
                                      ),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: Icon(
                                            isLiked
                                                ? Icons.favorite
                                                : Icons.favorite_border,
                                            color: isLiked ? Colors.red : null,
                                          ),
                                          onPressed: () async {
                                            if (isLiked) {
                                              likes.remove(
                                                widget.currentUserId,
                                              );
                                            } else {
                                              likes.add(widget.currentUserId);
                                            }
                                            await FirebaseFirestore.instance
                                                .collection('posts')
                                                .doc(doc.id)
                                                .update({'likes': likes});
                                          },
                                        ),
                                        Text('${likes.length}'),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.comment_outlined,
                                          ),
                                          onPressed: () =>
                                              _showCommentsDialog(doc.id),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
