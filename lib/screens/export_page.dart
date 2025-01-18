import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../service/database_providers.dart';

class ExportPage extends ConsumerWidget {
  const ExportPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Export Highlights'),
        actions: [
          FutureBuilder<String>(
            future: _generateMarkdown(ref),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: snapshot.data!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copied to clipboard')),
                    );
                  },
                );
              } else {
                return const SizedBox.shrink();
              }
            },
          ),
        ],
      ),
      body: FutureBuilder<String>(
        future: _generateMarkdown(ref),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SelectableText(
                  snapshot.data ?? '',
                  style:  TextStyle(fontFamily: 'Courier',
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                ),
              ),
            );
          }
        },
      ),
    );
  }

  Future<String> _generateMarkdown(WidgetRef ref) async {
    final database = ref.read(databaseProvider);
    final entries = await database.getNonArchivedUrlEntries();

    final markdown = StringBuffer();

    for (final entry in entries) {
        final entryHighlights = await database.getHighlightsForUrl(entry.url);
        if (entryHighlights.isNotEmpty) {
          markdown.writeln('- ${entry.title}');
          markdown.writeln('   site:: ${Uri.parse(entry.url).host}');
          markdown.writeln('   url:: ${entry.url}');
          markdown.writeln('   date:: ${DateFormat('yyyy-MM-dd').format(entry.date)}');
          markdown.writeln('   - Highlights');
          for (final highlight in entryHighlights) {
            markdown.writeln('      - ${highlight.text}');
          }
          markdown.writeln();
        }
    }
    return markdown.toString();
  }
}