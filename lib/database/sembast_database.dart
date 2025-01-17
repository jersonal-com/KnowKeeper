// ignore_for_file: constant_identifier_names

import 'dart:async';

import 'package:sembast/sembast_io.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import '../data/url_entry.dart';
import '../data/highlight.dart';

class SembastDatabase {
  static const String DB_NAME = 'know_keeper.db';
  static const String URL_STORE_NAME = 'url_entries';
  static const String HIGHLIGHT_STORE_NAME = 'highlights';

  // Singleton instance
  static final SembastDatabase _singleton = SembastDatabase._();

  // Singleton accessor
  static SembastDatabase get instance => _singleton;

  // Completer is used for transforming synchronous code into asynchronous code.
  Completer<Database>? _dbOpenCompleter;

  // Private constructor
  SembastDatabase._();

  // Database object accessor
  Future<Database> get database async {
    if (_dbOpenCompleter == null) {
      _dbOpenCompleter = Completer();
      _openDatabase();
    }
    return _dbOpenCompleter!.future;
  }

  Future<void> _openDatabase() async {
    final appDocumentDir = await getApplicationDocumentsDirectory();
    final dbPath = join(appDocumentDir.path, DB_NAME);
    final database = await databaseFactoryIo.openDatabase(dbPath);
    _dbOpenCompleter!.complete(database);
  }

  Future<void> addUrlEntry(UrlEntry entry) async {
    final db = await database;
    final store = intMapStoreFactory.store(URL_STORE_NAME);

    // Check if the entry already exists
    final finder = Finder(filter: Filter.equals('url', entry.url));
    final existingEntry = await store.findFirst(db, finder: finder);

    if (existingEntry == null) {
      // If the entry doesn't exist, add it
      await store.add(db, entry.toMap());
    } else {
      // If the entry exists, update it
      await store.update(db, entry.toMap(), finder: finder);
    }
  }

  Future<void> updateUrlEntry(UrlEntry entry) async {
    final db = await database;
    final store = intMapStoreFactory.store(URL_STORE_NAME);
    final finder = Finder(filter: Filter.byKey(entry.url));
    await store.update(db, entry.toMap(), finder: finder);
  }

  Future<void> addOrUpdateHighlight(Highlight highlight) async {
    final db = await database;
    final store = intMapStoreFactory.store(HIGHLIGHT_STORE_NAME);
    final finder = Finder(filter: Filter.and([
      Filter.equals('url', highlight.url),
      Filter.equals('paragraphIndex', highlight.paragraphIndex),
      Filter.equals('startIndex', highlight.startIndex),
    ]));
    await store.update(
      db,
      highlight.toMap(),
      finder: finder,
      // createIfMissing: true,
    );
  }

  Future<List<UrlEntry>> getNonArchivedUrlEntries() async {
    final db = await database;
    final store = intMapStoreFactory.store(URL_STORE_NAME);
    final finder = Finder(
      filter: Filter.equals('archived', false),
      sortOrders: [SortOrder('date', false)],
    );
    final snapshots = await store.find(db, finder: finder);
    return snapshots.map((snapshot) {
      final entry = UrlEntry.fromMap(snapshot.value);
      entry.id = snapshot.key;
      return entry;
    }).toList();
  }

  Future<UrlEntry?> getUrlEntryByUrl(String url) async {
    final db = await database;
    final store = intMapStoreFactory.store(URL_STORE_NAME);
    final finder = Finder(filter: Filter.equals('url', url));
    final snapshot = await store.findFirst(db, finder: finder);
    if (snapshot != null) {
      final entry = UrlEntry.fromMap(snapshot.value);
      entry.id = snapshot.key;
      return entry;
    }
    return null;
  }

  Future<List<Highlight>> getHighlightsForUrl(String url) async {
    final db = await database;
    final store = intMapStoreFactory.store(HIGHLIGHT_STORE_NAME);
    final finder = Finder(filter: Filter.equals('url', url));
    final snapshots = await store.find(db, finder: finder);
    return snapshots.map((snapshot) => Highlight.fromMap(snapshot.value)).toList();
  }
}