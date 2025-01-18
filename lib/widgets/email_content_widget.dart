import 'package:flutter/material.dart';
import 'package:html/parser.dart' as htmlparser;
import 'package:html/dom.dart' as dom;

import '../data/highlight.dart';
import '../data/highlight_mode.dart';

class EmailContentWidget extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final document = htmlparser.parse(emailContent);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _processNode(document.body!, context),
      ),
    );
  }

  List<Widget> _processNode(dom.Node node, BuildContext context) {
    List<Widget> widgets = [];

    for (var child in node.nodes) {
      if (child is dom.Element) {
        switch (child.localName) {
          case 'p':
            widgets.add(_buildParagraph(child, context));
            break;
          case 'img':
            widgets.add(_buildImage(child));
            break;
          case 'a':
            widgets.add(_buildLink(child, context));
            break;
          // Add more cases for other HTML elements as needed
          default:
            widgets.addAll(_processNode(child, context));
        }
      } else if (child is dom.Text) {
        widgets.add(_buildText(child.text, context));
      }
    }

    return widgets;
  }

  Widget _buildParagraph(dom.Element element, BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _processNode(element, context),
      ),
    );
  }

  Widget _buildImage(dom.Element element) {
    final src = element.attributes['src'];
    return src != null
        ? Image.network(_resolveUrl(src), fit: BoxFit.contain)
        : SizedBox.shrink();
  }


  Widget _buildLink(dom.Element element, BuildContext context) {
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

  Widget _buildText(String text, BuildContext context) {
    final highlightedText = _highlightText(text);
    return RichText(text: TextSpan(
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