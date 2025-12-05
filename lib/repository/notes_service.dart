// lib/repository/notes_service.dart  (replace entire file)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:saytask/model/note_model.dart';
import 'package:saytask/repository/note_repository.dart';


class NotesProvider with ChangeNotifier {
  final NotesRepository _repo = NotesRepository();

  List<Note> _notes = [];
  bool _isLoading = false;
  String? _error;

  String _searchQuery = '';

  List<Note> get notes => List.unmodifiable(_notes);
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<Note> get filteredNotes {
    if (_searchQuery.isEmpty) return _notes;
    final query = _searchQuery.toLowerCase();
    return _notes.where((note) =>
        note.title.toLowerCase().contains(query) ||
        note.original.toLowerCase().contains(query)).toList();
  }

  Future<void> loadNotes() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _notes = await _repo.fetchNotes();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addNote(String originalText) async {
    try {
      final note = await _repo.createNote(originalText);
      _notes.insert(0, note);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateNote(Note updatedNote) async {
    try {
      final note = await _repo.updateNote(updatedNote);
      final index = _notes.indexWhere((n) => n.id == note.id);
      if (index != -1) {
        _notes[index] = note;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteNote(String id) async {
    try {
      await _repo.deleteNote(id);
      _notes.removeWhere((n) => n.id == id);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
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
    notesProvider.deleteNote(_selectedNote! as String);
    clearSelectedNote();
  }

}