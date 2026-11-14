import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

class MediaHelper {
static final ImagePicker _picker = ImagePicker();

static Future<String?> pickAndEncodeImage({
ImageSource source = ImageSource.gallery,
int maxDimension = 900,
int quality = 72,
}) async {
final XFile? file = await _picker.pickImage(
source: source,
maxWidth: maxDimension.toDouble(),
maxHeight: maxDimension.toDouble(),
imageQuality: quality,
);
if (file == null) return null;

final Uint8List bytes = await file.readAsBytes();
if (bytes.lengthInBytes > 550 * 1024) {
return 'TOO_LARGE';
}
final base64Str = base64Encode(bytes);
return 'data:image/jpeg;base64,$base64Str';
}

static Future<String?> pickAndEncodeProfileVideo({
ImageSource source = ImageSource.gallery,
}) async {
final XFile? file = await _picker.pickVideo(
source: source,
maxDuration: const Duration(seconds: 6),
);
if (file == null) return null;

final Uint8List bytes = await file.readAsBytes();
if (bytes.lengthInBytes > 650 * 1024) {
return 'TOO_LARGE';
}
final base64Str = base64Encode(bytes);
return 'data:video/mp4;base64,$base64Str';
}
}

class SmartPostImage extends StatelessWidget {
final String url;
final double? height;
final double? width;
final BoxFit fit;
final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;

const SmartPostImage({
super.key,
required this.url,
this.height,
this.width,
this.fit = BoxFit.cover,
this.errorBuilder,
});

@override
Widget build(BuildContext context) {
final fallback = errorBuilder ?? (_, _, _) => const SizedBox.shrink();

if (url.startsWith('data:image')) {
final commaIndex = url.indexOf(',');
if (commaIndex != -1) {
try {
final bytes = base64Decode(url.substring(commaIndex + 1));
return Image.memory(
bytes,
height: height,
width: width,
fit: fit,
errorBuilder: fallback,
);
} catch (_) {
return const SizedBox.shrink();
}
}
}
return Image.network(
url,
height: height,
width: width,
fit: fit,
errorBuilder: fallback,
);
}
}

class ProfileMediaAvatar extends StatefulWidget {
final String mediaUrl;
final String fallbackLetter;
final double radius;
final VoidCallback? onTap;
final bool showEditBadge;

const ProfileMediaAvatar({
super.key,
required this.mediaUrl,
required this.fallbackLetter,
this.radius = 44,
this.onTap,
this.showEditBadge = false,
});

@override
State<ProfileMediaAvatar> createState() => _ProfileMediaAvatarState();
}

class _ProfileMediaAvatarState extends State<ProfileMediaAvatar> {
VideoPlayerController? _videoController;
String _loadedUrl = '';
bool _videoReady = false;

@override
void initState() {
super.initState();
_syncVideoIfNeeded();
}

@override
void didUpdateWidget(covariant ProfileMediaAvatar oldWidget) {
super.didUpdateWidget(oldWidget);
if (oldWidget.mediaUrl != widget.mediaUrl) {
_syncVideoIfNeeded();
}
}

Future<void> _syncVideoIfNeeded() async {
if (!widget.mediaUrl.startsWith('data:video')) {
await _disposeVideo();
return;
}
if (_loadedUrl == widget.mediaUrl && _videoController != null) return;

await _disposeVideo();
_loadedUrl = widget.mediaUrl;

final commaIndex = widget.mediaUrl.indexOf(',');
if (commaIndex == -1) return;

try {
final bytes = base64Decode(widget.mediaUrl.substring(commaIndex + 1));
final tempFile = File(
'${Directory.systemTemp.path}/avatar_${widget.mediaUrl.hashCode}.mp4',
);
await tempFile.writeAsBytes(bytes, flush: true);

final ctrl = VideoPlayerController.file(tempFile);
await ctrl.initialize();
await ctrl.setLooping(true);
await ctrl.setVolume(0);
await ctrl.play();

if (!mounted) {
await ctrl.dispose();
return;
}
setState(() {
_videoController = ctrl;
_videoReady = true;
});
} catch (_) {
await _disposeVideo();
}
}

Future<void> _disposeVideo() async {
final old = _videoController;
_videoController = null;
_loadedUrl = '';
if (mounted) {
setState(() => _videoReady = false);
}
await old?.dispose();
}

@override
void dispose() {
_videoController?.dispose();
super.dispose();
}

@override
Widget build(BuildContext context) {
final size = widget.radius * 2;
Widget inner;

if (widget.mediaUrl.startsWith('data:video')) {
if (_videoReady && _videoController != null) {
inner = SizedBox(
width: size,
height: size,
child: FittedBox(
fit: BoxFit.cover,
clipBehavior: Clip.hardEdge,
child: SizedBox(
width: _videoController!.value.size.width,
height: _videoController!.value.size.height,
child: VideoPlayer(_videoController!),
),
),
);
} else {
inner = Container(
width: size,
height: size,
color: Theme.of(context).colorScheme.surfaceContainerHighest,
child: const Center(
child: SizedBox(
width: 22,
height: 22,
child: CircularProgressIndicator(strokeWidth: 2),
),
),
);
}
} else if (widget.mediaUrl.startsWith('data:image')) {
final commaIndex = widget.mediaUrl.indexOf(',');
Uint8List? bytes;
if (commaIndex != -1) {
try {
bytes = base64Decode(widget.mediaUrl.substring(commaIndex + 1));
} catch (_) {}
}
if (bytes != null) {
inner = Image.memory(
bytes,
width: size,
height: size,
fit: BoxFit.cover,
);
} else {
inner = _buildLetterFallback(size);
}
} else if (widget.mediaUrl.isNotEmpty) {
inner = Image.network(
widget.mediaUrl,
width: size,
height: size,
fit: BoxFit.cover,
errorBuilder: (_, _, _) => _buildLetterFallback(size),
);
} else {
inner = _buildLetterFallback(size);
}

return GestureDetector(
onTap: widget.onTap,
child: Stack(
alignment: Alignment.bottomRight,
children: [
Container(
width: size,
height: size,
decoration: BoxDecoration(
shape: BoxShape.circle,
border: Border.all(
color: Theme.of(context).colorScheme.primary,
width: 2.5,
),
),
child: ClipOval(child: inner),
),
if (widget.showEditBadge)
Container(
padding: const EdgeInsets.all(5),
decoration: BoxDecoration(
color: Theme.of(context).colorScheme.primary,
shape: BoxShape.circle,
),
child: const Icon(
Icons.camera_alt,
size: 14,
color: Colors.white,
),
)
else if (widget.mediaUrl.startsWith('data:video'))
Container(
padding: const EdgeInsets.all(4),
decoration: const BoxDecoration(
color: Colors.black87,
shape: BoxShape.circle,
),
child: const Icon(
Icons.videocam,
size: 13,
color: Colors.white,
),
),
],
),
);
}

Widget _buildLetterFallback(double size) {
return Container(
width: size,
height: size,
color: Theme.of(context).colorScheme.primaryContainer,
alignment: Alignment.center,
child: Text(
widget.fallbackLetter,
style: TextStyle(
fontSize: widget.radius * 0.72,
fontWeight: FontWeight.bold,
),
),
);
}
}
