import '../database/sembast_database.dart';
import '../service/email_fetcher_provider.dart';
import 'fetch_url_entry.dart';
import 'processor.dart';

class EmailUrlProcessor extends Processor {
  final SembastDatabase database = SembastDatabase.instance;

  EmailUrlProcessor(super.ref);

  @override
  Future<void> process() async {
    final messages = await ref.read(fetchedEmailsProvider.future);

    for (final message in messages) {
      final subject = message.decodeSubject();
      if (subject != null && subject.startsWith('RL:')) {
        final url = subject.substring(3).trim();
        if (_isValidUrl(url)) {
          final urlEntry = await fetchUrlEntry(url);
          await database.addUrlEntry(urlEntry);
        }
      }
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