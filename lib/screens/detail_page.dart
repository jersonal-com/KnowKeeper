import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:know_keeper/widgets/content_widget.dart';
import '../data/highlight.dart';
import '../data/highlight_mode.dart';
import '../service/database_providers.dart';
import '../service/selection_provider.dart';
import '../service/url_providers.dart';
import '../widgets/html_content_widget.dart';

class DetailPage extends ConsumerStatefulWidget {
  final String url;

  const DetailPage({super.key, required this.url});

  @override
  DetailPageState createState() => DetailPageState();
}

class DetailPageState extends ConsumerState<DetailPage> {
  final _currentHighlightMode = HighlightMode.none;

  @override
  Widget build(BuildContext context) {
    final urlEntryAsyncValue = ref.watch(urlEntryProvider(widget.url));
    final highlightsAsyncValue = ref.watch(highlightsProvider(widget.url));
    final databaseOps = ref.read(databaseProvider);
    final currentSelection = ref.watch(currentSelectionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Article Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle),
            onPressed: () {
              if (currentSelection != null) {
                final highlight = Highlight(
                  url: widget.url,
                  paragraphIndex: currentSelection.paragraphIndex,
                  startIndex: currentSelection.startIndex,
                  length: currentSelection.length,
                  text: currentSelection.text,
                );
                databaseOps.addOrUpdateHighlight(highlight).then((_) {
                  ref.invalidate(highlightsProvider(widget.url));
                  ref.read(currentSelectionProvider.notifier).state = null;
                });
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle_outlined),
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
                      ref.invalidate(highlightsProvider(widget.url));
                      ref.read(currentSelectionProvider.notifier).state = null;
                    });
                  }
                });
              }
            },
          ),
        ],      ),
      body: urlEntryAsyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
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
                      const SizedBox(height: 8),
                      Text(urlEntry.description, style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 16),
                      highlightsAsyncValue.when(
                        loading: () => const CircularProgressIndicator(),
                        error: (err, stack) => Text('Error loading highlights: $err'),
                        data: (highlights) => ContentWidget(entry: urlEntry, highlights: highlights, currentHighlightMode: _currentHighlightMode),
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