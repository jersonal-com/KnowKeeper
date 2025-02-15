import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';

class NothingHere extends ConsumerWidget {
  const NothingHere({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        const SizedBox(height: 25),
        Lottie.asset('assets/animations/nothinghere.json'),
        const SizedBox(height: 50),
        Text(
          'Nothing Here ...',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        Text(
          '... add your first URL or RSS feed',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ],
    );
  }
}
