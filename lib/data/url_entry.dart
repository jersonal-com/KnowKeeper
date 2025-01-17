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
  bool deleted;

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
    this.deleted = false,
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
      'deleted': deleted,
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
      deleted: map['deleted'] ?? false,
    );
  }

  /// Creates a copy of this UrlEntry with the given values.
  UrlEntry copyWith({
    int? id,
    String? url,
    String? title,
    String? description,
    String? source,
    DateTime? date,
    String? imageUrl,
    String? text,
    bool? archived,
    bool? deleted,
  }) {
    return UrlEntry(
      id: id ?? this.id,
      url: url ?? this.url,
      title: title ?? this.title,
      description: description ?? this.description,
      source: source ?? this.source,
      date: date ?? this.date,
      imageUrl: imageUrl ?? this.imageUrl,
      text: text ?? this.text,
      archived: archived ?? this.archived,
      deleted: deleted ?? this.deleted,
    );
  }
}