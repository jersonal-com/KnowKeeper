import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:know_keeper/data_fetcher/email_attachment_directory.dart';

final emailAttachmentDirectoryProvider = FutureProvider<Directory>((ref) async {
  final attachmentDir = await getEmailAttachmentDirectory();
  if (!await attachmentDir.exists()) {
    await attachmentDir.create(recursive: true);
  }

  return attachmentDir;
});