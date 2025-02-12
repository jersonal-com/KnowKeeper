import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/sembast_database.dart';
import '../data/url_entry.dart';
import 'processor.dart';

class AutoTagProcessor extends Processor {
  final SembastDatabase database = SembastDatabase.instance;

  AutoTagProcessor();

  @override
  Future<void> process({bool force = false}) async {
    debugPrint('AutoTagProcessor: Starting auto-tagging...');

    final entries = await database.getNonArchivedUrlEntries();
    final tagKeywords = await _loadTagKeywords();

    for (final entry in entries) {
      if (!entry.autoTagged || force) {
        final newTags = _matchTags(entry, tagKeywords);
        if (newTags.isNotEmpty) {
          final updatedEntry = entry.copyWith(
            tags: [...entry.tags, ...newTags],
            autoTagged: true,
          );
          await database.updateUrlEntry(updatedEntry);
          debugPrint('AutoTagProcessor: Tagged entry ${entry.url} with ${newTags.join(', ')}');
        }
      }
    }

    debugPrint('AutoTagProcessor: Auto-tagging completed.');
  }

  Future<Map<String, List<String>>> _loadTagKeywords() async {
    final prefs = await SharedPreferences.getInstance();
    return Map.fromEntries(
      prefs.getKeys().where((key) => key.startsWith('tag_keywords_')).map(
            (key) => MapEntry(
          key.substring('tag_keywords_'.length),
          prefs.getStringList(key) ?? [],
        ),
      ),
    );
  }

  List<String> _matchTags(UrlEntry entry, Map<String, List<String>> tagKeywords) {
    final newTags = <String>[];
    for (final tag in tagKeywords.keys) {
      if (tagKeywords[tag]!.any((keyword) =>
      entry.url.toLowerCase().contains(keyword.toLowerCase()) ||
          entry.title.toLowerCase().contains(keyword.toLowerCase()) ||
          entry.description.toLowerCase().contains(keyword.toLowerCase()))) {
        newTags.add(tag);
      }
    }
    return newTags;
  }
}

final autoTagProcessorProvider = Provider<AutoTagProcessor>((ref) {
  return AutoTagProcessor();
});