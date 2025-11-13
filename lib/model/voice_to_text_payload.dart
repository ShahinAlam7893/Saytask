class TranscriptionPayload {
  final String text;
  final String? fileName;          // optional attached file
  final int? durationMs;           // optional

  TranscriptionPayload({
    required this.text,
    this.fileName,
    this.durationMs,
  });

  Map<String, dynamic> toJson() => {
    'text': text,
    if (fileName != null) 'file_name': fileName,
    if (durationMs != null) 'duration_ms': durationMs,
  };
}