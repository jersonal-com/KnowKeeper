import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/highlight.dart';
import '../service/url_providers.dart';
import '../widgets/html_content_widget.dart';
import '../database/sembast_database.dart';

class DetailPage extends ConsumerWidget {
  final String url;

  const DetailPage({super.key, required this.url});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final urlEntryAsyncValue = ref.watch(urlEntryProvider(url));
    final highlightsAsyncValue = ref.watch(highlightsProvider(url));

    Future<void> onCreateHighlight(int paragraphIndex, int startIndex, int length) async {
      final highlight = Highlight(
        url: url,
        paragraphIndex: paragraphIndex,
        startIndex: startIndex,
        length: length,
      );
      await SembastDatabase.instance.addOrUpdateHighlight(highlight);
      // ignore: unused_result
      ref.refresh(highlightsProvider(url));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Article Details'),
      ),
      body: urlEntryAsyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
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
                      const SizedBox(height: 8),
                      Text(urlEntry.description, style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 16),
                      HtmlContentWidget(
                        htmlContent: urlEntry.text,
                        baseUrl: Uri.parse(urlEntry.url).origin,
                        highlights: highlightsAsyncValue.when(
                          loading: () => [],
                          error: (_, __) => [],
                          data: (highlights) => highlights,
                        ),
                        onCreateHighlight: onCreateHighlight,
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