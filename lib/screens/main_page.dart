import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data_fetcher/email_url_processor.dart';
import '../data_fetcher/imap_config.dart';
import '../service/url_database_provider.dart';
import 'config_page.dart';
import 'detail_page.dart';

class MainPage extends ConsumerStatefulWidget {
  const MainPage({super.key});

  @override
  MainPageState createState() => MainPageState();
}

class MainPageState extends ConsumerState<MainPage> {
  late Future<void> _initFuture;

  @override
  void initState() {
    super.initState();
    _initFuture = _initializeAndFetchData();
  }

  Future<void> _initializeAndFetchData() async {
    final config = await ImapConfig.fromSharedPreferences();
    if (config != null) {
      final urlDatabaseNotifier = ref.watch(urlDatabaseProvider.notifier);
      final processor = EmailUrlProcessor(
        config: config,
        urlDatabase: urlDatabaseNotifier.state,
      );
      await processor.processEmails();
      // After processing, update the state
      urlDatabaseNotifier.state = processor.urlDatabase;
    } else {
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _initFuture = _initializeAndFetchData();
    });
  }

  @override
  Widget build(BuildContext context) {
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
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'config',
                child: Text('Configuration'),
              ),
            ],
          ),
        ],
      ),      body: FutureBuilder(
        future: _initFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else {
            return RefreshIndicator(
              onRefresh: _refreshData,
              child: Consumer(
                builder: (context, ref, child) {
                  final urlDatabase = ref.watch(urlDatabaseProvider);
                  final entries = urlDatabase.getAllEntries();
                  return ListView.builder(
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      return ListTile(
                        leading: SizedBox(
                          width: 100,
                          child: entry.imageUrl != null && entry.imageUrl!.isNotEmpty
                              ? Image.network(
                                  entry.imageUrl!,
                                  fit: BoxFit.fitHeight,
                                )
                              : null,
                        ),
                        title: Text(entry.title),
                        subtitle: Text(entry.source),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DetailPage(entry: entry),
                            ),
                          );
                        },                      );
                    },
                  );
                },
              ),
            );
          }
        },
      ),
    );
  }
}

