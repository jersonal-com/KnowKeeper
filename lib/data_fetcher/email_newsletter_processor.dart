import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:enough_mail/enough_mail.dart';
import 'package:path/path.dart';
import 'email_attachment_directory.dart';
import '../database/sembast_database.dart';
import 'imap_config.dart';
import '../data/url_entry.dart';
import 'processor.dart';

class EmailNewsletterProcessor extends Processor {
  ImapConfig? _config;
  final SembastDatabase database = SembastDatabase.instance;

  EmailNewsletterProcessor() {
    _initConfig();
  }

  Future<void> _initConfig() async {
    _config = await ImapConfig.fromSharedPreferences();
  }

  @override
  Future<void> process() async {
    final client = ImapClient(isLogEnabled: false);

    if (_config == null) {
      return;
    }

    try {
      await client.connectToServer(_config!.server, _config!.port, isSecure: _config!.isSecure);
      await client.login(_config!.username, _config!.password);
      await client.selectInbox();

      final fetchResult = await client.fetchRecentMessages(messageCount: 100, criteria: 'BODY.PEEK[]');
      for (final message in fetchResult.messages) {
        final subject = message.decodeSubject();
        if (subject != null && ! subject.startsWith('RL:')) {
          final urlEntry = await processEmail(message);
          await database.addUrlEntry(urlEntry);
        }
      }
    } finally {
      await client.logout();
    }
  }

  static Future<UrlEntry> processEmail(MimeMessage message) async {
    final subject = message.decodeSubject() ?? 'No Subject';
    final from = message.from?.first.email ?? 'Unknown';
    final date = message.decodeDate() ?? DateTime.now();
    String htmlContent = '';
    String plainTextContent = '';
    List<String> attachments = [];

    final attachmentsDir =  await getEmailAttachmentDirectory() ;
    if (!await attachmentsDir.exists()) {
      await attachmentsDir.create(recursive: true);
    }

    Future<void> processPart(MimePart part) async {
      if (part.mediaType.isImage) {
//        final fileName = part.decodeFileName() ?? 'attachment_${DateTime.now().millisecondsSinceEpoch}';
        String fileName = part.getHeader('Content-id').toString();
        if (fileName.contains('<') && fileName.contains('>')) {
          final start = fileName.indexOf('<') + 1;
          final end = fileName.indexOf('>');
          fileName = fileName.substring(start, end);
        }
        final filePath = join(attachmentsDir.path, sanitizeFileName(fileName));
        final file = File(filePath);
        await file.writeAsBytes(part.decodeContentBinary() ?? []);
        attachments.add(filePath);
      } else if (part.mediaType.text == 'text/plain') {
        plainTextContent += part.decodeContentText() ?? '';
      } else if (part.mediaType.text == 'text/html') {
        htmlContent += part.decodeContentText() ?? '';
      } else if (part.parts!= null && part.parts!.isNotEmpty) {
        final partsList = part.parts ?? [];
        for (final subPart in partsList) {
          await processPart(subPart);
        }
      }
    }

    await processPart(message);

    final content = htmlContent.isNotEmpty ? htmlContent : plainTextContent;
    UrlEntry entry = UrlEntry(
      url: 'email:',  // Using a custom scheme to identify emails
      title: subject,
      source: 'newsletter',
      description: from,
      imageUrl: '',  // You might want to use the first image attachment as a preview
      text: content,
      date: date,
      isEmail: true,
      attachments: attachments,
    );

    final hash = calculateMD5(entry);
    entry = entry.copyWith(url: 'email:$hash');
    return entry;
  }

  static String calculateMD5(UrlEntry entry) {
    final hashString = '${entry.description}${entry.text}';
    final bytes = utf8.encode(hashString);
    final hash = md5.convert(bytes);
    final md5String = base64Encode(hash.bytes);
    return md5String;
  }

}