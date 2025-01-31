import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:know_keeper/service/url_providers.dart';

import '../service/database_providers.dart';

class TagColorDot extends ConsumerWidget {
  final String tag;
  final double radius;

  const TagColorDot({required this.tag, this.radius = 6, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagColors = ref.watch(tagColorsProvider);

    return Container(
      width: radius,
      height: radius,
      decoration: BoxDecoration(
        color: tagColors.when(
            data: (data) {
              final color = data[tag];
              if (color != null) {
                return color;
              } else {
                final hash = stringToHash(tag);
                final newColor = hashToColor(hash);
                ref.read(databaseProvider).setTagColor(tag, hash);
                return newColor;
              }
            },
            error: (_, __) => Colors.amber,
            loading: () => hashToColor(stringToHash(tag))),
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
