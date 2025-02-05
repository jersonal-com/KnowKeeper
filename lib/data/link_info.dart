import 'paragraph_element.dart';

class LinkInfo implements ParagraphElement {
  @override
  final int startIndex;
  @override
  final int endIndex;
  final String url;

  LinkInfo({required this.startIndex, required this.endIndex, required this.url});
}