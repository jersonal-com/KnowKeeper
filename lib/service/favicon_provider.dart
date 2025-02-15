import 'package:favicon/favicon.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final faviconProvider = FutureProvider.family<String?, String>((ref, domain) async {
  try {
    final favicon = await FaviconFinder.getBest(domain);
    return favicon?.url;
  } catch (e) {
    debugPrint('Error fetching favicon for $domain: $e');
    return null;
  }
});