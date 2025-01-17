import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart' as dom;
import 'package:know_keeper/data/highlight_mode.dart';
import '../data/highlight.dart';
import '../service/selection_provider.dart';

class HtmlContentWidget extends ConsumerStatefulWidget {
  final String htmlContent;
  final String baseUrl;
  final List<Highlight> highlights;
  final HighlightMode highlightMode;

  const HtmlContentWidget({
    super.key,
    required this.htmlContent,
    required this.baseUrl,
    this.highlights = const [],
    required this.highlightMode,
  });

  @override
  HtmlContentWidgetState createState() => HtmlContentWidgetState();
}

class HtmlContentWidgetState extends ConsumerState<HtmlContentWidget> {
  // ignore: unused_field
  late List<dom.Element> _paragraphs;

  @override
  void initState() {
    super.initState();
    _parseParagraphs();
  }

  void _parseParagraphs() {
    final document = parse(widget.htmlContent);
    _paragraphs = document.body!.children;
  }

  @override
  Widget build(BuildContext context) {
    final document = parse(widget.htmlContent);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ..._parseNodes(context, document.body!.nodes),
      ],
    );
  }

  List<Widget> _parseNodes(BuildContext context, List<dom.Node> nodes) {
    List<Widget> widgets = [];
    bool foundFirstHeading = false;
    int paragraphIndex = 0;

    void parseNode(dom.Node node, bool foundFirstHeading) {
      if (node is dom.Element && node.localName != null && ! ['header', 'script', 'style'].any((node.localName!.startsWith))) {
        if (node.localName!.startsWith('h') && node.localName!.length == 2) {
          // Handle heading tags (h1, h2, h3, etc.)
          foundFirstHeading = true;
          widgets.add(
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                node.text,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          );
        } else if (node.localName == 'img') {
          // Handle image tags
          _addImageWidget(widgets, node);
        } else if (node.localName == 'p') {
          // Handle paragraph tags
          widgets.addAll(_parseParagraphContent(context, node, paragraphIndex));
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

  List<Widget> _parseParagraphContent(BuildContext context, dom.Element paragraphNode, int paragraphIndex) {
    List<Widget> paragraphWidgets = [];
    StringBuffer textBuffer = StringBuffer();

    void addTextWidget() {
      if (textBuffer.isNotEmpty) {
        paragraphWidgets.add(_buildHighlightedParagraph(context, textBuffer.toString(), paragraphIndex));
        textBuffer.clear();
      }
    }

    for (var child in paragraphNode.nodes) {
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

  Widget _buildHighlightedParagraph(BuildContext context, String text, int paragraphIndex) {
    List<TextSpan> spans = [];
    int currentIndex = 0;

    for (var highlight in widget.highlights.where((h) => h.paragraphIndex == paragraphIndex)) {
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


  void _addImageWidget(List<Widget> widgetList, dom.Element imgElement) {
    final src = imgElement.attributes['src'];
    if (src != null &&
        src.startsWith('http') &&
        ['png', 'jpg', 'jpeg'].any((ext) => src.endsWith(ext))) {
      final imageUrl = _resolveUrl(src);
      widgetList.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Image.network(imageUrl),
        ),
      );
    }
  }

  String _resolveUrl(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url; // Already an absolute URL
    } else {
      return Uri.parse(widget.baseUrl).resolve(url).toString();
    }
  }
}