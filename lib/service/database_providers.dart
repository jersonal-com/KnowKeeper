import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/sembast_database.dart';
import '../data/highlight.dart';

final databaseProvider = Provider<DatabaseOperations>((ref) {
  return DatabaseOperations(SembastDatabase.instance);
});

class DatabaseOperations {
  final SembastDatabase database;

  DatabaseOperations(this.database);

  Future<List<Highlight>> getHighlightsForUrl(String url) {
    return database.getHighlightsForUrl(url);
  }

  Future<void> addOrUpdateHighlight(Highlight highlight) {
    return database.addOrUpdateHighlight(highlight);
  }

  Future<void> deleteHighlight(Highlight highlight) {
    return database.deleteHighlight(highlight);
  }
}