class Note {
  final String title;
  final String content;
  final String? structuredSummary;
  final DateTime createdAt;

  Note({
    required this.title,
    required this.content,
    this.structuredSummary,
    required this.createdAt,
  });

  Note copyWith({
    String? title,
    String? content,
    String? structuredSummary,
  }) {
    return Note(
      title: title ?? this.title,
      content: content ?? this.content,
      structuredSummary: structuredSummary ?? this.structuredSummary,
      createdAt: createdAt,
    );
  }
}
