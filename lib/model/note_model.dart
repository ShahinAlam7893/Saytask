class Note {
  final String title;
  final String content;
  final DateTime createdAt;

  Note({
    required this.title,
    required this.content,
    required this.createdAt,
  });

  Note copyWith({String? title, String? content}) {
    return Note(
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt,
    );
  }
}
