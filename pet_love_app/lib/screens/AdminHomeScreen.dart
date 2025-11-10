import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pet_love_app/services/user_session.dart';
import 'package:pet_love_app/services/api_service.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
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
    return GestureDetector(
      onTap: closeMenu,
      child: Scaffold(
        body: Stack(
          children: [
            Column(
              children: [
                _HeaderAdmin(onMenuTap: toggleMenu),
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
                          child: Image.asset('img/admin.png', height: 100),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Hola Administrador',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Panel exclusivo para gestionar ventas y productos',
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
                top: 0,
                bottom: 0,
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
                            CircleAvatar(radius: 35, backgroundImage: AssetImage('img/admin.png')),
                            SizedBox(height: 12),
                            Text('Hola\nAdministrador!', textAlign: TextAlign.center),
                          ],
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.home),
                        title: const Text('Inicio'),
                        onTap: closeMenu,
                      ),
                      ListTile(
                        leading: const Icon(Icons.bar_chart),
                        title: const Text('Ventas'),
                        onTap: () {
                          closeMenu();
                          Navigator.pushNamed(context, '/adminsales');
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.category),
                        title: const Text('Categoría Productos'),
                        onTap: () {
                          closeMenu();
                           Navigator.pushNamed(context, '/admincategories');
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.loyalty),
                        title: const Text('Marcas'),
                        onTap: () {
                          closeMenu();
                           Navigator.pushNamed(context, '/adminbrands');
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.straighten),
                        title: const Text('Medidas'),
                        onTap: () {
                          closeMenu();
                           Navigator.pushNamed(context, '/adminmeasures');
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.inventory),
                        title: const Text('Productos'),
                        onTap: () {
                          closeMenu();
                           Navigator.pushNamed(context, '/adminproducts');
                        },
                      ),
                      const Spacer(),
                      // Dentro del menú lateral, en el ListTile de "Cerrar sesión"
                      ListTile(
                        leading: const Icon(Icons.logout),
                        title: const Text('Cerrar sesión'),
                        onTap: () {
                          closeMenu();
                          Provider.of<UserSession>(context, listen: false).clear();
                          ApiService.setToken(null);
                          Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                        },
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HeaderAdmin extends StatelessWidget {
  final VoidCallback onMenuTap;
  const _HeaderAdmin({required this.onMenuTap});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipPath(
          clipper: _CurvedClipper(),
          child: Container(
            height: 140,
            color: const Color(0xFFFFC928),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 40, left: 16, right: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: onMenuTap,
                child: const Icon(Icons.menu, size: 28, color: Colors.black),
              ),
              Image.asset('img/logopet.png', height: 40),
              const SizedBox(width: 28),
            ],
          ),
        ),
        const Positioned(
          top: 90,
          left: 0,
          right: 0,
          child: Center(
            child: Text(
              'MENÚ ADMIN',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                shadows: [Shadow(color: Colors.black26, offset: Offset(1, 1), blurRadius: 2)],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CurvedClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 40);
    path.quadraticBezierTo(size.width / 2, size.height, size.width, size.height - 40);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
