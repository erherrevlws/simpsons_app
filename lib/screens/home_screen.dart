import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/characters_providers.dart';
import 'detail_screen.dart';
import 'favorites_screeen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CharactersProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo Los Simpson'),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite),
            tooltip: 'Ver Favoritos',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FavoritesScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  onChanged: provider.updateSearchQuery,
                  decoration: const InputDecoration(
                    labelText: 'Buscar por nombre',
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

          // Contenido principal 
          Expanded(
            child: _buildContent(context, provider),
          ),

          // RF-04: Controles de paginación Anterior y Siguiente
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: provider.canGoPrev ? provider.prevPage : null,
                  child: const Text('Anterior'),
                ),
                Text(
                  'Página ${provider.currentPage} de ${provider.totalPages}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                ElevatedButton(
                  onPressed: provider.canGoNext ? provider.nextPage : null,
                  child: const Text('Siguiente'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, CharactersProvider provider) {
    // 1. Indicador de carga
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // 
    if (provider.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 10),
              Text(
                provider.errorMessage!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => provider.fetchCharacters(),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    final list = provider.filteredCharacters;

    // 3. Estado sin resultados al buscar
    if (list.isEmpty) {
      return const Center(
        child: Text('No se encontraron personajes en esta página.'),
      );
    }

    // 
    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (context, index) {
        final character = list[index];
        final isFav = provider.isFavorite(character.id);

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ListTile(
            leading: character.imageUrl.isNotEmpty
                ? Image.network(
                    character.imageUrl,
                    width: 50,
                    height: 50,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.broken_image, size: 40),
                  )
                : const Icon(Icons.person, size: 40),
            title: Text(
              character.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Estado: ${character.status}\nOcupación: ${character.occupation}',
            ),
            isThreeLine: true,
            trailing: IconButton(
              icon: Icon(
                isFav ? Icons.favorite : Icons.favorite_border,
                color: isFav ? Colors.red : null,
              ),
              onPressed: () => provider.toggleFavorite(character),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DetailScreen(character: character),
                ),
              );
            },
          ),
        );
      },
    );
  }
}