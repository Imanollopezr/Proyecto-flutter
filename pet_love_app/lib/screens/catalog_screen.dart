import 'package:flutter/material.dart';
import 'package:pet_love_app/screens/my_orders_screen.dart';
import 'package:pet_love_app/screens/shoppingcart_screen.dart';
import 'package:pet_love_app/screens/favorite_screen.dart';
import 'package:pet_love_app/screens/profile_screen.dart';
import 'package:pet_love_app/screens/home_screen.dart';
import 'package:pet_love_app/screens/category_screen.dart';
import 'package:provider/provider.dart';
import 'package:pet_love_app/services/user_session.dart';
import 'package:pet_love_app/services/api_service.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final List<Map<String, dynamic>> products = [
    {'title': 'Croquetas RINGO 3KL', 'price': '\$20.000', 'image': 'img/cuido.png'},
    {'title': 'Collar Perro Peque', 'price': '\$60.000', 'image': 'img/collar.png'},
    {'title': 'Pelota Perro Knot Pet', 'price': '\$60.000', 'image': 'img/pelota.png'},
    {'title': 'Enguaje Bucal Perro', 'price': '\$60.000', 'image': 'img/bucal.png'},
  ];

  final Set<String> favoriteTitles = {};
  bool showMenu = false;
  final TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> filteredProducts = [];

  @override
  void initState() {
    super.initState();
    filteredProducts = List.from(products);
  }

  void _closeMenu() {
    if (showMenu) setState(() => showMenu = false);
  }

  void _filterProducts(String query) {
    setState(() {
      filteredProducts = products.where((product) {
        return product['title'].toString().toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }

  List<Map<String, dynamic>> getFavoriteProducts() {
    return products.where((product) => favoriteTitles.contains(product['title'])).toList();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _closeMenu,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            Column(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFC928),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(60),
                      bottomRight: Radius.circular(60),
                    ),
                  ),
                  padding: const EdgeInsets.only(top: 50, bottom: 20, left: 20, right: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => showMenu = !showMenu),
                        child: const Icon(Icons.menu, size: 28),
                      ),
                      Image.asset('img/logopet.png', height: 40),
                      IconButton(
                        icon: const Icon(Icons.shopping_cart, size: 28),
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const ShoppingCartScreen()));
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'CATÁLOGO',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: TextField(
                    controller: searchController,
                    onChanged: _filterProducts,
                    decoration: InputDecoration(
                      hintText: 'Buscar producto',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: GridView.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.70,
                      children: filteredProducts.map((product) {
                        return _buildProductCard(
                          product['title'],
                          product['price'],
                          product['image'],
                          favoriteTitles.contains(product['title']),
                          () {
                            setState(() {
                              if (favoriteTitles.contains(product['title'])) {
                                favoriteTitles.remove(product['title']);
                              } else {
                                favoriteTitles.add(product['title']);
                              }
                            });
                          },
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
                      borderRadius: BorderRadius.only(topRight: Radius.circular(20)),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFC928),
                            borderRadius: BorderRadius.only(bottomRight: Radius.circular(40)),
                          ),
                          child: const Column(
                            children: [
                              CircleAvatar(radius: 35, backgroundImage: AssetImage('img/acceso.png')),
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
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.shopping_cart),
                          title: const Text('Mi Carrito'),
                          onTap: () {
                            _closeMenu();
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const ShoppingCartScreen()));
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.assignment),
                          title: const Text('Mis Pedidos'),
                          onTap: () {
                            _closeMenu();
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const PedidosScreen()));
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.view_module),
                          title: const Text('Catálogo'),
                          onTap: _closeMenu,
                        ),
                        ListTile(
                          leading: const Icon(Icons.category),
                          title: const Text('Categoría de productos'),
                          onTap: () {
                            _closeMenu();
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoryScreen()));
                          },
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
              Navigator.push(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
            } else if (index == 1) {
              Navigator.push(context, MaterialPageRoute(builder: (_) => FavoriteScreen(favorites: getFavoriteProducts())));
            } else if (index == 2) {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const PedidosScreen()));
            } else if (index == 3) {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
            }
          },
        ),
      ),
    );
  }

  Widget _buildProductCard(String title, String price, String imagePath, bool isFavorite, VoidCallback onFavoriteToggle) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/detalle_producto', arguments: {
          'title': title,
          'price': price,
          'image': imagePath,
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(2, 4),
            ),
          ],
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Container(
              height: 140,
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  colors: [Color(0xFFFDF6E3), Color(0xFFFFFFFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 6,
                    offset: Offset(2, 4),
                  ),
                ],
                border: Border.all(color: Colors.amber.shade100, width: 1),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.asset(imagePath, fit: BoxFit.contain),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    price,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF388E3C),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_red_eye, size: 20, color: Colors.black54),
                        onPressed: () {
                          Navigator.pushNamed(context, '/detalle_producto', arguments: {
                            'title': title,
                            'price': price,
                            'image': imagePath,
                          });
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? Colors.red : Colors.black,
                          size: 20,
                        ),
                        onPressed: onFavoriteToggle,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
