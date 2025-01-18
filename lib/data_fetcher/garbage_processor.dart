import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/sembast_database.dart';
import '../data/url_entry.dart';
import 'processor.dart';

class GarbageProcessor extends Processor {
  // ignore: constant_identifier_names
  static const String LAST_RUN_KEY = 'garbage_processor_last_run';
  final SembastDatabase database = SembastDatabase.instance;

  GarbageProcessor();

  @override
  Future<void> process() async {
    if (!await _shouldRun()) {
      debugPrint('GarbageProcessor: Already ran today. Skipping.');
      return;
    }

    debugPrint('GarbageProcessor: Starting garbage collection...');

    // Get old deleted entries
    final oldDeletedEntries = await database.getOldDeletedEntries();

    // Delete attachments
    await _deleteAttachments(oldDeletedEntries);

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

  Future<void> _updateLastRunTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(LAST_RUN_KEY, DateTime.now().millisecondsSinceEpoch);
  }
}