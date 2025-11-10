import 'package:flutter/material.dart';

class DetalleVentaScreen extends StatelessWidget {
  final List<Map<String, dynamic>> productos;
  final double total;

  const DetalleVentaScreen({
    super.key,
    required this.productos,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFC928),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
              ),
              child: ListView.builder(
                itemCount: productos.length,
                itemBuilder: (context, index) {
                  final producto = productos[index];
                  return _buildProductoCard(producto);
                },
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 5,
                  offset: Offset(0, -1),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '\$${total.toStringAsFixed(3)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 140,
          decoration: const BoxDecoration(
            color: Color(0xFFFFC928),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, size: 28, color: Colors.black),
                  onPressed: () => Navigator.pop(context),
                ),
                Image.asset('img/logopet.png', height: 40),
                const SizedBox(width: 28),
              ],
            ),
          ),
        ),
        const Positioned(
          bottom: 20,
          left: 0,
          right: 0,
          child: Center(
            child: Text(
              'DETALLE DE VENTA',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        )
      ],
    );
  }

  Widget _buildProductoCard(Map<String, dynamic> producto) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 3),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFC928),
              borderRadius: BorderRadius.circular(15),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.asset(
                producto['image'],
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.image, size: 40),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    producto['title'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Text('Estado: ',
                          style: TextStyle(fontSize: 13, color: Colors.black)),
                      Text(
                        producto['estado'],
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: producto['estado'] == 'Pendiente'
                              ? Colors.red
                              : Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'SubTotal: ${producto['subtotal']}',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
