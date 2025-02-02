// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart' show parse;
import 'package:know_keeper/widgets/content_widget.dart';
import 'package:know_keeper/widgets/filter_html_content_web.dart';

class HtmlContentWidget extends ContentWidget {

  const HtmlContentWidget({
    super.key,
    required super.content,
    required super.baseUrl,
    required super.entry,
    super.highlights,
    super.highlightMode,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final document = filterHtmlContent( parse(content) );

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
      return Uri.parse(baseUrl).resolve(url).toString();
    }
  }

}