import 'package:collection/collection.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart';

import 'paragraph.dart';

class ContentProcessor {
  final Set<String> _blacklistedTags = {
    'header',
    'footer',
    'script',
    'noscript',
    'style',
    'nav',
    'button',
    'aside',
  };
  final Map<String, Set<String>> _blacklistedAttributes = {
    'class': {
      'sidebar',
      'right-sidebar',
      'post-footer',
      'post-header',
      'footer-widget',
      'hide-on-button',
      'highlight-and-share-wrapper',
      'related-posts',
      'adsbygoogle',
      'has_twitter',
      'social-icons'
      'highlight-and-share-wrapper',
      'comments',
      'foot section'
    },
    'id': {
      'sidebar',
      'right-sidebar',
      'subscription-nudge',
      'comments',
      'right-sidebar-inner',
      'related-posts',
      'adsbygoogle',
      'has-mastodon-prompt',
      'cssnav',
      'PageList1',
    }
  };

  List<Paragraph> process(String html) {
    final document = parse(html);
    _removeBlacklistedElements(document.body!);
    final paragraphs = _parseElements(document.body!.nodes);

    return paragraphs;
  }

  List<Paragraph> _parseElements(List<dom.Node> nodes) {
    final paragraphs = <Paragraph>[];

    for (var node in nodes) {
      if (node is dom.Element) {
        if (node.nodes.length > 1 || node.nodes.firstWhereOrNull((n) => n is! dom.Text) != null) {
          paragraphs.addAll(_parseElements(node.nodes));
        } else if (node.localName == 'img') {
          final url = node.attributes['src'] ?? '';
          final features = <SpecialFeature>[
            ImageFeature(start:0, end: 0, url: url),
          ];

          paragraphs.add(Paragraph(
            text: '',
            features: features,
          ));
        }  else if (node.text.trim().isNotEmpty) {
          final text = node.text;
          final features = _extractFeatures(node);

          paragraphs.add(Paragraph(text: text, features: features));
        }
      } else if (node is dom.Text) {
        if (node.text.trim().isNotEmpty) {
          final text = node.text;
          final features = <SpecialFeature>[];

          paragraphs.add(Paragraph(text: text, features: features));
        }
        // Check if the node is an image

      }
    }

    return paragraphs;
  }

  void _removeBlacklistedElements(dom.Element element) {
    for (var child in element.nodes.toList()) {
      if (child is dom.Element) {
        if (_isBlacklisted(child)) {
          element.nodes.remove(child);
        } else {
          _removeBlacklistedElements(child);
        }
      }
    }
  }

  bool _isBlacklisted(dom.Element element) {

    if (_blacklistedTags.contains(element.localName)) {
      return true;
    }

    for (var attribute in _blacklistedAttributes.entries) {
      if (element.attributes[attribute.key] != null &&
          attribute.value.contains(element.attributes[attribute.key])) {
        return true;
      }
    }

    return false;
  }

  List<SpecialFeature> _extractFeatures(dom.Node element) {
    final features = <SpecialFeature>[];


    if (element is dom.Element) {
      // Extract links
      if (element.localName == 'a') {
        final link = element;
        final start = element.text.indexOf(link.text);
        final end = start + link.text.length;
        final url = link.attributes['href'] ?? '';

        features.add(LinkFeature(start: start, end: end, url: url));
      }

      // Extract bold text
      element.getElementsByTagName('b').forEach((bold) {
        final start = element.text.indexOf(bold.text);
        final end = start + bold.text.length;

        features.add(BoldFeature(start: start, end: end));
      });

      // Extract italic text
      element.getElementsByTagName('i').forEach((italic) {
        final start = element.text.indexOf(italic.text);
        final end = start + italic.text.length;

        // Add ItalicFeature class to the SpecialFeature hierarchy
        features.add(ItalicFeature(start: start, end: end));
      });

      // Extract all headings
      for (var i = 1; i <= 6; i++) {
        if (element.localName == 'h$i') {
          final heading = element;
          final start = element.text.indexOf(heading.text);
          final end = start + heading.text.length;

          features.add(HeadingFeature(start: start, end: end, level: i));
        }
      }

      // Extract images
      if (element.localName == 'img') {
        final url = element.attributes['src'] ?? '';

        features.add(ImageFeature(start: 0, end: 0, url: url));
      }
    }

    return features;
  }
}
