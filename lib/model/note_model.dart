
class Summarized {
  final String summary;
  final List<String> points;

  Summarized({required this.summary, required this.points});

  factory Summarized.fromJson(Map<String, dynamic> json) {
    return Summarized(
      summary: json['summary'] ?? '',
      points: List<String>.from(json['points'] ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
    "summary": summary,
    "points": points,
  };
}

class Note {
  final String id;
  final String title;
  final String original;
  final Summarized summarized;
  final DateTime createdAt;

  Note({
    required this.id,
    required this.title,
    required this.original,
    required this.summarized,
    required this.createdAt,
  });

  String get structuredSummary {
    if (summarized.points.isEmpty) return "No key points extracted yet.";
    return summarized.points.map((p) => "• $p").join('\n');
  }

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'] as String,
      title: (json['title'] as String?)?.trim().isEmpty == true ? "Untitled Note" : (json['title'] ?? "Untitled Note"),
      original: json['original'] ?? '',
      summarized: Summarized.fromJson(json['summarized'] ?? {}),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    "title": title,
    "original": original,
    "summarized": summarized.toJson(),
  };

  Note copyWith({
    String? title,
    String? original,
    Summarized? summarized,
  }) {
    return Note(
      id: id,
      title: title ?? this.title,
      original: original ?? this.original,
      summarized: summarized ?? this.summarized,
      createdAt: createdAt,
    );
  }
}