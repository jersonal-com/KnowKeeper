import 'package:flutter/material.dart';

class TagColorDot extends StatelessWidget {
  final String tag;
  final double radius;

  const TagColorDot({required this.tag, this.radius = 6, super.key} );

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius,
      height: radius,
      decoration: BoxDecoration(
        color: hashToColor(stringToHash(tag)),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

int stringToHash(String input) {
  var hash = 0;
  for (var i = 0; i < input.length; i++) {
    hash = input.codeUnitAt(i) + ((hash << 5) - hash);
  }
  return hash;
}

Color hashToColor(int hash) {
  final r = (hash & 0xFF0000) >> 16;
  final g = (hash & 0x00FF00) >> 8;
  final b = hash & 0x0000FF;

  return Color.fromARGB(255, r, g, b);
}