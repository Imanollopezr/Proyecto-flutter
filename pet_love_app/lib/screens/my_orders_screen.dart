import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:pet_love_app/config/api_config.dart';
import 'package:pet_love_app/services/api_service.dart';
import 'package:pet_love_app/screens/detalle_pedido_screen.dart';
import 'package:provider/provider.dart';
import 'package:pet_love_app/services/user_session.dart';

class PedidosScreen extends StatefulWidget {
  const PedidosScreen({super.key});

  @override
  State<PedidosScreen> createState() => _PedidosScreenState();
}

class _PedidosScreenState extends State<PedidosScreen> {
  List<Map<String, dynamic>> pedidos = [];
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    _fetchPedidos();
  }

  // Obtener pedidos desde la API (filtrados por el email de la sesión)
  Future<void> _fetchPedidos() async {
    try {
      final session = Provider.of<UserSession>(context, listen: false);
      final emailSesion = session.email?.trim().toLowerCase();
      if (emailSesion == null || emailSesion.isEmpty) {
        setState(() {
          pedidos = [];
          isLoading = false;
          hasError = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Debe iniciar sesión para ver sus compras')),
        );
        return;
      }

      final response = await http.get(
        Uri.parse(ApiConfig.getVentasUrl()),
        headers: ApiConfig.defaultHeaders,
      );

      if (response.statusCode == 200) { // corregido: usar statusCode
        final List<dynamic> data = json.decode(response.body);
        final List<dynamic> propias = data.where((venta) {
          final clienteObj = venta['cliente'] ?? venta['Cliente'];
          final correo = clienteObj is Map
              ? (clienteObj['correo'] ??
                  clienteObj['Correo'] ??
                  clienteObj['email'] ??
                  clienteObj['Email'])
              : null;
          return correo != null &&
              correo.toString().trim().toLowerCase() == emailSesion;
        }).toList();

        final List<Map<String, dynamic>> ventas = propias.map<Map<String, dynamic>>((venta) {
          final id = venta['id'] ?? venta['Id'] ?? 0;
          final fechaRaw = venta['fechaVenta'] ?? venta['FechaVenta'] ?? '';
          final fechaStr = fechaRaw is String ? _formatDate(fechaRaw.split('T').first) : '';

          final totalRaw = venta['total'] ?? venta['Total'] ?? 0;
          final total = totalRaw is num ? totalRaw.toDouble() : double.tryParse(totalRaw.toString()) ?? 0.0;

          final clienteObj = venta['cliente'] ?? venta['Cliente'];
          final clienteStr = clienteObj is Map ? (clienteObj['nombre'] ?? 'Cliente') : 'Cliente';

          return {
            'id': id is int ? id : int.tryParse(id.toString()) ?? 0,
            'fecha': fechaStr,
            'total': total,
            'cliente': clienteStr,
          };
        }).toList();

        setState(() {
          pedidos = ventas;
          isLoading = false;
          hasError = false;
        });
      } else {
        setState(() {
          isLoading = false;
          hasError = true;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        hasError = true;
      });
    }
  }

  Future<void> _openDetalleVenta(int ventaId) async {
    // Spinner de carga para una experiencia más intuitiva
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final session = Provider.of<UserSession>(context, listen: false);
      final emailSesion = session.email?.trim().toLowerCase();

      final data = await ApiService.get('ventas/$ventaId');

      // Validar que la venta pertenece al correo en sesión
      if (data is Map) {
        final clienteObj = data['cliente'] ?? data['Cliente'];
        final correoVenta = clienteObj is Map
            ? (clienteObj['correo'] ??
                clienteObj['Correo'] ??
                clienteObj['email'] ??
                clienteObj['Email'])
            : null;
        final correoNormalizado = correoVenta?.toString().trim().toLowerCase();

        if (emailSesion == null ||
            emailSesion.isEmpty ||
            correoNormalizado != emailSesion) {
          Navigator.of(context, rootNavigator: true).pop(); // cerrar spinner
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Esta venta no pertenece a su cuenta')),
          );
          return;
        }
      }

      List<Map<String, dynamic>> productos = [];

      if (data is Map) {
        final detalles = (data['detallesVenta'] ??
                data['DetallesVenta'] ??
                data['detalles'] ??
                data['Detalles']) as List<dynamic>?;

        if (detalles != null && detalles.isNotEmpty) {
          final estado = data['estado'] ?? data['Estado'] ?? 'Pendiente';

          productos = detalles.map<Map<String, dynamic>>((d) {
            final prod = d['producto'] ?? d['Producto'];
            final nombre = prod is Map
                ? (prod['nombre'] ?? prod['Nombre'] ?? 'Producto')
                : 'Producto';

            final cantidadRaw = d['cantidad'] ?? d['Cantidad'] ?? 0;
            final cantidad = cantidadRaw is int
                ? cantidadRaw
                : int.tryParse('$cantidadRaw') ?? 0;

            final precioRaw = d['precioUnitario'] ??
                d['PrecioUnitario'] ??
                d['precio'] ??
                d['Precio'] ??
                0;
            final precio = precioRaw is num
                ? precioRaw.toDouble()
                : double.tryParse('$precioRaw') ?? 0.0;

            final totalLinea = (precio * cantidad).toStringAsFixed(0);

            final imagen = prod is Map
                ? (prod['imagenUrl'] ?? prod['ImagenUrl'] ?? '')
                : '';

            return {
              'nombre': nombre,
              'estado': estado,
              'total': totalLinea,
              'imagen': imagen,
              // campos extra para una presentación más clara
              'cantidad': cantidad,
              'precioUnitario': precio,
            };
          }).toList();
        } else {
          // Resumen de la venta si no hay detalles
          final estado = data['estado'] ?? data['Estado'] ?? 'Pendiente';
          final totalVentaRaw = data['total'] ?? data['Total'] ?? 0;
          final totalVenta = totalVentaRaw is num
              ? totalVentaRaw.toDouble()
              : double.tryParse('$totalVentaRaw') ?? 0.0;

          productos = [
            {
              'nombre': 'Venta #$ventaId',
              'estado': estado,
              'total': totalVenta.toStringAsFixed(0),
              'imagen': '',
              'cantidad': 1,
              'precioUnitario': totalVenta, // se muestra como unitario si no hay líneas
            }
          ];
        }
      }

      Navigator.of(context, rootNavigator: true).pop(); // cerrar spinner

      if (productos.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se encontraron detalles para esta venta')),
        );
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DetallePedidoScreen(productos: productos),
        ),
      );
    } catch (e) {
      Navigator.of(context, rootNavigator: true).pop(); // cerrar spinner ante error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar el detalle: $e')),
      );
    }
  }

  // Formatear fecha de YYYY-MM-DD a DD/MM/YYYY
  String _formatDate(String fecha) {
    try {
      final parts = fecha.split('-');
      return '${parts[2]}/${parts[1]}/${parts[0]}';
    } catch (e) {
      return fecha;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Listado de Ventas'),
        backgroundColor: const Color(0xFFFFC928),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : hasError
              ? const Center(child: Text('Error al cargar las ventas'))
              : pedidos.isEmpty
                  ? const Center(child: Text('No se encontraron ventas'))
                  : ListView.builder(
                      itemCount: pedidos.length,
                      itemBuilder: (context, index) {
                        final venta = pedidos[index];

                        final id = venta['id'] is int
                            ? venta['id']
                            : int.tryParse('${venta['id']}') ?? 0;

                        final totalRaw = venta['total'] ?? 0;
                        final total = totalRaw is num
                            ? totalRaw.toDouble()
                            : double.tryParse('$totalRaw') ?? 0.0;

                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: ListTile(
                            title: Text('Venta #$id'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Cliente: ${venta['cliente']}'),
                                Text('Fecha: ${venta['fecha']}'),
                              ],
                            ),
                            trailing: Text(
                              '\$${total.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.green,
                              ),
                            ),
                            onTap: () => _openDetalleVenta(id),
                          ),
                        );
                      },
                    ),
    );
  }
}