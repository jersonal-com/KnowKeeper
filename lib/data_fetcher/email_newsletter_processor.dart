import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:enough_mail/enough_mail.dart';
import 'package:path/path.dart';
import '../service/email_fetcher_provider.dart';
import 'email_attachment_directory.dart';
import '../database/sembast_database.dart';
import '../data/url_entry.dart';
import 'processor.dart';

class EmailNewsletterProcessor extends Processor {
  final SembastDatabase database = SembastDatabase.instance;

  EmailNewsletterProcessor(super.ref);

  @override
  Future<void> process() async {
    final messages = await ref.read(fetchedEmailsProvider.future);

    for (final message in messages) {
      final subject = message.decodeSubject();
      if (subject != null && !subject.startsWith('RL:')) {
        final urlEntry = await processEmail(message);
        await database.addUrlEntry(urlEntry);
      }
    }
  }

  static Future<UrlEntry> processEmail(MimeMessage message) async {
    final subject = message.decodeSubject() ?? 'No Subject';
    final from = message.from?.first.email ?? 'Unknown';
    final date = message.decodeDate() ?? DateTime.now();
    String htmlContent = '';
    String plainTextContent = '';
    List<String> attachments = [];

    final attachmentsDir = await getEmailAttachmentDirectory();
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
      } else if (part.parts != null && part.parts!.isNotEmpty) {
        final partsList = part.parts ?? [];
        for (final subPart in partsList) {
          await processPart(subPart);
        }
      }
    }

    await processPart(message);

    final content = htmlContent.isNotEmpty ? htmlContent : plainTextContent;
    UrlEntry entry = UrlEntry(
      url: 'email:',
      // Using a custom scheme to identify emails
      title: subject,
      source: 'newsletter',
      description: from,
      imageUrl: '',
      // You might want to use the first image attachment as a preview
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
