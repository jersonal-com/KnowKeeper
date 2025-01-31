import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/url_entry.dart';
import '../database/sembast_database.dart';
import '../data/highlight.dart';

final databaseProvider = Provider<DatabaseOperations>((ref) {
  return DatabaseOperations(SembastDatabase.instance);
});

class DatabaseOperations {
  final SembastDatabase database;

  DatabaseOperations(this.database);

  Future<List<UrlEntry>> getNonArchivedUrlEntries() {
    return database.getNonArchivedUrlEntries();
  }

  Future<void> addUrlEntry(UrlEntry entry) {
    return database.addUrlEntry(entry);
  }

  Future<void> updateUrlEntry(UrlEntry entry) {
    return database.updateUrlEntry(entry);
  }

  Future<List<Highlight>> getHighlightsForUrl(String url) {
    return database.getHighlightsForUrl(url);
  }

  Future<void> addOrUpdateHighlight(Highlight highlight) {
    return database.addOrUpdateHighlight(highlight);
  }

  Future<void> deleteHighlight(Highlight highlight) {
    return database.deleteHighlight(highlight);
  }

  Future<void> wipe() async {
    return await database.wipeDatabase();
  }

  Future<List<String>> getAllTags() async {
    return await database.getAllTags();
  }

  Future<void> renameTag(String oldTag, String newTag) async {
    await database.renameTag(oldTag, newTag);
  }

  Future<void> deleteTag(String tag) async {
    await database.deleteTag(tag);
  }

  Future<void> setTagColor(String tag, int colorValue) async {
    await database.setTagColor(tag, colorValue);
  }

  Future<Map<String, Color>> getAllTagColors() async {
    return await database.getAllTagColors();
  }

}