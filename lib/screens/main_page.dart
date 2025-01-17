import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../service/url_providers.dart';
import 'detail_page.dart';
import 'config_page.dart';  // Add this import

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
    final processors = ref.read(processorsProvider);
    for (final processor in processors) {
      await processor.process();
    }
    // ignore: unused_result
    ref.refresh(urlEntriesProvider);
  }

  @override
  Widget build(BuildContext context) {
    final urlEntriesAsyncValue = ref.watch(urlEntriesProvider);

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
          loading: () => const Center(child: CircularProgressIndicator()),
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