import 'package:flutter/material.dart';
import 'package:html/parser.dart' as htmlparser;
import 'package:html/dom.dart' as dom;

class HtmlContentWidget extends StatelessWidget {
  final String htmlContent;
  final String baseUrl;

  const HtmlContentWidget(
      {Key? key, required this.htmlContent, required this.baseUrl})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final document = htmlparser.parse(htmlContent);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _parseNodes(document.body!.nodes, false),
    );
  }

  List<Widget> _parseNodes(List<dom.Node> nodes, bool foundFirstHeading) {
    List<Widget> widgets = [];

    for (var node in nodes) {
      if (node is dom.Element) {
        if (node.localName!.startsWith('h') && node.localName!.length == 2) {
          // Handle heading tags (h1, h2, h3, etc.)
          foundFirstHeading = true;
          widgets.add(
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                node.text,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          );
        } else if (node.localName == 'img') {
          // Handle image tags
          _addImageWidget(widgets, node);
        } else if (node.localName == 'p') {
          // Handle paragraph tags
          List<Widget> paragraphContent = [];
          for (var childNode in node.nodes) {
            if (childNode is dom.Element && childNode.localName == 'img') {
              // Handle images within paragraphs
              _addImageWidget(paragraphContent, childNode);
            } else if (childNode is dom.Text) {
              // Handle text within paragraphs
              final trimmedText = childNode.text.trim();
              if (trimmedText.isNotEmpty && foundFirstHeading) {
                paragraphContent.add(Text(trimmedText));
              }
            }
          }
          if (paragraphContent.isNotEmpty) {
            widgets.add(
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: paragraphContent,
                ),
              ),
            );
          }
        } else {
          // Recursively parse child nodes
          widgets.addAll(_parseNodes(node.nodes, foundFirstHeading));
        }
      }
    }

    return widgets;
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
