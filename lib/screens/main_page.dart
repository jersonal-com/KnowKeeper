import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../data/url_entry.dart';
import '../service/database_providers.dart';
import '../service/url_providers.dart';
import 'detail_page.dart';
import 'config_page.dart';
import 'export_page.dart';  // Add this import

class MainPage extends ConsumerStatefulWidget {
  const MainPage({super.key});

  @override
  MainPageState createState() => MainPageState();
}

class MainPageState extends ConsumerState<MainPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  Future<void> _refreshData() async {
    // await ref.read(databaseProvider).wipe();
    final processors = ref.read(processorsProvider);
    for (final processor in processors) {
      await processor.process();
    }
    ref.invalidate(urlEntriesProvider);
  }

  @override
  Widget build(BuildContext context) {
    final urlEntriesAsyncValue = ref.watch(urlEntriesProvider);
    final screenSize = MediaQuery.of(context).size;
    final imageWidth = (screenSize.width < screenSize.height ? screenSize.width : screenSize.height) * 0.2;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Know Keeper'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'config') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ConfigPage()),
                );
              } else if (value == 'export') {  // Add this condition
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ExportPage()),
                );
              }
            },
            itemBuilder: (BuildContext context) {
              return {'Config', 'Export'}.map((String choice) {  // Add 'Export' to the list
                return PopupMenuItem<String>(
                  value: choice.toLowerCase(),
                  child: Text(choice),
                );
              }).toList();
            },
          ),
        ],      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _refreshData();
          ref.invalidate(urlEntriesProvider);
        },
        child: urlEntriesAsyncValue.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
          data: (urlEntries) {
            return ListView.builder(
              itemCount: urlEntries.length,
              itemBuilder: (context, index) {
                final entry = urlEntries[index];
                return Slidable(
                  key: ValueKey(entry.url),
                  endActionPane: ActionPane(
                    motion: const ScrollMotion(),
                    children: [
                      SlidableAction(
                        onPressed: (context) => _archiveEntry(ref, entry),
                        backgroundColor: Theme.of(context).colorScheme.secondary,
                        foregroundColor: Theme.of(context).colorScheme.onSecondary,
                        icon: Icons.archive,
                        label: 'Archive',
                      ),
                      SlidableAction(
                        onPressed: (context) => _deleteEntry(ref, entry),
                        backgroundColor: Theme.of(context).colorScheme.error,
                        foregroundColor: Theme.of(context).colorScheme.onError,
                        icon: Icons.delete,
                        label: 'Delete',
                      ),
                    ],
                  ),
                  child: ListTile(
                    leading: entry.imageUrl.isNotEmpty
                        ? SizedBox(
                      width: imageWidth,
                      height: imageWidth,
                      child: Image.network(
                        entry.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(Icons.error, size: imageWidth);
                        },
                      ),
                    )
                        : SizedBox(
                      width: imageWidth,
                      height: imageWidth,
                      child: Icon(Icons.article, size: imageWidth * 0.6),
                    ),
                    title: Text(entry.title),
                    subtitle: Text(entry.description),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetailPage(url: entry.url),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _archiveEntry(WidgetRef ref, UrlEntry entry) async {
    final updatedEntry = entry.copyWith(archived: true);
    await ref.read(databaseProvider).updateUrlEntry(updatedEntry);
    ref.invalidate(urlEntriesProvider);
  }

  void _deleteEntry(WidgetRef ref, UrlEntry entry) async {
    final updatedEntry = entry.copyWith(archived: true, deleted: true);
    await ref.read(databaseProvider).updateUrlEntry(updatedEntry);
    ref.invalidate(urlEntriesProvider);
  }

}