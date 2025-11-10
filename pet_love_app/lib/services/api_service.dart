import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ApiService {


  // Método para crear una nueva orden
  static Future<Map<String, dynamic>> createOrder(Order order) async {
    final url = Uri.parse(ApiConfig.getVentasUrl());
    final response = await http.post(
      url,
      headers: ApiConfig.defaultHeaders,
      body: jsonEncode(order.toJson()),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return {
        'success': true,
        'data': jsonDecode(response.body.isNotEmpty ? response.body : '{}'),
      };
    } else {
      return {
        'success': false,
        'error': 'Error ${response.statusCode}: ${response.body}',
      };
    }
  }

  static Future<List<dynamic>> getAll(String endpoint) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/$endpoint');
    final response = await http.get(url, headers: ApiConfig.defaultHeaders);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al cargar $endpoint: ${response.statusCode}');
    }
  }

  static Future<dynamic> get(String endpoint) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/$endpoint');
    final headers = await _getHeaders();

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    }

    if (response.statusCode == 404) {
      // Recurso no encontrado: devolver null para que la UI lo maneje con un mensaje amigable
      return null;
    }

    throw Exception('Error GET ${response.statusCode}: ${response.body}');
  }

  static Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/$endpoint');
    final response = await http.post(
      url,
      headers: ApiConfig.defaultHeaders,
      body: jsonEncode(data),
    );
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al guardar: ${response.statusCode}');
    }
  }

  static Future<void> put(String endpoint, int id, Map<String, dynamic> data) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/$endpoint/$id');
    final response = await http.put(
      url,
      headers: ApiConfig.defaultHeaders,
      body: jsonEncode(data),
    );
    
    if (response.statusCode != 200) {
      throw Exception('Error al actualizar: ${response.statusCode}');
    }
  }

  static Future<void> delete(String endpoint, int id) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/$endpoint/$id');
    final response = await http.delete(url, headers: ApiConfig.defaultHeaders);
    
    if (response.statusCode != 200) {
      throw Exception('Error al eliminar: ${response.statusCode}');
    }
  }
  // Token opcional si deseas incluir autorización Bearer en las llamadas
  static String? _token;

  static Future<Map<String, String>> _getHeaders() async {
    final headers = Map<String, String>.from(ApiConfig.defaultHeaders);
    if (_token != null && _token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  static void setToken(String? token) {
    _token = token;
  }

  // Sincroniza usuario/cliente usando solo email y datos opcionales.
  // Este endpoint devuelve token y crea/actualiza el cliente sin requerir rol Admin.
  static Future<Map<String, dynamic>> oauthSync({
    required String email,
    String? nombre,
    String? apellido,
    String? telefono,
    String? direccion,
  }) async {
    final url = Uri.parse('${ApiConfig.getAuthUrl()}/oauth-sync');
    final body = <String, dynamic>{
      'email': email.trim(),
      if (nombre != null && nombre.trim().isNotEmpty) 'nombre': nombre.trim(),
      if (apellido != null && apellido.trim().isNotEmpty) 'apellido': apellido.trim(),
      if (telefono != null && telefono.trim().isNotEmpty) 'telefono': telefono.trim(),
      if (direccion != null && direccion.trim().isNotEmpty) 'direccion': direccion.trim(),
    };

    // oauth-sync suele ser público (AllowAnonymous), no adjuntamos Authorization
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['token'];
      if (token is String && token.isNotEmpty) {
        setToken(token); // quitar await (setToken retorna void)
      }
      return {
        'exitoso': true,
        'token': token,
        'usuario': data['usuario'],
        'cliente': data['cliente'],
      };
    }

    // Manejo explícito de errores comunes
    if (response.statusCode == 401) {
      throw Exception('oauth-sync: Token inválido o expirado (401): ${response.body}');
    }
    if (response.statusCode == 403) {
      throw Exception('oauth-sync: Acceso denegado: permisos insuficientes (403): ${response.body}');
    }

    throw Exception('oauth-sync: Error ${response.statusCode}: ${response.body}');
  }

  static Future<Map<String, dynamic>?> getClienteByEmail(String email) async {
    final encoded = Uri.encodeComponent(email.trim().toLowerCase());
    final url = Uri.parse('${ApiConfig.getClientesUrl()}/by-email/$encoded');
    final response = await http.get(url, headers: await _getHeaders());
    if (response.statusCode == 200) {
      final body = response.body.isNotEmpty ? jsonDecode(response.body) : null;
      return (body is Map<String, dynamic>) ? body : null;
    }
    if (response.statusCode == 404) {
      return null; // cliente no encontrado
    }
    throw Exception('Error al buscar cliente: ${response.statusCode}: ${response.body}');
  }

  // Iniciar sesión (valida correo y contraseña)
  static Future<Map<String, dynamic>> login({
    required String correo,
    required String clave,
  }) async {
    final url = Uri.parse('${ApiConfig.getAuthUrl()}/login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'Correo': correo.trim(), 'Clave': clave}),
    );

    final body = response.body.isNotEmpty ? jsonDecode(response.body) : {};
    final exitoso = (body['exitoso'] ?? body['Exitoso']) == true;
    if (response.statusCode != 200 || !exitoso) {
      final mensaje = body['mensaje'] ?? body['Mensaje'] ?? 'Error al iniciar sesión';
      throw Exception(mensaje);
    }

    final data = body['data'] ?? body['Data'] ?? {};
    final token = data['token'] ?? data['Token'];
    if (token is String && token.isNotEmpty) {
      setToken(token);
    }

    return {
      'exitoso': true,
      'token': token,
      'usuario': data['usuario'] ?? data['Usuario'],
    };
  }

  // Registrar usuario (valida formato de correo y contraseña + confirmación)
  static Future<Map<String, dynamic>> register({
    required String nombres,
    required String apellidos,
    required String correo,
    required String clave,
    required String confirmarClave,
  }) async {
    final url = Uri.parse('${ApiConfig.getAuthUrl()}/register');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'Nombres': nombres.trim(),
        'Apellidos': apellidos.trim(),
        'Correo': correo.trim(),
        'Clave': clave,
        'ConfirmarClave': confirmarClave,
        'IdRol': 3,
      }),
    );

    final body = response.body.isNotEmpty ? jsonDecode(response.body) : {};
    final exitoso = (body['exitoso'] ?? body['Exitoso']) == true;

    if (response.statusCode != 200 || !exitoso) {
      // Logs para depurar el motivo del 400
      print('Register response status: ${response.statusCode}');
      print('Register response body: ${response.body}');

      final errores = (body['errores'] ?? body['Errores']) as List<dynamic>? ?? [];
      final mensajeBase = body['mensaje'] ?? body['Mensaje'] ?? 'Error en el registro';
      final mensajeErrores = errores.isNotEmpty ? ': ${errores.join(', ')}' : '';
      throw Exception('$mensajeBase$mensajeErrores');
    }

    final data = body['data'] ?? body['Data'] ?? {};
    return {
      'exitoso': true,
      'usuario': data['usuario'] ?? data['Usuario'],
    };
  }

  static Future<bool> resetPassword({
    required String correo,
    required String codigo,
    required String nuevaClave,
    required String confirmarClave,
  }) async {
    final url = Uri.parse('${ApiConfig.getAuthUrl()}/reset-password');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'Correo': correo.trim(),
        'Codigo': codigo.trim(),
        'NuevaClave': nuevaClave,
        'ConfirmarClave': confirmarClave,
      }),
    );
  
    final body = response.body.isNotEmpty ? jsonDecode(response.body) : {};
    final exitoso = (body['exitoso'] ?? body['Exitoso']) == true;
    if (response.statusCode == 200 && exitoso) {
      return true;
    }

    final mensaje = body['mensaje'] ?? body['Mensaje'] ?? 'Error al restablecer contraseña';
    throw Exception(mensaje);
  }
  // Nuevo: solicitar código de recuperación
  static Future<Map<String, dynamic>> forgotPassword({
    required String correo,
  }) async {
    final url = Uri.parse('${ApiConfig.getAuthUrl()}/forgot-password');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'Correo': correo.trim()}),
    );

    final body = response.body.isNotEmpty ? jsonDecode(response.body) : {};
    final exitoso = (body['exitoso'] ?? body['Exitoso']) == true;

    // Logs para depurar
    print('ForgotPassword status: ${response.statusCode}');
    print('ForgotPassword body: ${response.body}');

    if (response.statusCode == 200 && exitoso) {
      final data = body['data'] ?? body['Data'];
      return {'exitoso': true, 'data': data};
    }

    final errores = (body['errores'] ?? body['Errores']) as List<dynamic>? ?? [];
    final mensaje = (body['mensaje'] ?? body['Mensaje'] ?? 'No se pudo enviar el código') +
        (errores.isNotEmpty ? ': ${errores.join(', ')}' : '');
    throw Exception(mensaje);
  }

  static Future<bool> verifyCode({
    required String correo,
    required String codigo,
  }) async {
    final url = Uri.parse('${ApiConfig.getAuthUrl()}/verify-code');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'Correo': correo.trim(),
        'Codigo': codigo.trim(),
      }),
    );
  
    // FIX: usar statusCode (no status_code)
    print('VerifyCode response status: ${response.statusCode}');
    print('VerifyCode response body: ${response.body}');
  
    final body = response.body.isNotEmpty ? jsonDecode(response.body) : {};
    final exitoso = (body['exitoso'] ?? body['Exitoso']) == true;
    if (response.statusCode == 200 && exitoso) {
      return true;
    }
    final errores = (body['errores'] ?? body['Errores']) as List<dynamic>? ?? [];
    final mensaje = (body['mensaje'] ?? body['Mensaje'] ?? 'Código inválido o expirado') +
        (errores.isNotEmpty ? ': ${errores.join(', ')}' : '');
    throw Exception(mensaje);
  }
}

// Modelo para la orden (VentaCreateDto)
class Order {
  final int clienteId;
  final String? fechaVenta; // ISO string o null
  final String? metodoPago;
  final String? estado; // debe ser string
  final String? observaciones;
  final List<OrderDetail> detallesVenta;

  Order({
    required this.clienteId,
    this.fechaVenta,
    this.metodoPago,
    this.estado,
    this.observaciones,
    required this.detallesVenta,
  });

  Map<String, dynamic> toJson() {
    final map = {
      'clienteId': clienteId,
      'fechaVenta': fechaVenta,
      'metodoPago': metodoPago,
      'estado': estado,
      'observaciones': observaciones,
      'detallesVenta': detallesVenta.map((detalle) => detalle.toJson()).toList(),
    };
    // eliminar campos null para evitar errores de binding
    map.removeWhere((key, value) => value == null);
    return map;
  }
}

// Modelo para los detalles (DetalleVentaCreateDto)
class OrderDetail {
  final int productoId;
  final int cantidad;
  final double? precioUnitario; // opcional
  final double? descuento;      // opcional

  OrderDetail({
    required this.productoId,
    required this.cantidad,
    this.precioUnitario,
    this.descuento,
  });

  Map<String, dynamic> toJson() {
    final map = {
      'productoId': productoId,
      'cantidad': cantidad,
      'precioUnitario': precioUnitario,
      'descuento': descuento,
    };
    map.removeWhere((key, value) => value == null);
    return map;
  }
}