import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data_fetcher/garbage_processor.dart';

class AdvancedSettingsPage extends ConsumerWidget {
  const AdvancedSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Advanced Settings'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            final garbageProcessor = GarbageProcessor();
            await garbageProcessor.process(force: true);
          },
          child: const Text('Delete all marked items'),
        ),
      ),
    );
  }
}