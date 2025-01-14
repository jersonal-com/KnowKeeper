import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data_fetcher/email_url_processor.dart';
import '../data_fetcher/imap_config.dart';
import '../service/url_database_provider.dart';
import 'detail_page.dart';

class MainPage extends ConsumerStatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends ConsumerState<MainPage> {
  late Future<void> _initFuture;

  @override
  void initState() {
    super.initState();
    _initFuture = _initializeAndFetchData();
  }

  Future<void> _initializeAndFetchData() async {
    final config = await ImapConfig.fromSharedPreferences();
    if (config != null) {
      final urlDatabaseNotifier = ref.read(urlDatabaseProvider.notifier);
      final processor = EmailUrlProcessor(
        config: config,
        urlDatabase: urlDatabaseNotifier.state,
      );
      await processor.processEmails();
      // After processing, update the state
      urlDatabaseNotifier.state = processor.urlDatabase;
    } else {
      print('Failed to load IMAP configuration. Please check your settings.');
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
        title: Text('Know Keeper'),
      ),
      body: FutureBuilder(
        future: _initFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
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