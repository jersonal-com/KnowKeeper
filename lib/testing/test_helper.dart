import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:know_keeper/data/highlight.dart';
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
            .overrideWith((ref) => Future.value(['Technology', 'Science', 'Self-Improvement'])),
        selectedTagProvider.overrideWith((ref) => 'Technology'),
        tagColorsProvider.overrideWith((ref) => Future.value(
            {'Technology': Colors.blue, 'Science': Colors.green, 'Self-Improvement': Colors.red})),
        highlightsProvider.overrideWith((ref, id) => Future.value([])),

        ...extraOverrides,
      ],
    );

    for (final entry in _mockUrlEntries) {
      container.read(databaseProvider).addUrlEntry(entry);
    }
    container.read(databaseProvider).addUrlEntry(mockDetailEntry);

    // Adding Highlights
    for (final highlight in _mockHighlights) {
      container.read(databaseProvider).addOrUpdateHighlight(highlight);
    }

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
    title: 'KnowKeeper open source app' ,
    description: 'This is a new way to work with your knowledge.',
    tags:  ['Knowledge', 'Read it later'],
    source: '',
    date: DateTime.now(),
    imageUrl: '01.jpg',
    text: '<p>I used to be a heavy user of Omnivore and after they shut down their app I was looking for a replacement. I found some open source apps but they were either too complex or not very user friendly. I decided to write my own app and release it as open source.</p>  <p dir="auto">The key features I wanted from this app are:</p>  <ul dir="auto">  <li>Easy to use</li>  <li>No complicated cloud-based backend</li>  <li>Support for RSS feeds</li>  <li>Support for email newsletters in the same app</li>  <li>Support for Read It Later integration to store bookmarks</li>  <li>Highlighting important text</li>  <li>Export your highlights in Markdown format (to then be used e.g. in LogSeq)</li>  </ul>  <p dir="auto">Know keeper has been a quick hack to get something working and I hope you find it useful.</p>' '<p dir="auto">Know Keeper does not use any cloud storage, so all data is stored locally on your device. For exchanging data we use an email address. This email should only be used for know keeper as otherwise   your personal emails will be displayed between the news. Ideally get an email from a free email   provider like google or setup a separate email for know keeper.</p>   <p dir="auto">When you first open Know Keeper, you should enter the details of your email account in the   configuration screen. You can reach the configuration screen from the menu in the top left corner.</p>   <p dir="auto"><a target="_blank" rel="noopener noreferrer" href="/jersonal-com/KnowKeeper/blob/master/screen_shots/configuration_page.png"><img src="/jersonal-com/KnowKeeper/raw/master/screen_shots/configuration_page.png" width="200" style="max-width: 100%;"></a></p> <div class="markdown-heading" dir="auto"><h2 tabindex="-1" class="heading-element" dir="auto">Home Screen</h2><a id="user-content-home-screen" class="anchor" aria-label="Permalink: Home Screen" href="#home-screen"><svg class="octicon octicon-link" viewBox="0 0 16 16" version="1.1" width="16" height="16" aria-hidden="true"><path d="m7.775 3.275 1.25-1.25a3.5 3.5 0 1 1 4.95 4.95l-2.5 2.5a3.5 3.5 0 0 1-4.95 0 .751.751 0 0 1 .018-1.042.751.751 0 0 1 1.042-.018 1.998 1.998 0 0 0 2.83 0l2.5-2.5a2.002 2.002 0 0 0-2.83-2.83l-1.25 1.25a.751.751 0 0 1-1.042-.018.751.751 0 0 1-.018-1.042Zm-4.69 9.64a1.998 1.998 0 0 0 2.83 0l1.25-1.25a.751.751 0 0 1 1.042.018.751.751 0 0 1 .018 1.042l-1.25 1.25a3.5 3.5 0 1 1-4.95-4.95l2.5-2.5a3.5 3.5 0 0 1 4.95 0 .751.751 0 0 1-.018 1.042.751.751 0 0 1-1.042.018 1.998 1.998 0 0 0-2.83 0l-2.5 2.5a1.998 1.998 0 0 0 0 2.83Z"></path></svg></a></div>  <p dir="auto">The home screen displays your recent entries and provides quick access to all main features of the  app. When you open the app for the first time this screen will be empty as you have to add URLs,      RSS feeds or emails to your knowledge base.</p>',
  );
}

final _mockHighlights = [
  Highlight(url: "https://export.it",
      paragraphIndex: 0,
      startIndex: 20,
      length: 200,
      text: "Easily export your highlights to LogSeq."),
  Highlight(url: "https://export.it",
      paragraphIndex: 4,
      startIndex: 20,
      length: 200,
      text: "Just copy them to the clipboard and paste them into LogSeq."),
];

// Mock data
final _mockUrlEntries = [
  UrlEntry(
    url: 'https://rss.feed',
    title: 'Subscribe to RSS feeds and read them offline',
    description: 'This is an example website',
    tags: [
      'Technology',
    ],
    source: '',
    date: DateTime.now(),
    imageUrl: '01.jpg',
    text: '',
  ),
  UrlEntry(
    url: 'https://news.letter',
    title: 'Get Newsletters without cluttering your inbox',
    description: 'This is an example website',
    tags: ['Technology', 'Science'],
    source: '',
    date: DateTime.now(),
    imageUrl: '02.jpg',
    text: '',
  ),
  UrlEntry(
    url: 'https://readit.later',
    title: 'Store article to read them later',
    description: 'This is an example website',
    tags: [
      'Science',
    ],
    source: '',
    date: DateTime.now(),
    imageUrl: '03.jpg',
    text: '',
  ),
  UrlEntry(
    url: 'https://tag.it',
    title: 'Tag your content',
    description: 'This is an example website',
    tags: ['Technology', 'Self-Improvement'],
    source: '',
    date: DateTime.now(),
    imageUrl: '04.jpg',
    text: '',
  ),
  UrlEntry(
    url: 'https://export.it',
    title: 'Export your content to e.g. LogSeq',
    description: 'This is an example article',
    tags: [
      'Technology',
    ],
    source: '',
    date: DateTime.now(),
    imageUrl: '01.jpg',
    text: '',
  ),
  UrlEntry(
    url: 'https://open.source',
    title: 'It\'s open source and doesn\'t require a cloud backend.',
    description: 'This is an example website',
    tags: ['Self-Improvement', 'Science'],
    source: '',
    date: DateTime.now(),
    imageUrl: '02.jpg',
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
