using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PetLove.Core.Models;
using PetLove.Infrastructure.Data;
using PetLove.API.DTOs;
using PetLove.API.Attributes;

namespace PetLove.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class ClientesController : ControllerBase
    {
        private readonly PetLoveDbContext _context;

        public ClientesController(PetLoveDbContext context)
        {
            _context = context;
        }

        // GET: api/clientes
        [HttpGet]
        public async Task<ActionResult<IEnumerable<ClienteResponseDto>>> GetClientes()
        {
            var clientes = await _context.Clientes
                .Where(c => c.Activo)
                .OrderBy(c => c.Apellido)
                .ThenBy(c => c.Nombre)
                .Select(c => new ClienteResponseDto
                {
                    Id = c.Id,
                    Nombre = c.Nombre,
                    Apellido = c.Apellido,
                    Email = c.Email,
                    Telefono = c.Telefono,
                    Documento = c.Documento,
                    Direccion = c.Direccion,
                    Ciudad = c.Ciudad,
                    FechaRegistro = c.FechaRegistro,
                    Activo = c.Activo,
                    TotalVentas = c.Ventas != null ? c.Ventas.Count : 0,
                    TotalPedidos = c.Pedidos != null ? c.Pedidos.Count : 0
                })
                .ToListAsync();

            return Ok(clientes);
        }

        // GET: api/clientes/5
        [HttpGet("{id}")]
        public async Task<ActionResult<ClienteResponseDto>> GetCliente(int id)
        {
            var cliente = await _context.Clientes
                .Where(c => c.Id == id && c.Activo)
                .Select(c => new ClienteResponseDto
                {
                    Id = c.Id,
                    Nombre = c.Nombre,
                    Apellido = c.Apellido,
                    Email = c.Email,
                    Telefono = c.Telefono,
                    Documento = c.Documento,
                    Direccion = c.Direccion,
                    Ciudad = c.Ciudad,
                    FechaRegistro = c.FechaRegistro,
                    Activo = c.Activo,
                    TotalVentas = c.Ventas != null ? c.Ventas.Count : 0,
                    TotalPedidos = c.Pedidos != null ? c.Pedidos.Count : 0
                })
                .FirstOrDefaultAsync();

            if (cliente == null)
            {
                return NotFound(new { message = "Cliente no encontrado" });
            }

            return Ok(cliente);
        }

        // POST: api/clientes
        [HttpPost]
        [RequireRole("Administrador", "Asistente")]
        public async Task<ActionResult<ClienteResponseDto>> PostCliente(ClienteCreateDto clienteDto)
        {
            try
            {
                // Validar que el email no exista
                var emailExistente = await _context.Clientes
                    .AnyAsync(c => c.Email.ToLower() == clienteDto.Email.ToLower());

                if (emailExistente)
                {
                    return BadRequest(new { message = "Ya existe un cliente con este email" });
                }

                // Crear el cliente desde el DTO
                var cliente = new Cliente
                {
                    Nombre = clienteDto.Nombre.Trim(),
                    Apellido = clienteDto.Apellido.Trim(),
                    Email = clienteDto.Email.ToLower().Trim(),
                    Telefono = clienteDto.Telefono?.Trim(),
                    Direccion = clienteDto.Direccion?.Trim(),
                    FechaRegistro = DateTime.UtcNow,
                    Activo = true
                };

                _context.Clientes.Add(cliente);
                await _context.SaveChangesAsync();

                // Retornar el DTO de respuesta
                var clienteResponse = new ClienteResponseDto
                {
                    Id = cliente.Id,
                    Nombre = cliente.Nombre,
                    Apellido = cliente.Apellido,
                    Email = cliente.Email,
                    Telefono = cliente.Telefono,
                    Direccion = cliente.Direccion,
                    FechaRegistro = cliente.FechaRegistro,
                    Activo = cliente.Activo,
                    TotalVentas = 0,
                    TotalPedidos = 0
                };

                return CreatedAtAction(nameof(GetCliente), new { id = cliente.Id }, clienteResponse);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Error interno del servidor", error = ex.Message });
            }
        }

        // PUT: api/clientes/5
        [HttpPut("{id}")]
        [RequireRole("Administrador", "Asistente")]
        public async Task<IActionResult> PutCliente(int id, ClienteUpdateDto clienteDto)
        {
            try
            {
                var existingCliente = await _context.Clientes.FindAsync(id);
                if (existingCliente == null)
                {
                    return NotFound(new { message = "Cliente no encontrado" });
                }

                // Verificar si el email ya existe en otro cliente (solo si se está actualizando)
                if (!string.IsNullOrEmpty(clienteDto.Email))
                {
                    var emailExistente = await _context.Clientes
                        .AnyAsync(c => c.Email.ToLower() == clienteDto.Email.ToLower() && c.Id != id);

                    if (emailExistente)
                    {
                        return BadRequest(new { message = "Ya existe otro cliente con este email" });
                    }
                }

                // Actualizar solo los campos proporcionados
                if (!string.IsNullOrEmpty(clienteDto.Nombre))
                    existingCliente.Nombre = clienteDto.Nombre.Trim();

                if (!string.IsNullOrEmpty(clienteDto.Apellido))
                    existingCliente.Apellido = clienteDto.Apellido.Trim();

                if (!string.IsNullOrEmpty(clienteDto.Email))
                    existingCliente.Email = clienteDto.Email.ToLower().Trim();

                if (clienteDto.Telefono != null)
                    existingCliente.Telefono = clienteDto.Telefono.Trim();

                if (clienteDto.Direccion != null)
                    existingCliente.Direccion = clienteDto.Direccion.Trim();

                if (clienteDto.Activo.HasValue)
                    existingCliente.Activo = clienteDto.Activo.Value;

                existingCliente.FechaActualizacion = DateTime.UtcNow;

                await _context.SaveChangesAsync();
                return Ok(new { message = "Cliente actualizado correctamente" });
            }
            catch (DbUpdateConcurrencyException)
            {
                if (!ClienteExists(id))
                {
                    return NotFound(new { message = "Cliente no encontrado" });
                }
                else
                {
                    return StatusCode(500, new { message = "Error de concurrencia al actualizar el cliente" });
                }
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Error interno del servidor", error = ex.Message });
            }
        }

        // DELETE: api/clientes/5
        [HttpDelete("{id}")]
        [RequireRole("Administrador", "Asistente")]
        public async Task<IActionResult> DeleteCliente(int id)
        {
            try
            {
                var cliente = await _context.Clientes.FindAsync(id);
                if (cliente == null)
                {
                    return NotFound(new { message = "Cliente no encontrado" });
                }

                // Verificar si el cliente tiene pedidos pendientes o confirmados
                var pedidosActivos = await _context.Pedidos
                    .CountAsync(p => p.ClienteId == id && 
                               (p.Estado == "Pendiente" || p.Estado == "Confirmado"));

                if (pedidosActivos > 0)
                {
                    return BadRequest(new { message = "No se puede eliminar el cliente porque tiene pedidos activos" });
                }

                // Eliminación permanente de la base de datos
                _context.Clientes.Remove(cliente);
                await _context.SaveChangesAsync();

                return Ok(new { message = "Cliente eliminado correctamente" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Error interno del servidor", error = ex.Message });
            }
        }

        // GET: api/clientes/buscar/{termino}
        [HttpGet("buscar/{termino}")]
        public async Task<ActionResult<IEnumerable<ClienteResponseDto>>> BuscarClientes(string termino)
        {
            var query = termino.Trim().ToLower();

            var clientes = await _context.Clientes
                .Where(c => c.Activo &&
                            (
                                (c.Nombre ?? "").ToLower().Contains(query) ||
                                (c.Apellido ?? "").ToLower().Contains(query) ||
                                (c.Email ?? "").ToLower().Contains(query)
                            ))
                .OrderBy(c => c.Apellido)
                .ThenBy(c => c.Nombre)
                .Select(c => new ClienteResponseDto
                {
                    Id = c.Id,
                    Nombre = c.Nombre,
                    Apellido = c.Apellido,
                    Email = c.Email,
                    Telefono = c.Telefono,
                    Documento = c.Documento,
                    Direccion = c.Direccion,
                    Ciudad = c.Ciudad,
                    FechaRegistro = c.FechaRegistro,
                    Activo = c.Activo,
                    TotalVentas = c.Ventas != null ? c.Ventas.Count : 0,
                    TotalPedidos = c.Pedidos != null ? c.Pedidos.Count : 0
                })
                .ToListAsync();

            return Ok(clientes);
        }

        // GET: api/clientes/by-email/{email}
        [HttpGet("by-email/{email}")]
        public async Task<ActionResult<ClienteResponseDto>> GetClientePorEmail(string email)
        {
            var correo = email.Trim().ToLower();

            var cliente = await _context.Clientes
                .Where(c => c.Activo && (c.Email ?? "").ToLower() == correo)
                .Select(c => new ClienteResponseDto
                {
                    Id = c.Id,
                    Nombre = c.Nombre,
                    Apellido = c.Apellido,
                    Email = c.Email,
                    Telefono = c.Telefono,
                    Documento = c.Documento,
                    Direccion = c.Direccion,
                    Ciudad = c.Ciudad,
                    FechaRegistro = c.FechaRegistro,
                    Activo = c.Activo,
                    TotalVentas = c.Ventas != null ? c.Ventas.Count : 0,
                    TotalPedidos = c.Pedidos != null ? c.Pedidos.Count : 0
                })
                .FirstOrDefaultAsync();

            if (cliente == null)
            {
                return NotFound(new { message = "Cliente no encontrado" });
            }

            return Ok(cliente);
        }

        private bool ClienteExists(int id)
        {
            return _context.Clientes.Any(e => e.Id == id);
        }

        // Método auxiliar para validar email
        private bool IsValidEmail(string email)
        {
            try
            {
                var addr = new System.Net.Mail.MailAddress(email);
                return addr.Address == email;
            }
            catch
            {
                return false;
            }
        }
    }
}