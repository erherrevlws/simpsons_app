import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/character_models.dart';
import '../services/simpsons_api_service.dart';

class CharactersProvider extends ChangeNotifier {
  final SimpsonsApiService _apiService = SimpsonsApiService();
  
  List<SimpsonsCharacter> _characters = []; // Personajes de la página actual
  final Map<int, SimpsonsCharacter> _cache = {}; // Caché general para favoritos
  Set<int> _favoriteIds = {};
  
  int? _currentUserId;
  String? _currentUsername;
  String? _currentDisplayName;
  
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasNext = false;
  bool _hasPrev = false;
  bool _isLoading = false;
  bool _isLoadingFavorites = false;
  String? _errorMessage;
  String _searchQuery = '';

  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  bool get isLoading => _isLoading;
  bool get isLoadingFavorites => _isLoadingFavorites;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  bool get isLoggedIn => _currentUsername != null;
  String get currentDisplayName => _currentDisplayName ?? '';

  // La paginación siempre está disponible
  bool get canGoPrev => !_isLoading && (_currentPage > 1 || _hasPrev);
  bool get canGoNext => !_isLoading && (_currentPage < _totalPages || _hasNext);

  String get _prefsKey => 'favs_${_currentUsername ?? 'guest'}';

  // REQUERIMIENTO ORIGINAL: Filtrado local sin distinguir mayúsculas
  List<SimpsonsCharacter> get filteredCharacters {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return _characters;
    
    return _characters.where((c) {
      return c.name.toLowerCase().contains(query);
    }).toList();
  }

  List<SimpsonsCharacter> get favoriteCharacters {
    if (!isLoggedIn) return [];
    return _favoriteIds.where((id) => _cache.containsKey(id)).map((id) => _cache[id]!).toList();
  }

  CharactersProvider() { _init(); }

  Future<void> _init() async {
    await _restoreSession();
    await fetchCharacters(page: 1);
  }

  Future<void> _restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUser = prefs.getString('username');
    if (savedUser != null) {
      _currentUserId = prefs.getInt('user_id');
      _currentUsername = savedUser;
      _currentDisplayName = prefs.getString('display_name') ?? savedUser;
      await loadFavoritesFromPrefs();
    }
  }

  Future<void> login(String user, String pass) async {
    final data = await _apiService.loginUser(user, pass);
    await _saveSession(data);
  }

  Future<void> register({required String nombre, required String username, required String email, required String password}) async {
    final data = await _apiService.registerUser(nombre: nombre, username: username, email: email, password: password);
    await _saveSession(data);
  }

  Future<void> _saveSession(Map<String, dynamic> data) async {
    _currentUserId = int.tryParse(data['id'].toString());
    _currentUsername = data['username'].toString();
    _currentDisplayName = data['nombre'].toString();

    final prefs = await SharedPreferences.getInstance();
    if (_currentUserId != null) await prefs.setInt('user_id', _currentUserId!);
    await prefs.setString('username', _currentUsername!);
    await prefs.setString('display_name', _currentDisplayName!);

    await loadFavoritesFromPrefs();

    if (data['favorite_ids'] is List) {
      for (final item in data['favorite_ids']) {
        final id = int.tryParse(item.toString());
        if (id != null) _favoriteIds.add(id);
      }
      await prefs.setStringList(_prefsKey, _favoriteIds.map((e) => e.toString()).toList());
    }
    notifyListeners();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    await prefs.remove('username');
    await prefs.remove('display_name');
    _currentUserId = null; _currentUsername = null; _currentDisplayName = null;
    _favoriteIds.clear();
    notifyListeners();
  }

  Future<void> fetchCharacters({int? page}) async {
    final targetPage = page ?? _currentPage;
    _isLoading = true; _errorMessage = null; notifyListeners();
    try {
      final res = await _apiService.getCharactersPage(targetPage);
      _characters = res.results;
      _currentPage = targetPage;
      _totalPages = res.pages > 0 ? res.pages : 1;
      _hasNext = res.next != null; _hasPrev = res.prev != null;
      for (var c in _characters) _cache[c.id] = c;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false; notifyListeners();
    }
  }

  void nextPage() { if (canGoNext) fetchCharacters(page: _currentPage + 1); }
  void prevPage() { if (canGoPrev) fetchCharacters(page: _currentPage - 1); }

  void updateSearchQuery(String q) {
    _searchQuery = q;
    notifyListeners();
  }

  Future<void> loadFavoritesFromPrefs() async {
    if (!isLoggedIn) { _favoriteIds = {}; notifyListeners(); return; }
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_prefsKey) ?? [];
    _favoriteIds = saved.map((e) => int.tryParse(e)).whereType<int>().toSet();
    notifyListeners();
  }

  Future<void> toggleFavorite(SimpsonsCharacter character) async {
    if (!isLoggedIn) return;
    _cache[character.id] = character;
    final bool isFav;
    if (_favoriteIds.contains(character.id)) { _favoriteIds.remove(character.id); isFav = false; } 
    else { _favoriteIds.add(character.id); isFav = true; }
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, _favoriteIds.map((e) => e.toString()).toList());
    
    if (_currentUserId != null) {
      await _apiService.syncFavoriteInDatabase(userId: _currentUserId!, characterId: character.id, isFavorite: isFav);
    }
  }

  bool isFavorite(int id) => isLoggedIn && _favoriteIds.contains(id);

  Future<void> loadMissingFavorites() async {
    if (!isLoggedIn) return;
    final missing = _favoriteIds.where((id) => !_cache.containsKey(id)).toList();
    if (missing.isEmpty) return;
    _isLoadingFavorites = true; notifyListeners();
    for (final id in missing) {
      try { _cache[id] = await _apiService.getCharacterById(id); } catch (_) {}
    }
    _isLoadingFavorites = false; notifyListeners();
  }
}