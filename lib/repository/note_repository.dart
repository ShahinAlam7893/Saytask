// lib/repository/notes_repository.dart

import 'dart:async';
import 'dart:convert';
import 'dart:core';
import 'package:http/http.dart' as http;
import 'package:saytask/model/note_model.dart';
import 'package:saytask/service/local_storage_service.dart';
import 'package:saytask/core/api_endpoints.dart';

class NotesRepository {
  static const String baseUrl = Urls.baseUrl; // your existing Urls class

  Future<String?> _getToken() async {
    await LocalStorageService.init();
    return LocalStorageService.token;
  }

  Future<List<Note>> fetchNotes() async {
    final token = await _getToken();
    if (token == null) throw Exception("Not authenticated");

    final response = await http.get(
      Uri.parse('$baseUrl/actions/notes/'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List notesJson = data['notes'] ?? [];
      return notesJson.map((json) => Note.fromJson(json)).toList();
    } else {
      throw Exception("Failed to load notes");
    }
  }

  Future<Note> createNote(String originalText) async {
    final token = await _getToken();
    if (token == null) throw Exception("Not authenticated");

    final response = await http.post(
      Uri.parse('$baseUrl/actions/notes/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        "title": "Note from voice",
        "original": originalText,
        "summarized": {"summary": "", "points": []}
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return Note.fromJson(json.decode(response.body));
    } else {
      throw Exception("Failed to create note: ${response.body}");
    }
  }

  Future<Note> updateNote(Note note) async {
    final token = await _getToken();
    if (token == null) throw Exception("Not authenticated");

    final response = await http.put(
      Uri.parse('$baseUrl/actions/notes/${note.id}/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(note.toJson()),
    );

    if (response.statusCode == 200) {
      return Note.fromJson(json.decode(response.body));
    } else {
      throw Exception("Failed to update note");
    }
  }

  Future<void> deleteNote(String id) async {
    final token = await _getToken();
    if (token == null) throw Exception("Not authenticated");

    final response = await http.delete(
      Uri.parse('$baseUrl/actions/notes/$id/'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception("Failed to delete note");
    }
  }
}