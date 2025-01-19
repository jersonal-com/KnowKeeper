import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:know_keeper/data_fetcher/fetch_url_entry.dart';
import '../data/url_entry.dart';
import '../service/database_providers.dart';
import '../service/url_providers.dart';
import 'detail_page.dart';
import 'config_page.dart';
import 'export_page.dart'; // Add this import

enum EntryFilter { all, archived, deleted, active }

class MainPage extends ConsumerStatefulWidget {
  const MainPage({super.key});

  @override
  MainPageState createState() => MainPageState();
}

class MainPageState extends ConsumerState<MainPage> {
  EntryFilter _currentFilter = EntryFilter.active;

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
    final imageWidth = (screenSize.width < screenSize.height
            ? screenSize.width
            : screenSize.height) *
        0.2;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Know Keeper'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: RefreshIndicator(
        onRefresh: () async {
          await _refreshData();
          ref.invalidate(urlEntriesProvider);
        },
        child: urlEntriesAsyncValue.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
          data: (urlEntries) {
            final filteredEntries = urlEntries.where((entry) {
              switch (_currentFilter) {
                case EntryFilter.all:
                  return !entry.deleted;
                case EntryFilter.archived:
                  return entry.archived && !entry.deleted;
                case EntryFilter.deleted:
                  return entry.deleted;
                case EntryFilter.active:
                  return !entry.archived && !entry.deleted;
              }
            }).toList();

            return ListView.builder(
              itemCount: filteredEntries.length,
              itemBuilder: (context, index) {
                final entry = filteredEntries[index];
                return _buildEntryTile(entry, context, imageWidth);
              },
            );
          },
        ),
      ),
/*
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddUrlDialog,
        tooltip: 'Add URL',
        child: const Icon(Icons.add),
      ),
*/
    );
  }

  Slidable _buildEntryTile(
      UrlEntry entry, BuildContext context, double imageWidth) {
    return Slidable(
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          if (!entry.deleted && !entry.archived)
            SlidableAction(
              onPressed: (context) => _archiveEntry(ref, entry),
              backgroundColor: Theme.of(context).colorScheme.secondary,
              foregroundColor: Theme.of(context).colorScheme.onSecondary,
              icon: Icons.archive,
              label: 'Archive',
            ),
          if (entry.archived)
            SlidableAction(
              onPressed: (context) => _unarchiveEntry(ref, entry),
              backgroundColor: Theme.of(context).colorScheme.secondary,
              foregroundColor: Theme.of(context).colorScheme.onSecondary,
              icon: Icons.unarchive,
              label: 'Unarchive',
            ),
          if (!entry.deleted)
            SlidableAction(
              onPressed: (context) => _deleteEntry(ref, entry),
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
              icon: Icons.delete,
              label: 'Delete',
            ),
          if (entry.deleted)
            SlidableAction(
              onPressed: (context) => _undeleteEntry(ref, entry),
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
              icon: Icons.restore_from_trash,
              label: 'Undelete',
            ),
        ],
      ),
      child: ListTile(
        leading: SizedBox(
          width: imageWidth / 2,
          child: entry.imageUrl.isNotEmpty
              ? CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.onSecondary,
                  backgroundImage: NetworkImage(entry.imageUrl),
                  radius: imageWidth / 2,
                  child: entry.imageUrl.isEmpty
                      ? Icon(Icons.error, size: imageWidth)
                      : null,
                )
              : SizedBox(
                  child: Icon(Icons.article, size: imageWidth * 0.4),
                ),
        ),
        title: Text(
          entry.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            Text(entry.domain()),
            const Spacer(),
            Text('${entry.duration()} min'),
          ],
        ),
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
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: const Text('Know Keeper Menu',
                style: TextStyle(color: Colors.white, fontSize: 24)),
          ),
          ListTile(
            leading: const Icon(Icons.add),
            title: const Text('Add URL'),
            onTap: () {
              Navigator.pop(context);
              _showAddUrlDialog();
            },
          ),
          CheckboxListTile(
            title: const Text('Show Active'),
            value: _currentFilter == EntryFilter.active,
            onChanged: (bool? value) {
              setState(() {
                _currentFilter = EntryFilter.active;
              });
              Navigator.pop(context);
            },
          ),
          CheckboxListTile(
            title: const Text('Show All'),
            value: _currentFilter == EntryFilter.all,
            onChanged: (bool? value) {
              setState(() {
                _currentFilter = EntryFilter.all;
              });
              Navigator.pop(context);
            },
          ),
          CheckboxListTile(
            title: const Text('Show Archived'),
            value: _currentFilter == EntryFilter.archived,
            onChanged: (bool? value) {
              setState(() {
                _currentFilter = EntryFilter.archived;
              });
              Navigator.pop(context);
            },
          ),
          CheckboxListTile(
            title: const Text('Show Deleted'),
            value: _currentFilter == EntryFilter.deleted,
            onChanged: (bool? value) {
              setState(() {
                _currentFilter = EntryFilter.deleted;
              });
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ConfigPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.import_export),
            title: const Text('Export'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ExportPage()),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showAddUrlDialog() {
    final urlController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Add URL'),
          content: TextField(
            controller: urlController,
            decoration: const InputDecoration(hintText: "Enter URL"),
            keyboardType: TextInputType.url,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text('Add'),
              onPressed: () async {
                final url = urlController.text.trim();
                if (url.isNotEmpty) {
                  Navigator.of(dialogContext).pop();
                  final urlEntry = await fetchUrlEntry(url);
                  await ref.read(databaseProvider).addUrlEntry(urlEntry);
                  ref.invalidate(urlEntriesProvider);
                }
              },
            ),
          ],
        );
      },
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

  void _unarchiveEntry(WidgetRef ref, UrlEntry entry) async {
    final updatedEntry = entry.copyWith(archived: false);
    await ref.read(databaseProvider).updateUrlEntry(updatedEntry);
    _refreshData();
  }

  void _undeleteEntry(WidgetRef ref, UrlEntry entry) async {
    final updatedEntry = entry.copyWith(deleted: false);
    await ref.read(databaseProvider).updateUrlEntry(updatedEntry);
    _refreshData();
  }
}
