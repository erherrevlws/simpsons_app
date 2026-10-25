import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/character_models.dart';

class SimpsonsApiService {
  static const String _baseUrl = 'https://thesimpsonsapi.com/api/characters';

  // FastAPI corre en el puerto 8000
  static String get _fastApiBaseUrl {
    if (!kIsWeb && Platform.isAndroid) return 'http://10.0.2.2:8000/api';
    return 'http://localhost:8000/api';
  }

  Future<PaginatedCharactersResponse> getCharactersPage(int page) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl?page=$page')).timeout(const Duration(seconds: 12));
      if (response.statusCode == 200) {
        return PaginatedCharactersResponse.fromJson(json.decode(utf8.decode(response.bodyBytes)));
      }
      throw Exception('Código inesperado: ${response.statusCode}');
    } on SocketException {
      throw Exception('Sin conexión a internet. Revisa tu red.');
    } catch (e) {
      throw Exception('Error al cargar personajes. Intenta nuevamente.');
    }
  }

  Future<SimpsonsCharacter> getCharacterById(int id) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/$id')).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return SimpsonsCharacter.fromJson(json.decode(utf8.decode(response.bodyBytes)));
      }
      throw Exception('Error al cargar detalle');
    } catch (_) {
      throw Exception('Error de conexión.');
    }
  }

  Future<Map<String, dynamic>> loginUser(String userOrEmail, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_fastApiBaseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'user_or_email': userOrEmail.trim(), 'password': password}),
      ).timeout(const Duration(seconds: 8));
      
      final data = json.decode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200) return data;
      throw Exception(data['detail'] ?? 'Credenciales incorrectas');
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<Map<String, dynamic>> registerUser({
    required String nombre, required String username, required String email, required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_fastApiBaseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'nombre': nombre.trim(), 'username': username.trim(), 'email': email.trim(), 'password': password}),
      ).timeout(const Duration(seconds: 8));
      
      final data = json.decode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 201 || response.statusCode == 200) return data;
      throw Exception(data['detail'] ?? 'Error al registrar.');
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> syncFavoriteInDatabase({required int userId, required int characterId, required bool isFavorite}) async {
    try {
      await http.post(
        Uri.parse('$_fastApiBaseUrl/toggle_favorite'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'user_id': userId, 'character_id': characterId, 'is_favorite': isFavorite}),
      ).timeout(const Duration(seconds: 5));
    } catch (_) {} 
  }
}