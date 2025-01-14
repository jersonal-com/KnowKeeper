import '../data_fetcher/fetch_url_entry.dart';
import 'url_entry.dart';

class UrlDatabase {
  final Map<String, UrlEntry> _database = {};

  Map<String, UrlEntry> get database => _database;

  void addEntry(String url, UrlEntry entry) {
    _database[url] = entry;
  }

  Future<void> addUrl(String url) async {
    final entry = await fetchUrlEntry(url);
    addEntry(url, entry);
  }

  UrlEntry? getEntry(String url) {
    return _database[url];
  }

  List<UrlEntry> getAllEntries() {
    return _database.values.toList();
  }

  void removeEntry(String url) {
    _database.remove(url);
  }
}
