import 'dart:io';
import 'package:know_keeper/data_fetcher/email_attachment_directory.dart';
import 'package:riverpod/riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

final emailAttachmentDirectoryProvider = FutureProvider<Directory>((ref) async {
  final attachmentDir = await getEmailAttachmentDirectory();
  if (!await attachmentDir.exists()) {
    await attachmentDir.create(recursive: true);
  }

  return attachmentDir;
});