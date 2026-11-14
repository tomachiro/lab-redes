import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
final double size;
final double borderRadius;

const AppLogo({
super.key,
required this.size,
this.borderRadius = 8,
});

@override
Widget build(BuildContext context) {
return Image.asset(
'assets/images/logo.png',
width: size,
height: size,
fit: BoxFit.cover,
frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
if (wasSynchronouslyLoaded || frame != null) {
return ClipRRect(
borderRadius: BorderRadius.circular(borderRadius),
child: child,
);
}
return const SizedBox.shrink();
},
errorBuilder: (_, _, _) => const SizedBox.shrink(),
);
}
}
