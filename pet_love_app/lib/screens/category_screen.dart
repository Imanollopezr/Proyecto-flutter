import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pet_love_app/config/api_config.dart';
import 'package:pet_love_app/screens/catalog_screen.dart';
import 'package:pet_love_app/screens/home_screen.dart';
import 'package:pet_love_app/screens/profile_screen.dart';
import 'package:pet_love_app/screens/shoppingcart_screen.dart';
import 'package:pet_love_app/screens/alimentos_screen.dart';
import 'package:pet_love_app/screens/juguetes_screen.dart';
import 'package:pet_love_app/screens/accesorios_screen.dart';
import 'package:pet_love_app/screens/category_screen.dart';
import 'package:pet_love_app/screens/medicamentos_screen.dart';
import 'package:pet_love_app/screens/my_orders_screen.dart';
import 'package:pet_love_app/screens/products_by_category_screen.dart';
import 'package:provider/provider.dart';
import 'package:pet_love_app/services/user_session.dart';
import 'package:pet_love_app/services/api_service.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  bool showMenu = false;
  TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> categories = [];
  List<Map<String, dynamic>> filteredCategories = [];
  bool isLoading = true;
  String errorMessage = '';

  void _toggleMenu() => setState(() => showMenu = !showMenu);
  void _closeMenu() => setState(() => showMenu = false);

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  // Dentro de _fetchCategories(), ajusta el mapeo de imageUrl:
  Future<void> _fetchCategories() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.getCategoriaProductosUrl()),
        headers: ApiConfig.defaultHeaders,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          categories = data.map((category) {
            // ID robusto: soporta varios nombres
            final rawId = category['idCategoriaProducto'] ??
                category['IdCategoriaProducto'] ??
                category['idCategoria'] ??
                category['id'];
            final intId = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '') ?? 0;

            return {
              'id': intId,
              'name': category['nombre'] ?? category['Nombre'] ?? 'Sin nombre',
              'imageUrl': ApiConfig.getImageUrl(
                category['imagenUrl'] ??
                category['ImagenUrl'] ??
                category['urlImagen'] ??
                category['fkImagenNavigation']?['urlImagen'] ??
                '',
              ),
            };
          })
          .where((cat) => (cat['id'] as int) > 0)
          .toList();

          filteredCategories = List.from(categories);
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Error al cargar categorías: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error de conexión: $e';
        isLoading = false;
      });
    }
  }

  void _searchCategory(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredCategories = List.from(categories);
      } else {
        filteredCategories = categories
            .where((cat) =>
                cat['name']!.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _onCategoryTap(String categoryName) {
    if (categoryName == 'Alimentos') {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => const AlimentosScreen()));
    } else if (categoryName == 'Juguetes') {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => const JuguetesScreen()));
    } else if (categoryName == 'Accesorios') {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const AccesoriosScreen()));
    } else if (categoryName == 'Medicamentos') {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const MedicamentosScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFC928),
      body: Stack(
        children: [
          Column(
            children: [
              Stack(
                children: [
                  Container(
                    height: 140,
                    color: const Color(0xFFFFC928),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back,
                                  color: Colors.black, size: 28),
                              onPressed: () {
                                Navigator.pop(context);
                              },
                            ),
                            Image.asset(
                              'img/logopet.png',
                              height: 50,
                            ),
                            // Se ha eliminado el icono del carrito
                            const SizedBox(width: 48), // Espacio para mantener el balance visual
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 100,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Text(
                        'Categoría productos',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black.withOpacity(0.85),
                          shadows: const [
                            Shadow(
                                offset: Offset(0, 2),
                                blurRadius: 2,
                                color: Colors.black26)
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: searchController,
                  onChanged: _searchCategory,
                  decoration: InputDecoration(
                    hintText: 'Buscar Categoría',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF3F3F3),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                  ),
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : errorMessage.isNotEmpty
                          ? Center(child: Text(errorMessage))
                          : filteredCategories.isEmpty
                              ? const Center(child: Text('No hay categorías disponibles'))
                              : GridView.count(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  children: filteredCategories.map((cat) {
                                    return GestureDetector(
                                      onTap: () {
                                        // Navegar a listado por categoría con ID validado
                                        final categoryId = cat['id'] is int
                                            ? cat['id'] as int
                                            : int.tryParse(cat['id']?.toString() ?? '') ?? 0;
                                        if (categoryId <= 0) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Categoría inválida')),
                                          );
                                          return;
                                        }
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => ProductsByCategoryScreen(
                                              categoryId: categoryId,
                                              categoryName: cat['name'] ?? 'Categoría',
                                            ),
                                          ),
                                        );
                                      },
                                      child: buildCategoryCard(cat),
                                    );
                                  }).toList(),
                                ),
                ),
              ),
            ],
          ),
          if (showMenu)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: GestureDetector(
                onTap: _closeMenu,
                child: Container(
                  width: 260,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF5EFFA),
                    borderRadius:
                        BorderRadius.only(topRight: Radius.circular(20)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 40),
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFC928),
                          borderRadius:
                              BorderRadius.only(bottomRight: Radius.circular(40)),
                        ),
                        child: const Column(
                          children: [
                            CircleAvatar(
                              radius: 35,
                              backgroundImage: AssetImage('img/acceso.png'),
                            ),
                            SizedBox(height: 12),
                            Text('Hola\nYeison!', textAlign: TextAlign.center),
                          ],
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.home),
                        title: const Text('Inicio'),
                        onTap: () {
                          _closeMenu();
                          Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const HomeScreen()));
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.shopping_cart),
                        title: const Text('Mi Carrito'),
                        onTap: () {
                          _closeMenu();
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const ShoppingCartScreen()));
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.assignment),
                        title: const Text('Mis Pedidos'),
                        onTap: () {
                          _closeMenu();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const PedidosScreen()),
                          );
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.grid_view),
                        title: const Text('Catálogo'),
                        onTap: () {
                          _closeMenu();
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const CatalogScreen()));
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.category),
                        title: const Text('Categoría de productos'),
                        onTap: _closeMenu,
                      ),
                      const Spacer(),
                      // Dentro del menú lateral, en el ListTile de "Cerrar sesión"
                      ListTile(
                        leading: const Icon(Icons.logout),
                        title: const Text('Cerrar sesión'),
                        onTap: () {
                          _closeMenu();
                          Provider.of<UserSession>(context, listen: false).clear();
                          ApiService.setToken(null);
                          Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite_border), label: 'Favoritos'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Pedidos'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
        onTap: (index) {
          if (index == 0) {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const HomeScreen()));
          } else if (index == 3) {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()));
          }
        },
      ),
    );
  }

  Widget buildCategoryCard(Map<String, dynamic> category) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
              color: Colors.black12, blurRadius: 6, offset: Offset(2, 2)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 90,
            width: 90,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.yellow.withOpacity(0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Builder(
              builder: (context) {
                final imgUrl = (category['imageUrl'] as String?)?.trim() ?? '';
                final isRemote = imgUrl.startsWith('http');
                final isPlaceholder = imgUrl.contains('via.placeholder.com');
                if (isRemote && !isPlaceholder) {
                  return ClipOval(
                    child: SizedBox.expand(
                      child: Image.network(
                        imgUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.image_not_supported),
                      ),
                    ),
                  );
                }
                // Fallback: asset local para cuando no hay imagen remota
                return ClipOval(
                  child: SizedBox.expand(
                    child: Image.asset(
                      'img/juguetes.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Text(
            category['name'] ?? 'Sin nombre',
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}