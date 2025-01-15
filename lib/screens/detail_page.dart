import 'package:flutter/material.dart';
import 'package:know_keeper/data/highlight.dart';
import '../data/url_entry.dart';
import '../widgets/html_content_widget.dart';

class DetailPage extends StatefulWidget {
  final UrlEntry entry;
  final String baseUrl;

  const DetailPage({
  Key? key,
  required this.entry,
  required this.baseUrl,
  }) : super(key: key);

  @override
  _DetailPageState createState() => _DetailPageState();
  }

  class _DetailPageState extends State<DetailPage> {
  List<Highlight> highlights = [];

  void _createHighlight(int paragraphIndex, int startIndex, int length) {
  setState(() {
  highlights.add(Highlight(
  url: widget.baseUrl,
  paragraphIndex: paragraphIndex,
  startIndex: startIndex,
  length: length,
  ));
  });
  // Here you would typically save the highlight to your database or state management solution
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.entry.title),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.entry.imageUrl != null && widget.entry.imageUrl!.isNotEmpty)
              Image.network(
                widget.entry.imageUrl!,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.entry.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Source: ${widget.entry.source}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Date: ${widget.entry.date.toString()}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 16),
                  HtmlContentWidget(
                    htmlContent: widget.entry.text,
                    baseUrl: widget.entry.source,
                    onCreateHighlight: _createHighlight,
                    highlights: [
                      Highlight(url: widget.entry.source, paragraphIndex: 2, startIndex: 0, length: 15)
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String stripHtmlIfNeeded(String text) {
  return text.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ' ');
}