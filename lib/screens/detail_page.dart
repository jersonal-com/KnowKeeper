import 'package:flutter/material.dart';
import '../data/url_entry.dart';
import '../widgets/html_content_widget.dart';

class DetailPage extends StatelessWidget {
  final UrlEntry entry;

  const DetailPage({Key? key, required this.entry}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(entry.title),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (entry.imageUrl != null && entry.imageUrl!.isNotEmpty)
              Image.network(
                entry.imageUrl!,
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
                    entry.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Source: ${entry.source}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Date: ${entry.date.toString()}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  SizedBox(height: 16),
                  HtmlContentWidget(
                    htmlContent: entry.text,
                    baseUrl: entry.source,
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