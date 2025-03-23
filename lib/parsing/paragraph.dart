class Paragraph {
  final String text;
  final List<SpecialFeature> features;

  Paragraph({required this.text, this.features = const []});
}

abstract class SpecialFeature {
  final int start;
  final int end;

  SpecialFeature({required this.start, required this.end});
}

class LinkFeature extends SpecialFeature {
  final String url;

  LinkFeature({required super.start, required super.end, required this.url});
}

class ImageFeature extends SpecialFeature {
  final String url;

  ImageFeature({required super.start, required super.end, required this.url});
}

class HighlightFeature extends SpecialFeature {
  final String highlightText;

  HighlightFeature({required super.start, required super.end, required this.highlightText});
}

class BoldFeature extends SpecialFeature {
  BoldFeature({required super.start, required super.end});
}

class ItalicFeature extends SpecialFeature {
  ItalicFeature({required super.start, required super.end});
}

class HeadingFeature extends SpecialFeature {
  final int level;

  HeadingFeature({required super.start, required super.end, required this.level});
}


