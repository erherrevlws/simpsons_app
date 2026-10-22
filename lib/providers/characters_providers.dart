import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/character_models.dart';
import '../services/simpsons_api_service.dart';

class CharactersProvider extends ChangeNotifier {
  final SimpsonsApiService _apiService = SimpsonsApiService();
  static const String _favoritesKey = 'favorite_ids';

  List<SimpsonsCharacter> _characters = [];
  final Map<int, SimpsonsCharacter> _cache = {};

  Set<int> _favoriteIds = {};
  bool _isLoadingFavorites = false;

  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasNext = false;
  bool _hasPrev = false;

  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';

  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  bool get isLoading => _isLoading;
  bool get isLoadingFavorites => _isLoadingFavorites;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;

  bool get canGoPrev => !_isLoading && (_currentPage > 1 || _hasPrev);
  bool get canGoNext => !_isLoading && (_currentPage < _totalPages || _hasNext);

  // Filtra por nombre en la página actual sin distinguir mayúsculas/minúsculas
  List<SimpsonsCharacter> get filteredCharacters {
    if (_searchQuery.trim().isEmpty) {
      return _characters;
    }
    final query = _searchQuery.trim().toLowerCase();
    return _characters
        .where((c) => c.name.toLowerCase().contains(query))
        .toList();
  }

  // Devuelve la lista de objetos favoritos guardados
  List<SimpsonsCharacter> get favoriteCharacters {
    return _favoriteIds
        .where((id) => _cache.containsKey(id))
        .map((id) => _cache[id]!)
        .toList();
  }

  CharactersProvider() {
    _init();
  }

  Future<void> _init() async {
    await loadFavoritesFromPrefs();
    await fetchCharacters(page: 1);
  }

  Future<void> fetchCharacters({int? page}) async {
    final targetPage = page ?? _currentPage;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.getCharactersPage(targetPage);
      _characters = response.results;
      _currentPage = targetPage;
      _totalPages = response.pages > 0 ? response.pages : 1;
      _hasNext = response.next != null && response.next!.isNotEmpty;
      _hasPrev = response.prev != null && response.prev!.isNotEmpty;

      for (var c in _characters) {
        _cache[c.id] = c;
      }
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void nextPage() {
    if (canGoNext) {
      fetchCharacters(page: _currentPage + 1);
    }
  }

  void prevPage() {
    if (canGoPrev) {
      fetchCharacters(page: _currentPage - 1);
    }
  }

  void updateSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> loadFavoritesFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_favoritesKey) ?? [];
    _favoriteIds = saved.map((e) => int.tryParse(e)).whereType<int>().toSet();
    notifyListeners();
  }

  Future<void> toggleFavorite(SimpsonsCharacter character) async {
    _cache[character.id] = character;

    if (_favoriteIds.contains(character.id)) {
      _favoriteIds.remove(character.id);
    } else {
      _favoriteIds.add(character.id);
    }
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final listToSave = _favoriteIds.map((id) => id.toString()).toList();
    await prefs.setStringList(_favoritesKey, listToSave);
  }

  bool isFavorite(int id) {
    return _favoriteIds.contains(id);
  }

  // Si se reinició la app, descarga por ID los favoritos que no estén en la página 1
  Future<void> loadMissingFavorites() async {
    final missing = _favoriteIds.where((id) => !_cache.containsKey(id)).toList();
    if (missing.isEmpty) return;

    _isLoadingFavorites = true;
    notifyListeners();

    for (final id in missing) {
      try {
        final character = await _apiService.getCharacterById(id);
        _cache[id] = character;
      } catch (_) {}
    }

    _isLoadingFavorites = false;
    notifyListeners();
  }
}