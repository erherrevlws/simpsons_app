import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/character_models.dart';
import '../providers/characters_providers.dart';
import 'detail_screen.dart';
import 'favorites_screeen.dart';
import 'login_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _handleFavoriteTap(BuildContext context, CharactersProvider provider, SimpsonsCharacter character) async {
    if (!provider.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Inicia sesión para guardar favoritos.')));
      final loggedIn = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      if (loggedIn == true && context.mounted) provider.toggleFavorite(character);
    } else {
      provider.toggleFavorite(character);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CharactersProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(provider.isLoggedIn ? 'Hola, ${provider.currentDisplayName}' : 'Catálogo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite),
            onPressed: () async {
              if (!provider.isLoggedIn) {
                final ok = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                if (ok != true || !context.mounted) return;
              }
              Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritesScreen()));
            },
          ),
          IconButton(
            icon: Icon(provider.isLoggedIn ? Icons.logout : Icons.login),
            onPressed: () {
              if (provider.isLoggedIn) provider.logout();
              else Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  onChanged: provider.updateSearchQuery,
                  decoration: const InputDecoration(
                    labelText: 'Buscar personaje por nombre',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '* La búsqueda filtra únicamente en la página actual (Página ${provider.currentPage}).',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : provider.errorMessage != null
                    ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(provider.errorMessage!), ElevatedButton(onPressed: provider.fetchCharacters, child: const Text('Reintentar'))]))
                    : provider.filteredCharacters.isEmpty
                        ? Center(child: Text('No hay coincidencias en la página ${provider.currentPage}.'))
                        : ListView.builder(
                            itemCount: provider.filteredCharacters.length,
                            itemBuilder: (c, i) {
                              final char = provider.filteredCharacters[i];
                              final isFav = provider.isFavorite(char.id);
                              return Card(
                                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                child: ListTile(
                                  leading: char.imageUrl.isNotEmpty ? Image.network(char.imageUrl, width: 50, height: 50, errorBuilder: (_,__,___)=>const Icon(Icons.broken_image)) : const Icon(Icons.person),
                                  title: Text(char.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text('Estado: ${char.status}\nOcupación: ${char.occupation}'),
                                  isThreeLine: true,
                                  trailing: IconButton(
                                    icon: Icon(isFav ? Icons.favorite : Icons.favorite_border, color: isFav ? Colors.red : null),
                                    onPressed: () => _handleFavoriteTap(context, provider, char),
                                  ),
                                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailScreen(character: char))),
                                ),
                              );
                            },
                          ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(onPressed: provider.canGoPrev ? provider.prevPage : null, child: const Icon(Icons.arrow_back_ios, size: 16)),
                Text('Página ${provider.currentPage} de ${provider.totalPages}', style: const TextStyle(fontWeight: FontWeight.bold)),
                ElevatedButton(onPressed: provider.canGoNext ? provider.nextPage : null, child: const Icon(Icons.arrow_forward_ios, size: 16)),
              ],
            ),
          )
        ],
      ),
    );
  }
}