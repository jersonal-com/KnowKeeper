import 'package:flutter/material.dart';
import 'package:know_keeper/data/highlight.dart';
import '../data/highlight_mode.dart';
import '../data/url_entry.dart';
import 'html_content_widget.dart';
import 'email_content_widget.dart';

class ContentSwitcherWidget extends StatelessWidget {
  final UrlEntry entry;
  final List<Highlight> highlights;
  final HighlightMode currentHighlightMode;

  const ContentSwitcherWidget({
    super.key,
    required this.entry,
    required this.highlights,
    required this.currentHighlightMode,
  });

  @override
  Widget build(BuildContext context) {
    if (entry.isEmail) {
      return EmailContentWidget(
        content: entry.text,
        baseUrl: entry.description,
        entry: entry,
        highlights: highlights,
        highlightMode: currentHighlightMode,
      );
    } else {
      return HtmlContentWidget(
        content: entry.text,
        baseUrl: Uri.parse(entry.url).origin,
        entry: entry,
        highlights: highlights,
        highlightMode: currentHighlightMode,
      );
    }
  }
}