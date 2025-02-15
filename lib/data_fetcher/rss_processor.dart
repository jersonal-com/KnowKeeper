import 'dart:isolate';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../data_fetcher/fetch_url_entry.dart';
import 'package:rss_dart/dart_rss.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../service/url_providers.dart';
import 'processor.dart';
import '../database/sembast_database.dart';

class RssProcessor extends Processor {
  final SembastDatabase database = SembastDatabase.instance;

  RssProcessor(super.ref);

  @override
  Future<void> process() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final rssFeeds = prefs.getStringList('rssFeeds') ?? [];

    // Get all existing entries
    final existingEntries = await ref.read(urlEntriesProvider.future);
    final existingUrls = existingEntries.map((entry) => entry.url).toSet();

    final receivePort = ReceivePort();
    final isolate = await Isolate.spawn(
      processRssFeedInIsolate,
      IsolateMessage(receivePort.sendPort, rssFeeds, existingUrls),
    );

    // ignore: unused_local_variable
    SendPort? sendPort;

    await for (final message in receivePort) {
      if (message is SendPort) {
        sendPort = message;
      } else if (message is List<Map<String, dynamic>>) {
        for (final entryData in message) {
          final urlEntry = await fetchUrlEntry(entryData['url']);
          final parsedDate = parseDateTime(entryData['date']) ?? DateTime.now();
          final updatedEntry = urlEntry.copyWith(
            date: parsedDate,
            source: entryData['source'],
            imageUrl: entryData['imageUrl'],
          );
          await database.addUrlEntry(updatedEntry);
        }
      } else if (message == 'finished') {
        break;
      }
    }

    receivePort.close();
    isolate.kill();
  }
}

class IsolateMessage {
  final SendPort sendPort;
  final List<String> rssFeeds;
  final Set<String> existingUrls;

  IsolateMessage(this.sendPort, this.rssFeeds, this.existingUrls);
}

DateTime? parseDateTime(String? dateString) {
  if (dateString == null || dateString.isEmpty) {
    return null;
  }

  // Try parsing with DateTime.parse first
  try {
    return DateTime.parse(dateString);
  } catch (_) {
    // If that fails, try other formats
  }

  // List of date formats to try
  final formats = [
    "EEE, dd MMM yyyy HH:mm:ss zzz", // RFC 822
    "yyyy-MM-dd'T'HH:mm:ss'Z'",      // ISO 8601
    "yyyy-MM-dd HH:mm:ss",
    "yyyy-MM-dd",
  ];

  for (var format in formats) {
    try {
      return DateFormat(format).parse(dateString);
    } catch (_) {
      // If this format doesn't work, try the next one
    }
  }

  return DateTime.now();
}

Future<void> processRssFeedInIsolate(IsolateMessage message) async {
  final receivePort = ReceivePort();
  message.sendPort.send(receivePort.sendPort);

  for (final feedUrl in message.rssFeeds) {
    final entries = await _fetchRssFeed(feedUrl, message.existingUrls);
    message.sendPort.send(entries);
  }

  message.sendPort.send('finished');
  receivePort.close();
}

Future<List<Map<String, dynamic>>> _fetchRssFeed(String feedUrl, Set<String> existingUrls) async {
  List<Map<String, dynamic>> entries = [];

  try {
    final response = await http.get(Uri.parse(feedUrl));
    if (response.statusCode == 200) {
      final channel = RssFeed.parse(response.body);
      for (final item in channel.items) {
        if (item.link != null && !existingUrls.contains(item.link)) {
          final entry = {
            'url': item.link!,
            'title': item.title ?? '',
            'description': item.description ?? '',
            'date': item.pubDate ?? DateTime.now().toIso8601String(),
            'source': feedUrl,
            'imageUrl': _getImageUrl(item),
          };
          entries.add(entry);
        }
      }
    }
  } catch (e) {
    debugPrint('Error processing RSS feed $feedUrl: $e');
  }

  return entries;
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
