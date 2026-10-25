class SimpsonsCharacter {
  final int id;
  final String name;
  final String status;
  final String occupation;
  final String gender;
  final String age;
  final String portraitPath;
  final List<String> phrases;

  SimpsonsCharacter({
    required this.id, required this.name, required this.status,
    required this.occupation, required this.gender, required this.age,
    required this.portraitPath, required this.phrases,
  });

  String get imageUrl {
    if (portraitPath.isEmpty) return '';
    if (portraitPath.startsWith('http')) return portraitPath;
    final cleanPath = portraitPath.startsWith('/') ? portraitPath : '/$portraitPath';
    return 'https://cdn.thesimpsonsapi.com/500$cleanPath';
  }

  String get mainPhrase => phrases.isEmpty ? 'Sin frase célebre registrada' : '"${phrases.first}"';

  factory SimpsonsCharacter.fromJson(Map<String, dynamic> json) {
    List<String> parsedPhrases = [];
    if (json['phrases'] != null && json['phrases'] is List) {
      parsedPhrases = (json['phrases'] as List)
          .where((item) => item != null && item.toString().trim().isNotEmpty)
          .map((item) => item.toString().trim()).toList();
    }

    String parseField(dynamic value, String fallback) {
      if (value == null) return fallback;
      final text = value.toString().trim();
      return text.isEmpty ? fallback : text;
    }

    return SimpsonsCharacter(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: parseField(json['name'], 'Nombre desconocido'),
      status: parseField(json['status'], 'Desconocido'),
      occupation: parseField(json['occupation'], 'Sin ocupación registrada'),
      gender: parseField(json['gender'], 'No especificado'),
      age: parseField(json['age'], 'Desconocida'),
      portraitPath: json['portrait_path']?.toString().trim() ?? '',
      phrases: parsedPhrases,
    );
  }
}

class PaginatedCharactersResponse {
  final int count;
  final int pages;
  final String? next;
  final String? prev;
  final List<SimpsonsCharacter> results;

  PaginatedCharactersResponse({
    required this.count, required this.pages, this.next, this.prev, required this.results,
  });

  factory PaginatedCharactersResponse.fromJson(Map<String, dynamic> json) {
    final meta = (json['info'] is Map<String, dynamic>) ? json['info'] as Map<String, dynamic> : json;
    final rawList = (json['results'] as List?) ?? [];
    return PaginatedCharactersResponse(
      count: meta['count'] is int ? meta['count'] : rawList.length,
      pages: meta['pages'] is int ? meta['pages'] : 1,
      next: meta['next']?.toString(), prev: meta['prev']?.toString(),
      results: rawList.whereType<Map<String, dynamic>>().map((item) => SimpsonsCharacter.fromJson(item)).toList(),
    );
  }
}