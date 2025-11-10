import 'package:flutter/material.dart';

class ProductDetailScreen extends StatelessWidget {
  final Map<String, dynamic> product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Encabezado curvado
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
                // 👈 Flechita para volver
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                Column(
                  children: const [
                    Text("PET", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                    Text("🐾 LOVE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                  ],
                ),
                const Icon(Icons.shopping_cart, color: Colors.black),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Descripcion Producto',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),

          // Card de producto
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.topRight,
                    children: [
                      Column(
                        children: [
                          Image.asset(product['image'], height: 120),
                          const SizedBox(height: 10),
                          const Icon(Icons.circle, size: 10, color: Colors.black45),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    product['title'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    product['description'],
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '\$${product['price'] ~/ 1000}.000',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            )
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.remove, size: 18),
                            const SizedBox(width: 6),
                            Text('${product['quantity']}'),
                            const SizedBox(width: 6),
                            const Icon(Icons.add, size: 18),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
