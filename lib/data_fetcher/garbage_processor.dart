import 'dart:io';
import 'package:enough_mail/enough_mail.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/sembast_database.dart';
import '../data/url_entry.dart';
import '../service/database_providers.dart';
import 'email_newsletter_processor.dart';
import 'imap_config.dart';
import 'processor.dart';

class GarbageProcessor extends Processor {
  // ignore: constant_identifier_names
  static const String LAST_RUN_KEY = 'garbage_processor_last_run';
  late SembastDatabase database;

  GarbageProcessor(super.ref) {
    database = ref.read(databaseProvider).database;
  }

  @override
  Future<void> process({bool force = false}) async {
    if (!force && !await _shouldRun()) {
      debugPrint('GarbageProcessor: Already ran today. Skipping.');
      return;
    }

    debugPrint('GarbageProcessor: Starting garbage collection...');

    // Get old deleted entries
    final oldDeletedEntries = (force) ? await database.getAllDeletedEntries() : await database.getOldDeletedEntries();

    // Delete attachments
    await _deleteAttachments(oldDeletedEntries);

    // Delete corresponding emails
    await _deleteEmails(oldDeletedEntries);

    // Delete entries from database
    await database.deleteEntries(oldDeletedEntries);

    // Update last run time
    await _updateLastRunTime();

    debugPrint('GarbageProcessor: Garbage collection completed.');
  }

  Future<bool> _shouldRun() async {
    final prefs = await SharedPreferences.getInstance();
    final lastRun = prefs.getInt(LAST_RUN_KEY) ?? 0;
    final now = DateTime.now();
    final lastRunDate = DateTime.fromMillisecondsSinceEpoch(lastRun);

    return now.difference(lastRunDate).inDays >= 1;
  }

  Future<void> _deleteAttachments(List<UrlEntry> entries) async {
    for (var entry in entries) {
      for (var attachmentPath in entry.attachments) {
        final file = File(attachmentPath);
        if (await file.exists()) {
          await file.delete();
          debugPrint('Deleted attachment: $attachmentPath');
        }
      }
    }
  }

  Future<void> _deleteEmails(List<UrlEntry> entries) async {
    final client = ImapClient(isLogEnabled: false);
    final config = await ImapConfig.fromSharedPreferences();

    // Prepare the list of MD5 sums and URLs
    final md5Sums = entries.map((e) => EmailNewsletterProcessor.calculateMD5(e)).toList();
    final urls = entries.map((e) => 'RL: ${e.url}').toList();

    try {
      await client.connectToServer(config!.server, config.port, isSecure: config.isSecure);
      await client.login(config.username, config.password);
      await client.selectInbox();

      // Fetch all messages
      final fetchResult = await client.fetchRecentMessages(
          messageCount: 1000, criteria: 'BODY.PEEK[]');

      List<int> messagesToDelete = [];

      for (final message in fetchResult.messages) {
        final md5Entry = await EmailNewsletterProcessor.processEmail(message);
        final md5 = EmailNewsletterProcessor.calculateMD5(md5Entry);

        final subject = message.decodeSubject() ?? '';

        // Check if the subject matches any URL in our list
        if (urls.contains(subject)) {
          messagesToDelete.add(message.sequenceId!);
          continue;
        }

        // Check if the body contains any MD5 sum in our list
        if (md5Sums.contains(md5)) {
          messagesToDelete.add(message.sequenceId!);
        }
      }

      // Mark matching messages as deleted
      if (messagesToDelete.isNotEmpty) {
        final sequenceSet = MessageSequence.fromIds(messagesToDelete);
        await client.store(sequenceSet, [MessageFlags.deleted]);
        debugPrint('Marked ${messagesToDelete.length} emails for deletion');

        // Expunge to permanently remove deleted messages
        await client.expunge();
        debugPrint('Expunged ${messagesToDelete.length} emails');
      } else {
        debugPrint('No emails found to delete');
      }
    } catch (e) {
      debugPrint('Error during email deletion: $e');
    } finally {
      await client.logout();
    }
  }


  Future<void> _updateLastRunTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(LAST_RUN_KEY, DateTime.now().millisecondsSinceEpoch);
  }
}