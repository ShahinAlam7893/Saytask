import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../model/note_model.dart';

class NotesProvider with ChangeNotifier {
  final List<Note> _notes = [
    Note(
      title: "Mobile App Design Ideas",
      content: "Create a minimalist interface with voice-first interaction. Focus on accessibility and ease...",
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    Note(
      title: "Weekend Project",
      content: "Build a small garden in the backyard. Research native plants and...",
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    Note(
      title: "Book Recommendations",
      content: "Atomic Habits, The Design of Everyday Things, Deep Work - all great books for...",
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
  ];
  String _searchQuery = '';

  List<Note> get notes => List.unmodifiable(_notes);

  List<Note> get filteredNotes {
    if (_searchQuery.isEmpty) return _notes;
    return _notes.where((note) =>
    note.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        note.content.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  void addNote(Note note) {
    _notes.insert(0, note);
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void updateNote(Note updatedNote) {
    final index = _notes.indexWhere((note) => note.createdAt == updatedNote.createdAt);
    if (index != -1) {
      _notes[index] = updatedNote;
      notifyListeners();
    }
  }

  void deleteNote(Note note) {
    _notes.remove(note);
    notifyListeners();
  }

}


class NoteDetailsViewModel with ChangeNotifier {
  Note? _selectedNote;

  Note? get selectedNote => _selectedNote;

  void setSelectedNote(Note note) {
    _selectedNote = note;
    notifyListeners();
  }

  void clearSelectedNote() {
    _selectedNote = null;
    notifyListeners();
  }

  void deleteSelectedNote(BuildContext context) {
    if (_selectedNote == null) return;
    final notesProvider = context.read<NotesProvider>();
    notesProvider.deleteNote(_selectedNote!);
    clearSelectedNote();
  }

}