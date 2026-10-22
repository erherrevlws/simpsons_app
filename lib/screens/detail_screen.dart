import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/character_models.dart';
import '../providers/characters_providers.dart';

class DetailScreen extends StatelessWidget {
  final SimpsonsCharacter character;

  const DetailScreen({super.key, required this.character});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CharactersProvider>();
    final isFav = provider.isFavorite(character.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(character.name),
        actions: [
          IconButton(
            icon: Icon(
              isFav ? Icons.favorite : Icons.favorite_border,
              color: isFav ? Colors.red : null,
            ),
            onPressed: () => provider.toggleFavorite(character),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: character.imageUrl.isNotEmpty
                  ? Image.network(
                      character.imageUrl,
                      height: 200,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.broken_image, size: 100),
                    )
                  : const Icon(Icons.person, size: 100),
            ),
            const SizedBox(height: 16),
            Text(
              character.name,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            ListTile(
              title: const Text('Estado'),
              subtitle: Text(character.status),
            ),
            ListTile(
              title: const Text('Ocupación'),
              subtitle: Text(character.occupation),
            ),
            ListTile(
              title: const Text('Género'),
              subtitle: Text(character.gender),
            ),
            ListTile(
              title: const Text('Edad'),
              subtitle: Text(character.age),
            ),
            ListTile(
              title: const Text('Frase'),
              subtitle: Text(character.mainPhrase), 
            ),
          ],
        ),
      ),
    );
  }
}