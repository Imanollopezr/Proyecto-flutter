class ApiConfig {
  static const String baseUrl = 'http://localhost:8090';
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
  };
  
  static String getCategoriaProductosUrl() => '$baseUrl/api/categorias';
  static String getProductosUrl() => '$baseUrl/api/productos';
  static String getVentasUrl() => '$baseUrl/api/ventas';
  
  static String getImageUrl(String imagePath) {
    if (imagePath.isEmpty) {
      // Fallback si no hay imagen
      return 'https://via.placeholder.com/150';
    }
    if (imagePath.startsWith('http')) {
      return imagePath;
    }
    // Asegurar que tenga "/" inicial
    final normalized = imagePath.startsWith('/') ? imagePath : '/$imagePath';
    return '$baseUrl$normalized';
  }
  
  static String getClientesUrl() => '$baseUrl/api/clientes';
  static String getEstadosUrl() => '$baseUrl/api/estados';
  static String getMetodosPagoUrl() => '$baseUrl/api/metodospago';
  static String getCarritoUrl() => '$baseUrl/api/carrito';
  static String getComprasUrl() => '$baseUrl/api/compras';
  static String getMarcasUrl() => '$baseUrl/api/marcas';
  static String getMedidasUrl() => '$baseUrl/api/medidas';
  static String getProveedoresUrl() => '$baseUrl/api/proveedores';
  static String getUsuariosUrl() => '$baseUrl/api/usuarios';
  static String getRolesUrl() => '$baseUrl/api/roles';
  static String getPermisosUrl() => '$baseUrl/api/permisos';
  static String getTipoDocumentosUrl() => '$baseUrl/api/tipodocumentos';
  static String getAuthUrl() => '$baseUrl/api/auth';
  static String getArchivosUrl() => '$baseUrl/api/archivos';
  static String getPedidosUrl() => '$baseUrl/api/pedidos';
}