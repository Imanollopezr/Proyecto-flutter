import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:pet_love_app/config/api_config.dart';
import 'package:pet_love_app/screens/sale_detail_screen.dart';

class AdminSalesScreen extends StatefulWidget {
  const AdminSalesScreen({super.key});

  @override
  State<AdminSalesScreen> createState() => _AdminSalesScreenState();
}

class _AdminSalesScreenState extends State<AdminSalesScreen> {
  List<Map<String, dynamic>> ventas = [];
  bool isLoading = true;
  bool hasError = false;

  // Filtros y ordenación
  final TextEditingController searchController = TextEditingController();
  String? metodoPagoFilter; // null = todos
  String sortField = 'fecha'; // 'fecha' | 'id'
  bool sortAsc = false;
  List<Map<String, dynamic>> filteredVentas = [];

  @override
  void initState() {
    super.initState();
    _fetchVentas();
  }

  // Obtener ventas desde la API
  Future<void> _fetchVentas() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.getVentasUrl()),
        headers: ApiConfig.defaultHeaders,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        final List<Map<String, dynamic>> listaVentas = data.map<Map<String, dynamic>>((venta) {
          final id = venta['id'] ?? venta['Id'] ?? 0;
          final fechaRaw = venta['fechaVenta'] ?? venta['FechaVenta'] ?? '';
          final fechaStr = fechaRaw is String ? _formatDate(fechaRaw.split('T').first) : '';
          final metodoPago = venta['metodoPago'] ?? venta['MetodoPago'] ?? 'N/A';
          final estado = venta['estado'] ?? venta['Estado'] ?? 'N/A';

          final clienteObj = venta['cliente'] ?? venta['Cliente'];
          final clienteStr = (clienteObj is Map)
              ? (clienteObj['nombre'] ?? clienteObj['Nombres'] ?? clienteObj['Nombre'] ?? 'Cliente')
              : 'Cliente';

          // Si el backend devuelve total, lo tomamos; si no, lo dejamos en null
          final total = venta['total'] ?? venta['Total'];

          return {
            'id': id is int ? id : int.tryParse(id.toString()) ?? 0,
            'cliente': clienteStr,
            'fecha': fechaStr,
            'fechaRaw': fechaRaw, // para ordenar con precisión si hiciera falta
            'metodoPago': metodoPago,
            'estado': estado,
            'total': total,
          };
        }).toList();

        setState(() {
          ventas = listaVentas;
          isLoading = false;
        });
        _applyFilters(); // NUEVO
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

  void _applyFilters() {
    List<Map<String, dynamic>> temp = List.from(ventas);

    // Filtro por texto (cliente o ID)
    final q = searchController.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      temp = temp.where((v) {
        final cliente = (v['cliente'] ?? '').toString().toLowerCase();
        final idStr = (v['id'] ?? '').toString();
        return cliente.contains(q) || idStr.contains(q);
      }).toList();
    }

    // Filtro por método de pago
    if (metodoPagoFilter != null && metodoPagoFilter!.isNotEmpty) {
      temp = temp.where((v) => (v['metodoPago'] ?? '').toString().toLowerCase() == metodoPagoFilter!.toLowerCase()).toList();
    }

    // Ordenación
    temp.sort((a, b) {
      int cmp;
      if (sortField == 'id') {
        cmp = (a['id'] as int).compareTo(b['id'] as int);
      } else {
        // Intentamos ordenar por fechaRaw si está presente; si no, por la cadena formateada
        final fa = (a['fechaRaw'] ?? a['fecha'] ?? '').toString();
        final fb = (b['fechaRaw'] ?? b['fecha'] ?? '').toString();
        cmp = fa.compareTo(fb);
      }
      return sortAsc ? cmp : -cmp;
    });

    setState(() {
      filteredVentas = temp;
    });
  }

  void _openDetalle(int ventaId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SaleDetailScreen(ventaId: ventaId),
      ),
    );
  }

  // Formatear fecha YYYY-MM-DD a DD/MM/YYYY
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
        actions: [
          // Ordenación
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                if (value == 'fecha_asc') { sortField = 'fecha'; sortAsc = true; }
                if (value == 'fecha_desc') { sortField = 'fecha'; sortAsc = false; }
                if (value == 'id_asc') { sortField = 'id'; sortAsc = true; }
                if (value == 'id_desc') { sortField = 'id'; sortAsc = false; }
              });
              _applyFilters();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'fecha_desc', child: Text('Ordenar por Fecha (desc)')),
              const PopupMenuItem(value: 'fecha_asc', child: Text('Ordenar por Fecha (asc)')),
              const PopupMenuItem(value: 'id_desc', child: Text('Ordenar por ID (desc)')),
              const PopupMenuItem(value: 'id_asc', child: Text('Ordenar por ID (asc)')),
            ],
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : hasError
              ? const Center(child: Text('Error al cargar las ventas'))
              : Column(
                  children: [
                    // Filtros
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: searchController,
                              decoration: const InputDecoration(
                                labelText: 'Buscar por cliente o ID',
                                prefixIcon: Icon(Icons.search),
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (_) => _applyFilters(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          DropdownButton<String>(
                            value: metodoPagoFilter?.isEmpty == true ? null : metodoPagoFilter,
                            hint: const Text('Método pago'),
                            items: const [
                              DropdownMenuItem(value: 'Efectivo', child: Text('Efectivo')),
                              DropdownMenuItem(value: 'Tarjeta', child: Text('Tarjeta')),
                              DropdownMenuItem(value: 'Transferencia', child: Text('Transferencia')),
                            ],
                            onChanged: (val) {
                              metodoPagoFilter = val;
                              _applyFilters();
                            },
                          ),
                          IconButton(
                            tooltip: 'Limpiar filtros',
                            onPressed: () {
                              searchController.clear();
                              metodoPagoFilter = null;
                              _applyFilters();
                            },
                            icon: const Icon(Icons.filter_alt_off),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: (filteredVentas.isEmpty)
                          ? const Center(child: Text('No se encontraron ventas'))
                          : ListView.builder(
                              itemCount: filteredVentas.length,
                              itemBuilder: (context, index) {
                                final venta = filteredVentas[index];
                                return Card(
                                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  child: ListTile(
                                    title: Text('Venta #${venta['id']}'),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Cliente: ${venta['cliente']}'),
                                        Text('Fecha: ${venta['fecha']}'),
                                        Text('Método de Pago: ${venta['metodoPago']}'),
                                        Text('Estado: ${venta['estado']}'),
                                        if (venta['total'] != null) Text('Total: \$${venta['total']}'),
                                      ],
                                    ),
                                    trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                                    onTap: () => _openDetalle(venta['id'] as int),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }
}
