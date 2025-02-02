import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:html/dom.dart' as dom;
import '../data/highlight.dart';
import '../data/highlight_mode.dart';
import '../service/selection_provider.dart';

class ContentWidget extends ConsumerWidget {
  final String content;
  final String baseUrl;
  final List<Highlight> highlights;
  final HighlightMode highlightMode;

  const ContentWidget({
    super.key,
    required this.content,
    required this.baseUrl,
    this.highlights = const [],
    this.highlightMode = HighlightMode.none,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Placeholder();
  }

  List<Widget> processNode(
      BuildContext context, WidgetRef ref, List<dom.Node> nodes) {
    List<Widget> widgets = [];
    bool foundFirstHeading = false;
    int paragraphIndex = 0;

    void parseNode(dom.Node node, bool foundFirstHeading) {
      if (node is dom.Element &&
          node.localName != null &&
          !['header', 'script', 'style'].any((node.localName!.startsWith))) {
        if (node.localName!.startsWith('h') && node.localName!.length == 2) {
          // Handle heading tags (h1, h2, h3, etc.)
          foundFirstHeading = true;
          widgets.add(
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                node.text.trim(),
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          );
        } else if (node.localName == 'img') {
          // Handle image tags
          widgets.add(buildImage(ref, node));
        } else if (node.localName == 'p') {
          // Handle paragraph tags
          widgets.addAll(
              parseParagraphContent(context, ref, node, paragraphIndex));
          paragraphIndex++;
        } else {
          // Recursively parse child nodes
          for (var childNode in node.nodes) {
            parseNode(childNode, foundFirstHeading);
          }
        }
      }
    }

    for (var node in nodes) {
      parseNode(node, foundFirstHeading);
    }

    return widgets;
  }

  Widget buildHighlightedParagraph(
      BuildContext context, WidgetRef ref, String text, int paragraphIndex) {
    List<TextSpan> spans = [];
    int currentIndex = 0;

    for (var highlight
        in highlights.where((h) => h.paragraphIndex == paragraphIndex)) {
      if (currentIndex < highlight.startIndex) {
        spans.add(
            TextSpan(text: text.substring(currentIndex, highlight.startIndex)));
      }
      int highlightEnd = highlight.length + highlight.startIndex;
      if (highlightEnd >= text.length) {
        highlightEnd = text.length-1;
      }
      spans.add(TextSpan(
        text: text.substring(
            highlight.startIndex, highlightEnd),
        style: const TextStyle(backgroundColor: Colors.yellow),
      ));
      currentIndex = highlightEnd;
    }

    if (currentIndex <= text.length) {
      spans.add(TextSpan(text: "${text.substring(currentIndex)} "));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: SelectableText.rich(
        TextSpan(children: spans),
        style: DefaultTextStyle.of(context).style,
        onSelectionChanged: (selection, cause) {
          if (selection.baseOffset != selection.extentOffset) {
            final selectionEnd = (selection.end - 1) < text.length
                ? (selection.end - 1)
                : text.length;
            ref.read(currentSelectionProvider.notifier).state = Selection(
              paragraphIndex: paragraphIndex,
              startIndex: selection.start,
              length: selection.end - selection.start,
              text: text.substring(selection.start, selectionEnd),
            );
          }
        },
      ),
    );
  }

  List<Widget> parseParagraphContent(BuildContext context, WidgetRef ref,
      dom.Element element, int paragraphIndex) {
    List<Widget> paragraphWidgets = [];
    StringBuffer textBuffer = StringBuffer();

    void addTextWidget() {
      if (textBuffer.isNotEmpty &&
          !RegExp(r'^[\u200B\s]*$').hasMatch(textBuffer.toString())) {
        debugPrint("<<${textBuffer.toString().trim()}>>");
        paragraphWidgets.add(buildHighlightedParagraph(
            context, ref, textBuffer.toString().trim(), paragraphIndex));
        textBuffer.clear();
      }
    }

    for (var child in element.nodes) {
      if (child is dom.Text) {
        textBuffer.write(child.text);
      } else if (child is dom.Element && child.localName == 'a') {
        textBuffer.write(child.text);
      } else if (child is dom.Element && child.localName == 'img') {
        addTextWidget(); // Add accumulated text before the image
        paragraphWidgets.add(buildImageWidget(child));
      } else {
        textBuffer.write(child.text);
      }
    }

    addTextWidget(); // Add any remaining text after the last image

    return paragraphWidgets;
  }

  Widget buildImageWidget(dom.Element imgElement) {
    final src = imgElement.attributes['src'];
    if (src != null &&
        src.startsWith('http') &&
        ['png', 'jpg', 'jpeg'].any((ext) => src.endsWith(ext))) {
      final imageUrl = resolveUrl(src);
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Image.network(imageUrl),
      );
    }
    return const SizedBox
        .shrink(); // Return an empty widget if the image is invalid
  }

  String resolveUrl(String url) {
    return url;
  }

  Widget buildImage(WidgetRef ref, dom.Element imgElement) {
    final src = imgElement.attributes['src'];
    if (src != null &&
        src.startsWith('http') &&
        ['png', 'jpg', 'jpeg'].any((ext) => src.endsWith(ext))) {
      final imageUrl = resolveUrl(src);
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Image.network(imageUrl),
      );
    }
    return const SizedBox.shrink();
  }
}
