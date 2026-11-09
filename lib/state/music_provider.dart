import 'dart:async';
import 'package:flutter/material.dart';
import '../core/models/song_model.dart';
import '../core/network/saavn_api_service.dart';

class MusicProvider extends ChangeNotifier {
  List<SongModel> _searchResults = [];
  List<String> _liveSuggestions = [];
  bool _isSearching = false;
  String _currentQuery = '';

  List<SongModel> get searchResults => _searchResults;
  List<String> get liveSuggestions => _liveSuggestions;
  bool get isSearching => _isSearching;
  String get currentQuery => _currentQuery;

  /// Real-time live search suggestions with debounced query
  Future<void> searchLiveSuggestions(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      clearSearch();
      return;
    }

    _currentQuery = trimmed;
    _isSearching = true;
    notifyListeners();

    try {
      final results = await SaavnApiService.searchSongs(trimmed);
      _searchResults = results;

      // Generate contextual live suggestions from title and artist names
      final Set<String> suggestionSet = {};
      for (final song in results.take(6)) {
        suggestionSet.add(song.title);
        suggestionSet.add(song.artist);
      }
      _liveSuggestions = suggestionSet.toList();
    } catch (_) {
      _searchResults = [];
      _liveSuggestions = [];
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  void clearSearch() {
    _currentQuery = '';
    _searchResults = [];
    _liveSuggestions = [];
    _isSearching = false;
    notifyListeners();
  }
}
