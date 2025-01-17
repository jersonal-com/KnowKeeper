import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/highlight.dart';
import '../data/highlight_mode.dart';
import '../service/database_providers.dart';
import '../service/selection_provider.dart';
import '../service/url_providers.dart';
import '../widgets/html_content_widget.dart';

class DetailPage extends ConsumerStatefulWidget {
  final String url;

  DetailPage({required this.url});

  @override
  _DetailPageState createState() => _DetailPageState();
}

class _DetailPageState extends ConsumerState<DetailPage> {
  HighlightMode _currentHighlightMode = HighlightMode.none;

  @override
  Widget build(BuildContext context) {
    final urlEntryAsyncValue = ref.watch(urlEntryProvider(widget.url));
    final highlightsAsyncValue = ref.watch(highlightsProvider(widget.url));
    final databaseOps = ref.read(databaseProvider);
    final currentSelection = ref.watch(currentSelectionProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Article Details'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              if (currentSelection != null) {
                final highlight = Highlight(
                  url: widget.url,
                  paragraphIndex: currentSelection.paragraphIndex,
                  startIndex: currentSelection.startIndex,
                  length: currentSelection.length,
                );
                databaseOps.addOrUpdateHighlight(highlight).then((_) {
                  ref.refresh(highlightsProvider(widget.url));
                  ref.read(currentSelectionProvider.notifier).state = null;
                });
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.remove),
            onPressed: () {
              if (currentSelection != null) {
                highlightsAsyncValue.whenData((highlights) {
                  final overlappingHighlight = highlights.firstWhereOrNull(
                        (h) => h.paragraphIndex == currentSelection.paragraphIndex &&
                        h.startIndex < currentSelection.startIndex + currentSelection.length &&
                        h.startIndex + h.length > currentSelection.startIndex,
                  );
                  if (overlappingHighlight != null) {
                    databaseOps.deleteHighlight(overlappingHighlight).then((_) {
                      ref.refresh(highlightsProvider(widget.url));
                      ref.read(currentSelectionProvider.notifier).state = null;
                    });
                  }
                });
              }
            },
          ),
        ],      ),
      body: urlEntryAsyncValue.when(
        loading: () => Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (urlEntry) {
          if (urlEntry == null) {
            return Center(child: Text('Article not found for URL: ${widget.url}'));
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
                          highlightMode: _currentHighlightMode,
                        ),
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