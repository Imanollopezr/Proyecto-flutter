import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pet_love_app/main.dart';
import 'package:pet_love_app/services/api_service.dart';
import 'package:pet_love_app/services/user_session.dart';
import 'package:pet_love_app/screens/my_orders_screen.dart';
import 'package:pet_love_app/screens/category_screen.dart';
import 'package:pet_love_app/screens/home_screen.dart';

class ShoppingCartScreen extends StatefulWidget {
  const ShoppingCartScreen({Key? key}) : super(key: key);

  @override
  State<ShoppingCartScreen> createState() => _ShoppingCartScreenState();
}

class _ShoppingCartScreenState extends State<ShoppingCartScreen> {
  bool isLoading = false;
  String metodoPago = 'Efectivo';

  /// Muestra formulario de cliente, busca por email y si no existe intenta crear el cliente
  Future<int?> _solicitarDatosClienteYObtenerId(BuildContext context) async {
    final session = Provider.of<UserSession>(context, listen: false);
    final emailSesion = session.email?.trim().toLowerCase();

    if (emailSesion == null || emailSesion.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debe iniciar sesión para continuar con la compra'),
          backgroundColor: Colors.red,
        ),
      );
      Navigator.pushNamed(
        context,
        '/signin',
        arguments: {'redirect': '/shoppingcart'},
      );
      return null;
    }

    Map<String, dynamic>? clienteActual;
    try {
      clienteActual = await ApiService.getClienteByEmail(emailSesion);
    } catch (_) {}

    final formKey = GlobalKey<FormState>();
    final nombreController = TextEditingController(
        text: clienteActual?['nombre'] ?? clienteActual?['Nombre'] ?? '');
    final apellidoController = TextEditingController(
        text: clienteActual?['apellido'] ?? clienteActual?['Apellido'] ?? '');
    final telefonoController = TextEditingController(
        text: clienteActual?['telefono']?.toString() ??
            clienteActual?['Telefono']?.toString() ??
            '');
    final direccionController = TextEditingController(
        text: clienteActual?['direccion'] ?? clienteActual?['Direccion'] ?? '');

    final datos = await showDialog<Map<String, String>?>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Datos del cliente'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    initialValue: emailSesion,
                    readOnly: true,
                    decoration: const InputDecoration(
                        labelText: 'Correo', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: nombreController,
                    decoration: const InputDecoration(
                        labelText: 'Nombre', border: OutlineInputBorder()),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Nombre es obligatorio';
                      }
                      if (v.trim().length < 2) {
                        return 'Debe tener al menos 2 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: apellidoController,
                    decoration: const InputDecoration(
                        labelText: 'Apellido', border: OutlineInputBorder()),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Apellido es obligatorio';
                      }
                      if (v.trim().length < 2) {
                        return 'Debe tener al menos 2 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: telefonoController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                        labelText: 'Teléfono (opcional)',
                        border: OutlineInputBorder()),
                    validator: (v) {
                      if (v == null || v.isEmpty) return null;
                      final digitsOnly = v.replaceAll(RegExp(r'\D'), '');
                      if (digitsOnly.length < 7 || digitsOnly.length > 15) {
                        return 'Teléfono debe tener entre 7 y 15 dígitos';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: direccionController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                        labelText: 'Dirección', border: OutlineInputBorder()),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Dirección es obligatoria';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(null),
                child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState?.validate() != true) return;
                Navigator.of(ctx).pop({
                  'Nombre': nombreController.text.trim(),
                  'Apellido': apellidoController.text.trim(),
                  'Telefono': telefonoController.text.trim(),
                  'Direccion': direccionController.text.trim(),
                });
              },
              child: const Text('Continuar'),
            ),
          ],
        );
      },
    );

    if (datos == null) return null;

    try {
      await ApiService.oauthSync(
        email: emailSesion,
        nombre: datos['Nombre'],
        apellido: datos['Apellido'],
        telefono:
            (datos['Telefono']?.isNotEmpty == true) ? datos['Telefono'] : null,
        direccion: datos['Direccion'],
      );

      final clienteSincronizado = await ApiService.getClienteByEmail(emailSesion);
      final idRaw = clienteSincronizado?['id'] ?? clienteSincronizado?['Id'];
      final clienteId =
          idRaw is int ? idRaw : int.tryParse(idRaw?.toString() ?? '');
      if (clienteId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('No se pudo obtener el ID del cliente'),
              backgroundColor: Colors.red),
        );
        return null;
      }
      return clienteId;
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('UNAUTHORIZED') ||
          msg.contains('401') ||
          msg.contains('Token inválido')) {
        await ApiService.oauthSync(email: emailSesion);
        final c2 = await ApiService.getClienteByEmail(emailSesion);
        final idRaw2 = c2?['id'] ?? c2?['Id'];
        final id2 = idRaw2 is int ? idRaw2 : int.tryParse(idRaw2?.toString() ?? '');
        if (id2 != null) return id2;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error al guardar datos del cliente: $e'),
            backgroundColor: Colors.red),
      );
      return null;
    }
  }

  /// Diálogo para seleccionar un cliente existente con búsqueda
  Future<int?> _seleccionarClienteExistenteDialog() async {
    bool initialized = false;
    bool cargando = true;
    List<dynamic> clientes = [];
    List<dynamic> filtrados = [];
    final searchController = TextEditingController();

    final selectedId = await showDialog<int?>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setStateSB) {
            Future<void> cargar() async {
              try {
                final data = await ApiService.getAll('clientes');
                clientes = data;
                filtrados = clientes;
              } catch (_) {
                clientes = [];
                filtrados = [];
              } finally {
                setStateSB(() => cargando = false);
              }
            }

            if (!initialized) {
              initialized = true;
              cargar();
            }

            return AlertDialog(
              title: const Text('Seleccionar cliente existente'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: searchController,
                      decoration: const InputDecoration(
                        labelText: 'Buscar por nombre o email',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (q) {
                        final query = q.trim().toLowerCase();
                        setStateSB(() {
                          filtrados = clientes.where((c) {
                            final nombre = (c['nombre'] ?? c['Nombre'] ?? '')
                                .toString()
                                .toLowerCase();
                            final apellido = (c['apellido'] ?? c['Apellido'] ?? '')
                                .toString()
                                .toLowerCase();
                            final email =
                                (c['email'] ?? c['Email'] ?? '').toString().toLowerCase();
                            return nombre.contains(query) ||
                                apellido.contains(query) ||
                                email.contains(query);
                          }).toList();
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    if (cargando)
                      const Center(child: CircularProgressIndicator())
                    else
                      SizedBox(
                        height: 300,
                        child: ListView.builder(
                          itemCount: filtrados.length,
                          itemBuilder: (ctx, i) {
                            final c = filtrados[i];
                            final nombre =
                                (c['nombre'] ?? c['Nombre'] ?? '').toString();
                            final apellido =
                                (c['apellido'] ?? c['Apellido'] ?? '').toString();
                            final email =
                                (c['email'] ?? c['Email'] ?? '').toString();
                            final idRaw = c['id'] ?? c['Id'];
                            final id = idRaw is int
                                ? idRaw
                                : int.tryParse(idRaw?.toString() ?? '');
                            return ListTile(
                              title: Text('$nombre $apellido'),
                              subtitle: Text(email),
                              trailing: const Icon(Icons.check_circle_outline),
                              onTap: () => Navigator.pop(ctx, id),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, null),
                  child: const Text('Cancelar'),
                ),
              ],
            );
          },
        );
      },
    );

    return selectedId;
  }

  /// Muestra un resumen claro de los productos incluidos en la compra
  Future<bool> _mostrarResumenCompra(CartModel cart) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Resumen de compra'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Lista de productos con cantidad y totales por línea
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: cart.items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final it = cart.items[index];
                      final lineTotal = (it.price * it.quantity);
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          it.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '${it.quantity} x \$${it.price.toStringAsFixed(0)}',
                          style: const TextStyle(color: Colors.black54),
                        ),
                        trailing: Text(
                          '\$${lineTotal.toStringAsFixed(0)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(),
                // Totales
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Subtotal:', style: TextStyle(fontSize: 16)),
                    Text('\$${cart.totalPrice.toStringAsFixed(0)}', style: const TextStyle(fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    Text('\$${cart.totalPrice.toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Editar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    ).then((value) => value ?? false);
  }

  /// Inicia el checkout: muestra resumen -> formulario cliente -> crear orden
  Future<void> _iniciarCompra(CartModel cart) async {
    if (cart.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El carrito está vacío'), backgroundColor: Colors.orange),
      );
      return;
    }

    // Paso 1: resumen y confirmación
    final confirmado = await _mostrarResumenCompra(cart);
    if (!confirmado) return;

    // Paso 2: solicitar/validar datos del cliente
    final clienteId = await _solicitarDatosClienteYObtenerId(context);
    if (clienteId == null) return;

    // Paso 3: crear la orden
    await _createOrder(cart, clienteId);
  }

  /// Crea la orden con pago en efectivo
  Future<void> _createOrder(CartModel cart, int clienteId) async {
    setState(() => isLoading = true);
    try {
      final insuficientes =
          cart.items.where((it) => it.quantity > it.availableStock).toList();
      if (insuficientes.isNotEmpty) {
        final productos = insuficientes.map((e) => e.title).join(', ');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('No hay stock suficiente para: $productos'),
              backgroundColor: Colors.red),
        );
        return;
      }

      final order = Order(
        clienteId: clienteId,
        fechaVenta: DateTime.now().toIso8601String(),
        metodoPago: 'Efectivo',
        estado: 'Pendiente',
        observaciones: null,
        detallesVenta: cart.items
            .map((it) => OrderDetail(
                  productoId: it.productId,
                  cantidad: it.quantity,
                ))
            .toList(),
      );

      final result = await ApiService.createOrder(order);

      if (result['success'] == true) {
        // Extraer el ID si viene en la respuesta
        final created = result['data'];
        final createdIdRaw = created is Map ? (created['id'] ?? created['Id']) : null;
        final createdId = createdIdRaw is int ? createdIdRaw : int.tryParse('${createdIdRaw ?? ''}');

        // Aviso breve
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Compra creada correctamente')),
        );

        // Vaciar carrito
        cart.clearCart();

        // Diálogo de confirmación: informa y obliga a ir al inicio
        await showDialog(
          context: context,
          barrierDismissible: false, // no se puede cerrar tocando fuera
          builder: (ctx) => AlertDialog(
            title: const Text('Pedido realizado con éxito'),
            content: Text(
              'Tu pedido ha sido registrado correctamente'
              '${createdId != null ? ' (Venta #$createdId)' : ''}. '
              'Ya puedes ver tus pedidos en la sección "Mis Pedidos".',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop(); // cerrar diálogo
                  // Forzar volver al Inicio y limpiar el historial
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                    (route) => false,
                  );
                },
                child: const Text('Ir al inicio'),
              ),
            ],
          ),
        );
      } else {
        final errorMsg = result['error']?.toString() ?? 'Error desconocido';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al crear la compra: $errorMsg'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al crear la compra: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  /// Construye la vista de productos agrupados por categoría
  Widget _buildGroupedCartItems(CartModel cart) {
    final groupedItems = cart.itemsByCategory;
    
    return ListView.builder(
      itemCount: groupedItems.length,
      itemBuilder: (context, categoryIndex) {
        final categoryName = groupedItems.keys.elementAt(categoryIndex);
        final categoryItems = groupedItems[categoryName]!;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado de categoría
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFC928).withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFC928), width: 1),
              ),
              child: Row(
                children: [
                  Icon(
                    _getCategoryIcon(categoryName),
                    color: Colors.black87,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    categoryName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFC928),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${categoryItems.length} ${categoryItems.length == 1 ? 'producto' : 'productos'}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Productos de la categoría
            ...categoryItems.asMap().entries.map((entry) {
              final itemIndex = entry.key;
              final item = entry.value;
              final globalIndex = cart.items.indexOf(item);
              
              return Card(
                color: Colors.amber.shade50,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: item.image.startsWith('http')
                            ? Image.network(
                                item.image,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported),
                              )
                            : Image.asset(
                                item.image,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline),
                                  onPressed: () {
                                    if (item.quantity > 1) {
                                      Provider.of<CartModel>(context, listen: false)
                                          .updateQuantity(globalIndex, item.quantity - 1);
                                    } else {
                                      Provider.of<CartModel>(context, listen: false).removeItem(globalIndex);
                                    }
                                  },
                                ),
                                Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.w600)),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline),
                                  onPressed: () {
                                    if (item.quantity < item.availableStock) {
                                      Provider.of<CartModel>(context, listen: false)
                                          .updateQuantity(globalIndex, item.quantity + 1);
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Stock máximo alcanzado para ${item.title} (${item.availableStock})',
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  },
                                ),
                                const Spacer(),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    Provider.of<CartModel>(context, listen: false).removeItem(globalIndex);
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '\$${(item.price * item.quantity).toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text(
                            '\$${item.price.toStringAsFixed(0)} c/u',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  /// Obtiene el icono apropiado para cada categoría
  IconData _getCategoryIcon(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'alimentos':
      case 'comida':
        return Icons.restaurant;
      case 'juguetes':
        return Icons.toys;
      case 'accesorios':
        return Icons.pets;
      case 'medicamentos':
      case 'medicina':
        return Icons.medical_services;
      case 'higiene':
      case 'cuidado':
        return Icons.cleaning_services;
      default:
        return Icons.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Carrito'),
        backgroundColor: const Color(0xFFFFC928),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_shopping_cart),
            tooltip: 'Agregar más productos',
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const CategoryScreen()),
              );
            },
          ),
          if (cart.items.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Vaciar carrito'),
                    content: const Text('¿Estás seguro de que quieres vaciar todo el carrito?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar'),
                      ),
                      TextButton(
                        onPressed: () {
                          cart.clearCart();
                          Navigator.pop(context);
                        },
                        child: const Text('Vaciar', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: Column(
        children: [

          Expanded(
            child: cart.items.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey),
                        SizedBox(height: 20),
                        Text('Tu carrito está vacío', style: TextStyle(fontSize: 20, color: Colors.grey)),
                      ],
                    ),
                  )
                : _buildGroupedCartItems(cart),
          ),
          if (cart.items.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Método de pago exclusivamente en efectivo (no editable)
                  InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Método de pago',
                      border: OutlineInputBorder(),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.payments_outlined, color: Colors.black54),
                        SizedBox(width: 8),
                        Text('Efectivo', style: TextStyle(fontWeight: FontWeight.w600)),
                        Spacer(),
                        Chip(label: Text('Único método')),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Subtotal:', style: TextStyle(fontSize: 18)),
                      Text(
                        '\$${cart.totalPrice.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 18),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Se elimina la fila de envío y el cálculo asociado para que el total
                  // refleje exclusivamente el valor de los productos.
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                      Text(
                        '\$${cart.totalPrice.toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFC928),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        textStyle: const TextStyle(fontSize: 18),
                      ),
                      onPressed: isLoading ? null : () => _iniciarCompra(cart),
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.black)
                          : const Text('Finalizar compra'),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      // Se ha eliminado el floatingActionButton de "Agregar productos"
    );
  }
}
