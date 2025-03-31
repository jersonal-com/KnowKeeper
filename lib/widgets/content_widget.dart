import 'dart:async';
import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:html/dom.dart' as dom;
import 'package:know_keeper/data/url_entry.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/highlight.dart';
import '../data/highlight_mode.dart';
import '../data/link_info.dart';
import '../service/selection_provider.dart';
import 'custom_image_widget.dart';


class ContentWidget extends ConsumerStatefulWidget {
  final String content;
  final String baseUrl;
  final UrlEntry entry;
  final List<Highlight> highlights;
  final HighlightMode highlightMode;

  const ContentWidget({
    super.key,
    required this.content,
    required this.baseUrl,
    required this.entry,
    this.highlights = const [],
    this.highlightMode = HighlightMode.none,
  });

  @override
  ContentWidgetState createState() => ContentWidgetState();
}

class ContentWidgetState extends ConsumerState<ContentWidget> {
  
  @override
  Widget build(BuildContext context) {
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

  static Timer? _debounce;
  final Map<String, GestureRecognizer> _gestureRecognizers = {};

    @override
  void dispose() {
    _debounce?.cancel();
    _gestureRecognizers.forEach((key, recognizer) => recognizer.dispose());
    super.dispose();
  }

  GestureRecognizer _getOrCreateLinkRecognizer(String url) {
    return _gestureRecognizers.putIfAbsent(
      url,
      () => TapGestureRecognizer()..onTap = () {
        launchUrl(Uri.parse(url));
      },
    );
  }

  Widget buildHighlightedParagraph(
      BuildContext context,
      WidgetRef ref,
      String text,
      int paragraphIndex,
      List<LinkInfo> links,
      ) {
    List<TextSpan> spans = [];
    int currentIndex = 0;

    // Sort highlights and links by their start index
    final allElements = [
      ...widget.highlights.where((h) => h.paragraphIndex == paragraphIndex),
      ...links,
    ]..sort((a, b) => a.startIndex.compareTo(b.startIndex));

    for (var element in allElements) {
      if (currentIndex < element.startIndex) {
        spans.add(TextSpan(text: text.substring(currentIndex, min(text.length, element.startIndex))));
      }

      if (element is Highlight) {
        int highlightEnd = min(element.startIndex + element.length, text.length);
        spans.add(TextSpan(
          text: text.substring(element.startIndex, highlightEnd),
          style: const TextStyle(backgroundColor: Colors.yellow),
        ));
        currentIndex = highlightEnd;
      } else if (element is LinkInfo) {
        spans.add(TextSpan(
          text: text.substring(min(text.length, element.startIndex), min(text.length, element.endIndex)),
          style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
          recognizer: _getOrCreateLinkRecognizer(element.url),
        ));
        currentIndex = element.endIndex + (element.endIndex - element.startIndex);
      }
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
            if (_debounce?.isActive ?? false) _debounce!.cancel();
            _debounce = Timer(const Duration(milliseconds: 200), () {
              final selectionEnd = min(selection.end - 1, text.length);
              ref.read(currentSelectionProvider.notifier).state = Selection(
                paragraphIndex: paragraphIndex,
                startIndex: selection.start,
                length: selection.end - selection.start,
                text: text.substring(selection.start, selectionEnd),
              );
            });          }
        },
      ),
    );
  }

  List<Widget> parseParagraphContent(BuildContext context, WidgetRef ref,
      dom.Element element, int paragraphIndex) {
    List<Widget> paragraphWidgets = [];
    StringBuffer textBuffer = StringBuffer();
    List<LinkInfo> links = [];

    void addTextWidget() {
      if (textBuffer.isNotEmpty &&
          !RegExp(r'^[\u200B\s]*$').hasMatch(textBuffer.toString())) {
        //debugPrint("<<${textBuffer.toString().trim()}>>");
        paragraphWidgets.add(buildHighlightedParagraph(
            context, ref, textBuffer.toString().trim(), paragraphIndex, links));
        textBuffer.clear();
        links.clear();
      }
    }

    for (var child in element.nodes) {
      if (child is dom.Text) {
        textBuffer.write(child.text);
      } else if (child is dom.Element && child.localName == 'a') {
        final linkText = child.text;
        final url = child.attributes['href'] ?? '';
        links.add(LinkInfo(
          startIndex: textBuffer.length,
          endIndex: textBuffer.length + linkText.length,
          url: url,
        ));
        textBuffer.write(linkText);
        textBuffer.write(child.text);
      } else if (child is dom.Element && child.localName == 'img') {
        addTextWidget(); // Add accumulated text before the image
        paragraphWidgets.add(buildImage(ref, child));
      } else {
        textBuffer.write(child.text);
      }
    }

    addTextWidget(); // Add any remaining text after the last image

    return paragraphWidgets;
  }

  String resolveUrl(String url) {
    return url;
  }

  Widget buildImage(WidgetRef ref, dom.Element imgElement) {
    String? src = imgElement.attributes['src'];
    src ??= imgElement.attributes['data-orig-file'];
    if (src != null &&
        src.startsWith('http') &&
        src != widget.entry.imageUrl &&
        ['png', 'jpg', 'jpeg'].any((ext) => src!.contains(ext))) {
      final imageUrl = resolveUrl(src);
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: CustomImageWidget(imageUrl),
      );
    }
    return const SizedBox.shrink();
  }

}
