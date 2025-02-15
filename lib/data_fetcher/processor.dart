import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class Processor {
  final Ref ref;

  Processor(this.ref);

  Future<void> process();
}