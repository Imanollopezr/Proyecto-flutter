using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Authorization;
using PetLove.Core.Models;
using PetLove.Infrastructure.Data;
using PetLove.API.Services;
using PetLove.API.DTOs;
using System.Security.Claims;

namespace PetLove.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class AuthController : ControllerBase
    {
        private readonly PetLoveDbContext _context;
        private readonly IJwtService _jwtService;
        private readonly IPasswordService _passwordService;
        private readonly IEmailService _emailService;
        private readonly ILogger<AuthController> _logger;
        private readonly IConfiguration _configuration;
        private readonly ITokenService _tokenService;
        private readonly IWebHostEnvironment _env;

        public AuthController(
            PetLoveDbContext context, 
            IJwtService jwtService, 
            IPasswordService passwordService,
            IEmailService emailService,
            ILogger<AuthController> logger,
            IConfiguration configuration,
            ITokenService tokenService,
            IWebHostEnvironment env)
        {
            _context = context;
            _jwtService = jwtService;
            _passwordService = passwordService;
            _emailService = emailService;
            _logger = logger;
            _configuration = configuration;
            _tokenService = tokenService;
            _env = env;
            
            // DEBUG: Verificar qué tipo de servicio de email se inyectó
            _logger.LogInformation("=== DEBUG AUTHCONTROLLER ===");
            _logger.LogInformation("Tipo de EmailService inyectado: {EmailServiceType}", _emailService.GetType().Name);
            _logger.LogInformation("============================");
        }

        // POST: api/auth/oauth-sync
        [HttpPost("oauth-sync")]
        public async Task<ActionResult<ApiResponseDto<LoginResponseDto>>> OAuthSync([FromBody] OAuthSyncRequest request)
        {
            try
            {
                if (request == null || string.IsNullOrWhiteSpace(request.Email))
                {
                    return BadRequest(new ApiResponseDto<LoginResponseDto>
                    {
                        Exitoso = false,
                        Mensaje = "Email es requerido"
                    });
                }

                var email = request.Email.Trim().ToLower();

                // Buscar usuario existente por email
                var usuario = await _context.Usuarios
                    .Include(u => u.Rol)
                    .FirstOrDefaultAsync(u => u.Correo.ToLower() == email);

                if (usuario != null)
                {
                    if (!usuario.Activo)
                    {
                        return Unauthorized(new ApiResponseDto<LoginResponseDto>
                        {
                            Exitoso = false,
                            Mensaje = "Usuario no activo"
                        });
                    }

                    // Generar tokens para usuario existente
                    var token = _jwtService.GenerateToken(usuario);
                    var refreshToken = _jwtService.GenerateRefreshToken();

                var refreshDays = _configuration.GetValue<int>("Jwt:RefreshTokenExpiryInDays", 7);
                var refreshTokenEntity = new RefreshToken
                {
                    Token = refreshToken,
                    UsuarioId = usuario.Id,
                    FechaCreacion = DateTime.UtcNow,
                    FechaExpiracion = DateTime.UtcNow.AddDays(refreshDays),
                    Usado = false,
                    Revocado = false,
                    DireccionIP = HttpContext.Connection.RemoteIpAddress?.ToString(),
                    UserAgent = HttpContext.Request.Headers["User-Agent"].ToString()
                };

                    try
                    {
                        _context.RefreshTokens.Add(refreshTokenEntity);
                        await _context.SaveChangesAsync();
                    }
                    catch (Exception ex)
                    {
                        _logger.LogError(ex, "Error al guardar RefreshToken para usuario {UserId}: {Message}", usuario.Id, ex.Message);

                        var responseWithoutRefresh = new LoginResponseDto
                        {
                            Token = token,
                            RefreshToken = string.Empty,
                            Expiracion = DateTime.UtcNow.AddHours(1),
                            Usuario = new UsuarioInfoDto
                            {
                                Id = usuario.Id,
                                Nombres = usuario.Nombres,
                                Apellidos = usuario.Apellidos,
                                Correo = usuario.Correo,
                                IdRol = usuario.IdRol,
                                NombreRol = usuario.Rol?.NombreRol ?? "Usuario",
                                Activo = usuario.Activo,
                                FechaRegistro = usuario.FechaRegistro
                            }
                        };

                        return Ok(new ApiResponseDto<LoginResponseDto>
                        {
                            Exitoso = true,
                            Mensaje = "Inicio de sesión OAuth exitoso",
                            Data = responseWithoutRefresh
                        });
                    }

                    var response = new LoginResponseDto
                    {
                        Token = token,
                        RefreshToken = refreshToken,
                        Expiracion = DateTime.UtcNow.AddHours(1),
                        Usuario = new UsuarioInfoDto
                        {
                            Id = usuario.Id,
                            Nombres = usuario.Nombres,
                            Apellidos = usuario.Apellidos,
                            Correo = usuario.Correo,
                            IdRol = usuario.IdRol,
                            NombreRol = usuario.Rol?.NombreRol ?? "Usuario",
                            Activo = usuario.Activo,
                            FechaRegistro = usuario.FechaRegistro
                        }
                    };

                    _logger.LogInformation("Usuario {Email} sincronizado vía OAuth exitosamente", usuario.Correo);

                    return Ok(new ApiResponseDto<LoginResponseDto>
                    {
                        Exitoso = true,
                        Mensaje = "Inicio de sesión OAuth exitoso",
                        Data = response
                    });
                }

                // Crear usuario nuevo si no existe
                var defaultRoleId = 3; // Rol Cliente por defecto
                var rol = await _context.Roles.FirstOrDefaultAsync(r => r.Id == defaultRoleId && r.Activo);
                if (rol == null)
                {
                    // Intentar por nombre o cualquier rol activo
                    rol = await _context.Roles.FirstOrDefaultAsync(r => r.NombreRol == "Cliente" && r.Activo)
                        ?? await _context.Roles.FirstOrDefaultAsync(r => r.Activo);
                }

                if (rol == null)
                {
                    return BadRequest(new ApiResponseDto<LoginResponseDto>
                    {
                        Exitoso = false,
                        Mensaje = "No hay roles activos disponibles"
                    });
                }

                var fullName = (request.Name ?? string.Empty).Trim();
                string nombres = fullName;
                string apellidos = string.Empty;
                if (!string.IsNullOrEmpty(fullName))
                {
                    var parts = fullName.Split(' ', StringSplitOptions.RemoveEmptyEntries);
                    if (parts.Length > 1)
                    {
                        nombres = parts[0];
                        apellidos = string.Join(" ", parts.Skip(1));
                    }
                }
                else
                {
                    nombres = "Usuario";
                    apellidos = "OAuth";
                }

                var randomPassword = $"OAuth-{Guid.NewGuid():N}".Substring(0, 16);
                var hashedPassword = _passwordService.HashPassword(randomPassword);

                var nuevoUsuario = new Usuario
                {
                    Nombres = nombres,
                    Apellidos = apellidos,
                    Correo = email,
                    Clave = hashedPassword,
                    IdRol = rol.Id,
                    Activo = true,
                    FechaRegistro = DateTime.UtcNow
                };

                _context.Usuarios.Add(nuevoUsuario);
                await _context.SaveChangesAsync();

                // Crear registro de Cliente automáticamente si no existe
                try
                {
                    var correoUsuario = nuevoUsuario.Correo.ToLower().Trim();
                    var clienteExiste = await _context.Clientes
                        .AnyAsync(c => c.Email.ToLower() == correoUsuario);

                    if (!clienteExiste)
                    {
                        var nuevoCliente = new Cliente
                        {
                            Nombre = nuevoUsuario.Nombres.Trim(),
                            Apellido = nuevoUsuario.Apellidos.Trim(),
                            Email = correoUsuario,
                            Activo = true,
                            FechaRegistro = DateTime.UtcNow
                        };

                        _context.Clientes.Add(nuevoCliente);
                        await _context.SaveChangesAsync();
                        _logger.LogInformation("Cliente creado automáticamente para usuario {Email}", nuevoUsuario.Correo);
                    }
                    else
                    {
                        _logger.LogInformation("Cliente ya existía para usuario {Email}", nuevoUsuario.Correo);
                    }
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Error al crear Cliente para usuario {Email}", nuevoUsuario.Correo);
                }

                // Enviar email de bienvenida al crear cuenta vía OAuth (no bloquea si falla)
                try
                {
                    var nombreUsuario = $"{nuevoUsuario.Nombres} {nuevoUsuario.Apellidos}".Trim();

                    var welcomeTokenOAuth = _tokenService.GenerateWelcomeToken(nuevoUsuario.Id, nuevoUsuario.Correo);

                    var enviadoOAuth = await _emailService.SendWelcomeEmailAsync(
                        nuevoUsuario.Correo,
                        string.IsNullOrWhiteSpace(nombreUsuario) ? nuevoUsuario.Nombres : nombreUsuario,
                        welcomeTokenOAuth
                    );
                    if (!enviadoOAuth)
                    {
                        _logger.LogWarning("No se pudo enviar el email de bienvenida (OAuth) a {Email}", nuevoUsuario.Correo);
                    }
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Error al enviar email de bienvenida (OAuth) a {Email}", nuevoUsuario.Correo);
                }

                await _context.Entry(nuevoUsuario).Reference(u => u.Rol).LoadAsync();

                var oauthToken = _jwtService.GenerateToken(nuevoUsuario);
                var oauthRefreshToken = _jwtService.GenerateRefreshToken();

                var refreshDays2 = _configuration.GetValue<int>("Jwt:RefreshTokenExpiryInDays", 7);
                var oauthRefreshTokenEntity = new RefreshToken
                {
                    Token = oauthRefreshToken,
                    UsuarioId = nuevoUsuario.Id,
                    FechaCreacion = DateTime.UtcNow,
                    FechaExpiracion = DateTime.UtcNow.AddDays(refreshDays2),
                    Usado = false,
                    Revocado = false,
                    DireccionIP = HttpContext.Connection.RemoteIpAddress?.ToString(),
                    UserAgent = HttpContext.Request.Headers["User-Agent"].ToString()
                };

                try
                {
                    _context.RefreshTokens.Add(oauthRefreshTokenEntity);
                    await _context.SaveChangesAsync();
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Error al guardar RefreshToken para usuario {UserId}: {Message}", nuevoUsuario.Id, ex.Message);

                    var responseWithoutRefresh = new LoginResponseDto
                    {
                        Token = oauthToken,
                        RefreshToken = string.Empty,
                        Expiracion = DateTime.UtcNow.AddHours(1),
                        Usuario = new UsuarioInfoDto
                        {
                            Id = nuevoUsuario.Id,
                            Nombres = nuevoUsuario.Nombres,
                            Apellidos = nuevoUsuario.Apellidos,
                            Correo = nuevoUsuario.Correo,
                            IdRol = nuevoUsuario.IdRol,
                            NombreRol = nuevoUsuario.Rol?.NombreRol ?? "Usuario",
                            Activo = nuevoUsuario.Activo,
                            FechaRegistro = nuevoUsuario.FechaRegistro
                        }
                    };

                    _logger.LogInformation("Usuario {Email} creado vía OAuth exitosamente (sin refresh token)", nuevoUsuario.Correo);

                    return Ok(new ApiResponseDto<LoginResponseDto>
                    {
                        Exitoso = true,
                        Mensaje = "Cuenta creada y sesión iniciada vía OAuth",
                        Data = responseWithoutRefresh
                    });
                }

                var oauthResponse = new LoginResponseDto
                {
                    Token = oauthToken,
                    RefreshToken = oauthRefreshToken,
                    Expiracion = DateTime.UtcNow.AddHours(1),
                    Usuario = new UsuarioInfoDto
                    {
                        Id = nuevoUsuario.Id,
                        Nombres = nuevoUsuario.Nombres,
                        Apellidos = nuevoUsuario.Apellidos,
                        Correo = nuevoUsuario.Correo,
                        IdRol = nuevoUsuario.IdRol,
                        NombreRol = nuevoUsuario.Rol?.NombreRol ?? "Usuario",
                        Activo = nuevoUsuario.Activo,
                        FechaRegistro = nuevoUsuario.FechaRegistro
                    }
                };

                _logger.LogInformation("Usuario {Email} creado y sincronizado vía OAuth exitosamente", nuevoUsuario.Correo);

                return Ok(new ApiResponseDto<LoginResponseDto>
                {
                    Exitoso = true,
                    Mensaje = "Cuenta creada y sesión iniciada vía OAuth",
                    Data = oauthResponse
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error durante oauth-sync");
                return StatusCode(500, new ApiResponseDto<LoginResponseDto>
                {
                    Exitoso = false,
                    Mensaje = "Error interno del servidor"
                });
            }
        }

        // POST: api/auth/login
        [HttpPost("login")]
        public async Task<ActionResult<ApiResponseDto<LoginResponseDto>>> Login([FromBody] LoginRequestDto request)
        {
            try
            {
                if (!ModelState.IsValid)
                {
                    var errores = ModelState.Values
                        .SelectMany(v => v.Errors)
                        .Select(e => e.ErrorMessage)
                        .ToList();
                    
                    return BadRequest(new ApiResponseDto<LoginResponseDto>
                    {
                        Exitoso = false,
                        Mensaje = "Datos de entrada inválidos",
                        Errores = errores
                    });
                }

                // Normalizar correo de entrada (trim + lower) para la comparación exacta
                var correoNormalizado = (request.Correo ?? string.Empty).Trim().ToLowerInvariant();
                // Buscar usuario por email ya normalizado
                var usuario = await _context.Usuarios
                    .Include(u => u.Rol)
                    .FirstOrDefaultAsync(u => u.Correo == correoNormalizado);

                if (usuario == null || !usuario.Activo)
                {
                    return Unauthorized(new ApiResponseDto<LoginResponseDto>
                    {
                        Exitoso = false,
                        Mensaje = "Usuario o contraseña incorrectos"
                    });
                }

                // Verificar contraseña
                var passwordMatches = _passwordService.VerifyPassword(request.Clave, usuario.Clave);
                
                // Fallback: si la verificación falla y la contraseña en BD parece NO ser hash BCrypt,
                // comparar simple igualdad (solo para migración desde texto plano)
                if (!passwordMatches)
                {
                    var stored = usuario.Clave ?? string.Empty;
                    var looksBcrypt = stored.StartsWith("$2a$") || stored.StartsWith("$2b$") || stored.StartsWith("$2y$");
                    if (!looksBcrypt && request.Clave == stored)
                    {
                        passwordMatches = true;
                        // Opcional: rehashear y actualizar a BCrypt para endurecer seguridad
                        try
                        {
                            usuario.Clave = _passwordService.HashPassword(request.Clave);
                            await _context.SaveChangesAsync();
                        }
                        catch (Exception ex)
                        {
                            _logger.LogWarning(ex, "No se pudo actualizar hash BCrypt para usuario {Email}", usuario.Correo);
                        }
                    }
                }

                if (!passwordMatches)
                {
                    return Unauthorized(new ApiResponseDto<LoginResponseDto>
                    {
                        Exitoso = false,
                        Mensaje = "Usuario o contraseña incorrectos"
                    });
                }

                // Sincronizar/asegurar Cliente para el usuario autenticado
                var correoUsuario = (usuario.Correo ?? string.Empty).Trim().ToLowerInvariant();
                try
                {
                    var existeCliente = await _context.Clientes.AnyAsync(c => (c.Email ?? string.Empty).ToLower() == correoUsuario);
                    if (!existeCliente)
                    {
                        var nuevoCliente = new Cliente
                        {
                            Nombre = (usuario.Nombres ?? string.Empty).Trim(),
                            Apellido = (usuario.Apellidos ?? string.Empty).Trim(),
                            Email = correoUsuario,
                            Activo = true,
                            FechaRegistro = DateTime.UtcNow
                        };

                        _context.Clientes.Add(nuevoCliente);
                        await _context.SaveChangesAsync();
                        _logger.LogInformation("Cliente creado automáticamente para usuario {Email}", usuario.Correo);
                    }
                }
                catch (Exception ex)
                {
                    _logger.LogWarning(ex, "No se pudo crear Cliente automáticamente para usuario {Email}", usuario.Correo);
                }

                // Generar tokens
                var token = _jwtService.GenerateToken(usuario);
                var refreshToken = _jwtService.GenerateRefreshToken();

                // Guardar refresh token en la base de datos
                var refreshDays3 = _configuration.GetValue<int>("Jwt:RefreshTokenExpiryInDays", 7);
                var refreshTokenEntity = new RefreshToken
                {
                    Token = refreshToken,
                    UsuarioId = usuario.Id,
                    FechaCreacion = DateTime.UtcNow,
                    FechaExpiracion = DateTime.UtcNow.AddDays(refreshDays3),
                    Usado = false,
                    Revocado = false
                };

                try
                {
                    _context.RefreshTokens.Add(refreshTokenEntity);
                    await _context.SaveChangesAsync();
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Error al guardar RefreshToken para usuario {UserId}: {Message}", usuario.Id, ex.Message);
                    
                    // Intentar login sin refresh token como fallback
                    var responseWithoutRefresh = new LoginResponseDto
                    {
                        Token = token,
                        RefreshToken = string.Empty, // Sin refresh token por el error
                        Expiracion = DateTime.UtcNow.AddHours(1),
                        Usuario = new UsuarioInfoDto
                        {
                            Id = usuario.Id,
                            Nombres = usuario.Nombres,
                            Apellidos = usuario.Apellidos,
                            Correo = usuario.Correo,
                            IdRol = usuario.IdRol,
                            NombreRol = usuario.Rol?.NombreRol ?? "Usuario",
                            Activo = usuario.Activo,
                            FechaRegistro = usuario.FechaRegistro
                        }
                    };

                    _logger.LogInformation("Usuario {Email} inició sesión exitosamente (sin refresh token)", usuario.Correo);

                    return Ok(new ApiResponseDto<LoginResponseDto>
                    {
                        Exitoso = true,
                        Mensaje = "Inicio de sesión exitoso",
                        Data = responseWithoutRefresh
                    });
                }

                var response = new LoginResponseDto
                {
                    Token = token,
                    RefreshToken = refreshToken,
                    Expiracion = DateTime.UtcNow.AddHours(1),
                    Usuario = new UsuarioInfoDto
                    {
                        Id = usuario.Id,
                        Nombres = usuario.Nombres,
                        Apellidos = usuario.Apellidos,
                        Correo = usuario.Correo,
                        IdRol = usuario.IdRol,
                        NombreRol = usuario.Rol?.NombreRol ?? "Usuario",
                        Activo = usuario.Activo,
                        FechaRegistro = usuario.FechaRegistro
                    }
                };

                _logger.LogInformation("Usuario {Email} inició sesión exitosamente", usuario.Correo);

                return Ok(new ApiResponseDto<LoginResponseDto>
                {
                    Exitoso = true,
                    Mensaje = "Inicio de sesión exitoso",
                    Data = response
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error durante el inicio de sesión");
                
                if (_env.IsDevelopment())
                {
                    return StatusCode(StatusCodes.Status500InternalServerError, new ApiResponseDto<LoginResponseDto>
                    {
                        Exitoso = false,
                        Mensaje = "Error durante el inicio de sesión",
                        Errores = new List<string> { ex.Message, ex.StackTrace }
                    });
                }

                return StatusCode(500, new ApiResponseDto<LoginResponseDto>
                {
                    Exitoso = false,
                    Mensaje = "Error interno del servidor"
                });
            }
        }

        // POST: api/auth/register
        [HttpPost("register")]
        public async Task<ActionResult<ApiResponseDto<RegisterResponseDto>>> Register([FromBody] RegisterRequestDto request)
        {
            try
            {
                _logger.LogInformation("=== DEBUG REGISTER ===");
                _logger.LogInformation("Datos recibidos: {@Request}", request);
                _logger.LogInformation("ModelState válido: {IsValid}", ModelState.IsValid);
                
                if (!ModelState.IsValid)
                {
                    var errores = ModelState.Values
                        .SelectMany(v => v.Errors)
                        .Select(e => e.ErrorMessage)
                        .ToList();
                    
                    _logger.LogWarning("Errores de validación: {@Errores}", errores);
                    
                    return BadRequest(new ApiResponseDto<RegisterResponseDto>
                    {
                        Exitoso = false,
                        Mensaje = "Datos de entrada inválidos",
                        Errores = errores
                    });
                }

                // Verificar que el email no exista
                var usuarioExistente = await _context.Usuarios
                    .FirstOrDefaultAsync(u => u.Correo.ToLower() == request.Correo.ToLower());

                if (usuarioExistente != null)
                {
                    return BadRequest(new ApiResponseDto<RegisterResponseDto>
                    {
                        Exitoso = false,
                        Mensaje = "Ya existe un usuario con ese correo electrónico"
                    });
                }

                // Verificar que el rol existe
                var rol = await _context.Roles.FirstOrDefaultAsync(r => r.Id == request.IdRol && r.Activo);
                if (rol == null)
                {
                    return BadRequest(new ApiResponseDto<RegisterResponseDto>
                    {
                        Exitoso = false,
                        Mensaje = "El rol especificado no existe o no está activo"
                    });
                }

                // Crear nuevo usuario con contraseña hasheada
                var nuevoUsuario = new Usuario
                {
                    Nombres = request.Nombres.Trim(),
                    Apellidos = request.Apellidos.Trim(),
                    Correo = request.Correo.ToLower().Trim(),
                    Clave = _passwordService.HashPassword(request.Clave),
                    IdRol = request.IdRol,
                    Activo = true,
                    FechaRegistro = DateTime.UtcNow
                };

                _context.Usuarios.Add(nuevoUsuario);
                await _context.SaveChangesAsync();

                // Crear registro de Cliente automáticamente si no existe (OAuth)
                try
                {
                    var correoUsuario = nuevoUsuario.Correo.ToLower().Trim();
                    var clienteExiste = await _context.Clientes
                        .AnyAsync(c => c.Email.ToLower() == correoUsuario);

                    if (!clienteExiste)
                    {
                        var nuevoCliente = new Cliente
                        {
                            Nombre = nuevoUsuario.Nombres.Trim(),
                            Apellido = nuevoUsuario.Apellidos.Trim(),
                            Email = correoUsuario,
                            Activo = true,
                            FechaRegistro = DateTime.UtcNow
                        };

                        _context.Clientes.Add(nuevoCliente);
                        await _context.SaveChangesAsync();
                        _logger.LogInformation("Cliente creado automáticamente (OAuth) para usuario {Email}", nuevoUsuario.Correo);
                    }
                    else
                    {
                        _logger.LogInformation("Cliente ya existía (OAuth) para usuario {Email}", nuevoUsuario.Correo);
                    }
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Error al crear Cliente (OAuth) para usuario {Email}", nuevoUsuario.Correo);
                }

                // Enviar email de bienvenida (no bloquea el flujo si falla)
                try
                {
                    var nombreUsuario = $"{nuevoUsuario.Nombres} {nuevoUsuario.Apellidos}".Trim();

                    var welcomeToken = _tokenService.GenerateWelcomeToken(nuevoUsuario.Id, nuevoUsuario.Correo);

                var enviado = await _emailService.SendWelcomeEmailAsync(
                    nuevoUsuario.Correo,
                    string.IsNullOrWhiteSpace(nombreUsuario) ? nuevoUsuario.Nombres : nombreUsuario,
                    welcomeToken
                );
                    if (!enviado)
                    {
                        _logger.LogWarning("No se pudo enviar el email de bienvenida a {Email}", nuevoUsuario.Correo);
                    }
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Error al enviar email de bienvenida a {Email}", nuevoUsuario.Correo);
                }

                // Cargar el rol para la respuesta
                await _context.Entry(nuevoUsuario).Reference(u => u.Rol).LoadAsync();

                var usuarioInfo = new UsuarioInfoDto
                {
                    Id = nuevoUsuario.Id,
                    Nombres = nuevoUsuario.Nombres,
                    Apellidos = nuevoUsuario.Apellidos,
                    Correo = nuevoUsuario.Correo,
                    IdRol = nuevoUsuario.IdRol,
                    NombreRol = nuevoUsuario.Rol?.NombreRol ?? "Usuario",
                    Activo = nuevoUsuario.Activo,
                    FechaRegistro = nuevoUsuario.FechaRegistro
                };

                _logger.LogInformation("Usuario {Email} registrado exitosamente", nuevoUsuario.Correo);

                return Ok(new ApiResponseDto<RegisterResponseDto>
                {
                    Exitoso = true,
                    Mensaje = "Usuario registrado exitosamente",
                    Data = new RegisterResponseDto
                    {
                        Exitoso = true,
                        Mensaje = "Registro exitoso",
                        Usuario = usuarioInfo
                    }
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error durante el registro de usuario");
                return StatusCode(500, new ApiResponseDto<RegisterResponseDto>
                {
                    Exitoso = false,
                    Mensaje = "Error interno del servidor"
                });
            }
        }

        // POST: api/auth/refresh-token
        [AllowAnonymous]
        [HttpPost("refresh-token")]
        public async Task<ActionResult<ApiResponseDto<LoginResponseDto>>> RefreshToken([FromBody] RefreshTokenRequestDto request)
        {
            try
            {
                if (!ModelState.IsValid)
                {
                    return BadRequest(new ApiResponseDto<LoginResponseDto>
                    {
                        Exitoso = false,
                        Mensaje = "Datos de entrada inválidos"
                    });
                }

                int userId = 0;
                if (!string.IsNullOrWhiteSpace(request.Token))
                {
                    // Validar el token expirado si viene
                    var principal = _jwtService.GetPrincipalFromExpiredToken(request.Token);
                    if (principal == null)
                    {
                        return Unauthorized(new ApiResponseDto<LoginResponseDto>
                        {
                            Exitoso = false,
                            Mensaje = "Token inválido"
                        });
                    }

                    var userIdClaim = principal.FindFirst(ClaimTypes.NameIdentifier)?.Value;
                    if (!int.TryParse(userIdClaim, out userId))
                    {
                        return Unauthorized(new ApiResponseDto<LoginResponseDto>
                        {
                            Exitoso = false,
                            Mensaje = "Token inválido"
                        });
                    }
                }
                else
                {
                    // Token no provisto: derivar usuario desde el refresh token activo
                    var refreshLookup = await _context.RefreshTokens
                        .Include(rt => rt.Usuario)
                        .ThenInclude(u => u.Rol)
                        .Where(rt => rt.Token == request.RefreshToken && rt.Usado == false && rt.Revocado == false && DateTime.UtcNow <= rt.FechaExpiracion)
                        .OrderByDescending(rt => rt.FechaCreacion)
                        .FirstOrDefaultAsync();

                    if (refreshLookup == null)
                    {
                        return Unauthorized(new ApiResponseDto<LoginResponseDto>
                        {
                            Exitoso = false,
                            Mensaje = "Refresh token inválido o expirado"
                        });
                    }

                    userId = refreshLookup.UsuarioId;
                }

                // Buscar el refresh token en la base de datos
                var refreshTokenEntity = await _context.RefreshTokens
                    .Include(rt => rt.Usuario)
                    .ThenInclude(u => u.Rol)
                    .FirstOrDefaultAsync(rt => rt.Token == request.RefreshToken && rt.UsuarioId == userId);

                if (refreshTokenEntity == null || !refreshTokenEntity.EsActivo)
                {
                    return Unauthorized(new ApiResponseDto<LoginResponseDto>
                    {
                        Exitoso = false,
                        Mensaje = "Refresh token inválido o expirado"
                    });
                }

                // Marcar el refresh token como usado
                refreshTokenEntity.Usado = true;

                // Generar nuevos tokens
                var newToken = _jwtService.GenerateToken(refreshTokenEntity.Usuario);
                var newRefreshToken = _jwtService.GenerateRefreshToken();

                // Crear nuevo refresh token
                var refreshDays4 = _configuration.GetValue<int>("Jwt:RefreshTokenExpiryInDays", 7);
                var newRefreshTokenEntity = new RefreshToken
                {
                    Token = newRefreshToken,
                    UsuarioId = userId,
                    FechaExpiracion = DateTime.UtcNow.AddDays(refreshDays4),
                    ReemplazadoPor = newRefreshToken
                };

                refreshTokenEntity.ReemplazadoPor = newRefreshToken;
                _context.RefreshTokens.Add(newRefreshTokenEntity);
                await _context.SaveChangesAsync();

                var response = new LoginResponseDto
                {
                    Token = newToken,
                    RefreshToken = newRefreshToken,
                    Expiracion = DateTime.UtcNow.AddHours(1),
                    Usuario = new UsuarioInfoDto
                    {
                        Id = refreshTokenEntity.Usuario.Id,
                        Nombres = refreshTokenEntity.Usuario.Nombres,
                        Apellidos = refreshTokenEntity.Usuario.Apellidos,
                        Correo = refreshTokenEntity.Usuario.Correo,
                        IdRol = refreshTokenEntity.Usuario.IdRol,
                        NombreRol = refreshTokenEntity.Usuario.Rol?.NombreRol ?? "Usuario",
                        Activo = refreshTokenEntity.Usuario.Activo,
                        FechaRegistro = refreshTokenEntity.Usuario.FechaRegistro
                    }
                };

                return Ok(new ApiResponseDto<LoginResponseDto>
                {
                    Exitoso = true,
                    Mensaje = "Token renovado exitosamente",
                    Data = response
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error durante la renovación del token");
                return StatusCode(500, new ApiResponseDto<LoginResponseDto>
                {
                    Exitoso = false,
                    Mensaje = "Error interno del servidor"
                });
            }
        }

        // POST: api/auth/forgot-password
        [HttpPost("forgot-password")]
        public async Task<ActionResult<ApiResponseDto<object>>> ForgotPassword([FromBody] ForgotPasswordRequestDto request)
        {
            try
            {
                _logger.LogInformation("=== INICIO FORGOT PASSWORD ===");
                _logger.LogInformation("Correo solicitado: {Email}", request.Correo);
                
                if (!ModelState.IsValid)
                {
                    _logger.LogWarning("ModelState inválido para forgot-password");
                    return BadRequest(new ApiResponseDto<object>
                    {
                        Exitoso = false,
                        Mensaje = "Datos de entrada inválidos"
                    });
                }

                var usuario = await _context.Usuarios
                    .FirstOrDefaultAsync(u => u.Correo.ToLower() == request.Correo.ToLower());

                _logger.LogInformation("Usuario encontrado: {UsuarioEncontrado}", usuario != null);
                if (usuario != null)
                {
                    _logger.LogInformation("Datos del usuario: ID={Id}, Nombre={Nombre}, Correo={Correo}", 
                        usuario.Id, $"{usuario.Nombres} {usuario.Apellidos}".Trim(), usuario.Correo);
                }

                // Siempre retornar éxito para evitar enumeración de usuarios
                if (usuario == null)
                {
                    _logger.LogWarning("Usuario no encontrado para el correo: {Email}", request.Correo);
                    return Ok(new ApiResponseDto<object>
                    {
                        Exitoso = true,
                        Mensaje = "Si el correo existe, se enviará un código de verificación"
                    });
                }

                // Generar código de 6 dígitos
                var random = new Random();
                var codigo = random.Next(100000, 999999).ToString();
                
                var passwordResetToken = new PasswordResetToken
                {
                    Codigo = codigo,
                    UsuarioId = usuario.Id,
                    FechaExpiracion = DateTime.UtcNow.AddHours(1), // Expira en 1 hora
                    DireccionIP = HttpContext.Connection.RemoteIpAddress?.ToString(),
                    UserAgent = HttpContext.Request.Headers["User-Agent"].ToString()
                };

                // Invalidar códigos anteriores del usuario
                var tokensAnteriores = await _context.PasswordResetTokens
                    .Where(prt => prt.UsuarioId == usuario.Id && !prt.Usado && DateTime.UtcNow <= prt.FechaExpiracion)
                    .ToListAsync();

                foreach (var token in tokensAnteriores)
                {
                    token.Usado = true;
                }

                try
                {
                    _context.PasswordResetTokens.Add(passwordResetToken);
                    await _context.SaveChangesAsync();
                    _logger.LogInformation("Código de recuperación guardado en BD para usuario {Email}", usuario.Correo);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Error al guardar PasswordResetToken para usuario {UserId}: {Message}", usuario.Id, ex.Message);
                    
                    // En lugar de continuar, abortar el proceso para no enviar un código inexistente
                    return StatusCode(500, new ApiResponseDto<object>
                    {
                        Exitoso = false,
                        Mensaje = "No se pudo generar el código de verificación. Inténtalo nuevamente."
                    });
                }

                // Enviar código por correo (independientemente de si se guardó el token en BD)
                try
                {
                    _logger.LogInformation("=== DEBUG FORGOT PASSWORD ===");
                    _logger.LogInformation("Intentando enviar código de recuperación a {Email} con código {Codigo}", usuario.Correo, codigo);
                    _logger.LogInformation("Tipo de servicio de email: {EmailServiceType}", _emailService.GetType().Name);
                    
                    var emailSent = await _emailService.SendPasswordResetCodeAsync(
                        usuario.Correo, 
                        $"{usuario.Nombres} {usuario.Apellidos}".Trim(), 
                        codigo);

                    _logger.LogInformation("Resultado del envío de email: {EmailSent}", emailSent);
                    _logger.LogInformation("==============================");

                    if (emailSent)
                    {
                        _logger.LogInformation("Código de recuperación enviado exitosamente a {Email}", usuario.Correo);
                    }
                    else
                    {
                        _logger.LogWarning("No se pudo enviar el código de recuperación a {Email}", usuario.Correo);
                    }
                }
                catch (Exception emailEx)
                {
                    _logger.LogError(emailEx, "Error al enviar código de recuperación a {Email}: {Message}", usuario.Correo, emailEx.Message);
                }

                var isMock = _emailService is PetLove.API.Services.MockEmailService;

                return Ok(new ApiResponseDto<object>
                {
                    Exitoso = true,
                    Mensaje = "Si el correo existe, se enviará un código de verificación",
                    Data = isMock ? new { Codigo = codigo, Expira = passwordResetToken.FechaExpiracion } : null
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error durante la solicitud de recuperación de contraseña");
                return StatusCode(500, new ApiResponseDto<object>
                {
                    Exitoso = false,
                    Mensaje = "Error interno del servidor"
                });
            }
        }

        // POST: api/auth/verify-code
        [HttpPost("verify-code")]
        public async Task<ActionResult<ApiResponseDto<object>>> VerifyCode([FromBody] VerifyCodeRequestDto request)
        {
            try
            {
                if (!ModelState.IsValid)
                {
                    return BadRequest(new ApiResponseDto<object>
                    {
                        Exitoso = false,
                        Mensaje = "Datos de entrada inválidos"
                    });
                }

                var usuario = await _context.Usuarios
                    .FirstOrDefaultAsync(u => u.Correo.ToLower() == request.Correo.ToLower() && u.Activo);

                if (usuario == null)
                {
                    return BadRequest(new ApiResponseDto<object>
                    {
                        Exitoso = false,
                        Mensaje = "Código inválido o expirado"
                    });
                }

                var resetToken = await _context.PasswordResetTokens
                    .FirstOrDefaultAsync(prt => prt.Codigo == request.Codigo && 
                                              prt.UsuarioId == usuario.Id && 
                                              !prt.Usado && 
                                              DateTime.UtcNow <= prt.FechaExpiracion);

                if (resetToken == null)
                {
                    return BadRequest(new ApiResponseDto<object>
                    {
                        Exitoso = false,
                        Mensaje = "Código inválido o expirado"
                    });
                }

                _logger.LogInformation("Código verificado exitosamente para usuario {Email}", usuario.Correo);

                return Ok(new ApiResponseDto<object>
                {
                    Exitoso = true,
                    Mensaje = "Código verificado correctamente"
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error en verify-code para {Email}", request.Correo);
                return StatusCode(500, new ApiResponseDto<object>
                {
                    Exitoso = false,
                    Mensaje = "Error interno del servidor"
                });
            }
        }

        // POST: api/auth/reset-password
        [HttpPost("reset-password")]
        public async Task<ActionResult<ApiResponseDto<object>>> ResetPassword([FromBody] ResetPasswordRequestDto request)
        {
            try
            {
                if (!ModelState.IsValid)
                {
                    return BadRequest(new ApiResponseDto<object>
                    {
                        Exitoso = false,
                        Mensaje = "Datos de entrada inválidos"
                    });
                }

                var usuario = await _context.Usuarios
                    .FirstOrDefaultAsync(u => u.Correo.ToLower() == request.Correo.ToLower());

                if (usuario == null)
                {
                    return BadRequest(new ApiResponseDto<object>
                    {
                        Exitoso = false,
                        Mensaje = "Código inválido o expirado"
                    });
                }

                var resetToken = await _context.PasswordResetTokens
                    .Include(prt => prt.Usuario)
                    .FirstOrDefaultAsync(prt => prt.Codigo == request.Codigo && 
                                              prt.UsuarioId == usuario.Id && 
                                              !prt.Usado && 
                                              DateTime.UtcNow <= prt.FechaExpiracion);

                if (resetToken == null)
                {
                    return BadRequest(new ApiResponseDto<object>
                    {
                        Exitoso = false,
                        Mensaje = "Código inválido o expirado"
                    });
                }

                // Actualizar la contraseña del usuario
                resetToken.Usuario.Clave = _passwordService.HashPassword(request.NuevaClave);
                resetToken.Usado = true;

                await _context.SaveChangesAsync();

                _logger.LogInformation("Contraseña restablecida exitosamente para usuario {Email}", resetToken.Usuario.Correo);

                return Ok(new ApiResponseDto<object>
                {
                    Exitoso = true,
                    Mensaje = "Contraseña restablecida exitosamente"
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error durante el restablecimiento de contraseña");
                return StatusCode(500, new ApiResponseDto<object>
                {
                    Exitoso = false,
                    Mensaje = "Error interno del servidor"
                });
            }
        }

        // POST: api/auth/change-password
        [HttpPost("change-password")]
        [Authorize]
        public async Task<ActionResult<ApiResponseDto<object>>> ChangePassword([FromBody] ChangePasswordRequestDto request)
        {
            try
            {
                if (!ModelState.IsValid)
                {
                    return BadRequest(new ApiResponseDto<object>
                    {
                        Exitoso = false,
                        Mensaje = "Datos de entrada inválidos"
                    });
                }

                var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
                if (!int.TryParse(userIdClaim, out int userId))
                {
                    return Unauthorized(new ApiResponseDto<object>
                    {
                        Exitoso = false,
                        Mensaje = "Token inválido"
                    });
                }

                var usuario = await _context.Usuarios.FindAsync(userId);
                if (usuario == null || !usuario.Activo)
                {
                    return NotFound(new ApiResponseDto<object>
                    {
                        Exitoso = false,
                        Mensaje = "Usuario no encontrado"
                    });
                }

                // Verificar contraseña actual
                if (!_passwordService.VerifyPassword(request.ClaveActual, usuario.Clave))
                {
                    return BadRequest(new ApiResponseDto<object>
                    {
                        Exitoso = false,
                        Mensaje = "La contraseña actual es incorrecta"
                    });
                }

                // Actualizar contraseña
                usuario.Clave = _passwordService.HashPassword(request.NuevaClave);
                await _context.SaveChangesAsync();

                _logger.LogInformation("Contraseña cambiada exitosamente para usuario {Email}", usuario.Correo);

                return Ok(new ApiResponseDto<object>
                {
                    Exitoso = true,
                    Mensaje = "Contraseña cambiada exitosamente"
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error durante el cambio de contraseña");
                return StatusCode(500, new ApiResponseDto<object>
                {
                    Exitoso = false,
                    Mensaje = "Error interno del servidor"
                });
            }
        }

        // POST: api/auth/logout
        [HttpPost("logout")]
        [Authorize]
        public async Task<ActionResult<ApiResponseDto<object>>> Logout([FromBody] RefreshTokenRequestDto request)
        {
            try
            {
                var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
                if (int.TryParse(userIdClaim, out int userId))
                {
                    // Revocar el refresh token
                    var refreshToken = await _context.RefreshTokens
                        .FirstOrDefaultAsync(rt => rt.Token == request.RefreshToken && rt.UsuarioId == userId);

                    if (refreshToken != null)
                    {
                        refreshToken.Revocado = true;
                        refreshToken.RazonRevocacion = "Logout del usuario";
                        await _context.SaveChangesAsync();
                    }
                }

                return Ok(new ApiResponseDto<object>
                {
                    Exitoso = true,
                    Mensaje = "Sesión cerrada exitosamente"
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error durante el logout");
                return StatusCode(500, new ApiResponseDto<object>
                {
                    Exitoso = false,
                    Mensaje = "Error interno del servidor"
                });
            }
        }

        // GET: api/auth/profile
        [HttpGet("profile")]
        [Authorize]
        public async Task<ActionResult<ApiResponseDto<UsuarioInfoDto>>> GetProfile()
        {
            try
            {
                var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
                if (!int.TryParse(userIdClaim, out int userId))
                {
                    return Unauthorized(new ApiResponseDto<UsuarioInfoDto>
                    {
                        Exitoso = false,
                        Mensaje = "Token inválido"
                    });
                }

                var usuario = await _context.Usuarios
                    .Include(u => u.Rol)
                    .FirstOrDefaultAsync(u => u.Id == userId && u.Activo);

                if (usuario == null)
                {
                    return NotFound(new ApiResponseDto<UsuarioInfoDto>
                    {
                        Exitoso = false,
                        Mensaje = "Usuario no encontrado"
                    });
                }

                var usuarioInfo = new UsuarioInfoDto
                {
                    Id = usuario.Id,
                    Nombres = usuario.Nombres,
                    Apellidos = usuario.Apellidos,
                    Correo = usuario.Correo,
                    IdRol = usuario.IdRol,
                    NombreRol = usuario.Rol?.NombreRol ?? "Usuario",
                    Activo = usuario.Activo,
                    FechaRegistro = usuario.FechaRegistro,
                    FotoPerfilUrl = usuario.FotoPerfilUrl
                };

                return Ok(new ApiResponseDto<UsuarioInfoDto>
                {
                    Exitoso = true,
                    Mensaje = "Perfil obtenido exitosamente",
                    Data = usuarioInfo
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error al obtener el perfil del usuario");
                return StatusCode(500, new ApiResponseDto<UsuarioInfoDto>
                {
                    Exitoso = false,
                    Mensaje = "Error interno del servidor"
                });
            }
        }
    }

    // DTOs para las requests
    public class LoginRequest
    {
        public string Email { get; set; } = string.Empty;
        public string Password { get; set; } = string.Empty;
    }

    public class RegisterRequest
    {
        public string Nombres { get; set; } = string.Empty;
        public string Apellidos { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public string Password { get; set; } = string.Empty;
    }

    public class OAuthSyncRequest
    {
        public string Email { get; set; } = string.Empty;
        public string Name { get; set; } = string.Empty;
        public string? Image { get; set; }
        public string? Provider { get; set; }
        public string? ProviderId { get; set; }
    }
}