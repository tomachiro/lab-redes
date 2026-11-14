import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../utils/app_strings.dart';

class ProfileFitnessSection extends StatefulWidget {
final String currentUserId;
final String targetUserId;
final bool isMyProfile;
final bool isAnonymous;
final Map<String, dynamic> userData;

const ProfileFitnessSection({
super.key,
required this.currentUserId,
required this.targetUserId,
required this.isMyProfile,
required this.isAnonymous,
required this.userData,
});

@override
State<ProfileFitnessSection> createState() => _ProfileFitnessSectionState();
}

class _ProfileFitnessSectionState extends State<ProfileFitnessSection> {
int _selectedDayIndex = DateTime.now().weekday - 1; // 0 = Lunes .. 6 = Domingo
final _liveExerciseController = TextEditingController();

// Temporizadores de entrenamiento en vivo
Timer? _restTimer;
int _restSecondsRemaining = 0;

Timer? _waterTimer;
int _waterIntervalMinutes = 0;
int _waterSecondsRemaining = 0;

DateTime? _workoutStartedAt;

@override
void initState() {
super.initState();
final activeExercise =
(widget.userData['currentExercise'] ?? '').toString();
_liveExerciseController.text = activeExercise;
if (widget.userData['isTraining'] == true) {
_workoutStartedAt = DateTime.now();
}
}

@override
void dispose() {
_restTimer?.cancel();
_waterTimer?.cancel();
_liveExerciseController.dispose();
super.dispose();
}

void _startRestTimer(int seconds) {
_restTimer?.cancel();
setState(() => _restSecondsRemaining = seconds);
_restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
if (!mounted) {
timer.cancel();
return;
}
if (_restSecondsRemaining <= 1) {
timer.cancel();
setState(() => _restSecondsRemaining = 0);
HapticFeedback.heavyImpact();
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text(AppStrings.restFinishedAlert),
backgroundColor: Colors.green,
),
);
} else {
setState(() => _restSecondsRemaining--);
}
});
}

void _setWaterReminder(int minutes) {
_waterTimer?.cancel();
if (minutes <= 0) {
setState(() {
_waterIntervalMinutes = 0;
_waterSecondsRemaining = 0;
});
return;
}
setState(() {
_waterIntervalMinutes = minutes;
_waterSecondsRemaining = minutes * 60;
});
_waterTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
if (!mounted) {
timer.cancel();
return;
}
if (_waterSecondsRemaining <= 1) {
HapticFeedback.vibrate();
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text(AppStrings.drinkWaterAlert),
backgroundColor: Colors.blueAccent,
),
);
setState(() => _waterSecondsRemaining = _waterIntervalMinutes * 60);
} else {
setState(() => _waterSecondsRemaining--);
}
});
}

String _formatClock(int totalSeconds) {
final m = (totalSeconds ~/ 60).toString().padLeft(2, '0');
final s = (totalSeconds % 60).toString().padLeft(2, '0');
return '$m:$s';
}

Future<void> _toggleLiveTraining(bool enable) async {
if (widget.isAnonymous) return;
final userRef = FirebaseFirestore.instance
.collection('users')
.doc(widget.currentUserId);

if (enable) {
_workoutStartedAt = DateTime.now();
await userRef.set({
'isTraining': true,
'currentExercise': _liveExerciseController.text.trim(),
'trainingStartedAt': FieldValue.serverTimestamp(),
}, SetOptions(merge: true));
} else {
final finishedExercise = _liveExerciseController.text.trim();
final elapsedMins = _workoutStartedAt != null
? DateTime.now().difference(_workoutStartedAt!).inMinutes.clamp(1, 300)
: 45;

_restTimer?.cancel();
_waterTimer?.cancel();
setState(() {
_restSecondsRemaining = 0;
_waterIntervalMinutes = 0;
_waterSecondsRemaining = 0;
});

await userRef.set({
'isTraining': false,
'currentExercise': '',
'totalWorkouts': FieldValue.increment(1),
}, SetOptions(merge: true));

if (!mounted) return;
final shouldPublish = await showDialog<bool>(
context: context,
builder: (ctx) => AlertDialog(
title: const Text(AppStrings.publishWorkoutPromptTitle),
content: const Text(AppStrings.publishWorkoutPromptBody),
actions: [
TextButton(
onPressed: () => Navigator.pop(ctx, false),
child: const Text(AppStrings.justFinishBtn),
),
ElevatedButton(
onPressed: () => Navigator.pop(ctx, true),
child: const Text(AppStrings.publishAsTemp24hBtn),
),
],
),
);

if (shouldPublish == true) {
final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
final summary = finishedExercise.isNotEmpty
? '💪 Entrenamiento completado: $finishedExercise ($elapsedMins min) #gym'
: '💪 Sesión de entrenamiento completada ($elapsedMins min) #gym';
await FirebaseFirestore.instance.collection('posts').add({
'uid': uid,
'author': widget.currentUserId,
'content': summary,
'postCategory': 'workout',
'durationMinutes': elapsedMins,
'calories': elapsedMins * 7,
'likes': [],
'commentsCount': 0,
'createdAt': FieldValue.serverTimestamp(),
'expiresAt': Timestamp.fromDate(
DateTime.now().add(const Duration(hours: 24)),
),
});
}
}
}

Future<void> _updateCurrentExercise() async {
await FirebaseFirestore.instance
.collection('users')
.doc(widget.currentUserId)
.set({
'currentExercise': _liveExerciseController.text.trim(),
}, SetOptions(merge: true));
if (!mounted) return;
FocusScope.of(context).unfocus();
}

void _showEditDayRoutineDialog(int dayIndex, Map<String, dynamic> currentDayData) {
final focusCtrl = TextEditingController(
text: (currentDayData['focus'] ?? '').toString(),
);
final exercisesCtrl = TextEditingController(
text: (currentDayData['exercises'] ?? '').toString(),
);

showDialog(
context: context,
builder: (ctx) => AlertDialog(
title: Text(
'${AppStrings.editDayRoutineTitle} (${AppStrings.weekDaysFull[dayIndex]})',
),
content: SingleChildScrollView(
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
TextField(
controller: focusCtrl,
decoration: const InputDecoration(
labelText: AppStrings.dayFocusHint,
border: OutlineInputBorder(),
),
),
const SizedBox(height: 12),
TextField(
controller: exercisesCtrl,
maxLines: 5,
decoration: const InputDecoration(
labelText: AppStrings.dayExercisesHint,
border: OutlineInputBorder(),
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
final nav = Navigator.of(ctx);
await FirebaseFirestore.instance
.collection('users')
.doc(widget.currentUserId)
.set({
'weeklyRoutine': {
dayIndex.toString(): {
'focus': focusCtrl.text.trim(),
'exercises': exercisesCtrl.text.trim(),
},
},
}, SetOptions(merge: true));
nav.pop();
},
child: const Text(AppStrings.save),
),
],
),
);
}

void _showAddPrDialog() {
final nameCtrl = TextEditingController();
final valueCtrl = TextEditingController();
final notesCtrl = TextEditingController();
final kmCtrl = TextEditingController();

showDialog(
context: context,
builder: (ctx) => AlertDialog(
title: const Text(AppStrings.addCustomPrBtn),
content: SingleChildScrollView(
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
TextField(
controller: nameCtrl,
decoration: const InputDecoration(
labelText: AppStrings.exerciseNameLabel,
hintText: AppStrings.exerciseNameHint,
border: OutlineInputBorder(),
),
),
const SizedBox(height: 12),
TextField(
controller: valueCtrl,
decoration: const InputDecoration(
labelText: AppStrings.prValueLabel,
hintText: AppStrings.prValueHint,
border: OutlineInputBorder(),
),
),
const SizedBox(height: 12),
TextField(
controller: notesCtrl,
decoration: const InputDecoration(
labelText: AppStrings.prNotesLabel,
border: OutlineInputBorder(),
),
),
const SizedBox(height: 12),
TextField(
controller: kmCtrl,
keyboardType: const TextInputType.numberWithOptions(decimal: true),
decoration: const InputDecoration(
labelText: '+ Km recorridos (opcional)',
hintText: 'Ej: 5.5',
border: OutlineInputBorder(),
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
final exName = nameCtrl.text.trim();
final prVal = valueCtrl.text.trim();
if (exName.isEmpty || prVal.isEmpty) return;

final nav = Navigator.of(ctx);
final addedKm = double.tryParse(kmCtrl.text.trim().replaceAll(',', '.')) ?? 0.0;

final updates = <String, dynamic>{
'personalRecords': FieldValue.arrayUnion([
{
'exercise': exName,
'record': prVal,
'notes': notesCtrl.text.trim(),
'date': DateTime.now().toIso8601String().substring(0, 10),
}
]),
};
if (addedKm > 0) {
updates['totalKm'] = FieldValue.increment(addedKm);
}

await FirebaseFirestore.instance
.collection('users')
.doc(widget.currentUserId)
.set(updates, SetOptions(merge: true));
nav.pop();
},
child: const Text(AppStrings.save),
),
],
),
);
}

@override
Widget build(BuildContext context) {
final isTraining = widget.userData['isTraining'] == true;
final activeExercise =
(widget.userData['currentExercise'] ?? '').toString();
final weeklyRoutine = Map<String, dynamic>.from(
widget.userData['weeklyRoutine'] ?? {},
);
final selectedDayMap = Map<String, dynamic>.from(
weeklyRoutine[_selectedDayIndex.toString()] ?? {},
);
final rawPrs = (widget.userData['personalRecords'] as List<dynamic>?) ?? [];
    final prs = rawPrs
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    final totalKm = (widget.userData['totalKm'] ?? 0).toDouble();
final totalWorkouts = (widget.userData['totalWorkouts'] ?? 0) as int;

return Column(
crossAxisAlignment: CrossAxisAlignment.stretch,
children: [
// 1. MODO ENTRENAMIENTO EN VIVO
if (widget.isMyProfile && !widget.isAnonymous) ...[
Card(
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(14),
side: BorderSide(
color: isTraining
? Colors.greenAccent
: Theme.of(context).dividerColor,
width: isTraining ? 1.5 : 1,
),
),
child: Padding(
padding: const EdgeInsets.all(14),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Row(
children: [
Icon(
Icons.fitness_center,
color: isTraining ? Colors.greenAccent : null,
),
const SizedBox(width: 8),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
const Text(
AppStrings.liveWorkoutTitle,
style: TextStyle(
fontWeight: FontWeight.bold,
fontSize: 15,
),
),
Text(
isTraining
? AppStrings.liveWorkoutActiveBadge
: AppStrings.liveWorkoutInactiveSub,
style: TextStyle(
fontSize: 12,
color: isTraining
? Colors.greenAccent
: Colors.grey,
fontWeight: isTraining
? FontWeight.bold
: FontWeight.normal,
),
),
],
),
),
Switch(
value: isTraining,
onChanged: _toggleLiveTraining,
),
],
),
if (isTraining) ...[
const Divider(height: 20),
Row(
children: [
Expanded(
child: TextField(
controller: _liveExerciseController,
decoration: const InputDecoration(
labelText: AppStrings.currentExerciseLabel,
hintText: AppStrings.currentExerciseHint,
isDense: true,
border: OutlineInputBorder(),
),
),
),
const SizedBox(width: 8),
ElevatedButton(
onPressed: _updateCurrentExercise,
child: const Text(AppStrings.updateExerciseBtn),
),
],
),
const SizedBox(height: 12),
// Temporizador de descanso entre series
Row(
children: [
const Icon(Icons.timer, size: 18),
const SizedBox(width: 6),
Text(
_restSecondsRemaining > 0
? '${AppStrings.restTimerTitle}: ${_formatClock(_restSecondsRemaining)}'
: AppStrings.restTimerTitle,
style: const TextStyle(
fontWeight: FontWeight.w600,
fontSize: 13,
),
),
],
),
const SizedBox(height: 6),
Wrap(
spacing: 6,
children: [
for (final sec in [60, 90, 120, 180])
ActionChip(
label: Text(sec < 120 ? '${sec}s' : '${sec ~/ 60}m'),
onPressed: () => _startRestTimer(sec),
),
if (_restSecondsRemaining > 0)
ActionChip(
label: const Text('Stop'),
onPressed: () {
_restTimer?.cancel();
setState(() => _restSecondsRemaining = 0);
},
),
],
),
const SizedBox(height: 10),
// Recordatorio de hidratación
Row(
children: [
const Icon(Icons.water_drop, size: 18, color: Colors.lightBlueAccent),
const SizedBox(width: 6),
Text(
_waterSecondsRemaining > 0
? '${AppStrings.waterTimerTitle}: ${_formatClock(_waterSecondsRemaining)}'
: AppStrings.waterTimerTitle,
style: const TextStyle(
fontWeight: FontWeight.w600,
fontSize: 13,
),
),
],
),
const SizedBox(height: 6),
Wrap(
spacing: 6,
children: [
for (final mins in [15, 20, 30])
ChoiceChip(
label: Text('c/ ${mins}m'),
selected: _waterIntervalMinutes == mins,
onSelected: (_) => _setWaterReminder(
_waterIntervalMinutes == mins ? 0 : mins,
),
),
],
),
const SizedBox(height: 12),
SizedBox(
width: double.infinity,
child: OutlinedButton.icon(
icon: const Icon(Icons.flag_outlined),
label: const Text(AppStrings.finishWorkoutBtn),
onPressed: () => _toggleLiveTraining(false),
),
),
],
],
),
),
),
const SizedBox(height: 12),
] else if (!widget.isMyProfile && isTraining) ...[
// Estado en vivo visible para visitantes del perfil
Container(
padding: const EdgeInsets.all(12),
decoration: BoxDecoration(
color: Colors.green.withValues(alpha: 0.15),
borderRadius: BorderRadius.circular(12),
border: Border.all(color: Colors.greenAccent),
),
child: Row(
children: [
const Icon(Icons.fitness_center, color: Colors.greenAccent),
const SizedBox(width: 10),
Expanded(
child: Text(
activeExercise.isNotEmpty
? '${AppStrings.liveWorkoutActiveBadge}: $activeExercise'
: AppStrings.liveWorkoutActiveBadge,
style: const TextStyle(
fontWeight: FontWeight.bold,
color: Colors.greenAccent,
),
),
),
],
),
),
const SizedBox(height: 12),
],

// 2. RUTINA SEMANAL DE 7 DÍAS
Card(
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
child: Padding(
padding: const EdgeInsets.all(14),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Row(
children: [
const Icon(Icons.calendar_view_week),
const SizedBox(width: 8),
const Expanded(
child: Text(
AppStrings.weeklyRoutineTitle,
style: TextStyle(
fontWeight: FontWeight.bold,
fontSize: 15,
),
),
),
if (widget.isMyProfile && !widget.isAnonymous)
IconButton(
icon: const Icon(Icons.edit_outlined, size: 20),
onPressed: () => _showEditDayRoutineDialog(
_selectedDayIndex,
selectedDayMap,
),
),
],
),
const SizedBox(height: 8),
SingleChildScrollView(
scrollDirection: Axis.horizontal,
child: Row(
children: List.generate(7, (idx) {
final selected = idx == _selectedDayIndex;
return Padding(
padding: const EdgeInsets.only(right: 6),
child: ChoiceChip(
label: Text(AppStrings.weekDaysShort[idx]),
selected: selected,
onSelected: (_) =>
setState(() => _selectedDayIndex = idx),
),
);
}),
),
),
const SizedBox(height: 10),
Container(
width: double.infinity,
padding: const EdgeInsets.all(12),
decoration: BoxDecoration(
color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
borderRadius: BorderRadius.circular(10),
),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
'${AppStrings.weekDaysFull[_selectedDayIndex]}: ${(selectedDayMap['focus'] ?? '').toString().isNotEmpty ? selectedDayMap['focus'] : AppStrings.restDayLabel}',
style: const TextStyle(fontWeight: FontWeight.bold),
),
const SizedBox(height: 6),
Text(
(selectedDayMap['exercises'] ?? '').toString().isNotEmpty
? selectedDayMap['exercises'].toString()
: AppStrings.noExercisesRegistered,
style: const TextStyle(fontSize: 13),
),
],
),
),
],
),
),
),
const SizedBox(height: 12),

// 3. LOGROS, PRs Y EVOLUCIÓN (KILÓMETROS / SESIONES / RÉCORDS)
Card(
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
child: Padding(
padding: const EdgeInsets.all(14),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Row(
children: [
const Icon(Icons.emoji_events_outlined, color: Colors.amber),
const SizedBox(width: 8),
const Expanded(
child: Text(
AppStrings.achievementsAndPrsTitle,
style: TextStyle(
fontWeight: FontWeight.bold,
fontSize: 15,
),
),
),
if (widget.isMyProfile && !widget.isAnonymous)
TextButton.icon(
icon: const Icon(Icons.add, size: 18),
label: const Text(AppStrings.addCustomPrBtn),
onPressed: _showAddPrDialog,
),
],
),
const SizedBox(height: 8),
Row(
children: [
Expanded(
child: _MetricTile(
icon: Icons.directions_run,
label: AppStrings.totalKmLabel,
value: '${totalKm.toStringAsFixed(1)} km',
),
),
const SizedBox(width: 8),
Expanded(
child: _MetricTile(
icon: Icons.check_circle_outline,
label: AppStrings.totalWorkoutsLabel,
value: '$totalWorkouts',
),
),
],
),
const SizedBox(height: 10),
if (prs.isEmpty)
const Text(
AppStrings.noPrsYet,
style: TextStyle(fontSize: 13, color: Colors.grey),
)
else
...prs.reversed.map(
(pr) => ListTile(
dense: true,
contentPadding: EdgeInsets.zero,
leading: const Icon(Icons.military_tech, color: Colors.amber),
title: Text(
'${pr['exercise']} — ${pr['record']}',
style: const TextStyle(fontWeight: FontWeight.w600),
),
subtitle: Text(
[
if ((pr['notes'] ?? '').toString().isNotEmpty)
pr['notes'].toString(),
if ((pr['date'] ?? '').toString().isNotEmpty)
pr['date'].toString(),
].join(' • '),
),
),
),
],
),
),
),
],
);
}
}

class _MetricTile extends StatelessWidget {
final IconData icon;
final String label;
final String value;

const _MetricTile({
required this.icon,
required this.label,
required this.value,
});

@override
Widget build(BuildContext context) {
return Container(
padding: const EdgeInsets.all(10),
decoration: BoxDecoration(
color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
borderRadius: BorderRadius.circular(10),
),
child: Row(
children: [
Icon(icon, size: 20),
const SizedBox(width: 8),
Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
],
),
],
),
);
}
}
