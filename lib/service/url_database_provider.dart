import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../data/url_database.dart';
import '../data/url_entry.dart';

// Assuming UrlDatabase and UrlEntry classes are defined as in the previous example

class UrlDatabaseNotifier extends StateNotifier<UrlDatabase> {
  UrlDatabaseNotifier() : super(UrlDatabase()) {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString('url_database');
    if (jsonString != null) {
      final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
      final UrlDatabase loadedDatabase = UrlDatabase();

      jsonMap.forEach((url, entryJson) {
        final entry = UrlEntry(
          title: entryJson['title'],
          source: entryJson['source'],
          date: DateTime.parse(entryJson['date']),
          imageUrl: entryJson['imageUrl'],
          text: entryJson['text'],
        );
        loadedDatabase.addEntry(url, entry);
      });

      state = loadedDatabase;
    }
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> jsonMap = {};

    state.getAllEntries().forEach((entry) {
      final url = state.database.entries
          .firstWhere((element) => element.value == entry)
          .key;
      jsonMap[url] = {
        'title': entry.title,
        'source': entry.source,
        'date': entry.date.toIso8601String(),
        'imageUrl': entry.imageUrl,
        'text': entry.text,
      };
    });

    await prefs.setString('url_database', jsonEncode(jsonMap));
  }

  void addEntry(String url, UrlEntry entry) {
    state.addEntry(url, entry);
    _saveToPrefs();
  }

  void removeEntry(String url) {
    state.removeEntry(url);
    _saveToPrefs();
  }
}

final urlDatabaseProvider = StateNotifierProvider<UrlDatabaseNotifier, UrlDatabase>((ref) {
  return UrlDatabaseNotifier();
});