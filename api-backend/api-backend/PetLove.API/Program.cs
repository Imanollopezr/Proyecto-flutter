using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using PetLove.Infrastructure.Data;
using PetLove.API.Middleware;
using PetLove.API.Services;
using SendGrid;
using System.Text;

var builder = WebApplication.CreateBuilder(args);

// Usar configuración de Kestrel definida en appsettings/appsettings.Development.json
// (Se elimina el forzado de puerto para evitar conflictos y permitir 8090 en Development)

// Add services to the container.
builder.Services.AddControllers()
    .AddJsonOptions(options =>
    {
        options.JsonSerializerOptions.ReferenceHandler = System.Text.Json.Serialization.ReferenceHandler.IgnoreCycles;
        options.JsonSerializerOptions.WriteIndented = true;
        options.JsonSerializerOptions.PropertyNamingPolicy = System.Text.Json.JsonNamingPolicy.CamelCase;
    });
builder.Services.AddEndpointsApiExplorer();

// Configurar Swagger con soporte para JWT
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo { Title = "PetLove API", Version = "v1" });
    
    // Configurar JWT en Swagger
    c.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Description = "JWT Authorization header using the Bearer scheme. Example: \"Authorization: Bearer {token}\"",
        Name = "Authorization",
        In = ParameterLocation.Header,
        Type = SecuritySchemeType.ApiKey,
        Scheme = "Bearer"
    });

    c.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        {
            new OpenApiSecurityScheme
            {
                Reference = new OpenApiReference
                {
                    Type = ReferenceType.SecurityScheme,
                    Id = "Bearer"
                }
            },
            new string[] {}
        }
    });
});

// Configurar Entity Framework con PostgreSQL o InMemory (fallback para desarrollo)
var useInMemory = builder.Configuration.GetValue<bool>("UseInMemoryDb");
if (useInMemory)
{
    Console.WriteLine("⚙️ Usando InMemoryDatabase para desarrollo");
    builder.Services.AddDbContext<PetLoveDbContext>(options =>
        options
            .UseInMemoryDatabase("PetLoveDev")
            // Suprimir advertencia por transacciones ignoradas en InMemory
            .ConfigureWarnings(w => w.Ignore(Microsoft.EntityFrameworkCore.Diagnostics.InMemoryEventId.TransactionIgnoredWarning))
    );
}
else
{
    builder.Services.AddDbContext<PetLoveDbContext>(options =>
        options.UseNpgsql(builder.Configuration.GetConnectionString("DefaultConnection"),
            npgsqlOptions => {
                npgsqlOptions.MigrationsAssembly("PetLove.API");
                npgsqlOptions.CommandTimeout(300); // 5 minutos de timeout para comandos
                npgsqlOptions.EnableRetryOnFailure(
                    maxRetryCount: 3,
                    maxRetryDelay: TimeSpan.FromSeconds(30),
                    errorCodesToAdd: null);
            }));
}

// Registrar servicios personalizados
builder.Services.AddScoped<DatabaseInitializer>();
builder.Services.AddScoped<IJwtService, JwtService>();
builder.Services.AddScoped<IPasswordService, PasswordService>();
// Añadir después de la línea donde se registra IPasswordService
builder.Services.AddScoped<ITokenService, TokenService>();

// Configurar SendGrid
var sendGridApiKey = builder.Configuration["SendGrid:ApiKey"];

Console.WriteLine($"SendGrid API Key configurada: {(!string.IsNullOrEmpty(sendGridApiKey) ? "SÍ" : "NO")}");
Console.WriteLine($"API Key válida: {(!string.IsNullOrEmpty(sendGridApiKey) && sendGridApiKey != "YOUR_SENDGRID_API_KEY_HERE" && sendGridApiKey.StartsWith("SG.") ? "SÍ" : "NO")}");

if (!string.IsNullOrEmpty(sendGridApiKey) && sendGridApiKey != "YOUR_SENDGRID_API_KEY_HERE" && sendGridApiKey.StartsWith("SG."))
{
    builder.Services.AddSingleton<ISendGridClient>(provider => new SendGridClient(sendGridApiKey));
    builder.Services.AddScoped<IEmailService, EmailService>();
    Console.WriteLine("✅ Usando EmailService REAL de SendGrid");
}
else
{
    // Registrar un servicio mock para desarrollo si no hay API key
    builder.Services.AddScoped<IEmailService, MockEmailService>();
    Console.WriteLine("⚠️ Usando MockEmailService - Los correos NO se enviarán realmente");
}

builder.Services.AddLogging();
// Vincular la sección Backup a BackupSettings
builder.Services.Configure<BackupSettings>(builder.Configuration.GetSection("Backup"));
// Registrar servicio de respaldo automático
builder.Services.AddHostedService<DataBackupService>();

// Configurar JWT Authentication
var jwtKey = builder.Configuration["Jwt:Key"] ?? throw new InvalidOperationException("JWT Key not configured");
var jwtIssuer = builder.Configuration["Jwt:Issuer"] ?? throw new InvalidOperationException("JWT Issuer not configured");
var jwtAudience = builder.Configuration["Jwt:Audience"] ?? throw new InvalidOperationException("JWT Audience not configured");

builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuerSigningKey = true,
        IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey)),
        ValidateIssuer = true,
        ValidIssuer = jwtIssuer,
        ValidateAudience = true,
        ValidAudience = jwtAudience,
        ValidateLifetime = true,
        ClockSkew = TimeSpan.Zero
    };

    options.Events = new JwtBearerEvents
    {
        OnChallenge = context =>
        {
            context.HandleResponse();
            context.Response.StatusCode = 401;
            context.Response.ContentType = "application/json";
            
            var response = new
            {
                exitoso = false,
                mensaje = "Token inválido o expirado",
                codigo = 401
            };

            return context.Response.WriteAsync(System.Text.Json.JsonSerializer.Serialize(response));
        },
        OnForbidden = context =>
        {
            context.Response.StatusCode = 403;
            context.Response.ContentType = "application/json";
            
            var response = new
            {
                exitoso = false,
                mensaje = "Acceso denegado: permisos insuficientes",
                codigo = 403
            };

            return context.Response.WriteAsync(System.Text.Json.JsonSerializer.Serialize(response));
        }
    };
});

builder.Services.AddAuthorization();

// Configurar CORS
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowReactApp", policy =>
    {
        policy.SetIsOriginAllowed(origin =>
        {
            // Permitir cualquier localhost en desarrollo
            if (string.IsNullOrEmpty(origin)) return false;
            
            try
            {
                var uri = new Uri(origin);
                return uri.Host == "localhost" || uri.Host == "127.0.0.1";
            }
            catch
            {
                return false;
            }
        })
        .AllowAnyHeader()
        .AllowAnyMethod()
        .AllowCredentials();
    });
});

var app = builder.Build();

// Configure the HTTP request pipeline.
// Habilitar Swagger en todos los entornos para desarrollo y pruebas
app.UseSwagger();
app.UseSwaggerUI();

// app.UseHttpsRedirection(); // Comentado para desarrollo local

// Usar CORS
app.UseCors("AllowReactApp");

// Configurar archivos estáticos para servir imágenes
app.UseStaticFiles(new StaticFileOptions
{
    FileProvider = new Microsoft.Extensions.FileProviders.PhysicalFileProvider(
        Path.Combine(app.Environment.ContentRootPath, "uploads")),
    RequestPath = "/uploads"
});

// Usar middleware de autenticación y autorización
app.UseAuthentication();

// Ejecutar JWT middleware antes de la autorización para adjuntar el usuario al contexto
app.UseMiddleware<JwtMiddleware>();

// Autorización del framework
app.UseAuthorization();

// Manejo de respuestas personalizadas para 401/403
app.UseMiddleware<CustomAuthorizationMiddleware>();

app.MapControllers();

// Inicializar la base de datos y datos esenciales
using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<PetLoveDbContext>();
    // Aplicar migraciones pendientes al arrancar (PostgreSQL)
    await db.Database.MigrateAsync();

    var initializer = scope.ServiceProvider.GetRequiredService<DatabaseInitializer>();
    await initializer.InitializeAsync();
}
// Registrar eventos de ciclo de vida para confirmar cierre ordenado
app.Lifetime.ApplicationStarted.Register(() =>
{
    app.Logger.LogInformation("Aplicación iniciada. Persistencia PostgreSQL activa.");
});
app.Lifetime.ApplicationStopping.Register(() =>
{
    app.Logger.LogInformation("Aplicación en cierre. Finalizando operaciones y respaldo final...");
});
app.Run();