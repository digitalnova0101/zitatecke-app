class Quote {
  const Quote({
    required this.id,
    required this.category,
    required this.text,
    this.author,
    this.tag,
  });

  final String id;
  final String category;
  final String text;
  final String? author;
  final String? tag;

  factory Quote.fromJson(Map<String, dynamic> json) => Quote(
        id: json['id'] as String,
        category: json['category'] as String,
        text: json['text'] as String,
        author: json['author'] as String?,
        tag: json['tag'] as String?,
      );

  /// Text jo copy / share hota hai.
  String get shareText => author == null ? text : '$text\n– $author';
}

class QuoteTag {
  const QuoteTag({required this.id, required this.label, required this.heading});

  final String id;
  final String label;
  final String heading;

  factory QuoteTag.fromJson(Map<String, dynamic> json) => QuoteTag(
        id: json['id'] as String,
        label: json['label'] as String,
        heading: json['heading'] as String,
      );
}

class QuoteCategory {
  const QuoteCategory({
    required this.id,
    required this.title,
    required this.emoji,
    required this.subtitle,
    required this.heading,
    required this.styles,
    this.tags = const [],
  });

  final String id;
  final String title;
  final String emoji;
  final String subtitle;
  final String heading;
  final List<String> styles;
  final List<QuoteTag> tags;

  factory QuoteCategory.fromJson(Map<String, dynamic> json) => QuoteCategory(
        id: json['id'] as String,
        title: json['title'] as String,
        emoji: json['emoji'] as String,
        subtitle: json['subtitle'] as String,
        heading: json['heading'] as String,
        styles: (json['styles'] as List).cast<String>(),
        tags: ((json['tags'] as List?) ?? const [])
            .map((e) => QuoteTag.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
