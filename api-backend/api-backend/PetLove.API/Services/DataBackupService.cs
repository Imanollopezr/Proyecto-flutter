using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using PetLove.Infrastructure.Data;

namespace PetLove.API.Services
{
    public class BackupSettings
    {
        public bool Enabled { get; set; } = true;
        public int IntervalMinutes { get; set; } = 15;
        public string Directory { get; set; } = "backups";
        public int RetentionDays { get; set; } = 14;
    }

    public class DataBackupService : BackgroundService
    {
        private readonly IServiceScopeFactory _scopeFactory;
        private readonly ILogger<DataBackupService> _logger;
        private readonly BackupSettings _settings;

        public DataBackupService(IServiceScopeFactory scopeFactory,
                                 ILogger<DataBackupService> logger,
                                 IOptionsMonitor<BackupSettings> settings)
        {
            _scopeFactory = scopeFactory;
            _logger = logger;
            _settings = settings.CurrentValue;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            if (!_settings.Enabled)
            {
                _logger.LogInformation("Respaldo deshabilitado por configuración.");
                return;
            }

            _logger.LogInformation("Servicio de respaldo iniciado. Intervalo: {Interval} minutos.", _settings.IntervalMinutes);

            // Respaldo inicial al comenzar
            await BackupOnceAsync(stoppingToken);

            // Timer periódico
            using var timer = new PeriodicTimer(TimeSpan.FromMinutes(Math.Max(_settings.IntervalMinutes, 1)));
            while (await timer.WaitForNextTickAsync(stoppingToken))
            {
                await BackupOnceAsync(stoppingToken);
            }
        }

        public override async Task StopAsync(CancellationToken cancellationToken)
        {
            _logger.LogInformation("Servicio de respaldo deteniéndose. Ejecutando respaldo final...");
            await BackupOnceAsync(cancellationToken);
            _logger.LogInformation("Respaldo final completado.");
            await base.StopAsync(cancellationToken);
        }

        private async Task BackupOnceAsync(CancellationToken ct)
        {
            try
            {
                using var scope = _scopeFactory.CreateScope();
                var db = scope.ServiceProvider.GetRequiredService<PetLoveDbContext>();

                var baseDir = Path.Combine(AppContext.BaseDirectory, _settings.Directory);
                Directory.CreateDirectory(baseDir);

                // Politica de retención
                ApplyRetention(baseDir);

                var timestamp = DateTime.UtcNow.ToString("yyyyMMdd_HHmmss");
                var options = new JsonSerializerOptions { WriteIndented = true };

                // Tablas principales
                await WriteJsonAsync(baseDir, $"Productos_{timestamp}.json", await db.Productos.AsNoTracking().ToListAsync(ct), options, ct);
                await WriteJsonAsync(baseDir, $"Clientes_{timestamp}.json", await db.Clientes.AsNoTracking().ToListAsync(ct), options, ct);
                await WriteJsonAsync(baseDir, $"Proveedores_{timestamp}.json", await db.Proveedores.AsNoTracking().ToListAsync(ct), options, ct);
                await WriteJsonAsync(baseDir, $"Ventas_{timestamp}.json", await db.Ventas.AsNoTracking().ToListAsync(ct), options, ct);
                await WriteJsonAsync(baseDir, $"Compras_{timestamp}.json", await db.Compras.AsNoTracking().ToListAsync(ct), options, ct);
                await WriteJsonAsync(baseDir, $"Pedidos_{timestamp}.json", await db.Pedidos.AsNoTracking().ToListAsync(ct), options, ct);
                await WriteJsonAsync(baseDir, $"Usuarios_{timestamp}.json", await db.Usuarios.AsNoTracking().ToListAsync(ct), options, ct);
                await WriteJsonAsync(baseDir, $"RefreshTokens_{timestamp}.json", await db.RefreshTokens.AsNoTracking().ToListAsync(ct), options, ct);
                await WriteJsonAsync(baseDir, $"PasswordResetTokens_{timestamp}.json", await db.PasswordResetTokens.AsNoTracking().ToListAsync(ct), options, ct);
                await WriteJsonAsync(baseDir, $"Categorias_{timestamp}.json", await db.Categorias.AsNoTracking().ToListAsync(ct), options, ct);
                await WriteJsonAsync(baseDir, $"Marcas_{timestamp}.json", await db.Marcas.AsNoTracking().ToListAsync(ct), options, ct);
                await WriteJsonAsync(baseDir, $"Medidas_{timestamp}.json", await db.Medidas.AsNoTracking().ToListAsync(ct), options, ct);
                await WriteJsonAsync(baseDir, $"MetodosPago_{timestamp}.json", await db.MetodosPago.AsNoTracking().ToListAsync(ct), options, ct);
                await WriteJsonAsync(baseDir, $"Estados_{timestamp}.json", await db.Estados.AsNoTracking().ToListAsync(ct), options, ct);
                await WriteJsonAsync(baseDir, $"Carritos_{timestamp}.json", await db.Carritos.AsNoTracking().ToListAsync(ct), options, ct);
                await WriteJsonAsync(baseDir, $"CarritoItems_{timestamp}.json", await db.CarritoItems.AsNoTracking().ToListAsync(ct), options, ct);
                await WriteJsonAsync(baseDir, $"ProductoProveedores_{timestamp}.json", await db.ProductoProveedores.AsNoTracking().ToListAsync(ct), options, ct);

                _logger.LogInformation("Respaldo completado en {BaseDir}", baseDir);
            }
            catch (OperationCanceledException)
            {
                _logger.LogWarning("Respaldo cancelado por cierre de la aplicación.");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error durante el respaldo.");
            }
        }

        private static async Task WriteJsonAsync<T>(string dir, string filename, T data, JsonSerializerOptions options, CancellationToken ct)
        {
            var path = Path.Combine(dir, filename);
            await using var stream = new FileStream(path, FileMode.Create, FileAccess.Write, FileShare.None);
            await JsonSerializer.SerializeAsync(stream, data, options, ct);
        }

        private void ApplyRetention(string baseDir)
        {
            try
            {
                var cutoff = DateTime.UtcNow.AddDays(-Math.Max(_settings.RetentionDays, 1));
                foreach (var file in Directory.GetFiles(baseDir, "*.json"))
                {
                    var name = Path.GetFileNameWithoutExtension(file);
                    // Expect format ..._yyyyMMdd_HHmmss
                    var parts = name.Split('_');
                    var stamp = parts.LastOrDefault();
                    if (DateTime.TryParseExact(stamp, "yyyyMMdd_HHmmss", null, System.Globalization.DateTimeStyles.AssumeUniversal, out var dt))
                    {
                        if (dt < cutoff)
                        {
                            File.Delete(file);
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "No se pudo aplicar retención de respaldos.");
            }
        }
    }
}