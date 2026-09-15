import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/app_strings.dart';
import 'direct_chats_screen.dart';
import 'user_search_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  final String currentUserId;
  final bool isAnonymous;

  const HomeScreen({
    super.key,
    required this.currentUserId,
    this.isAnonymous = false,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  bool _isStoriesOpen = false;
  String? _selectedHashtag;
  StreamSubscription? _messageSubscription;
  bool _hasUnreadMessages = false;

  @override
  void initState() {
    super.initState();
    _listenForNewMessages();
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    super.dispose();
  }

  void _listenForNewMessages() {
    if (widget.isAnonymous) return;

    _messageSubscription = FirebaseFirestore.instance
        .collectionGroup('messages')
        .where('receiverId', isEqualTo: widget.currentUserId)
        .limit(1)
        .snapshots()
        .listen((snapshot) {
          if (snapshot.docChanges.isNotEmpty) {
            for (var change in snapshot.docChanges) {
              if (change.type == DocumentChangeType.added) {
                final data = change.doc.data();
                if (data != null) {
                  final sender = data['senderId'] ?? AppStrings.anonymousUser;
                  final msg = data['message'] ?? '';

                  setState(() {
                    _hasUnreadMessages = true;
                  });

                  if (!mounted) return;
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      duration: const Duration(milliseconds: 2500),
                      content: Row(
                        children: [
                          const Icon(
                            Icons.mark_chat_unread,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${AppStrings.newMessageFrom} $sender: "$msg"',
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: Colors.blueAccent,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            }
          }
        });
  }

  void _showCreateOrEditPostDialog({String? postId, String? initialText}) {
    final contentController = TextEditingController(text: initialText);
    final mediaUrlController = TextEditingController();
    bool isStory = false;
    String mediaType = 'image';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setStateDialog) {
            String dialogTitle;
            if (postId != null) {
              dialogTitle = AppStrings.editPostTitle;
            } else if (isStory) {
              dialogTitle = AppStrings.newStoryTitle;
            } else {
              dialogTitle = AppStrings.newPostTitle;
            }

            return AlertDialog(
              title: Text(dialogTitle),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: contentController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: isStory
                            ? AppStrings.storyHint
                            : AppStrings.postHint,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    if (postId == null) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: mediaUrlController,
                        decoration: const InputDecoration(
                          labelText: AppStrings.mediaUrlLabel,
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          ChoiceChip(
                            label: const Text(AppStrings.imageType),
                            selected: mediaType == 'image',
                            onSelected: (_) =>
                                setStateDialog(() => mediaType = 'image'),
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text(AppStrings.videoType),
                            selected: mediaType == 'video',
                            onSelected: (_) =>
                                setStateDialog(() => mediaType = 'video'),
                          ),
                        ],
                      ),
                      if (!widget.isAnonymous) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Checkbox(
                              value: isStory,
                              onChanged: (val) {
                                setStateDialog(() => isStory = val ?? false);
                              },
                            ),
                            const Text(AppStrings.publishAsStory),
                          ],
                        ),
                      ],
                    ],
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
                    final text = contentController.text.trim();
                    if (text.isEmpty) return;

                    final nav = Navigator.of(dialogContext);

                    if (postId != null) {
                      await FirebaseFirestore.instance
                          .collection('posts')
                          .doc(postId)
                          .update({'content': text});
                    } else {
                      final collection = isStory ? 'stories' : 'posts';
                      final mediaUrl = mediaUrlController.text.trim();

                      await FirebaseFirestore.instance
                          .collection(collection)
                          .add({
                            'author': widget.currentUserId,
                            'content': text,
                            'mediaUrl': mediaUrl.isNotEmpty ? mediaUrl : null,
                            'mediaType': mediaUrl.isNotEmpty ? mediaType : null,
                            'likes': [],
                            'createdAt': FieldValue.serverTimestamp(),
                          });
                    }

                    nav.pop();
                  },
                  child: const Text(AppStrings.save),
                ),
              ],
            );
          },
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

  void _navigateToProfile(String username) {
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

  Widget _buildFeedView() {
    return Stack(
      children: [
        Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: (_isStoriesOpen && !widget.isAnonymous) ? 80 : 0,
              color: Colors.grey.shade100,
              child: (_isStoriesOpen && !widget.isAnonymous)
                  ? StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('stories')
                          .orderBy('createdAt', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        final stories = snapshot.data?.docs ?? [];
                        return ListView.builder(
                          padding: const EdgeInsets.only(top: 70),
                          itemCount: stories.length + 1,
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return GestureDetector(
                                onTap: () => _showCreateOrEditPostDialog(),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: Column(
                                    children: [
                                      CircleAvatar(
                                        radius: 24,
                                        child: Icon(Icons.add),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        AppStrings.yourStory,
                                        style: TextStyle(fontSize: 10),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }
                            final storyData =
                                stories[index - 1].data()
                                    as Map<String, dynamic>;
                            final author =
                                storyData['author'] ?? AppStrings.anonymousUser;

                            return GestureDetector(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (dialogContext) => AlertDialog(
                                    title: Text(
                                      '${AppStrings.storyFrom} $author',
                                    ),
                                    content: Text(storyData['content'] ?? ''),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                child: Column(
                                  children: [
                                    GestureDetector(
                                      onTap: () => _navigateToProfile(author),
                                      child: CircleAvatar(
                                        radius: 24,
                                        child: Text(author[0].toUpperCase()),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      author,
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    )
                  : const SizedBox.shrink(),
            ),
            Expanded(
              child: Column(
                children: [
                  if (_selectedHashtag != null)
                    Container(
                      color: Colors.amber.shade100,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          Text('Filtrado por: $_selectedHashtag'),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () =>
                                setState(() => _selectedHashtag = null),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('posts')
                          .orderBy('createdAt', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        var posts = snapshot.data?.docs ?? [];

                        if (_selectedHashtag != null) {
                          posts = posts.where((doc) {
                            final content =
                                (doc.data()
                                    as Map<String, dynamic>)['content'] ??
                                '';
                            return content.contains(_selectedHashtag!);
                          }).toList();
                        }

                        if (posts.isEmpty) {
                          return const Center(
                            child: Text(AppStrings.noPostsYet),
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.only(top: 60),
                          itemCount: posts.length,
                          itemBuilder: (context, index) {
                            final doc = posts[index];
                            final postData = doc.data() as Map<String, dynamic>;
                            final author =
                                postData['author'] ?? AppStrings.anonymousUser;
                            final content = postData['content'] ?? '';
                            final mediaUrl = postData['mediaUrl'];
                            final mediaType = postData['mediaType'];
                            final likes = List<String>.from(
                              postData['likes'] ?? [],
                            );
                            final isLiked = likes.contains(
                              widget.currentUserId,
                            );
                            final isMyPost = author == widget.currentUserId;

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ListTile(
                                    leading: GestureDetector(
                                      onTap: () => _navigateToProfile(author),
                                      child: CircleAvatar(
                                        child: Text(author[0].toUpperCase()),
                                      ),
                                    ),
                                    title: GestureDetector(
                                      onTap: () => _navigateToProfile(author),
                                      child: Text(
                                        author,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    trailing: isMyPost
                                        ? PopupMenuButton<String>(
                                            onSelected: (val) async {
                                              if (val == 'edit') {
                                                _showCreateOrEditPostDialog(
                                                  postId: doc.id,
                                                  initialText: content,
                                                );
                                              } else if (val == 'delete') {
                                                await FirebaseFirestore.instance
                                                    .collection('posts')
                                                    .doc(doc.id)
                                                    .delete();
                                              }
                                            },
                                            itemBuilder: (context) => [
                                              const PopupMenuItem(
                                                value: 'edit',
                                                child: Text('Editar'),
                                              ),
                                              const PopupMenuItem(
                                                value: 'delete',
                                                child: Text(
                                                  'Eliminar',
                                                  style: TextStyle(
                                                    color: Colors.red,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                        : null,
                                  ),
                                  if (content.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 4,
                                      ),
                                      child: Wrap(
                                        children: content
                                            .split(' ')
                                            .map<Widget>((word) {
                                              if (word.startsWith('#')) {
                                                return GestureDetector(
                                                  onTap: () => setState(
                                                    () =>
                                                        _selectedHashtag = word,
                                                  ),
                                                  child: Text(
                                                    '$word ',
                                                    style: const TextStyle(
                                                      color: Colors.blue,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                );
                                              }
                                              return Text('$word ');
                                            })
                                            .toList(),
                                      ),
                                    ),
                                  if (mediaUrl != null && mediaUrl.isNotEmpty)
                                    Container(
                                      height: 180,
                                      margin: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.black12,
                                        borderRadius: BorderRadius.circular(8),
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
                                            likes.remove(widget.currentUserId);
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
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (!widget.isAnonymous)
          Positioned(
            top: 12,
            left: 12,
            child: FloatingActionButton.small(
              heroTag: 'logoBtn',
              backgroundColor: Colors.black,
              onPressed: () {
                setState(() {
                  _isStoriesOpen = !_isStoriesOpen;
                });
              },
              child: const Icon(Icons.blur_on, color: Colors.white),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildFeedView(),
      widget.isAnonymous
          ? const Center(child: Text(AppStrings.anonNoMessagesView))
          : DirectChatsScreen(currentUserId: widget.currentUserId),
      widget.isAnonymous
          ? const Center(child: Text(AppStrings.anonNoSearchView))
          : UserSearchScreen(currentUserId: widget.currentUserId),
      ProfileScreen(currentUserId: widget.currentUserId),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.appName)),
      body: pages[_currentIndex],
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: () => _showCreateOrEditPostDialog(),
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
            if (index == 1) {
              _hasUnreadMessages = false;
            }
          });
        },
        type: BottomNavigationBarType.fixed,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: AppStrings.tabFeed,
          ),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                const Icon(Icons.send),
                if (_hasUnreadMessages)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: const BoxDecoration(
                        color: Colors.blueAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            label: AppStrings.tabMessages,
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: AppStrings.tabSearch,
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: AppStrings.tabProfile,
          ),
        ],
      ),
    );
  }
}
