class Highlight {
  final String url;
  final int paragraphIndex;
  final int startIndex;
  final int length;
  final String text;

  Highlight({
    required this.url,
    required this.paragraphIndex,
    required this.startIndex,
    required this.length,
    required this.text
  });

  Map<String, dynamic> toMap() {
    return {
      'url': url,
      'paragraphIndex': paragraphIndex,
      'startIndex': startIndex,
      'length': length,
      'text': text,
    };
  }

  static Highlight fromMap(Map<String, dynamic> map) {
    return Highlight(
      url: map['url'],
      paragraphIndex: map['paragraphIndex'],
      startIndex: map['startIndex'],
      length: map['length'],
      text: map['text'],
    );
  }
}