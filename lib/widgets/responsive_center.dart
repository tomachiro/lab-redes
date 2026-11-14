import 'package:flutter/material.dart';

class ResponsiveCenter extends StatelessWidget {
final Widget child;
final double maxWidth;
final EdgeInsetsGeometry padding;

const ResponsiveCenter({
super.key,
required this.child,
this.maxWidth = 680,
this.padding = EdgeInsets.zero,
});

@override
Widget build(BuildContext context) {
return Center(
child: ConstrainedBox(
constraints: BoxConstraints(maxWidth: maxWidth),
child: Padding(
padding: padding,
child: child,
),
),
);
}
}
