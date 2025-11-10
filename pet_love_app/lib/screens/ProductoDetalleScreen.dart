import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pet_love_app/main.dart'; // Importa el CartModel
import 'package:pet_love_app/screens/home_screen.dart';
import 'package:pet_love_app/screens/shoppingcart_screen.dart';
import 'package:pet_love_app/screens/category_screen.dart';
import 'package:pet_love_app/screens/my_orders_screen.dart';
import 'package:pet_love_app/screens/catalog_screen.dart';
import 'package:pet_love_app/services/user_session.dart';
import 'package:pet_love_app/services/api_service.dart';

class ProductoDetalleScreen extends StatefulWidget {
  final int productId;
  final String titulo;
  final String imagen;
  final String descripcion;
  final double precio;
  final int stock;
  final int? categoryId;
  final String? categoryName;

  const ProductoDetalleScreen({
    super.key,
    required this.productId,
    required this.titulo,
    required this.imagen,
    required this.descripcion,
    required this.precio,
    required this.stock,
    this.categoryId,
    this.categoryName,
  });

  @override
  State<ProductoDetalleScreen> createState() => _ProductoDetalleScreenState();
}

class _ProductoDetalleScreenState extends State<ProductoDetalleScreen> {
  int cantidad = 1;
  bool agregado = false;
  bool showMenu = false;

  void _toggleMenu() => setState(() => showMenu = !showMenu);
  void _closeMenu() => setState(() => showMenu = false);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Column(
            children: [
              ClipPath(
                clipper: HeaderClipper(),
                child: Container(
                  color: const Color(0xFFFFC928),
                  height: 180,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 50, left: 20, right: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(Icons.arrow_back_ios, color: Colors.black),
                        ),
                        Image.asset('img/logopet.png', height: 50),
                        GestureDetector(
                          onTap: _toggleMenu,
                          child: const Icon(Icons.menu, color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Descripción Producto",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: SingleChildScrollView(
                  child: Center(
                    child: Container(
                      margin: const EdgeInsets.all(20),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6F6F6),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          widget.imagen.startsWith('http')
                              ? Image.network(
                                  widget.imagen,
                                  height: 150,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported),
                                )
                              : Image.asset(
                                  widget.imagen,
                                  height: 150,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported),
                                ),
                          const SizedBox(height: 16),
                          Text(
                            widget.titulo,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.descripcion,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '\$${widget.precio.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Stock disponible: ${widget.stock}',
                            style: const TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: () {
                                  setState(() {
                                    if (cantidad > 1) cantidad--;
                                  });
                                },
                              ),
                              Text('$cantidad', style: const TextStyle(fontSize: 16)),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () {
                                  setState(() {
                                    if (cantidad < widget.stock) cantidad++;
                                  });
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFFC928),
                              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              elevation: 5,
                            ),
                            onPressed: (agregado || widget.stock <= 0)
                                ? null
                                : () {
                                    setState(() => agregado = true);
                                    final cart = Provider.of<CartModel>(context, listen: false);
                                    cart.addItem(CartItem(
                                      productId: widget.productId,
                                      title: widget.titulo,
                                      image: widget.imagen,
                                      price: widget.precio,
                                      quantity: cantidad,
                                      availableStock: widget.stock,
                                      categoryId: widget.categoryId ?? 0,
                                      categoryName: widget.categoryName ?? 'Sin categoría',
                                    ));

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('${widget.titulo} agregado al carrito ($cantidad)'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );

                                    Navigator.pushNamed(context, '/shoppingcart');
                                  },
                            child: Text(
                              agregado
                                  ? 'AGREGADO'
                                  : (widget.stock <= 0 ? 'SIN STOCK' : 'AGREGAR AL CARRITO'),
                              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // === MENÚ LATERAL ===
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
                          Navigator.pushNamed(context, '/shoppingcart');
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
                        onTap: () {
                          _closeMenu();
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const CatalogScreen()));
                        },
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
    );
  }
}

class HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 40);
    path.quadraticBezierTo(size.width / 2, size.height + 40, size.width, size.height - 40);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
