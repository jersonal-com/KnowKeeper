import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data_fetcher/processor.dart';
import '../data_fetcher/email_url_processor.dart';
import '../database/sembast_database.dart';
import '../data/url_entry.dart';
import '../data/highlight.dart';

final processorsProvider = Provider<List<Processor>>((ref) {
  return [
    EmailUrlProcessor(),
    // Add other processors here in the future
  ];
});

final urlEntriesProvider = FutureProvider<List<UrlEntry>>((ref) async {
  return await SembastDatabase.instance.getNonArchivedUrlEntries();
});

final urlEntryProvider = FutureProvider.family<UrlEntry?, String>((ref, url) async {
  return await SembastDatabase.instance.getUrlEntryByUrl(url);
});

final highlightsProvider = FutureProvider.family<List<Highlight>, String>((ref, url) async {
  return await SembastDatabase.instance.getHighlightsForUrl(url);
});