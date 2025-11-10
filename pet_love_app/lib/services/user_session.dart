import 'package:flutter/foundation.dart';
import 'dart:typed_data';

class UserSession extends ChangeNotifier {
  String? email;
  String? nombreRol;
  String? token;

  // Datos del cliente
  String? nombre;
  String? apellido;
  String? telefono;
  String? direccion;

  // Foto de perfil (opcional)
  String? fotoUrl;           // si tiene una URL (futuro, por ejemplo subida al backend)
  Uint8List? fotoBytes;      // si elige desde el dispositivo y la guardamos en memoria

  void setSession({required String email, String? nombreRol, String? token, String? nombre, String? apellido, String? telefono, String? direccion}) {
    this.email = email;
    this.nombreRol = nombreRol;
    this.token = token;
    // Nuevos campos
    this.nombre = nombre ?? this.nombre;
    this.apellido = apellido ?? this.apellido;
    this.telefono = telefono ?? this.telefono;
    this.direccion = direccion ?? this.direccion;
    notifyListeners();
  }

  void setFoto({Uint8List? bytes, String? url}) {
    // Actualizar la foto (uno u otro)
    if (bytes != null) {
      fotoBytes = bytes;
      fotoUrl = null; // priorizamos bytes locales
    } else if (url != null && url.isNotEmpty) {
      fotoUrl = url;
      fotoBytes = null;
    }
    notifyListeners();
  }

  void clear() {
    email = null;
    nombreRol = null;
    token = null;
    // Limpiar también datos del cliente
    nombre = null;
    apellido = null;
    telefono = null;
    direccion = null;
    // Limpiar foto
    fotoUrl = null;
    fotoBytes = null;
    notifyListeners();
  }
}