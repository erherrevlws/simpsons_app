import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/character_models.dart';

class SimpsonsApiService {
  static const String _baseUrl = 'https://thesimpsonsapi.com/api/characters';

  // Obtener listado paginado: GET https://thesimpsonsapi.com/api/characters?page=1
  Future<PaginatedCharactersResponse> getCharactersPage(int page) async {
    final uri = Uri.parse('$_baseUrl?page=$page');

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return PaginatedCharactersResponse.fromJson(data);
      } else {
        throw Exception(
          'El servidor respondió con un estado inesperado (Código ${response.statusCode}).',
        );
      }
    } on SocketException {
      throw Exception(
        'No hay conexión a internet. Verifica tu red Wi-Fi o datos móviles e intenta nuevamente.',
      );
    } on HttpException {
      throw Exception('No se pudo establecer comunicación con el servidor de Los Simpson.');
    } on FormatException {
      throw Exception('La respuesta recibida del servidor tiene un formato inválido.');
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      throw Exception(
        msg.isNotEmpty
            ? msg
            : 'Ocurrió un problema de red al consultar los personajes. Intenta nuevamente.',
      );
    }
  }

  // Obtener detalle por ID: GET https://thesimpsonsapi.com/api/characters/1
  Future<SimpsonsCharacter> getCharacterById(int id) async {
    final uri = Uri.parse('$_baseUrl/$id');

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return SimpsonsCharacter.fromJson(data);
      } else {
        throw Exception('No se pudo obtener la información del personaje #$id.');
      }
    } on SocketException {
      throw Exception('Sin conexión a internet para cargar el personaje.');
    } catch (_) {
      throw Exception('Error al consultar los detalles del personaje.');
    }
  }
}