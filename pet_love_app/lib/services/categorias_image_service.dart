import 'dart:typed_data';
import 'package:http/http.dart' as http;

class CategoriasImageService {
  final String apiBase; // ej: http://localhost:8090

  CategoriasImageService(this.apiBase);

  Future<Uint8List?> obtenerImagenCategoria(int id) async {
    final uri = Uri.parse('$apiBase/api/categorias/$id/imagen');
    final resp = await http.get(uri);
    if (resp.statusCode == 200) {
      return resp.bodyBytes;
    }
    return null; // maneja 404/500 según tu UX
  }
}