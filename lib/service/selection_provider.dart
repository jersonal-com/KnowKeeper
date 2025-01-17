import 'package:flutter_riverpod/flutter_riverpod.dart';

class Selection {
  final int paragraphIndex;
  final int startIndex;
  final int length;
  final String text;

  Selection({required this.paragraphIndex, required this.startIndex, required this.length, required this.text});
}

final currentSelectionProvider = StateProvider<Selection?>((ref) => null);