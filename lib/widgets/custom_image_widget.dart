import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:know_keeper/testing/test_configuration.dart';

class CustomImageWidget extends ConsumerWidget {
  final String imageUrl;
  const CustomImageWidget(this.imageUrl, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (TestConfiguration.isTestMode) {
      return Image.asset('assets/testImages/$imageUrl');
    }
    if (imageUrl.isEmpty) {
      return const SizedBox.shrink();
    }
    return CachedNetworkImage(
      imageUrl: imageUrl,
      placeholder: (context, url) => const CircularProgressIndicator(),
      errorWidget: (context, url, error) => const Icon(Icons.error),
    );
  }
}
