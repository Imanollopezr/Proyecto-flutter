import 'package:flutter/material.dart';
import 'package:pet_love_app/screens/category_screen.dart';
import 'package:pet_love_app/screens/catalog_screen.dart';
import 'package:pet_love_app/screens/my_orders_screen.dart';
import 'package:pet_love_app/screens/profile_screen.dart';
import 'package:pet_love_app/screens/shoppingcart_screen.dart';
import 'package:provider/provider.dart';
import 'package:pet_love_app/services/user_session.dart';
import 'package:pet_love_app/services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool showMenu = false;

  void toggleMenu() {
    setState(() {
      showMenu = !showMenu;
    });
  }

  void closeMenu() {
    if (showMenu) {
      setState(() {
        showMenu = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = Provider.of<UserSession>(context); // escucha cambios
    final saludoNombre = (session.nombre?.trim()?.isNotEmpty == true)
        ? session.nombre!.trim()
        : (session.email ?? 'Usuario');

    return GestureDetector(
      onTap: closeMenu,
      child: Scaffold(
        body: Stack(
          children: [
            Column(
              children: [
                CustomHeader(title: 'MENÚ', onMenuPressed: toggleMenu),
                const SizedBox(height: 20),
                Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Color(0xFFFFC928), width: 3),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.all(6),
                          child: Image.asset('img/perroacceso1.png', height: 100),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Bienvenido a PetLove',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Tu tienda de confianza para consentir a tu mascota',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (showMenu)
              Positioned(
                left: 0,
                top: 12, // separación respecto al header principal
                bottom: 0,
                child: GestureDetector(
                  onTap: () {},
                  child: Container(
                    width: 260,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5EFFA),
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            // Amarillo con un degradado suave para diferenciar
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFC928), Color(0xFFF2B300)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(20),
                              bottomRight: Radius.circular(40),
                            ),
                            // Borde blanco sutil que separa visualmente del fondo
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: const [
                              BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
                            ],
                          ),
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 35,
                                backgroundImage: session.fotoBytes != null
                                    ? MemoryImage(session.fotoBytes!)
                                    : (session.fotoUrl != null && session.fotoUrl!.isNotEmpty)
                                        ? (session.fotoUrl!.startsWith('http')
                                            ? NetworkImage(session.fotoUrl!)
                                            : AssetImage(session.fotoUrl!) as ImageProvider)
                                        : const AssetImage('img/Perroacceso.png'),
                              ),
                              const SizedBox(height: 12),
                              Text('Hola\n$saludoNombre!', textAlign: TextAlign.center),
                            ],
                          ),
                        ),
                        ListTile(
                          leading: const Icon(Icons.home),
                          title: const Text('Inicio'),
                          onTap: closeMenu,
                        ),
                        ListTile(
                          leading: const Icon(Icons.shopping_cart),
                          title: const Text('Mi Carrito'),
                          onTap: () {
                            closeMenu();
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const ShoppingCartScreen()));
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.assignment),
                          title: const Text('Mis Pedidos'),
                          onTap: () {
                            closeMenu();
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const PedidosScreen()));
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.view_module),
                          title: const Text('Catálogo'),
                          onTap: () {
                            closeMenu();
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const CatalogScreen()));
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.category),
                          title: const Text('Categoría de productos'),
                          onTap: () {
                            closeMenu();
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoryScreen()));
                          },
                        ),
                        const Spacer(),
                        // Dentro del menú lateral, en el ListTile de "Cerrar sesión"
                        ListTile(
                          leading: const Icon(Icons.logout),
                          title: const Text('Cerrar sesión'),
                          onTap: () {
                            closeMenu(); // corregido: usar closeMenu() en lugar de _closeMenu()
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
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.grey,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
            BottomNavigationBarItem(icon: Icon(Icons.favorite_border), label: 'Favoritos'),
            BottomNavigationBarItem(icon: Icon(Icons.refresh), label: 'Recargar'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Perfil'),
          ],
          onTap: (index) {
            if (index == 0) {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
            } else if (index == 1) {
              Navigator.pushNamed(context, '/favoritos');
            } else if (index == 2) {
              Navigator.pushNamed(context, '/recargar');
            } else if (index == 3) {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
            }
          },
        ),
      ),
    );
  }
}

class CustomHeader extends StatelessWidget {
  final String title;
  final VoidCallback onMenuPressed;

  const CustomHeader({super.key, required this.title, required this.onMenuPressed});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipPath(
          clipper: CurvedBottomClipper(),
          child: Container(
            height: 140,
            color: const Color(0xFFFFC928),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 40.0, left: 16, right: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: onMenuPressed,
                child: const Icon(Icons.menu, size: 28, color: Colors.black),
              ),
              Image.asset('img/logopet.png', height: 40),
              GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ShoppingCartScreen()));
                },
                child: const Icon(Icons.shopping_cart, size: 28, color: Colors.black),
              ),
            ],
          ),
        ),
        Positioned(
          top: 90,
          left: 0,
          right: 0,
          child: Center(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(color: Colors.black26, offset: Offset(1, 1), blurRadius: 2),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class CurvedBottomClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 40);
    path.quadraticBezierTo(
      size.width / 2, size.height, size.width, size.height - 40,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
