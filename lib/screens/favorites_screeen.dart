import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/characters_providers.dart';
import 'detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});
  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<CharactersProvider>().loadMissingFavorites());
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CharactersProvider>();
    final favorites = provider.favoriteCharacters;

    return Scaffold(
      appBar: AppBar(title: const Text('Favoritos')),
      body: provider.isLoadingFavorites
          ? const Center(child: CircularProgressIndicator())
          : favorites.isEmpty
              ? const Center(child: Text('No tienes personajes favoritos.'))
              : ListView.builder(
                  itemCount: favorites.length,
                  itemBuilder: (context, index) {
                    final character = favorites[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        leading: character.imageUrl.isNotEmpty ? Image.network(character.imageUrl, width: 50, height: 50, errorBuilder: (_,__,___)=>const Icon(Icons.broken_image)) : const Icon(Icons.person),
                        title: Text(character.name),
                        subtitle: Text(character.occupation),
                        trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => provider.toggleFavorite(character)),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailScreen(character: character))),
                      ),
                    );
                  },
                ),
    );
  }
}