import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;

import '../data/url_entry.dart';

Future<UrlEntry> fetchUrlEntry(String url) async {
  try {
    print("Parsing webpage: $url");

    // Fetch the webpage
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      // Parse the HTML content
      final document = parse(response.body);

      // Extract title
      final title = document.querySelector('title')?.text?.trim() ?? '';

      // Extract description (assuming it's in a meta tag)
      final description = document.querySelector('meta[name="description"]')?.attributes['content'] ?? '';

      // Extract the first image URL (if any)
      final imageUrl = document.querySelector('img[src\$=".png"], img[src\$=".jpg"]')?.attributes['src'] != null
          ? Uri.parse(url).resolve(document.querySelector('img[src\$=".png"], img[src\$=".jpg"]')!.attributes['src']!).toString()
          : '';
      print("Image URL: $imageUrl");

      // Extract text content (this is a simple implementation and might need refinement)
      final textContent = document.body?.innerHtml ?? '';

      // Create and return the UrlEntry
      return UrlEntry(
        title: title,
        source: url,
        date: DateTime.now(),
        imageUrl: imageUrl,
        text: description.isNotEmpty ? description : textContent.substring(0, textContent.length > 500 ? 500 : textContent.length),
      );
    } else {
      throw Exception('Failed to load webpage: Status ${response.statusCode}');
    }
  } catch (e) {
    print('Error fetching URL entry: $e');
    // Return a default UrlEntry in case of error
    return UrlEntry(
      title: 'Error fetching page',
      source: url,
      date: DateTime.now(),
      imageUrl: '',
      text: 'Failed to fetch content: $e',
    );
  }
}