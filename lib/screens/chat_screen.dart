import 'profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/chat_service.dart';
import '../utils/app_strings.dart';
import '../utils/app_theme.dart';

class ChatScreen extends StatefulWidget {
final String currentUserId;
final String chatPartnerId;
final String? chatId;
final String? groupName;
final bool isGroup;

const ChatScreen({
super.key,
required this.currentUserId,
this.chatPartnerId = '',
this.chatId,
this.groupName,
this.isGroup = false,
});

@override
State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
final TextEditingController _messageController = TextEditingController();
late String _chatId;

@override
void initState() {
super.initState();
_chatId = widget.chatId ??
ChatService.getChatId(widget.currentUserId, widget.chatPartnerId);
}

void _sendMessage() async {
final text = _messageController.text.trim();
if (text.isEmpty) return;

_messageController.clear();
await ChatService.sendMessage(
senderId: widget.currentUserId,
receiverId: widget.isGroup ? null : widget.chatPartnerId,
chatId: _chatId,
message: text,
);
}

Future<void> _openSharedActionSheet() async {
final detailController = TextEditingController();
String selectedCategory = 'workout';
bool isRoutineShare = false;

await showModalBottomSheet(
context: context,
isScrollControlled: true,
builder: (ctx) {
return StatefulBuilder(
builder: (ctx, setSheetState) {
return Padding(
padding: EdgeInsets.only(
left: 20,
right: 20,
top: 20,
bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
),
child: Column(
mainAxisSize: MainAxisSize.min,
crossAxisAlignment: CrossAxisAlignment.stretch,
children: [
Center(
child: Container(
width: 40,
height: 4,
margin: const EdgeInsets.only(bottom: 14),
decoration: BoxDecoration(
color: Colors.grey.withValues(alpha: 0.4),
borderRadius: BorderRadius.circular(10),
),
),
),
const Text(
AppStrings.sharedStreakTitle,
style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
),
const SizedBox(height: 4),
Text(
AppStrings.sharedStreakSubtitle,
style: TextStyle(
fontSize: 13,
color: Theme.of(ctx).colorScheme.onSurfaceVariant,
),
),
const SizedBox(height: 16),
SegmentedButton<String>(
segments: const [
ButtonSegment(
value: 'workout',
icon: Icon(Icons.fitness_center_rounded),
label: Text(AppStrings.workoutCategoryLabel),
),
ButtonSegment(
value: 'diet',
icon: Icon(Icons.restaurant_rounded),
label: Text(AppStrings.dietCategoryLabel),
),
],
selected: {selectedCategory},
onSelectionChanged: (val) {
setSheetState(() {
selectedCategory = val.first;
});
},
),
const SizedBox(height: 10),
if (selectedCategory == 'workout')
SwitchListTile(
contentPadding: EdgeInsets.zero,
title: const Text(AppStrings.shareAsFullRoutine),
subtitle: const Text(AppStrings.shareRoutineSubtitle),
value: isRoutineShare,
onChanged: (v) => setSheetState(() => isRoutineShare = v),
),
TextField(
controller: detailController,
maxLines: isRoutineShare ? 3 : 1,
decoration: InputDecoration(
labelText: selectedCategory == 'workout'
? (isRoutineShare
? AppStrings.routineDetailsHint
: AppStrings.workoutNoteHint)
: AppStrings.dietNoteHint,
),
),
const SizedBox(height: 16),
ElevatedButton.icon(
style: ElevatedButton.styleFrom(
backgroundColor: selectedCategory == 'workout'
? AppTheme.workoutAccent
: AppTheme.dietAccent,
foregroundColor: Colors.white,
),
icon: const Icon(Icons.local_fire_department_rounded),
label: const Text(AppStrings.logSharedActivityBtn),
onPressed: () async {
Navigator.pop(ctx);
final prefix =
isRoutineShare ? AppStrings.routineSharedPrefix : '';
await ChatService.logSharedActivity(
chatId: _chatId,
senderId: widget.currentUserId,
category: selectedCategory,
detail: '$prefix${detailController.text.trim()}',
partnerId: widget.isGroup ? null : widget.chatPartnerId,
);
},
),
],
),
);
},
);
},
);
}

  void _openQuickTrainingDialog() {
    final exCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(widget.currentUserId)
            .snapshots(),
        builder: (context, snap) {
          final data = (snap.data?.data() as Map<String, dynamic>?) ?? {};
          final isTraining = data['isTraining'] == true;
          final currentEx = (data['currentExercise'] ?? '').toString();
          if (exCtrl.text.isEmpty && currentEx.isNotEmpty) {
            exCtrl.text = currentEx;
          }

          return AlertDialog(
            title: const Text(AppStrings.liveWorkoutTitle),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    isTraining
                        ? AppStrings.liveWorkoutActiveBadge
                        : AppStrings.liveWorkoutTitle,
                  ),
                  value: isTraining,
                  onChanged: (val) async {
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(widget.currentUserId)
                        .set({
                      'isTraining': val,
                      'currentExercise': val ? exCtrl.text.trim() : '',
                    }, SetOptions(merge: true));
                  },
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: exCtrl,
                  decoration: const InputDecoration(
                    labelText: AppStrings.currentExerciseLabel,
                    hintText: AppStrings.currentExerciseHint,
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(AppStrings.cancel),
              ),
              ElevatedButton(
                onPressed: () async {
                  final nav = Navigator.of(ctx);
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(widget.currentUserId)
                      .set({
                    'isTraining': true,
                    'currentExercise': exCtrl.text.trim(),
                  }, SetOptions(merge: true));
                  nav.pop();
                },
                child: const Text(AppStrings.save),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showParticipantsActivitySheet(List<String> memberIds) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: SizedBox(
          height: MediaQuery.of(ctx).size.height * 0.68,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Icon(
                      widget.isGroup ? Icons.groups_rounded : Icons.person_outline,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.isGroup
                            ? '${AppStrings.groupParticipantsTitle} (${memberIds.length})'
                            : AppStrings.chatActivitySummaryTitle,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: memberIds.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final memberId = memberIds[index];
                    return StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(memberId)
                          .snapshots(),
                      builder: (context, snap) {
                        final uData =
                            (snap.data?.data() as Map<String, dynamic>?) ?? {};
                        final isTraining = uData['isTraining'] == true;
                        final curEx =
                            (uData['currentExercise'] ?? '').toString();
                        final wStreak = (uData['workoutStreak'] ?? 0) as int;
                        final dStreak = (uData['dietStreak'] ?? 0) as int;
                        final totalWorkouts =
                            (uData['totalWorkouts'] ?? 0) as int;
                        final totalKm =
                            ((uData['totalKm'] ?? 0) as num).toDouble();
                        final bio = (uData['bio'] ?? '').toString();

                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      child: Text(
                                        memberId.isNotEmpty
                                            ? memberId[0].toUpperCase()
                                            : 'U',
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            memberId == widget.currentUserId
                                                ? '$memberId (Tú)'
                                                : memberId,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                          ),
                                          Text(
                                            isTraining
                                                ? (curEx.isNotEmpty
                                                    ? '🟢 ${AppStrings.trainingNowLabel}: $curEx'
                                                    : '🟢 ${AppStrings.trainingNowLabel}')
                                                : AppStrings.inactiveNowLabel,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isTraining
                                                  ? Colors.greenAccent
                                                  : Colors.grey,
                                              fontWeight: isTraining
                                                  ? FontWeight.w600
                                                  : FontWeight.normal,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    OutlinedButton(
                                      onPressed: () {
                                        Navigator.pop(ctx);
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => ProfileScreen(
                                              currentUserId: widget.currentUserId,
                                              profileUserId: memberId,
                                            ),
                                          ),
                                        );
                                      },
                                      child: const Text(AppStrings.viewProfileBtn),
                                    ),
                                  ],
                                ),
                                if (bio.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    bio,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: [
                                    Chip(
                                      visualDensity: VisualDensity.compact,
                                      label: Text('🔥 $wStreak d gym'),
                                    ),
                                    Chip(
                                      visualDensity: VisualDensity.compact,
                                      label: Text('🥗 $dStreak d dieta'),
                                    ),
                                    Chip(
                                      visualDensity: VisualDensity.compact,
                                      label: Text('🏋️ $totalWorkouts sesiones'),
                                    ),
                                    Chip(
                                      visualDensity: VisualDensity.compact,
                                      label: Text(
                                        '🏃 ${totalKm.toStringAsFixed(1)} km',
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
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
      ),
    );
  }

@override
Widget build(BuildContext context) {
final cs = Theme.of(context).colorScheme;
final String headerTitle = widget.isGroup
? (widget.groupName ?? AppStrings.defaultGroupTitle)
: widget.chatPartnerId;

return Scaffold(
appBar: AppBar(
titleSpacing: 0,
title: InkWell(
borderRadius: BorderRadius.circular(12),
onTap: () async {
final snap = await FirebaseFirestore.instance
.collection('chats')
.doc(_chatId)
.get();
final data = snap.data() ?? {};
final members = List<String>.from(
data['users'] ??
(widget.isGroup
? [widget.currentUserId]
: [widget.currentUserId, widget.chatPartnerId]),
);
if (!mounted) return;
_showParticipantsActivitySheet(members);
},
child: Padding(
padding: const EdgeInsets.symmetric(vertical: 4),
child: Row(
children: [
Container(
width: 36,
height: 36,
decoration: BoxDecoration(
shape: BoxShape.circle,
gradient: LinearGradient(
colors: widget.isGroup
? [const Color(0xFF7C3AED), const Color(0xFF4F46E5)]
: [cs.primary, cs.tertiary],
),
),
alignment: Alignment.center,
child: widget.isGroup
? const Icon(Icons.groups_rounded,
size: 19, color: Colors.white)
: Text(
headerTitle.isNotEmpty
? headerTitle[0].toUpperCase()
: '?',
style: const TextStyle(
color: Colors.white,
fontWeight: FontWeight.bold,
),
),
),
const SizedBox(width: 10),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
mainAxisSize: MainAxisSize.min,
children: [
Text(
headerTitle,
overflow: TextOverflow.ellipsis,
style: const TextStyle(fontSize: 17),
),
Text(
AppStrings.tapHeaderForDetailsHint,
overflow: TextOverflow.ellipsis,
style: TextStyle(
fontSize: 11,
color: cs.onSurfaceVariant,
),
),
],
),
),
],
),
),
),
actions: [
IconButton(
tooltip: AppStrings.quickTrainToggleTooltip,
icon: const Icon(Icons.fitness_center),
onPressed: _openQuickTrainingDialog,
),
],
),
body: Column(
children: [
// Dashboard compacto de rachas compartidas
StreamBuilder<DocumentSnapshot>(
stream: FirebaseFirestore.instance
.collection('chats')
.doc(_chatId)
.snapshots(),
builder: (context, chatSnap) {
final chatData =
(chatSnap.data?.data() as Map<String, dynamic>?) ?? {};
final users = List<String>.from(chatData['users'] ??
(widget.isGroup
? [widget.currentUserId]
: [widget.currentUserId, widget.chatPartnerId]));

final wStreak =
ChatService.getEffectiveChatStreak(chatData, 'workout');
final dStreak =
ChatService.getEffectiveChatStreak(chatData, 'diet');

final wToday =
ChatService.getTodayCompletedUsers(chatData, 'workout');
final dToday =
ChatService.getTodayCompletedUsers(chatData, 'diet');

final bool iDidWorkout = wToday.contains(widget.currentUserId);
final bool iDidDiet = dToday.contains(widget.currentUserId);

return Container(
width: double.infinity,
padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
decoration: BoxDecoration(
color: Theme.of(context).cardColor,
border: Border(
bottom: BorderSide(
color: cs.outlineVariant.withValues(alpha: 0.4),
),
),
),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
if (widget.isGroup) ...[
Wrap(
spacing: 6,
runSpacing: 4,
children: users.map((u) {
return ActionChip(
visualDensity: VisualDensity.compact,
avatar: const Icon(Icons.person, size: 14),
label: Text(
u == widget.currentUserId ? '$u (Tú)' : u,
style: const TextStyle(fontSize: 11.5),
),
onPressed: () => _showParticipantsActivitySheet(users),
);
}).toList(),
),
const SizedBox(height: 6),
],
// Estado en vivo de Modo Entrenamiento de los integrantes
Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: users.map((memberId) {
return StreamBuilder<DocumentSnapshot>(
stream: FirebaseFirestore.instance
.collection('users')
.doc(memberId)
.snapshots(),
builder: (context, uSnap) {
final uData = (uSnap.data?.data() as Map<String, dynamic>?) ?? {};
if (uData['isTraining'] != true) return const SizedBox.shrink();
final ex = (uData['currentExercise'] ?? '').toString();
return Padding(
padding: const EdgeInsets.only(bottom: 4),
child: Row(
children: [
const Icon(Icons.fitness_center, size: 14, color: Colors.greenAccent),
const SizedBox(width: 6),
Expanded(
child: Text(
ex.isNotEmpty
? '🟢 $memberId • ${AppStrings.trainingNowLabel}: $ex'
: '🟢 $memberId • ${AppStrings.trainingNowLabel}',
style: const TextStyle(
fontSize: 12,
fontWeight: FontWeight.w600,
color: Colors.greenAccent,
),
overflow: TextOverflow.ellipsis,
),
),
],
),
);
},
);
}).toList(),
),
Row(
children: [
Expanded(
child: _StreakPill(
emoji: '🔥',
label: AppStrings.workoutStreakShort,
streak: wStreak,
doneCount: wToday.length,
totalCount: users.length,
completedByMe: iDidWorkout,
color: AppTheme.workoutAccent,
),
),
const SizedBox(width: 8),
Expanded(
child: _StreakPill(
emoji: '🥗',
label: AppStrings.dietStreakShort,
streak: dStreak,
doneCount: dToday.length,
totalCount: users.length,
completedByMe: iDidDiet,
color: AppTheme.dietAccent,
),
),
],
),
if (widget.isGroup && users.length > 1)
Padding(
padding: const EdgeInsets.only(top: 6, left: 2),
child: Text(
'Integrantes (${users.length}): ${users.join(", ")}',
style: TextStyle(
fontSize: 11.5,
color: cs.onSurfaceVariant,
),
maxLines: 1,
overflow: TextOverflow.ellipsis,
),
),
],
),
);
},
),
Expanded(
child: StreamBuilder<QuerySnapshot>(
stream: FirebaseFirestore.instance
.collection('chats')
.doc(_chatId)
.collection('messages')
.snapshots(),
builder: (context, snapshot) {
if (snapshot.connectionState == ConnectionState.waiting) {
return const Center(child: CircularProgressIndicator());
}

if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
return Center(
child: Text(
AppStrings.emptyChatHint,
style: TextStyle(color: cs.onSurfaceVariant),
),
);
}

final docs = snapshot.data!.docs.toList();
docs.sort((a, b) {
final aData = a.data() as Map<String, dynamic>;
final bData = b.data() as Map<String, dynamic>;
final aTime = aData['timestamp'] as Timestamp?;
final bTime = bData['timestamp'] as Timestamp?;

if (aTime == null) return 1;
if (bTime == null) return -1;
return bTime.compareTo(aTime);
});

return ListView.builder(
reverse: true,
padding: const EdgeInsets.symmetric(
horizontal: 12,
vertical: 10,
),
itemCount: docs.length,
itemBuilder: (context, index) {
final data = docs[index].data() as Map<String, dynamic>;
final sender = (data['senderId'] ?? '').toString();
final isMe = sender == widget.currentUserId;
final msg = (data['message'] ?? '').toString();
final type = (data['type'] ?? 'text').toString();

if (type == 'system') {
return Center(
child: Container(
margin: const EdgeInsets.symmetric(vertical: 8),
padding: const EdgeInsets.symmetric(
horizontal: 14, vertical: 7),
decoration: BoxDecoration(
color: cs.surfaceContainerHighest,
borderRadius: BorderRadius.circular(14),
),
child: Text(
msg,
textAlign: TextAlign.center,
style: TextStyle(
fontSize: 12,
color: cs.onSurfaceVariant,
),
),
),
);
}

final bool isCheckin = type == 'checkin';
final Color bubbleColor = isCheckin
? (data['activityCategory'] == 'diet'
? AppTheme.dietAccent
: AppTheme.workoutAccent)
: (isMe ? cs.primary : Theme.of(context).cardColor);

final Color textColor = (isMe || isCheckin)
? Colors.white
: cs.onSurface;

return Align(
alignment:
isMe ? Alignment.centerRight : Alignment.centerLeft,
child: Container(
margin: const EdgeInsets.symmetric(vertical: 4),
padding: const EdgeInsets.symmetric(
horizontal: 14,
vertical: 10,
),
constraints: BoxConstraints(
maxWidth: MediaQuery.of(context).size.width * 0.78,
),
decoration: BoxDecoration(
color: bubbleColor,
border: (!isMe && !isCheckin)
? Border.all(
color: cs.outlineVariant
.withValues(alpha: 0.45),
)
: null,
borderRadius: BorderRadius.only(
topLeft: const Radius.circular(16),
topRight: const Radius.circular(16),
bottomLeft: isMe
? const Radius.circular(16)
: const Radius.circular(4),
bottomRight: isMe
? const Radius.circular(4)
: const Radius.circular(16),
),
),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
if (widget.isGroup && !isMe)
Padding(
padding: const EdgeInsets.only(bottom: 3),
child: Text(
sender,
style: TextStyle(
fontSize: 11.5,
fontWeight: FontWeight.w800,
color: isCheckin
? Colors.white.withValues(alpha: 0.85)
: cs.primary,
),
),
),
Text(
msg,
style: TextStyle(
color: textColor,
fontSize: 15,
fontWeight: isCheckin
? FontWeight.w600
: FontWeight.normal,
),
),
],
),
),
);
},
);
},
),
),
// Barra inferior de escritura estilizada
SafeArea(
top: false,
child: Container(
padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
decoration: BoxDecoration(
color: Theme.of(context).cardColor,
border: Border(
top: BorderSide(
color: cs.outlineVariant.withValues(alpha: 0.4),
),
),
),
child: Row(
children: [
Container(
decoration: BoxDecoration(
color: AppTheme.workoutAccent.withValues(alpha: 0.14),
shape: BoxShape.circle,
),
child: IconButton(
tooltip: AppStrings.sharedActivityTooltip,
icon: const Icon(
Icons.local_fire_department_rounded,
color: AppTheme.workoutAccent,
),
onPressed: _openSharedActionSheet,
),
),
const SizedBox(width: 8),
Expanded(
child: StatefulBuilder(
builder: (context, setInputState) {
final match = RegExp(r'(?:^|\s)@([a-zA-Z0-9_.-]*)$')
.firstMatch(_messageController.text);
final query = match?.group(1)?.toLowerCase();

return Column(
mainAxisSize: MainAxisSize.min,
crossAxisAlignment: CrossAxisAlignment.start,
children: [
if (query != null)
FutureBuilder<DocumentSnapshot>(
future: FirebaseFirestore.instance
.collection('chats')
.doc(_chatId)
.get(),
builder: (context, snap) {
final data =
(snap.data?.data() as Map<String, dynamic>?) ?? {};
final members = List<String>.from(
data['users'] ??
(widget.isGroup
? [widget.currentUserId]
: [widget.currentUserId, widget.chatPartnerId]),
);
final filtered = members
.where((u) =>
u != widget.currentUserId &&
!u.startsWith('Invitado_') &&
u.toLowerCase().contains(query))
.toList();
if (filtered.isEmpty) return const SizedBox.shrink();
return Padding(
padding: const EdgeInsets.only(bottom: 6),
child: Wrap(
spacing: 6,
children: filtered.map((u) {
return ActionChip(
visualDensity: VisualDensity.compact,
label: Text('@$u'),
onPressed: () {
final updated = _messageController.text.replaceFirst(
RegExp(r'@([a-zA-Z0-9_.-]*)$'),
'@$u ',
);
_messageController.value = TextEditingValue(
text: updated,
selection:
TextSelection.collapsed(offset: updated.length),
);
setInputState(() {});
},
);
}).toList(),
),
);
},
),
TextField(
controller: _messageController,
onChanged: (_) => setInputState(() {}),
textInputAction: TextInputAction.send,
onSubmitted: (_) => _sendMessage(),
decoration: InputDecoration(
hintText: AppStrings.directMessageHint,
border: OutlineInputBorder(
borderRadius: BorderRadius.circular(24),
borderSide: BorderSide.none,
),
enabledBorder: OutlineInputBorder(
borderRadius: BorderRadius.circular(24),
borderSide: BorderSide.none,
),
focusedBorder: OutlineInputBorder(
borderRadius: BorderRadius.circular(24),
borderSide: BorderSide(color: cs.primary, width: 1.5),
),
contentPadding: const EdgeInsets.symmetric(
horizontal: 16,
vertical: 10,
),
),
),
],
);
},
),
),
const SizedBox(width: 8),
FilledButton(
style: FilledButton.styleFrom(
shape: const CircleBorder(),
padding: const EdgeInsets.all(12),
),
onPressed: _sendMessage,
child: const Icon(Icons.send_rounded, size: 20),
),
],
),
),
),
],
),
);
}
}

class _StreakPill extends StatelessWidget {
final String emoji;
final String label;
final int streak;
final int doneCount;
final int totalCount;
final bool completedByMe;
final Color color;

const _StreakPill({
required this.emoji,
required this.label,
required this.streak,
required this.doneCount,
required this.totalCount,
required this.completedByMe,
required this.color,
});

@override
Widget build(BuildContext context) {
final cs = Theme.of(context).colorScheme;
final double progress =
totalCount > 0 ? (doneCount / totalCount).clamp(0.0, 1.0) : 0.0;

return Container(
padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
decoration: BoxDecoration(
color: color.withValues(alpha: 0.11),
borderRadius: BorderRadius.circular(14),
border: Border.all(
color: completedByMe ? color : color.withValues(alpha: 0.35),
width: completedByMe ? 1.6 : 1,
),
),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Row(
children: [
Text(emoji, style: const TextStyle(fontSize: 15)),
const SizedBox(width: 5),
Expanded(
child: Text(
'$label: $streak d',
style: TextStyle(
fontWeight: FontWeight.w800,
fontSize: 12.5,
color: color,
),
overflow: TextOverflow.ellipsis,
),
),
Text(
'$doneCount/$totalCount',
style: TextStyle(
fontSize: 11.5,
fontWeight: FontWeight.bold,
color: cs.onSurface,
),
),
],
),
const SizedBox(height: 5),
ClipRRect(
borderRadius: BorderRadius.circular(6),
child: LinearProgressIndicator(
value: progress,
minHeight: 4,
backgroundColor: color.withValues(alpha: 0.2),
valueColor: AlwaysStoppedAnimation<Color>(color),
),
),
],
),
);
}
}
