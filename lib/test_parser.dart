// ignore_for_file: avoid_print

import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:know_keeper/parsing/content_processor.dart';

import 'parsing/paragraph.dart';

void main(List<String> args) async {
  if (args.length != 1) {
    print('Usage: dart run test_parser.dart <url>');
    return;
  }

  final url = args[0];
  final response = await http.get(Uri.parse(url));

  if (response.statusCode == 200) {
    final html = response.body;
    final document = html_parser.parse(html);
    final contentProcessor = ContentProcessor();
    final paragraphs = contentProcessor.process(document.body!.innerHtml);

    for (var paragraph in paragraphs) {
      print('Text: ${paragraph.text}');
      for (var feature in paragraph.features) {
        print('  Feature: ${feature.runtimeType}');
        print('    Start: ${feature.start}');
        print('    End: ${feature.end}');
        if (feature is LinkFeature) {
          print('    URL: ${feature.url}');
        }
        if (feature is ImageFeature) {
          print('    URL: ${feature.url}');
        }
      }
    }
  } else {
    print('Failed to load URL: ${response.statusCode}');
  }
}