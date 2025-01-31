// ignore_for_file: constant_identifier_names

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sembast/sembast_io.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import '../data/url_entry.dart';
import '../data/highlight.dart';

class SembastDatabase {
  static const String DB_NAME = 'know_keeper.db';
  static const String URL_STORE_NAME = 'url_entries';
  static const String HIGHLIGHT_STORE_NAME = 'highlights';
  final _highlightsStoreRef = intMapStoreFactory.store(HIGHLIGHT_STORE_NAME);
  final _urlStoreRef = intMapStoreFactory.store(URL_STORE_NAME);

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
    final store = _urlStoreRef;

    // Check if the entry already exists
    final finder = Finder(filter: Filter.equals('url', entry.url));
    final existingEntry = await store.findFirst(db, finder: finder);

    if (existingEntry == null) {
      // If the entry doesn't exist, add it
      await store.add(db, entry.toMap());
    } else {
      // We do not want to add the entry if it already exists
      // await store.update(db, entry.toMap(), finder: finder);
    }
  }

  Future<void> updateUrlEntry(UrlEntry entry) async {
    final db = await database;
    final store = _urlStoreRef;
    final finder = Finder(filter: Filter.equals('url', entry.url));
    await store.update(db, entry.toMap(), finder: finder);
  }

  Future<void> addOrUpdateHighlight(Highlight highlight) async {
    final db = await database;
    await _highlightsStoreRef.add(
      db,
      highlight.toMap(),
    );
  }

  Future<List<UrlEntry>> getAllDeletedEntries() async {
    final db = await database;
    final store = _urlStoreRef;

    final finder = Finder(
      filter: Filter.and([
        Filter.equals('deleted', true),
      ]),
    );

    final snapshots = await store.find(db, finder: finder);
    return snapshots.map((snapshot) {
      final entry = UrlEntry.fromMap(snapshot.value);
      entry.id = snapshot.key;
      return entry;
    }).toList();
  }


  Future<List<UrlEntry>> getOldDeletedEntries() async {
    final db = await database;
    final store = _urlStoreRef;
    final threeMonthsAgo = DateTime.now().subtract(const Duration(days: 90));

    final finder = Finder(
      filter: Filter.and([
        Filter.lessThan('dateAdded', threeMonthsAgo.toIso8601String()),
        Filter.equals('deleted', true),
      ]),
    );

    final snapshots = await store.find(db, finder: finder);
    return snapshots.map((snapshot) {
      final entry = UrlEntry.fromMap(snapshot.value);
      entry.id = snapshot.key;
      return entry;
    }).toList();
  }

  Future<void> deleteEntries(List<UrlEntry> entries) async {
    final db = await database;
    final store = _urlStoreRef;

    for (var entry in entries) {
      await store.delete(
        db,
        finder: Finder(filter: Filter.equals('url', entry.url)),
      );
      debugPrint('Deleted entry: ${entry.url}');
    }
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

  Future<void> deleteHighlight(Highlight highlight) async {
    // Create a finder to locate the specific highlight
    final finder = Finder(
      filter: Filter.and([
        Filter.equals('url', highlight.url),
        Filter.equals('paragraphIndex', highlight.paragraphIndex),
        Filter.equals('startIndex', highlight.startIndex),
        Filter.equals('length', highlight.length),
      ])
    );

    // Delete the record from the database
    await _highlightsStoreRef.delete(
      await database,
      finder: finder,
    );
  }

  Future<List<Highlight>> getHighlightsForUrl(String url) async {
    final db = await database;
    final store = intMapStoreFactory.store(HIGHLIGHT_STORE_NAME);
    final finder = Finder(filter: Filter.equals('url', url));
    final snapshots = await store.find(db, finder: finder);
    return snapshots.map((snapshot) => Highlight.fromMap(snapshot.value)).toList();
  }

  Future<void> wipeDatabase() async {
    final db = await database;
    await _highlightsStoreRef.drop(db);
    await _urlStoreRef.drop(db);
  }

  Future<List<UrlEntry>> getAllUrlEntries({String? searchQuery}) async {
      final db = await database;
    final store = intMapStoreFactory.store(URL_STORE_NAME);
    Finder finder = Finder(
      sortOrders: [SortOrder('date', false)],
    );

    // Make case insensitive
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final filter =
        Filter.or([
          Filter.matchesRegExp('title', RegExp(searchQuery, caseSensitive: false)),
          Filter.matchesRegExp('url', RegExp(searchQuery, caseSensitive: false)),
          Filter.matchesRegExp('text', RegExp(searchQuery, caseSensitive: false)),
        ]);
      finder = Finder(
        filter: filter,
        sortOrders: [SortOrder('date', false)],
      );
    }
    final snapshots = await store.find(db, finder: finder);
    return snapshots.map((snapshot) {
      final entry = UrlEntry.fromMap(snapshot.value);
      entry.id = snapshot.key;
      return entry;
    }).toList();
  }

  Future<List<String>> getAllTags() async {
    final db = await database;
    final store = intMapStoreFactory.store(URL_STORE_NAME);

    final snapshots = await store.find(db);
    Set<String> tags = {};

    for (var snapshot in snapshots) {
      final entry = UrlEntry.fromMap(snapshot.value);
      tags.addAll(entry.tags);
    }

    return tags.toList()..sort();
  }

}