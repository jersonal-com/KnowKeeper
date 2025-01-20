import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:know_keeper/data_fetcher/email_newsletter_processor.dart';
import 'package:know_keeper/data_fetcher/rss_processor.dart';
import '../data_fetcher/processor.dart';
import '../data_fetcher/email_url_processor.dart';
import '../data/url_entry.dart';
import '../data/highlight.dart';
import 'database_providers.dart';

final processorsProvider = Provider<List<Processor>>((ref) {
  return [
    EmailUrlProcessor(),
    RssProcessor(),
    EmailNewsletterProcessor()
    // Add other processors here in the future
  ];
});

final urlSearchTermProvider = StateProvider<String>((ref) => '');

final urlEntriesProvider = FutureProvider<List<UrlEntry>>((ref) async {
  final databaseOps = ref.read(databaseProvider);
  final searchTerm = ref.watch(urlSearchTermProvider);
  return await databaseOps.database.getAllUrlEntries(searchQuery: searchTerm);
});

final urlEntryProvider = FutureProvider.family<UrlEntry?, String>((ref, url) async {
  final databaseOps = ref.read(databaseProvider);
  return await databaseOps.database.getUrlEntryByUrl(url);
});

final highlightsProvider = FutureProvider.family<List<Highlight>, String>((ref, url) async {
  final databaseOps = ref.read(databaseProvider);
  return await databaseOps.getHighlightsForUrl(url);
});