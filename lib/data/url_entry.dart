class UrlEntry {
  final String title;
  final String source;
  final DateTime date;
  final String? imageUrl;
  final String text;

  UrlEntry({
    required this.title,
    required this.source,
    required this.date,
    this.imageUrl,
    required this.text,
  });
}