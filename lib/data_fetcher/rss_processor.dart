import 'package:collection/collection.dart';
import 'package:http/http.dart' as http;
import 'package:know_keeper/data_fetcher/fetch_url_entry.dart';
import 'package:rss_dart/dart_rss.dart';
import 'package:rss_dart/util/helpers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'processor.dart';
import '../database/sembast_database.dart';
import '../data/url_entry.dart';

class RssProcessor extends Processor {
  final SembastDatabase database = SembastDatabase.instance;

  RssProcessor() : super();

  @override
  Future<void> process() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final rssFeeds = prefs.getStringList('rssFeeds') ?? [];

    for (final feedUrl in rssFeeds) {
      try {
        final response = await http.get(Uri.parse(feedUrl));
        if (response.statusCode == 200) {
          final channel = RssFeed.parse(response.body);
          for (final item in channel.items) {
            if (item.link != null) {
              UrlEntry urlEntry = await fetchUrlEntry(item.link!);
              urlEntry = urlEntry.copyWith(date: parseDateTime(item.pubDate) ?? DateTime.now());
              urlEntry = urlEntry.copyWith(source: feedUrl);
              final imageUrl = _getImageUrl(item);
              if (imageUrl.isNotEmpty) {
                urlEntry = urlEntry.copyWith(imageUrl: imageUrl);
              }
              await database.addUrlEntry(urlEntry);
            }
          }
        }
      } catch (e) {
        // ignore: avoid_print
        print('Error processing RSS feed $feedUrl: $e');
      }
    }
  }


  String _getImageUrl(RssItem item) {
    // Try to get image from enclosure
    final enclosure = item.enclosure;
    if (enclosure != null && enclosure.type?.startsWith('image/') == true) {
      return enclosure.url ?? '';
    }

    // Try to get image from media:content
    final mediaContent = item.media?.contents
        .firstWhereOrNull((content) => content.medium == 'image');
    if (mediaContent != null) {
      return mediaContent.url ?? '';
    }

    // If no image found, return empty string
    return '';
  }
}