// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart' show parse;
import 'package:know_keeper/widgets/content_widget.dart';
import 'package:know_keeper/widgets/filter_html_content_web.dart';

import '../data/highlight.dart';
import '../data/highlight_mode.dart';
import '../data/url_entry.dart';

class HtmlContentWidget extends ContentWidget {

  const HtmlContentWidget({
    Key? key,
    required String content,
    required String baseUrl,
    required UrlEntry entry,
    List<Highlight> highlights = const [],
    HighlightMode highlightMode = HighlightMode.none,
  }) : super(
    key: key,
    content: content,
    baseUrl: baseUrl,
    entry: entry,
    highlights: highlights,
    highlightMode: highlightMode,
  );

  @override
  HtmlContentWidgetState createState() => HtmlContentWidgetState();
}

class HtmlContentWidgetState extends ContentWidgetState {

  @override
  Widget build(BuildContext context) {
    final document = filterHtmlContent( parse(widget.content) );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...processNode(context, ref, document.body!.nodes),
      ],
    );
  }

  @override
  String resolveUrl(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url; // Already an absolute URL
    } else {
      return Uri.parse(widget.baseUrl).resolve(url).toString();
    }
  }

}