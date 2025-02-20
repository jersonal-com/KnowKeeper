import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;

import '../data/url_entry.dart';
import 'dart:convert';

Future<UrlEntry> fetchUrlEntry(String url) async {
  try {

    // Fetch the webpage
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {

      // Fix encoding
      Encoding encoding = utf8;
      final contentType = response.headers['content-type'];
      if (contentType != null) {
        final charsetMatch = RegExp(r'charset=([\w-]+)').firstMatch(contentType);
        if (charsetMatch != null) {
          encoding = Encoding.getByName(charsetMatch.group(1)!) ?? utf8;
        }
      }
      final decodedBody = encoding.decode(response.bodyBytes);

      // Parse the HTML content
      final document = parse(decodedBody);

      // Extract title
      final title = document.querySelector('title')?.text.trim() ?? '';

      // Extract description (assuming it's in a meta tag)
      final description = document.querySelector('meta[name="description"]')?.attributes['content'] ?? '';

      // Extract the first image URL (if any)
      final imageUrl = document.querySelector('img[src\$=".png"], img[src\$=".jpg"]')?.attributes['src'] != null
          ? Uri.parse(url).resolve(document.querySelector('img[src\$=".png"], img[src\$=".jpg"]')!.attributes['src']!).toString()
          : '';

      // Extract text content (this is a simple implementation and might need refinement)
      final textContent = document.body?.innerHtml ?? '';

      // Create and return the UrlEntry
      return UrlEntry(
        title: title,
        description: description,
        source: url,
        url: url,
        date: DateTime.now(),
        imageUrl: imageUrl,
        text: textContent,
      );
    } else {
      throw Exception('Failed to load webpage: Status ${response.statusCode}');
    }
  } catch (e) {
    // Return a default UrlEntry in case of error
    return UrlEntry(
      title: 'Error fetching page',
      description: '',
      source: url,
      url: url,
      date: DateTime.now(),
      imageUrl: '',
      text: 'Failed to fetch content: $e',
    );
  }
}