import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:know_keeper/data/highlight.dart';
import 'package:know_keeper/data/url_entry.dart';
import 'package:know_keeper/database/sembast_database.dart';
import 'package:know_keeper/service/url_providers.dart';
import 'package:know_keeper/service/database_providers.dart';
import 'package:know_keeper/service/favicon_provider.dart';
import 'package:know_keeper/theme/app_theme.dart';

class TestHelper {
  static Widget wrapWithProviders(Widget child, {List<Override> extraOverrides = const [], themeMode = ThemeMode.light}) {
    final navigatorKey = GlobalKey<NavigatorState>();
    return ProviderScope(
      overrides: [
        // Override url providers
        urlEntriesProvider.overrideWith((ref) => Future.value(_mockUrlEntries)),
        urlEntryProvider.overrideWith((ref, url) => Future.value(_mockUrlEntries.firstWhere((entry) => entry.url == url))),
        allTagsProvider.overrideWith((ref) => Future.value(['Tag1', 'Tag2', 'Tag3'])),
        selectedTagProvider.overrideWith((ref) => 'Tag1'),
        tagColorsProvider.overrideWith((ref) => Future.value({'Tag1': Colors.blue, 'Tag2': Colors.green, 'Tag3': Colors.red})),

        // Override database provider
        databaseProvider.overrideWith((ref) => MockDatabaseOperations()),

        // Override favicon provider
        // faviconProvider.overrideWith((ref, domain) => Future.value('https://heise/favicon.ico')),

        // Add any extra overrides
        ...extraOverrides,
      ],
      child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          home: child
      ),
    );
  }

  static UrlEntry mockDetailEntry = UrlEntry(
    url: 'https://heise.de',
    title: 'Example Website',
    description: 'This is an example website',
    tags: ['Tag1', 'Tag2'],
    source: '', date: DateTime.now(),
    imageUrl: '',
    text: '',
  );

}


// Mock data
final _mockUrlEntries = [
  UrlEntry(
    url: 'https://heise.de',
    title: 'Example Website',
    description: 'This is an example website',
    tags: ['Tag1', ],
    source: '', date: DateTime.now(),
    imageUrl: '',
    text: '',
  ),
  UrlEntry(
    url: 'https://heise.de',
    title: 'Example Website',
    description: 'This is an example website',
    tags: ['Tag1', 'Tag2'],
    source: '', date: DateTime.now(),
    imageUrl: '',
    text: '',
  ),
];

// Mock database operations
class MockDatabaseOperations implements DatabaseOperations {
  @override
  Future<List<UrlEntry>> getAllUrlEntries({String? searchQuery}) async {
    return _mockUrlEntries;
  }

  @override
  Future<void> addOrUpdateHighlight(Highlight highlight) {
    // TODO: implement addOrUpdateHighlight
    throw UnimplementedError();
  }

  @override
  Future<void> addUrlEntry(UrlEntry entry) {
    // TODO: implement addUrlEntry
    throw UnimplementedError();
  }

  @override
  // TODO: implement database
  SembastDatabase get database => throw UnimplementedError();

  @override
  Future<void> deleteHighlight(Highlight highlight) {
    // TODO: implement deleteHighlight
    throw UnimplementedError();
  }

  @override
  Future<void> deleteTag(String tag) {
    // TODO: implement deleteTag
    throw UnimplementedError();
  }

  @override
  Future<Map<String, Color>> getAllTagColors() {
    // TODO: implement getAllTagColors
    throw UnimplementedError();
  }

  @override
  Future<List<String>> getAllTags() {
    // TODO: implement getAllTags
    throw UnimplementedError();
  }

  @override
  Future<List<Highlight>> getHighlightsForUrl(String url) {
    // TODO: implement getHighlightsForUrl
    throw UnimplementedError();
  }

  @override
  Future<List<UrlEntry>> getNonArchivedUrlEntries() {
    // TODO: implement getNonArchivedUrlEntries
    throw UnimplementedError();
  }

  @override
  Future<void> renameTag(String oldTag, String newTag) {
    // TODO: implement renameTag
    throw UnimplementedError();
  }

  @override
  Future<void> setTagColor(String tag, int colorValue) {
    // TODO: implement setTagColor
    throw UnimplementedError();
  }

  @override
  Future<void> updateUrlEntry(UrlEntry entry) {
    // TODO: implement updateUrlEntry
    throw UnimplementedError();
  }

  @override
  Future<void> wipe() {
    // TODO: implement wipe
    throw UnimplementedError();
  }

  // Implement other methods as needed...
}