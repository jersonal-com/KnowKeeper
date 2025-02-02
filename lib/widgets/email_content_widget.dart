import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:html/parser.dart' as htmlparser;
import 'package:html/dom.dart' as dom;
import 'package:know_keeper/widgets/content_widget.dart';
import 'package:path/path.dart';

import '../data_fetcher/email_attachment_directory.dart';
import '../service/directory_provider.dart';

class EmailContentWidget extends ContentWidget {

  const EmailContentWidget({
    super.key,
    required super.content,
    required super.baseUrl,
    required super.entry,
    super.highlights,
    super.highlightMode,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final document = htmlparser.parse(content);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: processNode(context, ref, document.body!.nodes),
      ),
    );
  }


  @override
  Widget buildImage(WidgetRef ref, dom.Element imgElement) {
    final src = imgElement.attributes['src'];
    if (src == null) {
      return const SizedBox.shrink();
    }

    // External URL
    if (src.startsWith('http')) {
      return super.buildImage(ref, imgElement);
    }

    final dir = ref.watch(emailAttachmentDirectoryProvider);
    final fileName = src.startsWith('cid:') ? src.substring(4) : src;

    return dir.when(
      data: (directory) {
        final filePath = join(directory.path, sanitizeFileName(fileName));
        final file = File(filePath);
        if (file.existsSync()) {
          return Image.file(file, fit: BoxFit.contain);
        } else {
          return Text("Attachment not found: $filePath");
        }
      },
      loading: () => const CircularProgressIndicator(),
      error: (error, stack) => Text('Error loading attachment: $error'),
    );
  }

}
