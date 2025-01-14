import 'package:enough_mail/enough_mail.dart';
import '../data/url_database.dart';
import 'imap_config.dart';

class EmailUrlProcessor {
  final ImapConfig config;
  final UrlDatabase urlDatabase;

  EmailUrlProcessor({
    required this.config,
    required this.urlDatabase,
  });

  Future<void> processEmails() async {
    final client = ImapClient(isLogEnabled: false);

    try {
      await client.connectToServer(config.server, config.port,
          isSecure: config.isSecure);
      await client.login(config.username, config.password);

      await client.selectInbox();
      final fetchResult = await client.fetchRecentMessages(
          messageCount: 100, criteria: 'BODY[HEADER.FIELDS (SUBJECT)]');

      for (final message in fetchResult.messages) {
        final subject = message.decodeSubject();
        print("Processing message: $subject");
        if (subject != null && subject.startsWith('RL:')) {
          final url = subject.substring(3).trim();
          if (_isValidUrl(url)) {
            await urlDatabase.addUrl(url);
            print('Added URL to database: $url');
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