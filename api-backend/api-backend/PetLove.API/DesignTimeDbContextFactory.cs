using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;
using Microsoft.Extensions.Configuration;
using PetLove.Infrastructure.Data;
using System;
using System.IO;

namespace PetLove.API
{
    // Factory para crear PetLoveDbContext en tiempo de diseño (migraciones)
    public class DesignTimeDbContextFactory : IDesignTimeDbContextFactory<PetLoveDbContext>
    {
        public PetLoveDbContext CreateDbContext(string[] args)
        {
            // Construir configuración desde appsettings.json y variables de entorno
            var environment = Environment.GetEnvironmentVariable("ASPNETCORE_ENVIRONMENT") ?? "Development";

            var configuration = new ConfigurationBuilder()
                .SetBasePath(Directory.GetCurrentDirectory())
                .AddJsonFile("appsettings.json", optional: true)
                .AddJsonFile($"appsettings.{environment}.json", optional: true)
                .AddEnvironmentVariables()
                .Build();

            var useInMemory = configuration.GetValue<bool>("UseInMemoryDb");

            var optionsBuilder = new DbContextOptionsBuilder<PetLoveDbContext>();

            if (useInMemory)
            {
                // Para generar migraciones, preferimos SQL Server; pero si está activado InMemory,
                // seguimos leyendo la cadena y aplicando SQL Server para que las migraciones se creen correctamente.
                // Esto permite crear migraciones aunque el entorno use InMemory en tiempo de ejecución.
            }

            var connectionString = configuration.GetConnectionString("DefaultConnection");
            if (string.IsNullOrWhiteSpace(connectionString))
            {
                // Fallback por si no hay cadena: intentar SQLEXPRESS por defecto
                connectionString = "Server=.\\SQLEXPRESS;Database=PetLove;Trusted_Connection=true;MultipleActiveResultSets=true;TrustServerCertificate=true";
            }

            optionsBuilder.UseSqlServer(connectionString, sqlOptions =>
            {
                sqlOptions.MigrationsAssembly("PetLove.API");
                sqlOptions.CommandTimeout(300);
                sqlOptions.EnableRetryOnFailure(3, TimeSpan.FromSeconds(30), null);
            });

            return new PetLoveDbContext(optionsBuilder.Options);
        }
    }
}