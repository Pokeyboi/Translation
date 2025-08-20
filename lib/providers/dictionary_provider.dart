import 'package:flutter/foundation.dart';
import '../models/dictionary_entry.dart';
import '../services/database_service.dart';

class DictionaryProvider extends ChangeNotifier {
  List<DictionaryEntry> _entries = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _selectedLanguage = 'zopau';

  List<DictionaryEntry> get entries => _entries;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  String get selectedLanguage => _selectedLanguage;

  List<DictionaryEntry> get filteredEntries {
    return _entries.where((entry) {
      final matchesSearch = _searchQuery.isEmpty ||
          entry.english.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          entry.translation.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (entry.phoneticHelper?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      
      final matchesCategory = _selectedCategory == 'All' ||
          entry.category == _selectedCategory;
          
      return matchesSearch && matchesCategory;
    }).toList();
  }

  Future<void> loadEntries() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _entries = await DatabaseService.getDictionaryEntries(languageCode: _selectedLanguage);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSelectedCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setSelectedLanguage(String language) {
    _selectedLanguage = language;
    loadEntries();
  }

  Future<void> addEntry(DictionaryEntry entry) async {
    try {
      await DatabaseService.saveDictionaryEntry(entry);
      await loadEntries();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateEntry(DictionaryEntry entry) async {
    try {
      await DatabaseService.updateDictionaryEntry(entry);
      await loadEntries();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteEntry(String id) async {
    try {
      await DatabaseService.delete('dictionary_entries', 'id = ?', [id]);
      await loadEntries();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> importEntries(List<DictionaryEntry> entries) async {
    try {
      await DatabaseService.importDictionaryEntries(entries);
      await loadEntries();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }


  Future<void> addEntries(List<DictionaryEntry> entries) async {
    try {
      for (final entry in entries) {
        await DatabaseService.saveDictionaryEntry(entry);
      }
      await loadEntries();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}