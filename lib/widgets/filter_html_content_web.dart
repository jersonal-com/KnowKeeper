import 'package:html/dom.dart';

final ignoreElementsDivId = [
  'comments', 'right-sidebar-inner', 'related-posts', 'adsbygoogle', 'sidebar',
  'subscription-nudge',
];

final ignoreElementsClass = [
  'right-sidebar'
];

Document filterHtmlContent(Document document) {
  for (var elementId in ignoreElementsDivId) {
    final Element? element = document.getElementById(elementId);
    if (element != null) {
      element.remove();
    }
  }

  for (var elementClass in ignoreElementsClass) {
    for (var element in document.getElementsByClassName(elementClass)) {
      element.remove();
    }
  }

  return document;
}