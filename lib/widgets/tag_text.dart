import 'package:flutter/material.dart';

import 'tag_color_dot.dart';

class TagText extends StatelessWidget {
  final String text;

  const TagText(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        TagColorDot(tag: text),
        const SizedBox(width: 8),
        Text(text),
      ],
    );
  }
}