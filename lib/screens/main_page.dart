import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../service/url_providers.dart';
import 'detail_page.dart';
import 'config_page.dart';  // Add this import

class MainPage extends ConsumerStatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends ConsumerState<MainPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  Future<void> _refreshData() async {
    final processors = ref.read(processorsProvider);
    for (final processor in processors) {
      await processor.process();
    }
    ref.refresh(urlEntriesProvider);
  }

  @override
  Widget build(BuildContext context) {
    final urlEntriesAsyncValue = ref.watch(urlEntriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Know Keeper'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'config') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ConfigPage()),
                );
              }
            },
            itemBuilder: (BuildContext context) {
              return {'Config'}.map((String choice) {
                return PopupMenuItem<String>(
                  value: 'config',
                  child: Text(choice),
                );
              }).toList();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: urlEntriesAsyncValue.when(
          loading: () => Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
          data: (urlEntries) {
            return ListView.builder(
              itemCount: urlEntries.length,
              itemBuilder: (context, index) {
                final entry = urlEntries[index];
                return ListTile(
                  leading: entry.imageUrl.isNotEmpty
                      ? Image.network(entry.imageUrl)
                      : null,
                  title: Text(entry.title),
                  subtitle: Text(entry.description),
                  onTap: () {
                    print("Opening url: ${entry.url}");
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetailPage(url: entry.url),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}