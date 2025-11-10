import 'package:flutter/material.dart';
import 'package:pet_love_app/screens/catalog_screen.dart';
import 'package:pet_love_app/screens/home_screen.dart';
import 'package:pet_love_app/screens/profile_screen.dart';
import 'package:pet_love_app/screens/shoppingcart_screen.dart';
import 'package:provider/provider.dart';
import 'package:pet_love_app/services/user_session.dart';
import 'package:pet_love_app/services/api_service.dart';
import 'package:pet_love_app/config/api_config.dart';

class DetallePedidoScreen extends StatefulWidget {
  final List<Map<String, dynamic>> productos;

  const DetallePedidoScreen({Key? key, required this.productos}) : super(key: key);

  @override
  State<DetallePedidoScreen> createState() => _DetallePedidoScreenState();
}

class _DetallePedidoScreenState extends State<DetallePedidoScreen> {
  bool showMenu = false;

  void _toggleMenu() => setState(() => showMenu = !showMenu);
  void _closeMenu() => setState(() => showMenu = false);

  double calcularTotal() {
    double total = 0;
    for (var producto in widget.productos) {
      final precio = double.tryParse((producto['total'] ?? '0').toString().replaceAll('.', '').replaceAll(',', '')) ?? 0;
      total += precio;
    }
    return total;
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
                    width: double.infinity,
                    height: 140,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFC928),
                      borderRadius: BorderRadius.only(bottomLeft: Radius.circular(80)),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back, size: 30),
                              onPressed: () => Navigator.pop(context),
                            ),
                            IconButton(
                              icon: const Icon(Icons.menu, size: 30),
                              onPressed: _toggleMenu,
                            ),
                          ],
                        ),
                        Image.asset('img/logopet.png', height: 40),
                        const SizedBox(width: 30),
                      ],
                    ),
                  ),
                  const Positioned(
                    bottom: 15,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Text(
                        'DETALLE DE PEDIDO',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF3F3F3),
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(40), topRight: Radius.circular(40)),
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          itemCount: widget.productos.length,
                          itemBuilder: (context, index) {
                            final producto = widget.productos[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.15),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  // Imagen del producto comprado
                                  Container(
                                    margin: const EdgeInsets.all(12),
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFC928),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Builder(
                                        builder: (_) {
                                          // Prioriza ImagenUrl > imagenUrl > imagen
                                          final raw = ((producto['ImagenUrl'] ??
                                                        producto['imagenUrl'] ??
                                                        producto['imagen']) ?? '')
                                                    .toString()
                                                    .trim();
                                          if (raw.isEmpty) {
                                            return const Icon(Icons.image_not_supported);
                                          }
                                          final isAsset = raw.startsWith('img/') || raw.startsWith('assets/');
                                          if (isAsset) {
                                            return Image.asset(
                                              raw,
                                              width: 60,
                                              height: 60,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) =>
                                                  const Icon(Icons.broken_image),
                                            );
                                          }
                                          final url = ApiConfig.getImageUrl(raw);
                                          return Image.network(
                                            url,
                                            width: 60,
                                            height: 60,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) =>
                                                const Icon(Icons.broken_image),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            producto['nombre'] ?? 'Producto',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                          ),
                                          const SizedBox(height: 8),
                                          // Cantidad comprada
                                          Row(
                                            children: [
                                              const Icon(Icons.confirmation_number, size: 16, color: Colors.black54),
                                              const SizedBox(width: 6),
                                              Text('Cantidad: ${producto['cantidad'] ?? 1}'),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Total: \$${producto['total'] ?? '0'}',
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total del pedido:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            Text('\$${calcularTotal().toStringAsFixed(0)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Menú lateral con fondo semitransparente
          if (showMenu)
            Stack(
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    onTap: _closeMenu,
                    child: Container(
                      color: Colors.black.withOpacity(0.3),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 260,
                    decoration: const BoxDecoration(
                      color: Color(0xFFB4CB82),
                      borderRadius: BorderRadius.only(topRight: Radius.circular(40)),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: const Column(
                            children: [
                              CircleAvatar(radius: 40, backgroundColor: Colors.blue),
                              SizedBox(height: 8),
                              Text('Hola\nYeison!', textAlign: TextAlign.center),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Container(
                            color: const Color(0xFFA6DAF3),
                            child: ListView(
                              children: [
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
                                  onTap: _closeMenu,
                                ),
                                ListTile(
                                  leading: const Icon(Icons.grid_view),
                                  title: const Text('Catálogo'),
                                  onTap: () {
                                    _closeMenu();
                                    Navigator.push(context, MaterialPageRoute(builder: (_) => const CatalogScreen()));
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.person),
                                  title: const Text('Perfil'),
                                  onTap: () {
                                    _closeMenu();
                                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
                                  },
                                ),
                                const Divider(),
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
                      ],
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
