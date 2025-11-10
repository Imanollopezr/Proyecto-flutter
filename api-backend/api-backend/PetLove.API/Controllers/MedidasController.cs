using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PetLove.Core.Models;
using PetLove.Infrastructure.Data;
using PetLove.API.DTOs;

namespace PetLove.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class MedidasController : ControllerBase
    {
        private readonly PetLoveDbContext _context;

        public MedidasController(PetLoveDbContext context)
        {
            _context = context;
        }

        // GET: api/Medidas
        [HttpGet]
        public async Task<ActionResult<IEnumerable<MedidaDto>>> GetMedidas()
        {
            try
            {
                var medidas = await _context.Medidas
                    .Where(m => m.Activo)
                    .OrderBy(m => m.Nombre)
                    .Select(m => new MedidaDto
                    {
                        IdMedida = m.IdMedida,
                        Nombre = m.Nombre,
                        Abreviatura = m.Abreviatura,
                        Descripcion = m.Descripcion,
                        Activo = m.Activo,
                        FechaRegistro = m.FechaRegistro
                    })
                    .ToListAsync();

                return Ok(medidas);
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Error interno del servidor: {ex.Message}");
            }
        }

        // GET: api/Medidas/5
        [HttpGet("{id}")]
        public async Task<ActionResult<MedidaDto>> GetMedida(int id)
        {
            try
            {
                var medida = await _context.Medidas
                    .Where(m => m.IdMedida == id && m.Activo)
                    .Select(m => new MedidaDto
                    {
                        IdMedida = m.IdMedida,
                        Nombre = m.Nombre,
                        Abreviatura = m.Abreviatura,
                        Descripcion = m.Descripcion,
                        Activo = m.Activo,
                        FechaRegistro = m.FechaRegistro
                    })
                    .FirstOrDefaultAsync();

                if (medida == null)
                {
                    return NotFound();
                }

                return Ok(medida);
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Error interno del servidor: {ex.Message}");
            }
        }

        // PUT: api/Medidas/5
        [HttpPut("{id}")]
        public async Task<IActionResult> PutMedida(int id, MedidaUpdateDto medidaDto)
        {
            try
            {
                var medida = await _context.Medidas.FindAsync(id);
                if (medida == null || !medida.Activo)
                {
                    return NotFound("Medida no encontrada");
                }

                // Actualizar propiedades
                medida.Nombre = medidaDto.Nombre;
                medida.Abreviatura = medidaDto.Abreviatura;
                medida.Descripcion = medidaDto.Descripcion;
                medida.Activo = medidaDto.Activo;

                await _context.SaveChangesAsync();
                return NoContent();
            }
            catch (DbUpdateConcurrencyException)
            {
                if (!MedidaExists(id))
                {
                    return NotFound();
                }
                else
                {
                    throw;
                }
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Error interno del servidor: {ex.Message}");
            }
        }

        // POST: api/Medidas
        [HttpPost]
        public async Task<ActionResult<MedidaDto>> PostMedida(MedidaCreateDto medidaDto)
        {
            try
            {
                var medida = new Medida
                {
                    Nombre = medidaDto.Nombre,
                    Abreviatura = medidaDto.Abreviatura,
                    Descripcion = medidaDto.Descripcion,
                    FechaRegistro = DateTime.Now,
                    Activo = true
                };

                _context.Medidas.Add(medida);
                await _context.SaveChangesAsync();

                var medidaResponse = new MedidaDto
                {
                    IdMedida = medida.IdMedida,
                    Nombre = medida.Nombre,
                    Abreviatura = medida.Abreviatura,
                    Descripcion = medida.Descripcion,
                    Activo = medida.Activo,
                    FechaRegistro = medida.FechaRegistro
                };

                return CreatedAtAction("GetMedida", new { id = medida.IdMedida }, medidaResponse);
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Error interno del servidor: {ex.Message}");
            }
        }

        // DELETE: api/Medidas/5
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteMedida(int id)
        {
            try
            {
                var medida = await _context.Medidas.FindAsync(id);
                if (medida == null)
                {
                    return NotFound(new { message = "Medida no encontrada" });
                }
                
                // Si ya está eliminada, devolver éxito sin hacer nada
                if (!medida.Activo)
                {
                    return Ok(new { message = "Medida eliminada correctamente" });
                }

                // Verificar si hay productos usando esta medida
                var productosConMedida = await _context.Productos
                    .CountAsync(p => p.IdMedidaProducto == id && p.Activo);

                if (productosConMedida > 0)
                {
                    return BadRequest(new { message = $"No se puede eliminar la medida porque tiene {productosConMedida} productos asociados" });
                }

                // Soft delete - marcar como inactivo
                medida.Activo = false;
                await _context.SaveChangesAsync();

                return Ok(new { message = "Medida eliminada correctamente" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Error interno del servidor", error = ex.Message });
            }
        }

        // GET: api/Medidas/buscar/{termino}
        [HttpGet("buscar/{termino}")]
        public async Task<ActionResult<IEnumerable<MedidaDto>>> BuscarMedidas(string termino)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(termino))
                {
                    return BadRequest(new { message = "El término de búsqueda es requerido" });
                }

                var medidas = await _context.Medidas
                    .Where(m => m.Activo && 
                               (m.Nombre.ToLower().Contains(termino.ToLower()) ||
                                (m.Descripcion != null && m.Descripcion.ToLower().Contains(termino.ToLower()))))
                    .OrderBy(m => m.Nombre)
                    .Select(m => new MedidaDto
                    {
                        IdMedida = m.IdMedida,
                        Nombre = m.Nombre,
                        Abreviatura = m.Abreviatura,
                        Descripcion = m.Descripcion,
                        Activo = m.Activo,
                        FechaRegistro = m.FechaRegistro
                    })
                    .ToListAsync();

                return Ok(medidas);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Error interno del servidor", error = ex.Message });
            }
        }

        private bool MedidaExists(int id)
        {
            return _context.Medidas.Any(e => e.IdMedida == id);
        }
    }
}