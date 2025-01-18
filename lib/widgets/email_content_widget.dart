import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:html/parser.dart' as htmlparser;
import 'package:html/dom.dart' as dom;
import 'package:path/path.dart';

import '../data/highlight.dart';
import '../data/highlight_mode.dart';
import '../data_fetcher/email_attachment_directory.dart';
import '../service/directory_provider.dart';

class EmailContentWidget extends ConsumerWidget {
  final String emailContent;
  final List<Highlight> highlights;
  final HighlightMode highlightMode;

  const EmailContentWidget({
    Key? key,
    required this.emailContent,
    required this.highlights,
    this.highlightMode = HighlightMode.none,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final document = htmlparser.parse(emailContent);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _processNode(ref, document.body!, context),
      ),
    );
  }

  List<Widget> _processNode(WidgetRef ref, dom.Node node, BuildContext context) {
    List<Widget> widgets = [];

    for (var child in node.nodes) {
      if (child is dom.Element) {
        switch (child.localName) {
          case 'p':
            widgets.add(_buildParagraph(ref, child, context));
            break;
          case 'img':
            widgets.add(_buildImage(ref, child));
            break;
          case 'a':
            widgets.add(_buildLink(ref, child, context));
            break;
          // Add more cases for other HTML elements as needed
          default:
            widgets.addAll(_processNode(ref, child, context));
        }
      } else if (child is dom.Text) {
        widgets.add(_buildText(ref, child.text, context));
      }
    }

    return widgets;
  }

  Widget _buildParagraph(WidgetRef ref, dom.Element element, BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _processNode(ref, element, context),
      ),
    );
  }

  Widget _buildImage(WidgetRef ref, dom.Element element) {
    final src = element.attributes['src'];
    if (src == null) {
      return const SizedBox.shrink();
    }

    // External URL
    if (src.startsWith('http')) {
      return Image.network(src, fit: BoxFit.contain);
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

  Widget _buildLink(WidgetRef ref, dom.Element element, BuildContext context) {
    final href = element.attributes['href'];
    final text = element.text;

    return InkWell(
      onTap: () {
        // Implement link handling logic here
      },
      child: Text(
        text,
        style: TextStyle(
          color: Colors.blue,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }

  Widget _buildText(WidgetRef ref, String text, BuildContext context) {
    final highlightedText = _highlightText(text);
    return RichText(
        text: TextSpan(
      children: highlightedText,
      style: DefaultTextStyle.of(context).style,
    ));
  }

  List<TextSpan> _highlightText(String text) {
    // TODO: Implement highlighting
    return [TextSpan(text: text)];
  }

  String _resolveUrl(String url) {
    // TODO: Handle image attachments
    return url;
  }
}
