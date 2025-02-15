import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:enough_mail/enough_mail.dart';
import '../data_fetcher/imap_config.dart';

class EmailFetchResult {
  final List<MimeMessage> messages;
  final DateTime fetchTime;

  EmailFetchResult(this.messages, this.fetchTime);
}

class EmailFetcherNotifier extends StateNotifier<EmailFetchResult?> {
  EmailFetcherNotifier() : super(null);

  Future<List<MimeMessage>> fetchEmails() async {
    final currentState = state;
    if (currentState != null &&
        DateTime.now().difference(currentState.fetchTime).inSeconds < 90) {
      return currentState.messages;
    }

    final config = await ImapConfig.fromSharedPreferences();
    if (config == null) {
      return [];
    }

    final client = ImapClient(isLogEnabled: false);
    try {
      await client.connectToServer(config.server, config.port, isSecure: config.isSecure);
      await client.login(config.username, config.password);
      await client.selectInbox();

      final fetchResult = await client.fetchRecentMessages(messageCount: 100, criteria: 'BODY.PEEK[]');
      state = EmailFetchResult(fetchResult.messages, DateTime.now());
      return fetchResult.messages;
    } finally {
      await client.logout();
    }
  }
}

final emailFetcherProvider = StateNotifierProvider<EmailFetcherNotifier, EmailFetchResult?>((ref) {
  return EmailFetcherNotifier();
});

final fetchedEmailsProvider = FutureProvider<List<MimeMessage>>((ref) async {
  final fetcher = ref.watch(emailFetcherProvider.notifier);
  return fetcher.fetchEmails();
});