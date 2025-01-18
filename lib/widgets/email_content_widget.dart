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
import '../service/selection_provider.dart';

class EmailContentWidget extends ConsumerWidget {
  final String emailContent;
  final List<Highlight> highlights;
  final HighlightMode highlightMode;

  const EmailContentWidget({
    super.key,
    required this.emailContent,
    required this.highlights,
    this.highlightMode = HighlightMode.none,
  });

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
    int paragraphIndex = 0;

    for (var child in node.nodes) {
      if (child is dom.Element && child.localName != null && ! ['header', 'script', 'style'].any((child.localName!.startsWith))) {
        if (child.localName!.startsWith('h') && child.localName!.length == 2) {
          // Handle heading tags (h1, h2, h3, etc.)
          widgets.add(
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                child.text,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          );
        } else {
          switch (child.localName) {
          case 'p':
            widgets.addAll(_parseParagraphContent(ref, child, context, paragraphIndex));
            paragraphIndex++;
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
        }
      } else if (child is dom.Text) {
        widgets.add(_buildText(ref, child.text, context));
      }
    }

    return widgets;
  }

  List<Widget> _parseParagraphContent(WidgetRef ref, dom.Element element, BuildContext context, int paragraphIndex) {
    List<Widget> paragraphWidgets = [];
    StringBuffer textBuffer = StringBuffer();

    void addTextWidget() {
      if (textBuffer.isNotEmpty) {
        paragraphWidgets.add(_buildHighlightedParagraph(ref, context, textBuffer.toString(), paragraphIndex));
        textBuffer.clear();
      }
    }

    for (var child in element.nodes) {
      if (child is dom.Text) {
        textBuffer.write(child.text);
      } else if (child is dom.Element && child.localName == 'img') {
        addTextWidget(); // Add accumulated text before the image
        paragraphWidgets.add(_buildImageWidget(child));
      }
    }

    addTextWidget(); // Add any remaining text after the last image

    return paragraphWidgets;
  }

  Widget _buildHighlightedParagraph(WidgetRef ref, BuildContext context, String text, int paragraphIndex) {
    List<TextSpan> spans = [];
    int currentIndex = 0;

    for (var highlight in highlights.where((h) => h.paragraphIndex == paragraphIndex)) {
      if (currentIndex < highlight.startIndex) {
        spans.add(TextSpan(text: text.substring(currentIndex, highlight.startIndex)));
      }
      spans.add(TextSpan(
        text: text.substring(highlight.startIndex, highlight.startIndex + highlight.length),
        style: const TextStyle(backgroundColor: Colors.yellow),
      ));
      currentIndex = highlight.startIndex + highlight.length;
    }

    if (currentIndex < text.length) {
      spans.add(TextSpan(text: text.substring(currentIndex)));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: SelectableText.rich(
        TextSpan(children: spans),
        style: DefaultTextStyle.of(context).style,
        onSelectionChanged: (selection, cause) {
          if (selection.baseOffset != selection.extentOffset) {
            ref.read(currentSelectionProvider.notifier).state = Selection(
              paragraphIndex: paragraphIndex,
              startIndex: selection.start,
              length: selection.end - selection.start,
              text: text.substring(selection.start, selection.end),
            );
          }
        },
      ),
    );
  }


  Widget _buildImageWidget(dom.Element imgElement) {
    final src = imgElement.attributes['src'];
    if (src != null &&
        src.startsWith('http') &&
        ['png', 'jpg', 'jpeg'].any((ext) => src.endsWith(ext))) {
      final imageUrl = _resolveUrl(src);
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Image.network(imageUrl),
      );
    }
    return const SizedBox.shrink(); // Return an empty widget if the image is invalid
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
    final text = element.text;

    return InkWell(
      onTap: () {
        // Implement link handling logic here
      },
      child: Text(
        text,
        style: const TextStyle(
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
