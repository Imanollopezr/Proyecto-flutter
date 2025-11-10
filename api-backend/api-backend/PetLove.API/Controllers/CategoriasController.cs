using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PetLove.Core.Models;
using PetLove.Infrastructure.Data;

namespace PetLove.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class CategoriasController : ControllerBase
    {
        private readonly PetLoveDbContext _context;

        public CategoriasController(PetLoveDbContext context)
        {
            _context = context;
        }

        // GET: api/categorias
        [HttpGet]
        public async Task<ActionResult<IEnumerable<Categoria>>> GetCategorias()
        {
            var categorias = await _context.Categorias
                .Where(c => c.Activo)
                .OrderBy(c => c.Nombre)
                .ToListAsync();

            return Ok(categorias);
        }

        // GET: api/categorias/5
        [HttpGet("{id}")]
        public async Task<ActionResult<Categoria>> GetCategoria(int id)
        {
            try
            {
                var categoria = await _context.Categorias.FindAsync(id);

                if (categoria == null || !categoria.Activo)
                {
                    return NotFound();
                }

                return Ok(categoria);
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Error interno del servidor: {ex.Message}");
            }
        }

        // POST: api/categorias
        [HttpPost]
        public async Task<ActionResult<Categoria>> PostCategoria([FromBody] Categoria categoria)
        {
            try
            {
                // Validaciones de campos requeridos
                if (string.IsNullOrWhiteSpace(categoria.Nombre) || categoria.Nombre.Length < 2)
                {
                    return BadRequest("El nombre de la categoría es requerido y debe tener al menos 2 caracteres");
                }

                // Normalizar datos
                categoria.Nombre = categoria.Nombre.Trim();
                categoria.Descripcion = categoria.Descripcion?.Trim();
                categoria.ImagenUrl = string.IsNullOrWhiteSpace(categoria.ImagenUrl) ? null : categoria.ImagenUrl.Trim();

                // Verificar si la categoría ya existe (case-insensitive)
                var categoriaExiste = await _context.Categorias
                    .AnyAsync(c => c.Nombre.ToLower() == categoria.Nombre.ToLower());

                if (categoriaExiste)
                {
                    return Conflict("La categoría ya existe");
                }

                categoria.FechaRegistro = DateTime.Now;
                categoria.Activo = true;

                _context.Categorias.Add(categoria);
                await _context.SaveChangesAsync();

                return CreatedAtAction(nameof(GetCategoria), new { id = categoria.IdCategoriaProducto }, categoria);
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Error interno del servidor: {ex.Message}");
            }
        }

        // PUT: api/categorias/5
        [HttpPut("{id}")]
        public async Task<IActionResult> PutCategoria(int id, [FromBody] Categoria categoria)
        {
            try
            {
                if (id != categoria.IdCategoriaProducto)
                {
                    return BadRequest("El ID no coincide");
                }

                // Validaciones de campos requeridos
                if (string.IsNullOrWhiteSpace(categoria.Nombre) || categoria.Nombre.Length < 2)
                {
                    return BadRequest("El nombre de la categoría es requerido y debe tener al menos 2 caracteres");
                }

                var categoriaExistente = await _context.Categorias.FindAsync(id);
                if (categoriaExistente == null || !categoriaExistente.Activo)
                {
                    return NotFound();
                }

                // Normalizar datos
                var nombreNormalizado = categoria.Nombre.Trim();

                // Verificar si ya existe otra categoría con el mismo nombre (case-insensitive)
                var nombreExiste = await _context.Categorias
                    .AnyAsync(c => c.Nombre.ToLower() == nombreNormalizado.ToLower() && 
                                   c.IdCategoriaProducto != id);

                if (nombreExiste)
                {
                    return Conflict("Ya existe otra categoría con ese nombre");
                }

                // Actualizar propiedades con normalización
                categoriaExistente.Nombre = nombreNormalizado;
                categoriaExistente.Descripcion = categoria.Descripcion?.Trim();
                categoriaExistente.ImagenUrl = string.IsNullOrWhiteSpace(categoria.ImagenUrl) ? null : categoria.ImagenUrl.Trim();

                await _context.SaveChangesAsync();

                return NoContent();
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Error interno del servidor: {ex.Message}");
            }
        }

        // DELETE: api/categorias/5
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteCategoria(int id)
        {
            try
            {
                var categoria = await _context.Categorias.FindAsync(id);
                if (categoria == null || !categoria.Activo)
                {
                    return NotFound();
                }

                // Verificar si hay productos usando esta categoría
                var productosConCategoria = await _context.Productos
                    .CountAsync(p => p.IdCategoriaProducto == id && p.Activo);

                if (productosConCategoria > 0)
                {
                    return BadRequest($"No se puede eliminar la categoría porque tiene {productosConCategoria} productos asociados");
                }

                // Eliminación permanente de la base de datos
                _context.Categorias.Remove(categoria);
                await _context.SaveChangesAsync();

                return NoContent();
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Error interno del servidor: {ex.Message}");
            }
        }

        private bool CategoriaExists(int id)
        {
            return _context.Categorias.Any(e => e.IdCategoriaProducto == id && e.Activo);
        }

        // Crear categoría con imagen (multipart/form-data)
        [HttpPost("con-imagen")]
        public async Task<ActionResult<Categoria>> PostCategoriaConImagen([FromForm] string nombre, [FromForm] string? descripcion, [FromForm] IFormFile? imagen)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(nombre) || nombre.Trim().Length < 2)
                    return BadRequest("El nombre de la categoría es requerido y debe tener al menos 2 caracteres");

                // Normalización
                var nombreNormalizado = nombre.Trim();
                var descripcionNormalizada = descripcion?.Trim();

                // Unicidad
                var existe = await _context.Categorias.AnyAsync(c => c.Nombre.ToLower() == nombreNormalizado.ToLower());
                if (existe) return Conflict("La categoría ya existe");

                string? imagenUrl = null;
                if (imagen != null && imagen.Length > 0)
                {
                    var extensionesPermitidas = new[] { ".jpg", ".jpeg", ".png", ".gif", ".webp" };
                    var extension = Path.GetExtension(imagen.FileName).ToLowerInvariant();
                    if (!extensionesPermitidas.Contains(extension))
                        return BadRequest(new { message = $"Tipo de archivo no permitido. Extensiones: {string.Join(", ", extensionesPermitidas)}" });

                    if (!imagen.ContentType.StartsWith("image/"))
                        return BadRequest(new { message = "El archivo debe ser una imagen válida" });

                    if (imagen.Length > 5 * 1024 * 1024)
                        return BadRequest(new { message = "El archivo es demasiado grande. Máximo 5MB" });

                    var uploadsPath = Path.Combine(Directory.GetCurrentDirectory(), "uploads", "categorias");
                    if (!Directory.Exists(uploadsPath)) Directory.CreateDirectory(uploadsPath);

                    var nombreArchivo = $"{Guid.NewGuid()}{extension}";
                    var rutaCompleta = Path.Combine(uploadsPath, nombreArchivo);
                    using (var stream = new FileStream(rutaCompleta, FileMode.Create))
                    {
                        await imagen.CopyToAsync(stream);
                    }

                    // URL ABSOLUTA en vez de relativa
                    var baseUrl = $"{Request.Scheme}://{Request.Host}";
                    imagenUrl = $"{baseUrl}/uploads/categorias/{nombreArchivo}";
                }

                var nueva = new Categoria
                {
                    Nombre = nombreNormalizado,
                    Descripcion = descripcionNormalizada,
                    ImagenUrl = imagenUrl,
                    Activo = true,
                    FechaRegistro = DateTime.Now
                };

                _context.Categorias.Add(nueva);
                await _context.SaveChangesAsync();

                return CreatedAtAction(nameof(GetCategoria), new { id = nueva.IdCategoriaProducto }, nueva);
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Error interno del servidor: {ex.Message}");
            }
        }

        // Devuelve la imagen binaria de una categoría
        [HttpGet("{id}/imagen")]
        public IActionResult GetCategoriaImagen(int id)
        {
            var categoria = _context.Categorias.FirstOrDefault(c => c.IdCategoriaProducto == id && c.Activo);
            if (categoria == null) return NotFound("Categoría no encontrada");
    
            if (string.IsNullOrWhiteSpace(categoria.ImagenUrl))
                return NotFound("La categoría no tiene imagen");
    
            // Extraer nombre de archivo desde ImagenUrl (absoluta o relativa)
            string nombreArchivo;
            var url = categoria.ImagenUrl!;
            if (Uri.TryCreate(url, UriKind.Absolute, out var abs))
                nombreArchivo = Path.GetFileName(abs.AbsolutePath);
            else
                nombreArchivo = Path.GetFileName(url);
    
            var rutaFisica = Path.Combine(Directory.GetCurrentDirectory(), "uploads", "categorias", nombreArchivo);
            if (!System.IO.File.Exists(rutaFisica))
                return NotFound("Archivo de imagen no encontrado");
    
            var ext = Path.GetExtension(nombreArchivo).ToLowerInvariant();
            var contentType = ext switch
            {
                ".jpg" or ".jpeg" => "image/jpeg",
                ".png" => "image/png",
                ".gif" => "image/gif",
                ".webp" => "image/webp",
                _ => "application/octet-stream"
            };
    
            return PhysicalFile(rutaFisica, contentType);
        }

        [HttpPut("{id}/imagen")]
        public async Task<IActionResult> PutCategoriaImagen(int id, [FromForm] IFormFile imagen)
        {
            var categoria = await _context.Categorias.FirstOrDefaultAsync(c => c.IdCategoriaProducto == id && c.Activo);
            if (categoria == null) return NotFound(new { message = "Categoría no encontrada" });
    
            if (imagen == null || imagen.Length == 0)
                return BadRequest(new { message = "No se ha seleccionado ningún archivo" });
    
            var extensionesPermitidas = new[] { ".jpg", ".jpeg", ".png", ".gif", ".webp" };
            var extension = Path.GetExtension(imagen.FileName).ToLowerInvariant();
            if (!extensionesPermitidas.Contains(extension))
                return BadRequest(new { message = $"Tipo de archivo no permitido. Extensiones: {string.Join(", ", extensionesPermitidas)}" });
    
            if (!imagen.ContentType.StartsWith("image/"))
                return BadRequest(new { message = "El archivo debe ser una imagen válida" });
    
            if (imagen.Length > 5 * 1024 * 1024)
                return BadRequest(new { message = "El archivo es demasiado grande. Máximo 5MB" });
    
            // Eliminar imagen anterior si existe (opcional)
            if (!string.IsNullOrWhiteSpace(categoria.ImagenUrl))
            {
                try
                {
                    var anteriorNombre = Uri.TryCreate(categoria.ImagenUrl!, UriKind.Absolute, out var abs)
                        ? Path.GetFileName(abs.AbsolutePath)
                        : Path.GetFileName(categoria.ImagenUrl!);
    
                    var rutaAnterior = Path.Combine(Directory.GetCurrentDirectory(), "uploads", "categorias", anteriorNombre);
                    if (System.IO.File.Exists(rutaAnterior))
                        System.IO.File.Delete(rutaAnterior);
                }
                catch { }
            }
    
            // Guardar nueva imagen
            var uploadsPath = Path.Combine(Directory.GetCurrentDirectory(), "uploads", "categorias");
            if (!Directory.Exists(uploadsPath)) Directory.CreateDirectory(uploadsPath);
    
            var nombreArchivo = $"{Guid.NewGuid()}{extension}";
            var rutaNueva = Path.Combine(uploadsPath, nombreArchivo);
            using (var stream = new FileStream(rutaNueva, FileMode.Create))
            {
                await imagen.CopyToAsync(stream);
            }
    
            var baseUrl = $"{Request.Scheme}://{Request.Host}";
            categoria.ImagenUrl = $"{baseUrl}/uploads/categorias/{nombreArchivo}";
    
            await _context.SaveChangesAsync();
    
            return Ok(new { message = "Imagen actualizada", imagenUrl = categoria.ImagenUrl });
        }
    }
}