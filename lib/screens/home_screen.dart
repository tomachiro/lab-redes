import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/app_models.dart';
import '../services/streak_service.dart';
import '../utils/app_strings.dart';
import 'direct_chats_screen.dart';
import 'user_search_screen.dart';
import '../widgets/app_logo.dart';
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

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
Timer? _countdownTimer;
  int _currentIndex = 0;
  final bool _isStoriesOpen = false;
  String? _selectedHashtag;
  String _feedFilter = 'all'; // 'all', 'workout', 'food'
  StreamSubscription? _messageSubscription;
  bool _hasUnreadMessages = false;

  late final DateTime _sessionStartTime;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  @override
void initState() {
super.initState();
_countdownTimer = Timer.periodic(const Duration(seconds: 30), (_) {
if (mounted) setState(() {});
});
    _sessionStartTime = DateTime.now();
    _initLocalNotifications();
    _listenForNewMessages();
  }

  Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const darwinSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      linux: LinuxInitializationSettings(defaultActionName: 'Abrir'),
    );

    await _localNotifications.initialize(settings: initSettings);

    // Solicitar permiso en Android 13+
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  Future<void> _showSystemNotification(String sender, String msg) async {
    const androidDetails = AndroidNotificationDetails(
      'gymbook_messages',
      AppStrings.directMessagesTitle,
      channelDescription: AppStrings.notifChannelDesc,
      importance: Importance.max,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);

    await _localNotifications.show(
id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
title: AppStrings.newMessageTitle(sender),
body: msg,
notificationDetails: details,
);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _countdownTimer?.cancel();
    _messageSubscription?.cancel();
    super.dispose();
  }

  void _listenForNewMessages() {
    if (widget.isAnonymous) return;

    _messageSubscription = FirebaseFirestore.instance
        .collectionGroup('messages')
        .where('receiverId', isEqualTo: widget.currentUserId)
        .snapshots()
        .listen((snapshot) {
          for (var change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.added) {
              final data = change.doc.data();
              if (data == null) continue;

              // Ignorar mensajes previos a abrir la sesión actual
              final ts = data['timestamp'] as Timestamp?;
              if (ts != null && ts.toDate().isBefore(_sessionStartTime)) {
                continue;
              }

              final sender = data['senderId'] ?? AppStrings.anonymousUser;
              final msg = data['message'] ?? '';

              // Mostrar notificación del sistema
              _showSystemNotification(sender, msg);

              if (!mounted) return;
              setState(() {
                if (_currentIndex != 1) {
                  _hasUnreadMessages = true;
                }
              });

              // Alerta visual dentro de la app si no está en la pestaña de mensajes
              if (_currentIndex != 1) {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    duration: const Duration(seconds: 3),
                    content: Row(
                      children: [
                        const Icon(Icons.mark_chat_unread, color: Colors.white),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${AppStrings.newMessageFrom} $sender: "$msg"',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: Colors.blueAccent,
                    behavior: SnackBarBehavior.floating,
                    action: SnackBarAction(
                      label: 'Ver',
                      textColor: Colors.white,
                      onPressed: () {
                        setState(() {
                          _currentIndex = 1;
                          _hasUnreadMessages = false;
                        });
                      },
                    ),
                  ),
                );
              }
            }
          }
        });
  }

  void _showCreateOrEditPostDialog({String? postId, String? initialText}) {
if (widget.isAnonymous) {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text(AppStrings.anonCannotPost),
),
);
return;
}
    final contentController = TextEditingController(text: initialText);
    final mediaUrlController = TextEditingController();
    final durationController = TextEditingController();
    final caloriesController = TextEditingController();
    int? tempHours; // null = permanente
    String mediaType = 'image';
    String category = 'workout'; // 'workout' o 'food'
    String selectedRoutine = AppStrings.routineWeights;
    bool isHealthyDiet = true;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setStateDialog) {
            String dialogTitle;
            if (postId != null) {
              dialogTitle = AppStrings.editPostTitle;
            } else {
              dialogTitle = AppStrings.newPostTitle;
            }

            // Cálculo previo de calorías estimadas en vivo para mostrarlo como hint
            final parsedMins =
                int.tryParse(durationController.text.trim()) ?? 0;
            final estimatedKcal = FitnessCalorieHelper.estimateBurnedCalories(
              selectedRoutine,
              parsedMins,
            );

            return AlertDialog(
              title: Text(dialogTitle),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (postId == null) ...[
                      const Text(
                        AppStrings.postCategoryTitle,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                            value: 'workout',
                            label: Text(AppStrings.workoutTabLabel),
                            icon: Icon(Icons.fitness_center),
                          ),
                          ButtonSegment(
                            value: 'food',
                            label: Text(AppStrings.foodTabLabel),
                            icon: Icon(Icons.restaurant),
                          ),
                        ],
                        selected: {category},
                        onSelectionChanged: (newSelection) {
                          setStateDialog(() {
                            category = newSelection.first;
                            caloriesController.clear();
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextField(
                      controller: contentController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: category == 'workout'
                                  ? AppStrings.workoutContentHint
                                  : AppStrings.foodContentHint,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    if (postId == null) ...[
                      const SizedBox(height: 12),
                      if (category == 'workout') ...[
                        DropdownButtonFormField<String>(
                          initialValue: selectedRoutine,
                          decoration: const InputDecoration(
                            labelText: AppStrings.activeRoutineLabel,
                            border: OutlineInputBorder(),
                          ),
                          items: FitnessCalorieHelper.kcalPerMinute.keys
                              .map(
                                (type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(type),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setStateDialog(() => selectedRoutine = val);
                            }
                          },
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: durationController,
                                keyboardType: TextInputType.number,
                                onChanged: (_) => setStateDialog(() {}),
                                decoration: const InputDecoration(
                                  labelText: AppStrings.durationMinsLabel,
                                  hintText: AppStrings.durationMinsHint,
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: caloriesController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: AppStrings.burnedKcalLabel,
                                  hintText: parsedMins > 0
                                      ? 'Auto: ~$estimatedKcal'
                                      : AppStrings.kcalAutoEmptyHint,
                                  border: const OutlineInputBorder(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        TextField(
                          controller: caloriesController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText:
                                AppStrings.foodCaloriesLabel,
                            hintText: AppStrings.foodCaloriesHint,
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 6),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text(
                            AppStrings.healthyDietSwitchLabel,
                            style: TextStyle(fontSize: 13),
                          ),
                          value: isHealthyDiet,
                          onChanged: (val) =>
                              setStateDialog(() => isHealthyDiet = val),
                        ),
                      ],
                    ],
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
                        const SizedBox(height: 12),
                        DropdownButtonFormField<int?>(
                          initialValue: tempHours,
                          decoration: const InputDecoration(
                            labelText: AppStrings.tempPostLabel,
prefixIcon: Icon(Icons.timer_outlined),
),
items: const [
DropdownMenuItem<int?>(
value: null,
child: Text(AppStrings.tempPostPermanent),
),
DropdownMenuItem<int?>(
value: 1,
child: Text(AppStrings.tempPost1h),
),
DropdownMenuItem<int?>(
value: 6,
child: Text(AppStrings.tempPost6h),
),
DropdownMenuItem<int?>(
value: 12,
child: Text(AppStrings.tempPost12h),
),
DropdownMenuItem<int?>(
value: 24,
child: Text(AppStrings.tempPost24h),
),
],
onChanged: (val) =>
setStateDialog(() => tempHours = val),
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
                      const collection = 'posts';
                      final mediaUrl = mediaUrlController.text.trim();

                      int? finalCalories = int.tryParse(
                        caloriesController.text.trim(),
                      );
                      final int? duration = int.tryParse(
                        durationController.text.trim(),
                      );

                      // Si es rutina y no puso calorías pero sí tiempo (o por defecto 30 min), calcular aprox.
                      if (category == 'workout' &&
                          finalCalories == null) {
                        final minsToCalc = (duration != null && duration > 0)
                            ? duration
                            : 30;
                        finalCalories =
                            FitnessCalorieHelper.estimateBurnedCalories(
                              selectedRoutine,
                              minsToCalc,
                            );
                      }

                      await FirebaseFirestore.instance
                          .collection(collection)
                          .add({
                            'author': widget.currentUserId,
                            'content': text,
                            'category': category,
                            'routineType': category == 'workout'
                                ? selectedRoutine
                                : null,
                            'durationMinutes': category == 'workout'
                                ? duration
                                : null,
                            'calories': finalCalories,
                            'isHealthyDiet': category == 'food'
                                ? isHealthyDiet
                                : null,
                            'mediaUrl': mediaUrl.isNotEmpty ? mediaUrl : null,
                            'mediaType': mediaUrl.isNotEmpty ? mediaType : null,
                            'likes': [],
'createdAt': FieldValue.serverTimestamp(),
                            'expiresAt': ((tempHours ?? 0) > 0)
? Timestamp.fromDate(
DateTime.now().add(Duration(hours: tempHours ?? 0)),
)
: null,
                          });

                      // Actualizar racha diaria (Ejercicio o Dieta) si es un post normal
                      if (!widget.isAnonymous) {
                        await StreakService.registerActivity(
                          username: widget.currentUserId,
                          category: category,
                          isHealthyDiet: isHealthyDiet,
                        );
                      }
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

  Widget _buildFitnessBadges(Map<String, dynamic> postData) {
    final category = postData['category'] ?? 'workout';
    final routineType = postData['routineType'];
    final duration = postData['durationMinutes'];
    final calories = postData['calories'];
    final isHealthy = postData['isHealthyDiet'] ?? true;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: [
          Chip(
            avatar: Icon(
              category == 'food' ? Icons.restaurant : Icons.fitness_center,
              size: 16,
              color: Colors.white,
            ),
            label: Text(
              category == 'food'
                  ? (isHealthy ? AppStrings.healthyFoodBadge : AppStrings.freeFoodBadge)
                  : (routineType ?? 'Ejercicio'),
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
            backgroundColor: category == 'food'
                ? (isHealthy ? Colors.green : Colors.orange)
                : Colors.deepPurple,
            visualDensity: VisualDensity.compact,
          ),
          if (duration != null && duration > 0)
            Chip(
              avatar: const Icon(Icons.timer, size: 16),
              label: Text(
                '$duration min',
                style: const TextStyle(fontSize: 12),
              ),
              visualDensity: VisualDensity.compact,
            ),
          if (calories != null && calories > 0)
            Chip(
              avatar: const Icon(
                Icons.local_fire_department,
                size: 16,
                color: Colors.deepOrange,
              ),
              label: Text(
                category == 'food'
                    ? '$calories kcal'
                    : '~$calories kcal quemadas',
                style: const TextStyle(fontSize: 12),
              ),
              visualDensity: VisualDensity.compact,
            ),
        ],
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
                  // Barra de filtro rápido entre Todo / Ejercicio / Comida
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 64,
                      right: 12,
                      top: 10,
                      bottom: 4,
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ChoiceChip(
                            label: const Text('Todo'),
                            selected: _feedFilter == 'all',
                            onSelected: (_) =>
                                setState(() => _feedFilter = 'all'),
                          ),
                          const SizedBox(width: 6),
                          ChoiceChip(
                            label: const Text('Ejercicios'),
                            selected: _feedFilter == 'workout',
                            onSelected: (_) =>
                                setState(() => _feedFilter = 'workout'),
                          ),
                          const SizedBox(width: 6),
                          ChoiceChip(
                            label: const Text('Comidas'),
                            selected: _feedFilter == 'food',
                            onSelected: (_) =>
                                setState(() => _feedFilter = 'food'),
                          ),
                        ],
                      ),
                    ),
                  ),
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

                        var posts = (snapshot.data?.docs ?? []).where((doc) {
final data = doc.data() as Map<String, dynamic>;
final exp = (data['expiresAt'] as Timestamp?)?.toDate();
if (exp != null && exp.isBefore(DateTime.now())) {
if (data['author'] == widget.currentUserId) {
doc.reference.delete();
}
return false;
}
return true;
}).toList();

                        if (_feedFilter != 'all') {
                          posts = posts.where((doc) {
                            final cat =
                                (doc.data()
                                    as Map<String, dynamic>)['category'] ??
                                'workout';
                            return cat == _feedFilter;
                          }).toList();
                        }

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
                          padding: const EdgeInsets.only(top: 8, bottom: 80),
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
                                  _buildFitnessBadges(postData),
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
      appBar: AppBar(
title: const Row(
children: [
AppLogo(size: 28, borderRadius: 6),
SizedBox(width: 8),
Text(AppStrings.appName),
],
),
),
body: pages[_currentIndex],
      floatingActionButton: (_currentIndex == 0 && !widget.isAnonymous)
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
