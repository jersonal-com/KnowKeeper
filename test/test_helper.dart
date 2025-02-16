import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:know_keeper/data/url_entry.dart';
import 'package:know_keeper/database/sembast_database.dart';
import 'package:know_keeper/service/url_providers.dart';
import 'package:know_keeper/service/database_providers.dart';
import 'package:know_keeper/testing/test_configuration.dart';
import 'package:know_keeper/theme/app_theme.dart';

class TestHelper {
  static Widget wrapWithProviders(Widget child,
      {List<Override> extraOverrides = const [], themeMode = ThemeMode.light}) {
    // ignore: unused_local_variable
    final navigatorKey = GlobalKey<NavigatorState>();
    TestConfiguration.setTestMode(true);

    final container = ProviderContainer(
      overrides: [
        // Override url providers
        urlEntriesProvider.overrideWith((ref) => Future.value(_mockUrlEntries)),
        urlEntryProvider
            .overrideWith((ref, url) => Future.value(mockDetailEntry)),
        allTagsProvider
            .overrideWith((ref) => Future.value(['Tag1', 'Tag2', 'Tag3'])),
        selectedTagProvider.overrideWith((ref) => 'Tag1'),
        tagColorsProvider.overrideWith((ref) => Future.value(
            {'Tag1': Colors.blue, 'Tag2': Colors.green, 'Tag3': Colors.red})),
        highlightsProvider.overrideWith((ref, id) => Future.value([])),

        ...extraOverrides,
      ],
    );

    for (final entry in _mockUrlEntries) {
      container.read(databaseProvider).addUrlEntry(entry);
    }
    container.read(databaseProvider).addUrlEntry(mockDetailEntry);

    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          home: child),
    );
  }

  static UrlEntry mockDetailEntry = UrlEntry(
    url: 'https://example.com',
    title: 'Example Website',
    description: 'This is an example website',
    tags:  ['Knowledge', 'Read it later'],
    source: '',
    date: DateTime.now(),
    imageUrl: '01.jpg',
    text: '<p>Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet.</p><p><img src="04.jpg" /></p>',
  );
}

// Mock data
final _mockUrlEntries = [
  UrlEntry(
    url: 'https://example.com',
    title: 'Example Website',
    description: 'This is an example website',
    tags: [
      'Tag1',
    ],
    source: '',
    date: DateTime.now(),
    imageUrl: '02.jpg',
    text: '',
  ),
  UrlEntry(
    url: 'https://heise.de',
    title: 'Example Website',
    description: 'This is an example website',
    tags: ['Tag1', 'Tag2'],
    source: '',
    date: DateTime.now(),
    imageUrl: '04.jpg',
    text: '',
  ),
];

// Mock database operations
mixin MockDatabaseOperations implements SembastDatabase {
  @override
  Future<List<UrlEntry>> getAllUrlEntries({String? searchQuery}) async {
    return _mockUrlEntries;
  }
}
