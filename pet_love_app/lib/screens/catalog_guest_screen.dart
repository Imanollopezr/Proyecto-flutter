import 'package:flutter/material.dart';
import 'package:pet_love_app/screens/shoppingcart_screen.dart';

class CatalogGuestScreen extends StatefulWidget {
  const CatalogGuestScreen({super.key});

  @override
  State<CatalogGuestScreen> createState() => _CatalogGuestScreenState();
}

class _CatalogGuestScreenState extends State<CatalogGuestScreen> {
  final List<Map<String, dynamic>> products = [
    {'title': 'Croquetas RINGO 3KL', 'price': '\$20.000', 'image': 'img/cuido.png'},
    {'title': 'Collar Perro Peque', 'price': '\$60.000', 'image': 'img/collar.png'},
    {'title': 'Pelota Perro Knot Pet', 'price': '\$60.000', 'image': 'img/pelota.png'},
    {'title': 'Enguaje Bucal Perro', 'price': '\$60.000', 'image': 'img/bucal.png'},
  ];

  final TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> filteredProducts = [];

  @override
  void initState() {
    super.initState();
    filteredProducts = List.from(products);
  }

  void _filterProducts(String query) {
    setState(() {
      filteredProducts = products.where((product) {
        return product['title'].toString().toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(top: 50, left: 16, right: 16, bottom: 16),
            decoration: const BoxDecoration(
              color: Color(0xFFFFC928),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, size: 28),
                  onPressed: () => Navigator.pop(context),
                ),
                Image.asset('img/logopet.png', height: 40),
                const SizedBox(width: 28),
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
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(String title, String price, String imagePath) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.grey.shade300, blurRadius: 6, offset: const Offset(2, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            height: 130,
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.asset(imagePath, fit: BoxFit.contain),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              children: [
                Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(price, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.remove_red_eye, size: 18),
                  onPressed: () {
                    Navigator.pushNamed(context, '/detalle_producto', arguments: {
                      'title': title,
                      'price': price,
                      'image': imagePath,
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
