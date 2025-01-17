import 'package:flutter_riverpod/flutter_riverpod.dart';

class Selection {
  final int paragraphIndex;
  final int startIndex;
  final int length;

  Selection({required this.paragraphIndex, required this.startIndex, required this.length});
}

final currentSelectionProvider = StateProvider<Selection?>((ref) => null);