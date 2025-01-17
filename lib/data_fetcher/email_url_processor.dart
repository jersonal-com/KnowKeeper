import 'package:enough_mail/enough_mail.dart';
import '../data/url_entry.dart';
import '../database/sembast_database.dart';
import 'imap_config.dart';
import 'fetch_url_entry.dart';
import 'processor.dart';

class EmailUrlProcessor implements Processor {
  ImapConfig? _config;
  final SembastDatabase database = SembastDatabase.instance;

  EmailUrlProcessor() {
    _initConfig();
  }

  Future<void> _initConfig() async {
    _config = await ImapConfig.fromSharedPreferences();
  }

  @override
  Future<void> process() async {
    if (_config == null) {
      print('IMAP configuration is not set. Skipping email processing.');
      return;
    }

    final client = ImapClient(isLogEnabled: false);

    try {
      await client.connectToServer(_config!.server, _config!.port, isSecure: _config!.isSecure);
      await client.login(_config!.username, _config!.password);

      await client.selectInbox();
      final fetchResult = await client.fetchRecentMessages(
          messageCount: 100, criteria: 'BODY[HEADER.FIELDS (SUBJECT)]');

      for (final message in fetchResult.messages) {
        final subject = message.decodeSubject();
        if (subject != null && subject.startsWith('RL:')) {
          final url = subject.substring(3).trim();
          if (_isValidUrl(url)) {
            final urlEntry = await fetchUrlEntry(url);
            await database.addUrlEntry(urlEntry);
          }
        }
      }
    } catch (e) {
      print('Error processing emails: $e');
    } finally {
      await client.logout();
    }
  }

  bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.scheme.startsWith('http') && uri.host.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}