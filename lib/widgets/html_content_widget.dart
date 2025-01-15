import 'package:flutter/material.dart';
import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart' as dom;

class HtmlContentWidget extends StatelessWidget {
  final String htmlContent;
  final String baseUrl;

  const HtmlContentWidget({
    Key? key,
    required this.htmlContent,
    required this.baseUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final document = parse(htmlContent);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _parseNodes(document.body!.nodes, false),
    );
  }

  List<Widget> _parseNodes(List<dom.Node> nodes, bool foundFirstHeading) {
    List<Widget> widgets = [];

    for (var node in nodes) {
      if (node is dom.Element && node.localName != null && ! ['header', 'svg', 'script', 'meta', 'style', 'link'].any((tag) => node.localName!.contains(tag))) {
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
          // Handle image tags outside paragraphs
          _addImageWidget(widgets, node);
        } else if (node.localName == 'p') {
          // Handle paragraph tags
          widgets.addAll(_parseParagraphContent(node, foundFirstHeading));
        } else {
          // Recursively parse child nodes
          widgets.addAll(_parseNodes(node.nodes, foundFirstHeading));
        }
      }
    }

    return widgets;
  }

  List<Widget> _parseParagraphContent(dom.Element paragraphNode, bool foundFirstHeading) {
    List<Widget> paragraphWidgets = [];
    StringBuffer textBuffer = StringBuffer();

    void addTextWidget() {
      if (textBuffer.isNotEmpty && foundFirstHeading) {
        paragraphWidgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Text(textBuffer.toString().trim()),
          ),
        );
        textBuffer.clear();
      }
    }

    for (var child in paragraphNode.nodes) {
      if (child is dom.Text) {
        textBuffer.write(child.text);
      } else if (child is dom.Element && child.localName == 'img') {
        addTextWidget(); // Add accumulated text before the image
        _addImageWidget(paragraphWidgets, child);
      }
    }

    addTextWidget(); // Add any remaining text after the last image

    return paragraphWidgets;
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
      return Uri.parse(baseUrl).resolve(url).toString();
    }
  }
}