import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/highlight.dart';
import '../service/database_providers.dart';
import '../service/url_providers.dart';
import '../widgets/html_content_widget.dart';

class DetailPage extends ConsumerWidget {
  final String url;

  DetailPage({required this.url});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final urlEntryAsyncValue = ref.watch(urlEntryProvider(url));
    final highlightsAsyncValue = ref.watch(highlightsProvider(url));
    final databaseOps = ref.read(databaseProvider);

    Future<void> onCreateHighlight(int paragraphIndex, int startIndex, int length) async {
      final highlight = Highlight(
        url: url,
        paragraphIndex: paragraphIndex,
        startIndex: startIndex,
        length: length,
      );
      await databaseOps.addOrUpdateHighlight(highlight);
      ref.invalidate(highlightsProvider(url));
    }

    Future<void> onDeleteHighlight(Highlight highlight) async {
      await databaseOps.deleteHighlight(highlight);
      ref.invalidate(highlightsProvider(url));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Article Details'),
      ),
      body: urlEntryAsyncValue.when(
        loading: () => Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (urlEntry) {
          if (urlEntry == null) {
            return Center(child: Text('Article not found for URL: $url'));
          }
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (urlEntry.imageUrl.isNotEmpty)
                  Image.network(urlEntry.imageUrl),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(urlEntry.title, style: Theme.of(context).textTheme.titleSmall),
                      SizedBox(height: 8),
                      Text(urlEntry.description, style: Theme.of(context).textTheme.headlineSmall),
                      SizedBox(height: 16),
                      highlightsAsyncValue.when(
                        loading: () => CircularProgressIndicator(),
                        error: (err, stack) => Text('Error loading highlights: $err'),
                        data: (highlights) => HtmlContentWidget(
                          htmlContent: urlEntry.text,
                          baseUrl: Uri.parse(urlEntry.url).origin,
                          highlights: highlights,
                          onCreateHighlight: (paragraphIndex, startIndex, length) async {
                            final highlight = Highlight(
                              url: urlEntry.url,
                              paragraphIndex: paragraphIndex,
                              startIndex: startIndex,
                              length: length,
                            );
                            await databaseOps.addOrUpdateHighlight(highlight);
                            ref.invalidate(highlightsProvider(urlEntry.url));
                          },
                          onDeleteHighlight: (highlight) async {
                            await databaseOps.deleteHighlight(highlight);
                            ref.invalidate(highlightsProvider(urlEntry.url));
                          },
                        )
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}