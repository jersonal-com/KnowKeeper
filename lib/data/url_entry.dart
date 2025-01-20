import 'package:flutter/material.dart';
import 'package:html/parser.dart' as html_parser;

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
  final bool isEmail; // New field to indicate if it's an email
  final List<String> attachments; // New field to store attachment paths
  final List<String> tags;

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
    this.isEmail = false,
    this.attachments = const [],
    this.tags = const [],
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
      'isEmail': isEmail,
      'attachments': attachments,
      'tags': tags
    };
  }

  String domain() {
    if (isEmail) {
      // Extract domain from email address in description
      final emailParts = description.split('@');
      if (emailParts.length > 1) {
        return emailParts.last.trim();
      }
      return '';
    } else {
      // Extract domain from URL
      try {
        final uri = Uri.parse(url);
        return uri.host;
      } catch (e) {
        debugPrint('Error parsing URL: $e');
        return '';
      }
    }
  }

  int wordCount() {
    // Parse the HTML content
    final document = html_parser.parse(text);

    // Find all <p> tags
    final paragraphs = document.getElementsByTagName('p');

    // Join the text content of all paragraphs
    final allText = paragraphs.map((p) => p.text).join(' ');

    // Split the text into words and count them
    final words = allText.split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .length;

    return words;
  }

  int duration() {
    return wordCount() ~/ 300;
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
      isEmail: map['isEmail'] ?? false,
      attachments: List<String>.from(map['attachments'] ?? []),
      tags: List<String>.from(map['tags'] ?? []),
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
    bool? isEmail,
    List<String>? attachments,
    List<String>? tags

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
      isEmail: isEmail ?? this.isEmail,
      attachments: attachments ?? this.attachments,
      tags: tags ?? this.tags
    );
  }
}