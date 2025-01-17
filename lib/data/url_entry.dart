class UrlEntry {
  int? id;
  final String url;
  final String title;
  final String description;
  final String source;
  final DateTime date;
  final String imageUrl;
  final String text;
  bool archived;

  UrlEntry({
    this.id,
    required this.url,
    required this.title,
    required this.description,
    required this.source,
    required this.date,
    required this.imageUrl,
    required this.text,
    this.archived = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'url': url,
      'title': title,
      'description': description,
      'source': source,
      'date': date.toIso8601String(),
      'imageUrl': imageUrl,
      'text': text,
      'archived': archived,
    };
  }

  static UrlEntry fromMap(Map<String, dynamic> map) {
    return UrlEntry(
      url: map['url'],
      title: map['title'],
      description: map['description'],
      source: map['source'],
      date: DateTime.parse(map['date']),
      imageUrl: map['imageUrl'],
      text: map['text'],
      archived: map['archived'] ?? false,
    );
  }
}