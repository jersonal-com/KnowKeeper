import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:know_keeper/widgets/content_switcher_widget.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/highlight.dart';
import '../data/highlight_mode.dart';
import '../data/url_entry.dart';
import '../service/database_providers.dart';
import '../service/selection_provider.dart';
import '../service/url_providers.dart';
import '../widgets/tag_color_dot.dart';

class DetailPage extends ConsumerStatefulWidget {
  final UrlEntry entry;

  const DetailPage({super.key, required this.entry});

  @override
  DetailPageState createState() => DetailPageState();
}

class DetailPageState extends ConsumerState<DetailPage> {
  final _currentHighlightMode = HighlightMode.none;

  @override
  Widget build(BuildContext context) {
    final urlEntryAsyncValue = ref.watch(urlEntryProvider(widget.entry.url));
    final highlightsAsyncValue =
        ref.watch(highlightsProvider(widget.entry.url));
    final databaseOps = ref.read(databaseProvider);
    final currentSelection = ref.watch(currentSelectionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Article Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.label),
            onPressed: () => _showAddTagDialog(context, ref),
          ),
          if (!widget.entry.isEmail) ...[
            IconButton(
              icon: const Icon(Icons.open_in_browser),
              onPressed: () => _launchURL(widget.entry.url),
              tooltip: 'Open in browser',
            ),
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () => _shareURL(widget.entry.url),
              tooltip: 'Share URL',
            ),
          ],
          IconButton(
            icon: const Icon(Icons.archive),
            onPressed: () => _archiveEntry(ref),
            tooltip: 'Archive',
          ),
          IconButton(
            icon: const Icon(Icons.add_circle),
            onPressed: () {
              if (currentSelection != null) {
                final highlight = Highlight(
                  url: widget.entry.url,
                  paragraphIndex: currentSelection.paragraphIndex,
                  startIndex: currentSelection.startIndex,
                  length: currentSelection.length,
                  text: currentSelection.text,
                );
                databaseOps.addOrUpdateHighlight(highlight).then((_) {
                  ref.invalidate(highlightsProvider(widget.entry.url));
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
                    (h) =>
                        h.paragraphIndex == currentSelection.paragraphIndex &&
                        h.startIndex <
                            currentSelection.startIndex +
                                currentSelection.length &&
                        h.startIndex + h.length > currentSelection.startIndex,
                  );
                  if (overlappingHighlight != null) {
                    databaseOps.deleteHighlight(overlappingHighlight).then((_) {
                      ref.invalidate(highlightsProvider(widget.entry.url));
                      ref.read(currentSelectionProvider.notifier).state = null;
                    });
                  }
                });
              }
            },
          ),
        ],
      ),
      body: urlEntryAsyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (urlEntry) {
          if (urlEntry == null) {
            return Center(
                child: Text('Article not found for URL: ${widget.entry.url}'));
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
                      (urlEntry.description.isNotEmpty)
                          ? Text(urlEntry.description,
                              style: Theme.of(context).textTheme.titleSmall)
                          : Text(Uri.parse(urlEntry.url).origin,
                              style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 8),
                      Text(urlEntry.title,
                          style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 16),
                      const SizedBox(height: 16),
                      _buildTagsRow(urlEntry),
                      const SizedBox(height: 16),
                      highlightsAsyncValue.when(
                        loading: () => const CircularProgressIndicator(),
                        error: (err, stack) =>
                            Text('Error loading highlights: $err'),
                        data: (highlights) => ContentSwitcherWidget(
                            entry: urlEntry,
                            highlights: highlights,
                            currentHighlightMode: _currentHighlightMode),
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

  Widget _buildTagsRow(UrlEntry urlEntry) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        ...urlEntry.tags.map((tag) => Chip(
              avatar: TagColorDot(tag: tag),
              label: Text(tag),
              onDeleted: () => _removeTag(tag),
              deleteIcon: const Icon(Icons.close, size: 18),
            )),
        ActionChip(
          label: const Text('Add Tag'),
          onPressed: () => _showAddTagDialog(context, ref),
          avatar: const Icon(Icons.add, size: 18),
        ),
      ],
    );
  }

  void _removeTag(String tagToRemove) async {
    final updatedEntry = widget.entry.copyWith(
      tags: widget.entry.tags.where((tag) => tag != tagToRemove).toList(),
    );
    await ref.read(databaseProvider).updateUrlEntry(updatedEntry);
    ref.invalidate(urlEntriesProvider);
    ref.invalidate(allTagsProvider);
    ref.invalidate(urlEntryProvider);
    setState(() {}); // Refresh the UI
  }

  void _showAddTagDialog(BuildContext context, WidgetRef ref) {
    final textController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Add Tag'),
          content: Consumer(
            builder: (context, ref, child) {
              final tagsAsyncValue = ref.watch(allTagsProvider);
              return tagsAsyncValue.when(
                data: (allTags) {
                  final availableTags = allTags
                      .where((tag) => !widget.entry.tags.contains(tag))
                      .toList();
                  return SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (availableTags.isNotEmpty) ...[
                          const Text('Select an existing tag:'),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: availableTags
                                .map((tag) => FilterChip(
                                      label: Text(tag),
                                      onSelected: (selected) {
                                        _addTag(ref, tag);
                                        Navigator.of(dialogContext).pop();
                                      },
                                    ))
                                .toList(),
                          ),
                          const Divider(),
                          const Text('Or enter a new tag:'),
                        ],
                        TextField(
                          controller: textController,
                          decoration:
                              const InputDecoration(hintText: "Enter new tag"),
                        ),
                      ],
                    ),
                  );
                },
                loading: () => const CircularProgressIndicator(),
                error: (error, stack) => Text('Error: $error'),
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: const Text('Add New Tag'),
              onPressed: () {
                final newTag = textController.text.trim();
                if (newTag.isNotEmpty) {
                  _addTag(ref, newTag);
                  Navigator.of(dialogContext).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _addTag(WidgetRef ref, String newTag) async {
    final updatedEntry = widget.entry.copyWith(
      tags: [...widget.entry.tags, newTag],
    );
    await ref.read(databaseProvider).updateUrlEntry(updatedEntry);
    ref.invalidate(urlEntriesProvider);
    ref.invalidate(allTagsProvider);
    ref.invalidate(urlEntryProvider);
    setState(() {});
  }

  void _launchURL(String url) async {
    try {
      await launchUrl(Uri.parse(url));
    } catch (e) {
      debugPrint('Could not launch $url: $e');
    }
  }

  void _shareURL(String url) {
    Share.share('Check out this link: $url');
  }

  void _archiveEntry(WidgetRef ref) async {
    final updatedEntry = widget.entry.copyWith(archived: true);
    Navigator.of(context).pop(); // Return to the main page
    await ref.read(databaseProvider).updateUrlEntry(updatedEntry);
  }
}
