using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PetLove.Core.Models;
using PetLove.Infrastructure.Data;
using PetLove.API.DTOs;

namespace PetLove.API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class VentasController : ControllerBase
    {
        private readonly PetLoveDbContext _context;

        public VentasController(PetLoveDbContext context)
        {
            _context = context;
        }

        // GET: api/Ventas
        [HttpGet]
        public async Task<ActionResult<IEnumerable<VentaResponseDto>>> GetVentas()
        {
            try
            {
                var ventas = await _context.Ventas
                    .Include(v => v.Cliente)
                    .Include(v => v.DetallesVenta)
                        .ThenInclude(dv => dv.Producto)
                    .OrderByDescending(v => v.FechaVenta)
                    .Select(v => new VentaResponseDto
                    {
                        Id = v.Id,
                        FechaVenta = v.FechaVenta,
                        Subtotal = v.Subtotal,
                        Impuestos = v.Impuestos,
                        Total = v.Total,
                        MetodoPago = v.MetodoPago,
                        Cliente = new ClienteSimpleDto
                        {
                            Id = v.Cliente.Id,
                            Nombre = v.Cliente.Nombre,
                            Documento = v.Cliente.Documento,
                            Ciudad = v.Cliente.Ciudad,
                            Email = v.Cliente.Email
                        },
                        DetallesVenta = v.DetallesVenta.Select(dv => new DetalleVentaSimpleDto
                        {
                            Id = dv.Id,
                            Cantidad = dv.Cantidad,
                            PrecioUnitario = dv.PrecioUnitario,
                            Subtotal = dv.Subtotal,
                            Producto = new ProductoSimpleDto
                            {
                                Id = dv.Producto.Id,
                                Nombre = dv.Producto.Nombre,
                                Precio = dv.Producto.Precio
                            }
                        }).ToList()
                    })
                    .ToListAsync();

                return Ok(ventas);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Error al obtener las ventas", error = ex.Message });
            }
        }

        // GET: api/Ventas/5
        [HttpGet("{id}")]
        public async Task<ActionResult<VentaResponseDto>> GetVenta(int id)
        {
            try
            {
                var venta = await _context.Ventas
                    .Include(v => v.Cliente)
                    .Include(v => v.DetallesVenta)
                        .ThenInclude(dv => dv.Producto)
                    .Where(v => v.Id == id)
                    .Select(v => new VentaResponseDto
                    {
                        Id = v.Id,
                        FechaVenta = v.FechaVenta,
                        Subtotal = v.Subtotal,
                        Impuestos = v.Impuestos,
                        Total = v.Total,
                        MetodoPago = v.MetodoPago,
                        Cliente = new ClienteSimpleDto
                        {
                            Id = v.Cliente.Id,
                            Nombre = v.Cliente.Nombre,
                            Documento = v.Cliente.Documento,
                            Ciudad = v.Cliente.Ciudad,
                            Email = v.Cliente.Email
                        },
                        DetallesVenta = v.DetallesVenta.Select(dv => new DetalleVentaSimpleDto
                        {
                            Id = dv.Id,
                            Cantidad = dv.Cantidad,
                            PrecioUnitario = dv.PrecioUnitario,
                            Subtotal = dv.Subtotal,
                            Producto = new ProductoSimpleDto
                            {
                                Id = dv.Producto.Id,
                                Nombre = dv.Producto.Nombre,
                                Precio = dv.Producto.Precio
                            }
                        }).ToList()
                    })
                    .FirstOrDefaultAsync();

                if (venta == null)
                {
                    return NotFound(new { message = "Venta no encontrada" });
                }

                return Ok(venta);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Error al obtener la venta", error = ex.Message });
            }
        }

        // GET: api/Ventas/cliente/5
        [HttpGet("cliente/{clienteId}")]
        public async Task<ActionResult<IEnumerable<VentaResponseDto>>> GetVentasByCliente(int clienteId)
        {
            try
            {
                var ventas = await _context.Ventas
                    .Include(v => v.Cliente)
                    .Include(v => v.DetallesVenta)
                        .ThenInclude(dv => dv.Producto)
                    .Where(v => v.ClienteId == clienteId)
                    .OrderByDescending(v => v.FechaVenta)
                    .Select(v => new VentaResponseDto
                    {
                        Id = v.Id,
                        FechaVenta = v.FechaVenta,
                        Subtotal = v.Subtotal,
                        Impuestos = v.Impuestos,
                        Total = v.Total,
                        MetodoPago = v.MetodoPago,
                        Cliente = new ClienteSimpleDto
                        {
                            Id = v.Cliente.Id,
                            Nombre = v.Cliente.Nombre,
                            Documento = v.Cliente.Documento,
                            Ciudad = v.Cliente.Ciudad,
                            Email = v.Cliente.Email
                        },
                        DetallesVenta = v.DetallesVenta.Select(dv => new DetalleVentaSimpleDto
                        {
                            Id = dv.Id,
                            Cantidad = dv.Cantidad,
                            PrecioUnitario = dv.PrecioUnitario,
                            Subtotal = dv.Subtotal,
                            Producto = new ProductoSimpleDto
                            {
                                Id = dv.Producto.Id,
                                Nombre = dv.Producto.Nombre,
                                Precio = dv.Producto.Precio
                            }
                        }).ToList()
                    })
                    .ToListAsync();

                return Ok(ventas);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Error al obtener las ventas del cliente", error = ex.Message });
            }
        }

        // GET: api/Ventas/fecha/{fecha}
        [HttpGet("fecha/{fecha}")]
        public async Task<ActionResult<IEnumerable<VentaResponseDto>>> GetVentasByFecha(DateTime fecha)
        {
            try
            {
                var ventas = await _context.Ventas
                    .Include(v => v.Cliente)
                    .Include(v => v.DetallesVenta!)
                        .ThenInclude(dv => dv.Producto)
                    .Where(v => v.FechaVenta.Date == fecha.Date)
                    .OrderByDescending(v => v.FechaVenta)
                    .Select(v => new VentaResponseDto
                    {
                        Id = v.Id,
                        FechaVenta = v.FechaVenta,
                        Subtotal = v.Subtotal,
                        Impuestos = v.Impuestos,
                        Total = v.Total,
                        MetodoPago = v.MetodoPago,
                        Cliente = new ClienteSimpleDto
                        {
                            Id = v.Cliente.Id,
                            Nombre = v.Cliente.Nombre,
                            Documento = v.Cliente.Documento,
                            Ciudad = v.Cliente.Ciudad,
                            Email = v.Cliente.Email
                        },
                        DetallesVenta = v.DetallesVenta.Select(dv => new DetalleVentaSimpleDto
                        {
                            Id = dv.Id,
                            Cantidad = dv.Cantidad,
                            PrecioUnitario = dv.PrecioUnitario,
                            Subtotal = dv.Subtotal,
                            Producto = new ProductoSimpleDto
                            {
                                Id = dv.Producto.Id,
                                Nombre = dv.Producto.Nombre,
                                Precio = dv.Producto.Precio
                            }
                        }).ToList()
                    })
                    .ToListAsync();

                return Ok(ventas);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Error al obtener las ventas por fecha", error = ex.Message });
            }
        }

        // POST: api/Ventas
        [HttpPost]
        public async Task<ActionResult<VentaResponseDto>> PostVenta(VentaCreateDto ventaDto)
        {
            try
            {
                // Validar que el cliente existe
                var cliente = await _context.Clientes.FindAsync(ventaDto.ClienteId);
                if (cliente == null)
                {
                    return BadRequest(new { message = "El cliente especificado no existe" });
                }

                // Validar que hay detalles de venta
                if (ventaDto.DetallesVenta == null || !ventaDto.DetallesVenta.Any())
                {
                    return BadRequest(new { message = "La venta debe tener al menos un producto" });
                }

                // Crear la venta
                var venta = new Venta
                {
                    ClienteId = ventaDto.ClienteId,
                    FechaVenta = ventaDto.FechaVenta ?? DateTime.UtcNow,
                    MetodoPago = ventaDto.MetodoPago ?? "Efectivo",
                    Estado = ventaDto.Estado ?? "Completada",
                    Observaciones = ventaDto.Observaciones,
                    NumeroFactura = GenerarNumeroFactura()
                };

                // Calcular totales y crear detalles
                decimal subtotal = 0;
                var detallesVenta = new List<DetalleVenta>();

                foreach (var detalleDto in ventaDto.DetallesVenta)
                {
                    // Validar que el producto existe
                    var producto = await _context.Productos.FindAsync(detalleDto.ProductoId);
                    if (producto == null)
                    {
                        return BadRequest(new { message = $"El producto con ID {detalleDto.ProductoId} no existe" });
                    }

                    // Validar stock disponible
                    if (producto.Stock < detalleDto.Cantidad)
                    {
                        return BadRequest(new { message = $"Stock insuficiente para el producto {producto.Nombre}. Stock disponible: {producto.Stock}" });
                    }

                    var detalle = new DetalleVenta
                    {
                        ProductoId = detalleDto.ProductoId,
                        Cantidad = detalleDto.Cantidad,
                        PrecioUnitario = detalleDto.PrecioUnitario ?? producto.Precio,
                        Descuento = detalleDto.Descuento,
                        Subtotal = (detalleDto.PrecioUnitario ?? producto.Precio) * detalleDto.Cantidad - detalleDto.Descuento
                    };

                    detallesVenta.Add(detalle);
                    subtotal += detalle.Subtotal;

                    // Actualizar stock del producto
                    producto.Stock -= detalleDto.Cantidad;
                    producto.FechaActualizacion = DateTime.UtcNow;
                }

                // Calcular totales de la venta
                venta.Subtotal = subtotal;
                venta.Impuestos = subtotal * 0.18m; // 18% de impuestos
                venta.Total = venta.Subtotal + venta.Impuestos;
                venta.DetallesVenta = detallesVenta;

                _context.Ventas.Add(venta);
                await _context.SaveChangesAsync();

                // Cargar la venta completa para retornar como DTO
                var ventaResponse = await _context.Ventas
                    .Include(v => v.Cliente)
                    .Include(v => v.DetallesVenta!)
                        .ThenInclude(dv => dv.Producto)
                    .Where(v => v.Id == venta.Id)
                    .Select(v => new VentaResponseDto
                    {
                        Id = v.Id,
                        FechaVenta = v.FechaVenta,
                        Subtotal = v.Subtotal,
                        Impuestos = v.Impuestos,
                        Total = v.Total,
                        MetodoPago = v.MetodoPago,
                        Cliente = new ClienteSimpleDto
                        {
                            Id = v.Cliente.Id,
                            Nombre = v.Cliente.Nombre,
                            Email = v.Cliente.Email
                        },
                        DetallesVenta = v.DetallesVenta.Select(dv => new DetalleVentaSimpleDto
                        {
                            Id = dv.Id,
                            Cantidad = dv.Cantidad,
                            PrecioUnitario = dv.PrecioUnitario,
                            Subtotal = dv.Subtotal,
                            Producto = new ProductoSimpleDto
                            {
                                Id = dv.Producto.Id,
                                Nombre = dv.Producto.Nombre,
                                Precio = dv.Producto.Precio
                            }
                        }).ToList()
                    })
                    .FirstOrDefaultAsync();

                return CreatedAtAction("GetVenta", new { id = venta.Id }, ventaResponse);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Error al crear la venta", error = ex.Message });
            }
        }

        // PUT: api/Ventas/5
        [HttpPut("{id}")]
        public async Task<IActionResult> PutVenta(int id, VentaUpdateDto ventaDto)
        {
            try
            {
                var venta = await _context.Ventas
                    .Include(v => v.DetallesVenta)
                    .FirstOrDefaultAsync(v => v.Id == id);

                if (venta == null)
                {
                    return NotFound(new { message = "Venta no encontrada" });
                }

                // Solo permitir actualizar ciertos campos
                if (!string.IsNullOrEmpty(ventaDto.MetodoPago))
                    venta.MetodoPago = ventaDto.MetodoPago;

                if (!string.IsNullOrEmpty(ventaDto.Estado))
                    venta.Estado = ventaDto.Estado;

                if (!string.IsNullOrEmpty(ventaDto.Observaciones))
                    venta.Observaciones = ventaDto.Observaciones;

                venta.FechaActualizacion = DateTime.UtcNow;

                await _context.SaveChangesAsync();

                return Ok(new { message = "Venta actualizada correctamente" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Error al actualizar la venta", error = ex.Message });
            }
        }

        // DELETE: api/Ventas/5 (Anular venta)
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteVenta(int id)
        {
            try
            {
                var venta = await _context.Ventas
                    .Include(v => v.DetallesVenta!)
                        .ThenInclude(dv => dv.Producto)
                    .FirstOrDefaultAsync(v => v.Id == id);

                if (venta == null)
                {
                    return NotFound(new { message = "Venta no encontrada" });
                }

                if (venta.Estado == "Anulada")
                {
                    return BadRequest(new { message = "La venta ya está anulada" });
                }

                // Restaurar stock de productos
                foreach (var detalle in venta.DetallesVenta!)
                {
                    detalle.Producto!.Stock += detalle.Cantidad;
                    detalle.Producto.FechaActualizacion = DateTime.UtcNow;
                }

                // Anular la venta (soft delete)
                venta.Estado = "Anulada";
                venta.FechaActualizacion = DateTime.UtcNow;

                await _context.SaveChangesAsync();

                return Ok(new { message = "Venta anulada correctamente. Stock restaurado." });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Error al anular la venta", error = ex.Message });
            }
        }

        // POST: api/Ventas/{id}/anular (Anular venta con recuperación de stock)
        [HttpPost("{id}/anular")]
        public async Task<IActionResult> AnularVenta(int id)
        {
            try
            {
                var venta = await _context.Ventas
                    .Include(v => v.DetallesVenta!)
                        .ThenInclude(dv => dv.Producto)
                    .FirstOrDefaultAsync(v => v.Id == id);

                if (venta == null)
                {
                    return NotFound(new { message = "Venta no encontrada" });
                }

                if (venta.Estado == "Anulada")
                {
                    return BadRequest(new { message = "La venta ya está anulada" });
                }

                // Restaurar stock de productos
                foreach (var detalle in venta.DetallesVenta!)
                {
                    if (detalle.Producto != null)
                    {
                        detalle.Producto.Stock += detalle.Cantidad;
                        detalle.Producto.FechaActualizacion = DateTime.UtcNow;
                    }
                }

                // Anular la venta (soft delete)
                venta.Estado = "Anulada";
                venta.FechaActualizacion = DateTime.UtcNow;

                await _context.SaveChangesAsync();

                return Ok(new { 
                    message = "Venta anulada correctamente. Stock restaurado.",
                    ventaId = id,
                    estado = "Anulada"
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Error al anular la venta", error = ex.Message });
            }
        }

        // GET: api/Ventas/estadisticas
        [HttpGet("estadisticas")]
        public async Task<ActionResult> GetEstadisticas()
        {
            try
            {
                var hoy = DateTime.Today;
                var inicioMes = new DateTime(hoy.Year, hoy.Month, 1);

                var estadisticas = new
                {
                    VentasHoy = await _context.Ventas
                        .Where(v => v.FechaVenta.Date == hoy && v.Estado != "Anulada")
                        .CountAsync(),
                    
                    VentasMes = await _context.Ventas
                        .Where(v => v.FechaVenta >= inicioMes && v.Estado != "Anulada")
                        .CountAsync(),
                    
                    TotalVentasHoy = await _context.Ventas
                        .Where(v => v.FechaVenta.Date == hoy && v.Estado != "Anulada")
                        .SumAsync(v => (decimal?)v.Total) ?? 0,
                    
                    TotalVentasMes = await _context.Ventas
                        .Where(v => v.FechaVenta >= inicioMes && v.Estado != "Anulada")
                        .SumAsync(v => (decimal?)v.Total) ?? 0,
                    
                    ProductosMasVendidos = await _context.DetallesVenta
                        .Include(dv => dv.Producto)
                        .Where(dv => dv.Venta!.FechaVenta >= inicioMes && dv.Venta.Estado != "Anulada")
                        .GroupBy(dv => new { dv.ProductoId, dv.Producto!.Nombre })
                        .Select(g => new
                        {
                            ProductoId = g.Key.ProductoId,
                            Nombre = g.Key.Nombre,
                            CantidadVendida = g.Sum(dv => dv.Cantidad)
                        })
                        .OrderByDescending(x => x.CantidadVendida)
                        .Take(5)
                        .ToListAsync()
                };

                return Ok(estadisticas);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Error al obtener estadísticas", error = ex.Message });
            }
        }

        private string GenerarNumeroFactura()
        {
            var fecha = DateTime.Now;
            var numero = $"F{fecha:yyyyMMdd}{fecha:HHmmss}";
            return numero;
        }

        private bool VentaExists(int id)
        {
            return _context.Ventas.Any(e => e.Id == id);
        }
    }

    // DTOs para las operaciones
    public class VentaCreateDto
    {
        public int ClienteId { get; set; }
        public DateTime? FechaVenta { get; set; }
        public string? MetodoPago { get; set; }
        public string? Estado { get; set; }
        public string? Observaciones { get; set; }
        public List<DetalleVentaCreateDto> DetallesVenta { get; set; } = new();
    }

    public class DetalleVentaCreateDto
    {
        public int ProductoId { get; set; }
        public int Cantidad { get; set; }
        public decimal? PrecioUnitario { get; set; }
        public decimal Descuento { get; set; } = 0;
    }

    public class VentaUpdateDto
    {
        public string? MetodoPago { get; set; }
        public string? Estado { get; set; }
        public string? Observaciones { get; set; }
    }
}