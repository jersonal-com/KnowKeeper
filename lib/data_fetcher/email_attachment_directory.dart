import 'dart:io';

import 'package:path_provider/path_provider.dart';

Future<Directory> getEmailAttachmentDirectory() async {
  final appDir = await getApplicationDocumentsDirectory();
  return Directory('${appDir.path}/email_attachments');
}

String sanitizeFileName(String fileName) {
  return fileName.replaceAll(RegExp(r'[^\w\s.-]'), '_');
}