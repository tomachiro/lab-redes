import '../services/mention_service.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/media_helper.dart';
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
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.photo_library, size: 18),
                              label: const Text(AppStrings.pickFromGalleryBtn),
                              onPressed: () async {
                                final encoded = await MediaHelper.pickAndEncodeImage(
                                  source: ImageSource.gallery,
                                );
                                if (encoded == null) return;
                                if (encoded == 'TOO_LARGE') {
if (!mounted) return;
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text(AppStrings.photoTooLargeError),
),
);
return;
}
setStateDialog(() {
mediaUrlController.text = encoded;
mediaType = 'image';
});
},
),
),
const SizedBox(width: 8),
OutlinedButton.icon(
icon: const Icon(Icons.camera_alt, size: 18),
label: const Text(AppStrings.takePhotoBtn),
onPressed: () async {
final encoded = await MediaHelper.pickAndEncodeImage(
source: ImageSource.camera,
);
if (encoded == null || encoded == 'TOO_LARGE') return;
setStateDialog(() {
mediaUrlController.text = encoded;
mediaType = 'image';
});
},
),
],
),
if (mediaUrlController.text.startsWith('data:image'))
Padding(
padding: const EdgeInsets.only(top: 6, bottom: 4),
child: Row(
children: [
const Icon(Icons.check_circle, color: Colors.green, size: 16),
const SizedBox(width: 6),
const Expanded(
child: Text(
AppStrings.photoAttachedBadge,
style: TextStyle(fontSize: 12, color: Colors.green),
),
),
IconButton(
icon: const Icon(Icons.close, size: 16),
onPressed: () => setStateDialog(() {
mediaUrlController.clear();
}),
),
],
),
),
const SizedBox(height: 8),
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
await MentionService.notifyMentions(fromUser: widget.currentUserId, text: text, contextLabel: "en una publicación", postId: postId);
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

                      final createdPostRef = await FirebaseFirestore.instance.collection(collection).add({
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
                      await MentionService.notifyMentions(fromUser: widget.currentUserId, text: text, contextLabel: "en una publicación", postId: createdPostRef.id);
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
              if (widget.isAnonymous || widget.currentUserId.startsWith("Invitado_"))
  const Padding(
    padding: EdgeInsets.symmetric(vertical: 8),
    child: Text(AppStrings.anonCommentRestrictedHint, style: TextStyle(fontSize: 12, color: Colors.grey)),
  )
else
  StatefulBuilder(
    builder: (context, setCommentState) {
      final cMatch = RegExp(r"(?:^|\s)@([a-zA-Z0-9_.-]*)$").firstMatch(commentController.text);
      final cQuery = cMatch?.group(1)?.toLowerCase();
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (cQuery != null)
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection("users").doc(widget.currentUserId).get(),
              builder: (context, snap) {
                if (!snap.hasData) return const SizedBox.shrink();
                final myData = (snap.data!.data() as Map<String, dynamic>?) ?? {};
                final following = List<String>.from(myData["following"] ?? []);
                final matches = following
                    .where((u) => u != widget.currentUserId && !u.startsWith("Invitado_") && u.toLowerCase().contains(cQuery))
                    .take(5)
                    .toList();
                if (matches.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Wrap(
                    spacing: 6,
                    children: matches.map((uname) {
                      return ActionChip(
                        visualDensity: VisualDensity.compact,
                        label: Text("@$uname"),
                        onPressed: () {
                          final updated = commentController.text.replaceFirst(RegExp(r"@([a-zA-Z0-9_.-]*)$"), "@$uname ");
                          commentController.value = TextEditingValue(text: updated, selection: TextSelection.collapsed(offset: updated.length));
                          setCommentState(() {});
                        },
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: commentController,
                  onChanged: (_) => setCommentState(() {}),
                  decoration: const InputDecoration(hintText: AppStrings.commentHint, border: OutlineInputBorder()),
                ),
              ),
      IconButton(
        icon: const Icon(Icons.send),
        onPressed: () async {
          final text = commentController.text.trim();
          if (text.isEmpty) return;
          commentController.clear();
          await FirebaseFirestore.instance.collection("posts").doc(postId).collection("comments").add({
            "author": widget.currentUserId,
            "text": text,
            "createdAt": FieldValue.serverTimestamp(),
          });
              await MentionService.notifyMentions(fromUser: widget.currentUserId, text: text, contextLabel: "en un comentario", postId: postId);
              setCommentState(() {});
            },
          ),
        ],
      ),
    ],
  );
},
),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }


  void _showLeaderboardSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: SizedBox(
          height: MediaQuery.of(ctx).size.height * 0.72,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Icon(Icons.emoji_events, color: Colors.amber),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        AppStrings.leaderboardTitle,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                      ),
                    ),
                  ],
                ),
              ),
              if (!widget.isAnonymous)
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(widget.currentUserId)
                      .snapshots(),
                  builder: (context, meSnap) {
                    final meData =
                        (meSnap.data?.data() as Map<String, dynamic>?) ?? {};
                    final participating =
                        meData['participateInLeaderboard'] == true;
                    return SwitchListTile(
                      title: const Text(
                        AppStrings.participateLeaderboardLabel,
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      subtitle: const Text(
                        AppStrings.participateLeaderboardSub,
                        style: TextStyle(fontSize: 12),
                      ),
                      value: participating,
                      onChanged: (val) async {
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(widget.currentUserId)
                            .set({
                          'participateInLeaderboard': val,
                        }, SetOptions(merge: true));
                      },
                    );
                  },
                ),
              const Divider(height: 1),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .where('participateInLeaderboard', isEqualTo: true)
                      .snapshots(),
                  builder: (context, snap) {
                    if (!snap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final docs = snap.data!.docs.where((d) {
                      final data = d.data() as Map<String, dynamic>;
                      return data['isAnonymous'] != true;
                    }).toList();

                    if (docs.isEmpty) {
                      return const Center(
                        child: Text(AppStrings.noLeaderboardParticipants),
                      );
                    }

                    int calcScore(Map<String, dynamic> d) {
                      final wStreak = (d['workoutStreak'] ?? 0) as int;
                      final dStreak = (d['dietStreak'] ?? 0) as int;
                      final workouts = (d['totalWorkouts'] ?? 0) as int;
                      final km = ((d['totalKm'] ?? 0) as num).round();
                      return (wStreak * 10) +
                          (dStreak * 8) +
                          (workouts * 5) +
                          (km * 2);
                    }

                    docs.sort((a, b) {
                      final da = a.data() as Map<String, dynamic>;
                      final db = b.data() as Map<String, dynamic>;
                      return calcScore(db).compareTo(calcScore(da));
                    });

                    final topDocs = docs.take(15).toList();
                    return ListView.builder(
                      itemCount: topDocs.length,
                      itemBuilder: (context, i) {
                        final data = topDocs[i].data() as Map<String, dynamic>;
                        final name =
                            (data['username'] ?? topDocs[i].id).toString();
                        final score = calcScore(data);
                        final wStreak = (data['workoutStreak'] ?? 0) as int;
                        final km = ((data['totalKm'] ?? 0) as num).toDouble();
                        final medal = i == 0
                            ? '🥇'
                            : (i == 1
                                ? '🥈'
                                : (i == 2 ? '🥉' : '#${i + 1}'));

                        return ListTile(
                          leading: CircleAvatar(
                            child: Text(
                              medal,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(
                            name,
                            style: TextStyle(
                              fontWeight: name == widget.currentUserId
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            '🔥 $wStreak d • 🏃 ${km.toStringAsFixed(1)} km',
                          ),
                          trailing: Text(
                            '$score pts',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.amber,
                            ),
                          ),
                          onTap: () {
                            Navigator.pop(ctx);
                            _navigateToProfile(name);
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

void _showNotificationsSheet() {
showModalBottomSheet(
context: context,
isScrollControlled: true,
builder: (ctx) => SafeArea(
child: SizedBox(
height: MediaQuery.of(ctx).size.height * 0.65,
child: Column(
children: [
Padding(
padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
child: Row(
children: [
const Icon(Icons.notifications),
const SizedBox(width: 8),
const Expanded(
child: Text(
AppStrings.notificationsTitle,
style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
),
),
TextButton(
onPressed: () async {
final snap = await FirebaseFirestore.instance
.collection('users')
.doc(widget.currentUserId)
.collection('notifications')
.where('read', isEqualTo: false)
.get();
for (final doc in snap.docs) {
await doc.reference.update({'read': true});
}
},
child: const Text(AppStrings.markAllReadBtn),
),
],
),
),
const Divider(height: 1),
Expanded(
child: StreamBuilder<QuerySnapshot>(
stream: FirebaseFirestore.instance
.collection('users')
.doc(widget.currentUserId)
.collection('notifications')
.orderBy('createdAt', descending: true)
.limit(30)
.snapshots(),
builder: (context, snap) {
final docs = snap.data?.docs ?? [];
if (docs.isEmpty) {
return const Center(
child: Text(AppStrings.noNotificationsYet),
);
}
return ListView.builder(
itemCount: docs.length,
itemBuilder: (context, i) {
final data = docs[i].data() as Map<String, dynamic>;
final isRead = data['read'] == true;
return ListTile(
leading: Icon(
Icons.notifications_active,
color: isRead ? Colors.grey : Colors.amber,
),
title: Text(
(data['text'] ?? '').toString(),
style: TextStyle(
fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
),
),
onTap: () => docs[i].reference.update({'read': true}),
);
},
);
},
),
),
],
),
),
),
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
                                            : SmartPostImage(
url:                                                 mediaUrl,
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
if (widget.isAnonymous || widget.currentUserId.startsWith("Invitado_")) {
  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(AppStrings.anonCannotLikeOrComment)));
  return;
}
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
actions: [
          IconButton(
            tooltip: AppStrings.openRankingTooltip,
            onPressed: _showLeaderboardSheet,
            icon: const Icon(Icons.emoji_events_outlined, color: Colors.amber),
          ),
if (!widget.isAnonymous)
StreamBuilder<QuerySnapshot>(
stream: FirebaseFirestore.instance
.collection('users')
.doc(widget.currentUserId)
.collection('notifications')
.where('read', isEqualTo: false)
.snapshots(),
builder: (context, snap) {
final unread = snap.data?.docs.length ?? 0;
return IconButton(
tooltip: AppStrings.notificationsTitle,
onPressed: _showNotificationsSheet,
icon: Badge(
isLabelVisible: unread > 0,
label: Text('$unread'),
child: const Icon(Icons.notifications_outlined),
),
);
},
),
],
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
