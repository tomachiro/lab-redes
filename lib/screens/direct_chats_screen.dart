import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/chat_service.dart';
import '../utils/app_strings.dart';
import '../utils/app_theme.dart';
import 'chat_screen.dart';

class DirectChatsScreen extends StatelessWidget {
final String currentUserId;

const DirectChatsScreen({super.key, required this.currentUserId});

Future<void> _showCreateGroupDialog(BuildContext context) async {
final nameController = TextEditingController();
final Set<String> selectedUsers = {};

final myDoc = await FirebaseFirestore.instance
    .collection('users')
    .doc(currentUserId)
    .get();
final myData = myDoc.data() ?? {};
final myFollowing = Set<String>.from(myData['following'] ?? []);
final myFollowers = Set<String>.from(myData['followers'] ?? []);

// Solo amigos mutuos (los sigo y me siguen)
final mutualIds = myFollowing.intersection(myFollowers);

final usersSnap =
    await FirebaseFirestore.instance.collection('users').get();
final allUsernames = usersSnap.docs
    .where((d) {
      final data = d.data();
      final uname = (data['username'] ?? d.id).toString();
      final isAnon =
          data['isAnonymous'] == true || uname.startsWith('Invitado_');
      return !isAnon &&
          uname.isNotEmpty &&
          uname != currentUserId &&
          (mutualIds.contains(uname) || mutualIds.contains(d.id));
    })
    .map((d) => (d.data()['username'] ?? d.id).toString())
    .toSet()
    .toList()
  ..sort();

if (!context.mounted) return;

await showDialog(
context: context,
builder: (ctx) {
return StatefulBuilder(
builder: (ctx, setDialogState) {
return AlertDialog(
title: const Row(
children: [
Icon(Icons.groups_rounded),
SizedBox(width: 8),
Expanded(child: Text(AppStrings.newGroupDialogTitle)),
],
),
content: SizedBox(
width: double.maxFinite,
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
TextField(
controller: nameController,
decoration: const InputDecoration(
labelText: AppStrings.groupNameLabel,
hintText: AppStrings.groupNameHint,
prefixIcon: Icon(Icons.edit_outlined),
),
),
const SizedBox(height: 14),
const Align(
alignment: Alignment.centerLeft,
child: Text(
AppStrings.groupMembersLabel,
style: TextStyle(fontWeight: FontWeight.bold),
),
),
const SizedBox(height: 6),
if (allUsernames.isEmpty)
const Padding(
padding: EdgeInsets.all(8.0),
child: Text(AppStrings.groupNoMutualFriends),
)
else
ConstrainedBox(
constraints: const BoxConstraints(maxHeight: 220),
child: ListView.builder(
shrinkWrap: true,
itemCount: allUsernames.length,
itemBuilder: (_, idx) {
final uname = allUsernames[idx];
final checked = selectedUsers.contains(uname);
return CheckboxListTile(
dense: true,
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(10),
),
value: checked,
title: Text(uname),
onChanged: (val) {
setDialogState(() {
if (val == true) {
selectedUsers.add(uname);
} else {
selectedUsers.remove(uname);
}
});
},
);
},
),
),
],
),
),
actions: [
TextButton(
onPressed: () => Navigator.pop(ctx),
child: const Text(AppStrings.cancel),
),
ElevatedButton(
onPressed: () async {
final gName = nameController.text.trim();
if (gName.isEmpty || selectedUsers.isEmpty) return;
Navigator.pop(ctx);

final chatId = await ChatService.createGroupChat(
creatorId: currentUserId,
groupName: gName,
memberIds: selectedUsers.toList(),
);

if (!context.mounted) return;
Navigator.push(
context,
MaterialPageRoute(
builder: (_) => ChatScreen(
currentUserId: currentUserId,
chatId: chatId,
groupName: gName,
isGroup: true,
),
),
);
},
child: const Text(AppStrings.createGroupBtn),
),
],
);
},
);
},
);
}

@override
Widget build(BuildContext context) {
final cs = Theme.of(context).colorScheme;

return Scaffold(
appBar: AppBar(
title: const Text(AppStrings.directMessagesTitle),
actions: [
Padding(
padding: const EdgeInsets.only(right: 10),
child: FilledButton.tonalIcon(
onPressed: () => _showCreateGroupDialog(context),
icon: const Icon(Icons.group_add_rounded, size: 18),
label: const Text(AppStrings.newGroupBtn),
),
),
],
),
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
return Center(
child: Padding(
padding: const EdgeInsets.all(24),
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
Icon(Icons.forum_outlined, size: 54, color: cs.outline),
const SizedBox(height: 12),
Text(
AppStrings.noActiveChats,
textAlign: TextAlign.center,
style: TextStyle(color: cs.onSurfaceVariant),
),
],
),
),
);
}

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
padding: const EdgeInsets.symmetric(vertical: 8),
itemCount: chatDocs.length,
itemBuilder: (context, index) {
final doc = chatDocs[index];
final data = doc.data() as Map<String, dynamic>;
final users = List<String>.from(data['users'] ?? []);
final bool isGroup =
data['isGroup'] == true || users.length > 2;

final String title;
String partnerId = '';
if (isGroup) {
title = (data['groupName'] ?? 'Grupo (${users.length})')
.toString();
} else {
partnerId = users.firstWhere(
(id) => id != currentUserId,
orElse: () => '',
);
if (partnerId.isEmpty) return const SizedBox.shrink();
title = partnerId;
}

final wStreak =
ChatService.getEffectiveChatStreak(data, 'workout');
final dStreak =
ChatService.getEffectiveChatStreak(data, 'diet');

return Card(
child: InkWell(
borderRadius: BorderRadius.circular(18),
onTap: () => Navigator.push(
context,
MaterialPageRoute(
builder: (context) => ChatScreen(
currentUserId: currentUserId,
chatPartnerId: partnerId,
chatId: doc.id,
groupName: isGroup ? title : null,
isGroup: isGroup,
),
),
),
child: Padding(
padding: const EdgeInsets.symmetric(
horizontal: 14, vertical: 12),
child: Row(
children: [
Container(
width: 48,
height: 48,
decoration: BoxDecoration(
shape: BoxShape.circle,
gradient: LinearGradient(
colors: isGroup
? [
const Color(0xFF7C3AED),
const Color(0xFF4F46E5)
]
: [cs.primary, cs.tertiary],
),
),
alignment: Alignment.center,
child: isGroup
? const Icon(Icons.groups_rounded,
color: Colors.white, size: 24)
: Text(
title[0].toUpperCase(),
style: const TextStyle(
color: Colors.white,
fontWeight: FontWeight.bold,
fontSize: 18,
),
),
),
const SizedBox(width: 12),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Row(
children: [
Expanded(
child: Text(
title,
style: const TextStyle(
fontWeight: FontWeight.w700,
fontSize: 16,
),
overflow: TextOverflow.ellipsis,
),
),
if (wStreak > 0)
_MiniStreakBadge(
text: '🔥 $wStreak',
color: AppTheme.workoutAccent,
),
if (dStreak > 0)
_MiniStreakBadge(
text: '🥗 $dStreak',
color: AppTheme.dietAccent,
),
],
),
const SizedBox(height: 4),
Text(
data['lastMessage'] ?? '',
maxLines: 1,
overflow: TextOverflow.ellipsis,
style: TextStyle(
fontSize: 13,
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
);
},
);
},
),
);
}
}

class _MiniStreakBadge extends StatelessWidget {
final String text;
final Color color;

const _MiniStreakBadge({required this.text, required this.color});

@override
Widget build(BuildContext context) {
return Container(
margin: const EdgeInsets.only(left: 6),
padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
decoration: BoxDecoration(
color: color.withValues(alpha: 0.14),
borderRadius: BorderRadius.circular(20),
border: Border.all(color: color.withValues(alpha: 0.35)),
),
child: Text(
text,
style: TextStyle(
fontSize: 11.5,
fontWeight: FontWeight.w800,
color: color,
),
),
);
}
}
