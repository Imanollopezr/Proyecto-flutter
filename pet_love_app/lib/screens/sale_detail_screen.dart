import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:pet_love_app/config/api_config.dart';
import 'package:intl/intl.dart';

class SaleDetailScreen extends StatefulWidget {
  final int ventaId;
  const SaleDetailScreen({super.key, required this.ventaId});

  @override
  State<SaleDetailScreen> createState() => _SaleDetailScreenState();
}

class _SaleDetailScreenState extends State<SaleDetailScreen> {
  bool isLoading = true;
  bool hasError = false;

  Map<String, dynamic>? venta;
  Map<String, dynamic>? cliente;
  List<Map<String, dynamic>> detalles = [];

  @override
  void initState() {
    super.initState();
    _fetchDetalle();
  }

  Future<void> _fetchDetalle() async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/api/ventas/${widget.ventaId}');
      final resp = await http.get(url, headers: ApiConfig.defaultHeaders);

      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);

        final id = data['id'] ?? data['Id'] ?? widget.ventaId;
        final fechaRaw = data['fechaVenta'] ?? data['FechaVenta'] ?? '';
        final fechaStr = _formatDate(fechaRaw is String ? fechaRaw.split('T').first : '');
        final metodoPago = data['metodoPago'] ?? data['MetodoPago'] ?? 'N/A';
        final estado = data['estado'] ?? data['Estado'] ?? 'N/A';
        final total = data['total'] ?? data['Total'];
        final observaciones = data['observaciones'] ?? data['Observaciones'] ?? '';

        final clienteObj = data['cliente'] ?? data['Cliente'] ?? {};
        final cli = {
          'nombre': clienteObj['nombre'] ?? clienteObj['Nombres'] ?? clienteObj['Nombre'] ?? 'Sin nombre',
          'apellido': clienteObj['apellido'] ?? clienteObj['Apellidos'] ?? clienteObj['Apellido'] ?? '',
          'correo': clienteObj['correo'] ?? clienteObj['Correo'] ?? '',
          'telefono': clienteObj['telefono']?.toString() ?? clienteObj['Telefono']?.toString() ?? '',
          'direccion': clienteObj['direccion'] ?? clienteObj['Direccion'] ?? '',
        };

        // Detalles (productos)
        final detallesRaw = (data['detalles'] ?? data['Detalles'] ?? []) as List<dynamic>;
        final dets = detallesRaw.map<Map<String, dynamic>>((d) {
          final prod = d['producto'] ?? d['Producto'] ?? {};
          final nombreProd = prod['nombre'] ?? prod['Nombre'] ?? 'Producto';

          // Posibles nombres para imagen en producto
          final imagenPath = prod['imagen'] ?? prod['Imagen'] ?? prod['image'] ?? prod['imageUrl'] ?? '';
          final imagenUrl = ApiConfig.getImageUrl(imagenPath.toString());

          final cant = d['cantidad'] ?? d['Cantidad'] ?? 0;
          final precioUnit = d['precioUnitario'] ?? d['PrecioUnitario'] ?? d['precio'] ?? d['Precio'] ?? 0;
          final cantidadNum = (cant is num ? cant : num.tryParse(cant.toString()) ?? 0);
          final precioNum = (precioUnit is num ? precioUnit : num.tryParse(precioUnit.toString()) ?? 0);
          final totalLinea = cantidadNum * precioNum;

          return {
            'producto': nombreProd,
            'cantidad': cantidadNum,
            'precioUnitario': precioNum,
            'totalLinea': totalLinea,
            'imagenUrl': imagenUrl,
          };
        }).toList();

        setState(() {
          venta = {
            'id': id,
            'fecha': fechaStr,
            'metodoPago': metodoPago,
            'estado': estado,
            'total': total,
            'observaciones': observaciones,
          };
          cliente = cli;
          detalles = dets;
          isLoading = false;
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

  String _formatDate(String fecha) {
    try {
      final parts = fecha.split('-');
      if (parts.length == 3) {
        return '${parts[2]}/${parts[1]}/${parts[0]}';
      }
      return fecha;
    } catch (_) {
      return fecha;
    }
  }

  final NumberFormat _currency = NumberFormat.currency(locale: 'es', symbol: '\$');

  String _formatCurrency(num? value) {
    final v = value ?? 0;
    return _currency.format(v);
  }

  @override
  Widget build(BuildContext context) {
    final v = venta;
    final c = cliente;

    return Scaffold(
      appBar: AppBar(
        title: Text(v != null ? 'Venta #${v['id']}' : 'Detalle de Venta'),
        backgroundColor: const Color(0xFFFFC928),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : hasError
              ? const Center(child: Text('No se pudo cargar el detalle'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Resumen Venta
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('ID: ${v?['id'] ?? ''}'),
                              Text('Fecha: ${v?['fecha'] ?? ''}'),
                              Text('Método de Pago: ${v?['metodoPago'] ?? ''}'),
                              Text('Estado: ${v?['estado'] ?? ''}'),
                              if ((v?['observaciones'] ?? '').toString().isNotEmpty)
                                Text('Observaciones: ${v?['observaciones']}', maxLines: 3),
                              const SizedBox(height: 8),
                              if (v?['total'] != null)
                                Text('Total: ${_formatCurrency(v?['total'] as num)}',
                                    style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Datos Cliente
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Cliente', style: TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Text('Nombre: ${c?['nombre'] ?? ''} ${c?['apellido'] ?? ''}'),
                              Text('Correo: ${c?['correo'] ?? ''}'),
                              Text('Teléfono: ${c?['telefono'] ?? ''}'),
                              Text('Dirección: ${c?['direccion'] ?? ''}'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Productos vendidos
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Productos', style: TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              if (detalles.isEmpty)
                                const Text('No hay detalles de productos para esta venta.'),
                              for (final d in detalles)
                                ListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  leading: ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: Image.network(
                                      d['imagenUrl']?.toString() ?? ApiConfig.getImageUrl(''),
                                      width: 46,
                                      height: 46,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(Icons.image, size: 32),
                                    ),
                                  ),
                                  title: Text(d['producto'].toString()),
                                  subtitle: Text(
                                    'Cantidad: ${d['cantidad']} • Precio unit.: ${_formatCurrency(d['precioUnitario'] as num)}',
                                  ),
                                  trailing: Text(_formatCurrency(d['totalLinea'] as num)),
                                ),
                              const Divider(),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  'Total productos: ${_formatCurrency(detalles.fold<num>(0, (sum, d) => sum + (d['totalLinea'] as num)))}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
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